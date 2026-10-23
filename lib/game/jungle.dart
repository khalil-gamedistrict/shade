// Ghana jungle (Limbo jaisa silhouette): darakhton ki 4 layers, zameen pe fern/jhaariyan,
// latakti bailen, aur oopar se aati roshni ki kirnein.
//
// Speed ka raaz: har darakht/paude ki ek dafa tasveer (image) banti hai, phir har frame woh
// tasveer sirf hawa ke hisaab se jhukayi jaati hai. Qareeb wale darakhton ke patte alag se
// har frame hilte hain (drawVertices — GPU pe bohot sasta).
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'palette.dart';
import 'plants.dart';
import 'trees.dart';
import 'world.dart';

typedef Sprite = (ui.Image, Rect);

/// Har (i, salt) ke liye hamesha same "random" number 0..1
double _hash(int i, int salt) {
  final h = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return h - h.floorToDouble();
}

class SpriteCache {
  final _m = <String, Sprite>{};

  /// [build] shakalein aur unke rang deta hai — sirf pehli dafa chalta hai
  Sprite get(
    String key,
    double res,
    List<(List<Path>, Color)> Function() build,
  ) {
    final k = '$key@${(res * 4).round()}';
    final hit = _m[k];
    if (hit != null) return hit;
    final parts = build();
    Rect? b;
    for (final (paths, _) in parts) {
      for (final p in paths) {
        final pb = p.getBounds();
        if (pb.isEmpty) continue;
        b = b == null ? pb : b.expandToInclude(pb);
      }
    }
    final bounds = (b ?? const Rect.fromLTWH(0, 0, 1, 1)).inflate(2);
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)
      ..scale(res)
      ..translate(-bounds.left, -bounds.top);
    for (final (paths, color) in parts) {
      final paint = Paint()..color = color;
      for (final p in paths) {
        c.drawPath(p, paint);
      }
    }
    final img = rec.endRecording().toImageSync(
      max(1, (bounds.width * res).ceil()),
      max(1, (bounds.height * res).ceil()),
    );
    return _m[k] = (img, bounds);
  }

  static final _blitPaint = Paint()..filterQuality = FilterQuality.medium;
  static void blit(Canvas canvas, Sprite s) {
    final (img, bounds) = s;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      bounds,
      _blitPaint,
    );
  }

  /// (tasveeron ki ginti, kul memory bytes, sab se bari) — memory ka hisaab
  (int, int, String) stats() {
    var bytes = 0, big = 0;
    var bigName = '';
    for (final MapEntry(:key, :value) in _m.entries) {
      final b = value.$1.width * value.$1.height * 4;
      bytes += b;
      if (b > big) {
        big = b;
        bigName = '$key ${value.$1.width}x${value.$1.height}';
      }
    }
    return (_m.length, bytes, bigName);
  }

  void clear() {
    for (final (img, _) in _m.values) {
      img.dispose();
    }
    _m.clear();
  }

  /// [shear]: x' = x + shear*y — zameen pe ugi cheez ke liye manfi (oopar ka hissa jhuke),
  /// latakti cheez ke liye musbat (neeche ka hissa jhuke)
  static void draw(
    Canvas canvas,
    Sprite s,
    Offset at, {
    double shear = 0,
    bool mirror = false,
    double opacity = 1,
    double scale = 1,
  }) {
    final (img, bounds) = s;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    if (shear != 0) canvas.skew(shear, 0);
    if (mirror || scale != 1) canvas.scale(mirror ? -scale : scale, scale);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      bounds,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(0, 0, 0, opacity),
    );
    canvas.restore();
  }
}

enum _Plant { fern, bush, broadleaf }

class Jungle {
  /// Kis rang mein (kaala-safed ya rangeen subah) — har rang ki apni tasveerein
  final Palette colors;
  Jungle({this.colors = Palette.mono});

  double dpr = 1; // screen ki pixel density — tasveerein isi hisaab se tez (sharp) banti hain
  final cache = SpriteCache();
  double _lastScale = 0;

  // Darakht: jitne door, utne halke aur dhundle (patte shaakhon se bhi halke)
  late final far = TreeLayer(
    parallax: 0.2,
    spacing: 48,
    seed: 11,
    color: colors.farTrunk,
    leafColor: colors.farLeaf,
    leafSize: 1.0,
    leafDensity: 2.4,
    minHeight: 540,
    maxHeight: 720,
    thickness: 0.38,
    maxDepth: 6,
    leafiness: 0.8,
    variants: 8,
  );
  late final mid = TreeLayer(
    parallax: 0.5,
    spacing: 115,
    seed: 22,
    color: colors.midTrunk,
    leafColor: colors.midLeaf,
    leafSize: 1.05,
    leafDensity: 2.2,
    minHeight: 500,
    maxHeight: 680,
    thickness: 0.48,
    leafiness: 0.9,
    variants: 8,
  );
  late final near = TreeLayer(
    parallax: 1,
    spacing: 250,
    seed: 33,
    color: colors.nearTrunk,
    leafColor: colors.nearLeaf,
    minHeight: 500,
    maxHeight: 660,
    thickness: 0.58,
    leafiness: 0.95,
    variants: 10,
  );
  late final front = TreeLayer(
    parallax: 1.4,
    spacing: 1300,
    seed: 44,
    color: colors.frontTrunk,
    leafColor: colors.frontLeaf,
    minHeight: 750,
    maxHeight: 900,
    thickness: 0.9,
    maxDepth: 6,
    leafiness: 0.8,
    variants: 3,
  );

  // Har layer ki tasveer ki resolution (screen pixels har view unit) — door wali kam = naram/fade
  // Phone ki density pe poori resolution ki zaroorat nahi (khaas kar door ke dhundle darakht) — hadd lagao,
  // warna 500 tasveerein 300MB+ graphics memory kha jaati hain aur phone atak jata hai
  double _res(double scale, double factor) =>
      min(1.15 * factor, scale * dpr * factor);

  Sprite _tree(TreeLayer layer, int key, double res, {required bool leaves}) {
    return cache.get('tree${layer.seed}:$key:${leaves ? 1 : 0}', res, () {
      final (branches, leafPath) = layer.tree(key).restShape();
      return [
        ([branches], layer.color),
        if (leaves) ([leafPath], layer.leafColor),
      ];
    });
  }

  Sprite _piece(TreeLayer layer, int key, int piece, double res) {
    return cache.get('piece${layer.seed}:$key:$piece', res, () {
      final (branches, leaves) = layer.tree(key).pieceShape(piece);
      return [
        ([branches], layer.color),
        ([leaves], layer.leafColor),
      ];
    });
  }

  /// Darakht tukron mein: tana halka sa jhukta hai, har bari shaakh apne jor pe aahista,
  /// har chhoti shaakh tez — patte apni shaakh ke saath
  void _drawPieces(
    Canvas canvas,
    TreeLayer layer,
    int i,
    Offset root,
    double wind,
    double t,
    double res,
  ) {
    final key = layer.variantOf(i), mirror = layer.mirrored(i);
    final tree = layer.tree(key);
    final pieces = tree.pieces;
    final lw = mirror
        ? -wind
        : wind; // ulti tasveer mein hawa ki direction bhi ulti
    canvas.save();
    canvas.translate(root.dx, root.dy);
    canvas.skew(
      -(wind * 0.015 + sin(t * 0.9 + i * 1.7) * 0.004 * (0.4 + wind.abs())),
      0,
    );
    if (mirror) canvas.scale(-1, 1);
    void draw(int p) {
      final pc = pieces[p];
      canvas.save();
      if (pc.tier > 0) {
        final big = pc.tier == 1;
        final a = big
            ? lw * 0.045 / tree.stiffness +
                  sin(t * (0.9 + pc.phase * 0.12) + pc.phase) *
                      (0.012 + 0.03 * lw.abs())
            : lw * 0.05 +
                  sin(t * (1.8 + pc.phase * 0.25) + pc.phase * 2) *
                      (0.02 + 0.06 * lw.abs());
        canvas.translate(pc.pivot.dx, pc.pivot.dy);
        canvas.rotate(a);
        canvas.translate(-pc.pivot.dx, -pc.pivot.dy);
      }
      SpriteCache.blit(canvas, _piece(layer, key, p, res));
      for (final c in pc.children) {
        draw(c);
      }
      canvas.restore();
    }

    draw(0);
    canvas.restore();
  }

  void _pieceLayer(
    Canvas canvas,
    TreeLayer layer,
    double camX,
    double viewW,
    double rootY,
    double wind,
    double t,
    double res,
  ) {
    final shift = camX * layer.parallax;
    for (final (i, x) in layer.visible(shift - 250, shift + viewW + 250)) {
      _drawPieces(canvas, layer, i, Offset(x - shift, rootY), wind, t, res);
    }
  }

  Sprite _plant(_Plant type, int variant, double res, Color color) {
    return cache.get('${type.name}:$variant:${color.toARGB32()}', res, () {
      final seed = variant * 97 + type.index * 13;
      final paths = switch (type) {
        _Plant.fern => fern(seed, 70),
        _Plant.bush => bush(seed, 60),
        _Plant.broadleaf => broadleaf(seed, 80),
      };
      return [(paths, color)];
    });
  }

  Sprite _vine(int variant, double res) => cache.get(
    'vine:$variant',
    res,
    () => [(vine(variant * 31 + 5, 200 + variant * 25.0), colors.vine)],
  );

  /// Screen ka size badle to tasveerein naye size pe; pehli dafa sab ek saath bana lo,
  /// taake khelte waqt kabhi tasveer banne ki wajah se frame na atke
  final _warmQueue = <void Function()>[];

  /// Screen ka size badle to tasveerein naye size pe. Sab ek frame mein nahi — [warmUp] har frame thori
  /// thori banata hai (phone pe pehla frame atak na jaye); jo dikh rahi hon woh waise bhi foran ban jaati hain.
  void prepare(double scale) {
    if ((scale - _lastScale).abs() < 0.01) return;
    _lastScale = scale;
    cache.clear();
    _warmQueue.clear();
    for (final (layer, f) in [(far, 0.45), (front, 0.8)]) {
      for (var v = 0; v < layer.variants!; v++) {
        _warmQueue.add(() => _tree(layer, v, _res(scale, f), leaves: true));
      }
    }
    for (final (layer, f) in [(mid, 0.6), (near, 1.0)]) {
      for (var v = 0; v < layer.variants!; v++) {
        for (var p = 0; p < layer.tree(v).pieces.length; p++) {
          _warmQueue.add(() => _piece(layer, v, p, _res(scale, f)));
        }
      }
    }
    for (final type in _Plant.values) {
      for (var v = 0; v < 6; v++) {
        _warmQueue.add(
          () => _plant(type, v, _res(scale, 0.45), _undergrowthFar),
        );
        _warmQueue.add(
          () => _plant(type, v, _res(scale, 0.6), _undergrowthMid),
        );
        _warmQueue.add(() => _plant(type, v, _res(scale, 1), _groundColor));
        _warmQueue.add(() => _plant(type, v, _res(scale, 0.8), _frontColor));
      }
    }
    for (var v = 0; v < 5; v++) {
      _warmQueue.add(() => _vine(v, _res(scale, 1)));
    }
  }

  /// Har frame zyada se zyada [count] tasveerein pehle se bana lo
  void warmUp([int count = 6]) {
    for (var i = 0; i < count && _warmQueue.isNotEmpty; i++) {
      _warmQueue.removeLast()();
    }
  }

  /// Sab tasveerein abhi bana lo (tests aur screenshots ke liye)
  void warmAll() {
    while (_warmQueue.isNotEmpty) {
      _warmQueue.removeLast()();
    }
  }

  // Subah ki dhoop sunehri, warna safed
  Color get _ray =>
      colors.colorful ? const Color(0xFFFFE7A6) : const Color(0xFFFFFFFF);
  Color get _undergrowthFar => colors.undergrowthFar;
  Color get _undergrowthMid => colors.undergrowthMid;
  // Game ki zameen ke paude kaale se thore halke, taake kaala player un ke saamne dikhe
  Color get _groundColor => colors.plants;
  Color get _frontColor => colors.frontPlants;

  // ---------------------------------------------------------------- Peeche wali layers

  /// Door ke darakht + door ki jhaariyan (view coordinates)
  void drawFar(
    Canvas canvas,
    double camX,
    double viewW,
    double wind,
    double t,
    double scale,
  ) {
    _treeLayer(canvas, far, camX, viewW, 470, wind * 0.4, t, _res(scale, 0.45));
    _undergrowth(
      canvas,
      0.3,
      34,
      470,
      1.1,
      _undergrowthFar,
      camX,
      viewW,
      wind * 0.4,
      t,
      _res(scale, 0.45),
      1,
    );
  }

  /// Beech ke darakht + ghani jhaariyon ki deewar
  void drawMid(
    Canvas canvas,
    double camX,
    double viewW,
    double wind,
    double t,
    double scale,
  ) {
    _pieceLayer(canvas, mid, camX, viewW, 452, wind * 0.8, t, _res(scale, 0.6));
    _undergrowth(
      canvas,
      0.6,
      30,
      458,
      1.5,
      _undergrowthMid,
      camX,
      viewW,
      wind * 0.8,
      t,
      _res(scale, 0.6),
      2,
    );
  }

  /// Oopar se patton ke beech chhan kar aati roshni ki kirnein
  void drawLightRays(
    Canvas canvas,
    double camX,
    double viewW,
    double t,
    double rain,
  ) {
    final strength = 1 - rain * 0.85;
    if (strength <= 0.02) return;
    const spacing = 360.0, parallax = 0.35;
    final shift = camX * parallax;
    for (
      var i = (shift / spacing).floor() - 1;
      i * spacing < shift + viewW + spacing;
      i++
    ) {
      if (_hash(i, 21) > 0.65) continue;
      final x = i * spacing + _hash(i, 22) * spacing * 0.6 - shift;
      final top = 30 + _hash(i, 23) * 40, bottom = 140 + _hash(i, 24) * 120;
      final alpha =
          (0.11 + _hash(i, 25) * 0.1) *
          strength *
          (0.75 + 0.25 * sin(t * 0.6 + i * 2.1));
      final path = Path()
        ..moveTo(x - top / 2, -10)
        ..lineTo(x + top / 2, -10)
        ..lineTo(x + 170 + bottom / 2, 480)
        ..lineTo(x + 170 - bottom / 2, 480)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _ray.withValues(alpha: alpha * (colors.colorful ? 1.6 : 1)),
              _ray.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x - 100, -10, 400, 490)),
      );
    }
  }

  // ---------------------------------------------------------------- Game ki duniya (world coordinates)

  /// Bailen, qareeb ke darakht (patte hilte hue), aur zameen ke paude — player ke peeche
  void drawWorldBack(
    Canvas canvas,
    World world,
    double camX,
    double viewW,
    double t,
    double scale,
  ) {
    final level = world.level;

    // Latakti bailen
    for (
      var i = ((camX - 100) / 140).floor();
      i * 140 < camX + viewW + 100;
      i++
    ) {
      if (_hash(i, 31) > 0.6) continue;
      final x = i * 140 + _hash(i, 32) * 110;
      final w = world.windAt(x);
      final sway =
          w * 0.12 +
          sin(t * (1.1 + _hash(i, 33)) + i) * (0.03 + w.abs() * 0.04);
      SpriteCache.draw(
        canvas,
        _vine(i % 5, _res(scale, 1)),
        Offset(x, -12),
        shear: sway,
        mirror: i.isOdd,
      );
    }

    // Qareeb ke darakht: tukron mein — shaakhen aur un ke patte apne jor pe jhoolte hue
    final res = _res(scale, 1);
    for (final (i, x) in near.visible(camX - 260, camX + viewW + 260)) {
      final ground = level.ground.where(
        (s) => x > s.left + 10 && x < s.right - 10 && s.top >= 340,
      );
      // Ooncha-neecha zameen pe bhi darakht — paani mein nahi
      final hill = level.poolAt(x) == null ? level.terrainTop(x) : null;
      final top = ground.isNotEmpty
          ? ground.first.top
          : (hill != null && hill >= 300 ? hill : null);
      if (top == null) continue;
      _drawPieces(canvas, near, i, Offset(x, top + 2), world.windAt(x), t, res);
    }

    // Zameen pe fern, jhaariyan, bare patte — spikes ke paas nahi (taake khatra saaf dikhe)
    final pres = _res(scale, 1);
    // Seedhi zameen aur ooncha-neecha zameen dono: (left, right, sath)
    final spans = <(double, double, double Function(double))>[
      for (final s in level.ground)
        if (s.width >= 60 && s.height >= 10) (s.left, s.right, (_) => s.top),
      for (final tr in level.terrain) (tr.left, tr.right, (x) => tr.topAt(x)!),
    ];
    for (final (left, right, topAt) in spans) {
      if (right < camX - 80 || left > camX + viewW + 80) continue;
      const cell = 26.0;
      for (
        var i = (max(left, camX - 80) / cell).floor();
        i * cell < min(right, camX + viewW + 80);
        i++
      ) {
        if (_hash(i, 41) > 0.8) continue;
        final x = i * cell + _hash(i, 42) * cell;
        if (x < left + 15 || x > right - 15) continue;
        if (level.poolAt(x) != null) continue; // paani mein paude nahi
        if ([
          ...level.spikes,
          ...level.fires,
        ].any((k) => x > k.left - 50 && x < k.right + 50)) {
          continue;
        }
        final type = _Plant.values[(_hash(i, 43) * 3).floor()];
        final w = world.windAt(x);
        final sway =
            w * 0.1 +
            sin(t * (1.6 + w.abs() * 2) + i * 1.3) * (0.025 + w.abs() * 0.05);
        SpriteCache.draw(
          canvas,
          _plant(type, i % 6, pres, _groundColor),
          Offset(x, topAt(x) + 3),
          shear: -sway,
          mirror: _hash(i, 44) > 0.5,
          scale:
              0.24 +
              _hash(i, 45) *
                  0.2, // hero ke hisaab se — patte us ke sar se bare na hon
        );
      }
    }
  }

  // ---------------------------------------------------------------- Saamne wali layers (view coordinates)

  /// Saamne ke bare darakht aur paude — player in ke peeche aaye to yeh halke ho jaate hain
  void drawFront(
    Canvas canvas,
    World world,
    double camX,
    double viewW,
    double wind,
    double t,
    double scale,
  ) {
    final playerX = world.pos.dx - camX;
    double fade(double sx, double range) =>
        1 - (1 - ((sx - playerX).abs() - 40) / range).clamp(0.0, 1.0) * 0.7;

    final shift = camX * front.parallax;
    for (final (i, x) in front.visible(shift - 300, shift + viewW + 300)) {
      final sx = x - shift;
      final sway = wind * 0.025 + sin(t * 0.8 + i) * 0.006;
      SpriteCache.draw(
        canvas,
        _tree(front, front.variantOf(i), _res(scale, 0.8), leaves: true),
        Offset(sx, 560),
        shear: -sway,
        mirror: front.mirrored(i),
        opacity: fade(sx, 160),
      );
    }

    const parallax = 1.3, cell = 150.0;
    final pshift = camX * parallax;
    for (
      var i = ((pshift - 200) / cell).floor();
      i * cell < pshift + viewW + 200;
      i++
    ) {
      if (_hash(i, 51) > 0.55) continue;
      final sx = i * cell + _hash(i, 52) * cell - pshift;
      final type = _hash(i, 53) > 0.5 ? _Plant.fern : _Plant.broadleaf;
      final sway = wind * 0.08 + sin(t * 1.3 + i) * 0.03;
      SpriteCache.draw(
        canvas,
        _plant(type, i % 6, _res(scale, 0.8), _frontColor),
        Offset(sx, 570),
        shear: -sway,
        mirror: i.isOdd,
        scale: 1.0 + _hash(i, 54) * 0.4,
        opacity: fade(sx, 140),
      );
    }
  }

  // ---------------------------------------------------------------- Madadgar

  void _treeLayer(
    Canvas canvas,
    TreeLayer layer,
    double camX,
    double viewW,
    double rootY,
    double wind,
    double t,
    double res,
  ) {
    final shift = camX * layer.parallax;
    for (final (i, x) in layer.visible(shift - 250, shift + viewW + 250)) {
      final sway =
          wind * 0.035 + sin(t * 1.1 + i * 1.7) * 0.008 * (0.4 + wind.abs());
      SpriteCache.draw(
        canvas,
        _tree(layer, layer.variantOf(i), res, leaves: true),
        Offset(x - shift, rootY),
        shear: -sway,
        mirror: layer.mirrored(i),
      );
    }
  }

  /// Ek gehraai pe jhaariyon/fern ki lagataar qataar
  void _undergrowth(
    Canvas canvas,
    double parallax,
    double cell,
    double rootY,
    double size,
    Color color,
    double camX,
    double viewW,
    double wind,
    double t,
    double res,
    int salt,
  ) {
    final shift = camX * parallax;
    for (
      var i = ((shift - 120) / cell).floor();
      i * cell < shift + viewW + 120;
      i++
    ) {
      final x = i * cell + _hash(i, 60 + salt) * cell - shift;
      // Peeche sirf fern aur jhaariyan — bare patte door se ajeeb dhabbe lagte hain
      final type = _hash(i, 61 + salt) > 0.5 ? _Plant.fern : _Plant.bush;
      final sway = wind * 0.06 + sin(t * 1.2 + i * 0.7) * 0.015;
      SpriteCache.draw(
        canvas,
        _plant(type, i % 6, res, color),
        Offset(x, rootY),
        shear: -sway,
        mirror: _hash(i, 62 + salt) > 0.5,
        scale: size * (0.6 + _hash(i, 63 + salt) * 0.4),
      );
    }
  }
}
