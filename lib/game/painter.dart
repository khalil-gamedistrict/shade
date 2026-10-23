// Limbo jaisa look: grey dhundla background, sab kuch kaala silhouette.
// Tarteeb (peeche se aagay): aasmaan → bijli → door ke darakht+baarish → beech ke → game → saamne ke darakht → dhund
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'fight.dart';
import 'figures.dart';
import 'grass.dart';
import 'props.dart';
import 'jungle.dart';
import 'palette.dart';
import 'weather.dart';
import 'world.dart';

class WorldPainter extends CustomPainter {
  final World world;
  final Jungle jungle;
  final Weather weather;

  /// Trailer jaisi jagahon ke liye apni cheezen (game ki duniya ke coordinates mein, player se pehle)
  final void Function(Canvas canvas)? extra;
  WorldPainter(
    this.world,
    this.jungle,
    this.weather, {
    this.extra,
    super.repaint,
  });

  static const viewHeight = 500.0; // itni world height screen pe fit hogi
  static Paint get _black => Paint()..color = palette.ink;

  static double viewWidth(Size size) => size.width / (size.height / viewHeight);
  static double cameraX(World world, double viewW) =>
      max(0.0, world.pos.dx - viewW * 0.35);

  @override
  void paint(Canvas canvas, Size size) {
    palette = world.level.mood == Mood.dawn ? Palette.dawn : Palette.mono;
    final scale = size.height / viewHeight;
    final viewW = viewWidth(size);
    final camX = cameraX(world, viewW);
    final t = world.time;
    final wind = weather.wind;

    _sky(canvas, size);

    canvas.save();
    canvas.scale(scale);

    jungle.prepare(scale);
    jungle.warmUp(); // tasveerein thori thori — pehla frame halka

    // Door ka jungle + door ki baarish, phir dhund
    jungle.drawFar(canvas, camX, viewW, wind, t, scale);
    _rain(canvas, 0);
    _haze(canvas, viewW, 0.18);

    // Beech ka jungle, patton se chhanti roshni
    jungle.drawMid(canvas, camX, viewW, wind, t, scale);
    jungle.drawLightRays(canvas, camX, viewW, t, weather.rain);
    _rain(canvas, 1);
    _haze(canvas, viewW, 0.12);

    // --- Game ki duniya (camera ke saath)
    canvas.save();
    canvas.translate(-camX + _shake(), 0);
    jungle.drawWorldBack(canvas, world, camX, viewW, t, scale);
    final level = world.level;
    for (var i = 0; i < level.huts.length; i++) {
      final x = level.huts[i];
      if (x < camX - 150 || x > camX + viewW + 150) continue;
      drawHut(canvas, x, _groundAt(x), t, world.windAt(x), i);
    }
    if (level.home) _village(canvas, camX, viewW);
    final waterY = level.waterY;
    if (waterY != null) {
      for (final (l, r) in _gaps(camX - 20, camX + viewW + 20)) {
        drawWater(canvas, l, r, waterY, t);
      }
    }
    final grass = Path();
    for (final s in world.level.ground) {
      if (s.right < camX - 40 || s.left > camX + viewW + 40) continue;
      if (s.height < 10) {
        drawBridge(canvas, s, t, world.windAt(s.center.dx)); // rassi ka pul
        continue;
      }
      canvas.drawRect(s, Paint()..color = palette.ground);
      Grass.addTo(
        grass,
        s.top,
        s.left,
        s.right,
        camX - 40,
        camX + viewW + 40,
        world.windAt,
        t,
      );
    }
    // Ooncha-neecha zameen: teelay, dhalan, gadhe — ghaas sath ke saath, paani ke neeche nahi
    for (final tr in level.terrain) {
      if (tr.right < camX - 40 || tr.left > camX + viewW + 40) continue;
      final a = max(tr.left, camX - 40), b = min(tr.right, camX + viewW + 40);
      final ground = Path()..moveTo(a, tr.bottom);
      for (var x = a; x < b; x += 4) {
        ground.lineTo(x, tr.topAt(x)!);
      }
      ground
        ..lineTo(b, tr.topAt(b)!)
        ..lineTo(b, tr.bottom)
        ..close();
      canvas.drawPath(ground, Paint()..color = palette.ground);
      var from = tr.left;
      for (final p in [
        ...level.pools,
      ]..sort((x, y) => x.left.compareTo(y.left))) {
        if (p.right < tr.left || p.left > tr.right) continue;
        _terrainGrass(grass, tr, from, p.left - 6, camX, viewW, t);
        from = p.right + 6;
      }
      _terrainGrass(grass, tr, from, tr.right, camX, viewW, t);
    }
    final hole = level.hideout;
    if (hole != null &&
        hole.right > camX - 60 &&
        hole.left < camX + viewW + 60) {
      drawHideoutBack(canvas, hole, _groundAt(hole.center.dx), t);
    }
    canvas.drawPath(grass, Paint()..color = palette.grass);
    if (palette.colorful) _flowers(canvas, camX, viewW);
    for (final s in world.level.spikes) {
      _spikes(canvas, s);
    }
    for (final saw in world.level.saws) {
      _saw(canvas, saw);
    }
    for (final m in world.level.movers) {
      if (m.boat) {
        drawBoat(
          canvas,
          m.rectAt(t),
          t,
          level.waterY ?? m.rectAt(t).bottom,
          level.movers.indexOf(m),
        );
      } else {
        _mover(canvas, m.rectAt(t));
      }
    }
    for (final f in level.fires) {
      if (f.right < camX - 80 || f.left > camX + viewW + 80) continue;
      drawFire(canvas, f, t);
    }
    for (var i = 0; i < world.level.traps.length; i++) {
      _trap(canvas, world.level.traps[i], closed: world.closedTrap == i);
    }
    for (final p in world.level.pendulums) {
      _pendulum(canvas, p);
    }
    for (final c in world.level.checkpoints.skip(1)) {
      _lamp(
        canvas,
        c,
        lit: world.level.checkpoints.indexOf(c) <= world.checkpoint,
      );
    }
    // Panah ho to wahi manzil ki nishani; warna purani roshni
    if (world.level.hideout == null && !world.level.home) {
      _goalLight(canvas);
    }
    extra?.call(canvas);
    _hunters(canvas, camX, viewW);
    _shields(canvas);
    _player(canvas);
    _pools(
      canvas,
      camX,
      viewW,
    ); // paani jismon ke saamne — paon andar doobe dikhen
    _hideoutFront(canvas);
    if (palette.colorful) _butterflies(canvas, camX, viewW);
    // Shaakhen player ke baad — neeche dabi laash lakdi ke neeche dikhe
    for (var i = 0; i < world.level.branches.length; i++) {
      if (world.branchState[i] == 0) continue; // abhi oopar chhupa hai
      final branch = world.level.branches[i];
      _branch(
        canvas,
        Offset(branch.x, world.branchY[i]),
        branch.radius,
        i,
        falling: world.branchState[i] == 1,
      );
    }
    _spears(canvas);
    _fightDust(canvas);
    _splashes(canvas);
    canvas.restore();

    // Saamne wali baarish, saamne ke darakht aur urte patte
    _rain(canvas, 2);
    jungle.drawFront(canvas, world, camX, viewW, wind * 0.5, t, scale);
    _flyingLeaves(canvas);

    canvas.restore();

    _fogAndVignette(canvas, size);
  }

  void _terrainGrass(
    Path grass,
    Terrain tr,
    double left,
    double right,
    double camX,
    double viewW,
    double t,
  ) {
    if (right <= left) return;
    Grass.addTo(
      grass,
      0,
      left,
      right,
      camX - 40,
      camX + viewW + 40,
      world.windAt,
      t,
      topAt: (x) => tr.topAt(x.clamp(tr.left, tr.right))!,
    );
  }

  /// Khara paani: sath pe halki chamakti lehar, andar gehra andhera. Andar khare jism ke paas chhalle.
  void _pools(Canvas canvas, double camX, double viewW) {
    final t = world.time;
    for (final p in world.level.pools) {
      if (p.right < camX - 20 || p.left > camX + viewW + 20) continue;
      double floor(double x) =>
          max(p.surface, world.level.terrainTop(x) ?? p.surface + 80);
      final body = Path()..moveTo(p.left, p.surface);
      for (var x = p.left; x <= p.right; x += 3) {
        body.lineTo(x, p.surface + sin(t * 1.6 + x * 0.09) * 0.6);
      }
      for (var x = p.right; x >= p.left; x -= 3) {
        body.lineTo(x, floor(x) + 1);
      }
      body.close();
      final bottom = p.surface + (p.deep ? 75 : 20);
      canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.waterTop, palette.waterDeep],
          ).createShader(Rect.fromLTRB(p.left, p.surface, p.right, bottom)),
      );
      // Sath ki chamak: toot'ti hui patli lakeerein, aahista behti
      final shine = Paint()
        ..color = palette.waterShine
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < (p.right - p.left) / 14; k++) {
        final u = (k * 14 + t * 6) % (p.right - p.left);
        final x = p.left + u;
        if (floor(x) <= p.surface + 1) continue;
        final len = 3 + (sin(k * 3.7) * 0.5 + 0.5) * 6;
        final y = p.surface + sin(t * 1.6 + x * 0.09) * 0.6;
        canvas.drawLine(Offset(x, y), Offset(min(p.right, x + len), y), shine);
      }
      // Andar khare/chalte jism ke gird phailte chhalle
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      for (final b in [
        if (world.state != PlayerState.dead) world.pos,
        if (world.chaseActive)
          for (final h in world.hunters) Offset(h.x, h.y),
      ]) {
        if (b.dx < p.left || b.dx > p.right || b.dy < p.surface + 2) continue;
        for (var k = 0; k < 2; k++) {
          final u = (t * 1.4 + k * 0.5 + b.dx * 0.01) % 1;
          ring.color = Color.fromRGBO(210, 214, 218, 0.5 * (1 - u));
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(b.dx, p.surface),
              width: 14 + u * 30,
              height: 2 + u * 3,
            ),
            ring,
          );
        }
      }
    }
  }

  static const _petals = [
    Color(0xFFF06292),
    Color(0xFFFFD54F),
    Color(0xFFFFFFFF),
    Color(0xFFB388FF),
    Color(0xFFFF8A50),
  ];

  static double _h(int i, int salt) {
    final v = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// Rangeen subah: ghaas mein chhote rang birange phool (paani aur khatron se door)
  void _flowers(Canvas canvas, double camX, double viewW) {
    final level = world.level;
    final stem = Paint()
      ..color = const Color(0xFF2E6B1F)
      ..strokeWidth = 1;
    for (var i = (camX / 9).floor(); i * 9 < camX + viewW; i++) {
      if (_h(i, 120) > 0.22) continue;
      final x = i * 9 + _h(i, 121) * 9;
      if (level.poolAt(x) != null) continue;
      final onGround =
          level.terrainTop(x) != null ||
          level.ground.any((s) => x > s.left && x < s.right && s.height > 10);
      if (!onGround) continue;
      if ([
        ...level.spikes,
        ...level.traps,
      ].any((k) => x > k.left - 20 && x < k.right + 20)) {
        continue;
      }
      final g = _groundAt(x);
      final hgt = 4 + _h(i, 122) * 7;
      final top = Offset(x + sin(world.time * 2 + i) * 0.8, g - hgt);
      canvas.drawLine(Offset(x, g), top, stem);
      final petal = Paint()..color = _petals[(_h(i, 123) * 5).floor()];
      for (var k = 0; k < 4; k++) {
        final a = k * pi / 2 + i;
        canvas.drawCircle(top + Offset(cos(a), sin(a)) * 1.6, 1.4, petal);
      }
      canvas.drawCircle(top, 1, Paint()..color = const Color(0xFFFFC107));
    }
  }

  /// Rangeen subah: idhar udhar urti titliyan
  void _butterflies(Canvas canvas, double camX, double viewW) {
    final t = world.time;
    for (var k = 0; k < 7; k++) {
      final x = camX + (k * 211 + t * (22 + k * 3)) % (viewW + 80) - 40;
      final y = 290 + sin(t * 1.3 + k) * 35 + k * 9 + sin(t * 3.1 + k * 2) * 6;
      final flap = sin(t * 15 + k).abs();
      final wing = Paint()..color = _petals[k % 5].withValues(alpha: 0.95);
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + side * 2.6 * flap, y),
            width: 4.6 * flap + 0.8,
            height: 5.5,
          ),
          wing,
        );
      }
      canvas.drawLine(
        Offset(x, y - 2.5),
        Offset(x, y + 2.5),
        Paint()
          ..color = palette.ink
          ..strokeWidth = 1,
      );
    }
  }

  /// Apna gaon (aakhri chapter): sabut jhonpriyan, alaao, ghar wale — aur do jawan neze liye, jo shikaari
  /// aate hi neze utha kar khare ho jaate hain
  void _village(Canvas canvas, double camX, double viewW) {
    final g = world.level.goalX;
    if (g + 600 < camX || g - 100 > camX + viewW) return;
    final t = world.time, wind = world.windAt(g);
    final ground = _groundAt(g + 100);
    drawHut(canvas, g + 70, ground, t, wind, 1, burning: false);
    drawHut(canvas, g + 430, ground, t, wind, 2, burning: false);
    final log = Paint()
      ..color = palette.ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const fx = 245.0;
    canvas.drawLine(
      Offset(g + fx - 16, ground),
      Offset(g + fx + 12, ground - 7),
      log,
    );
    canvas.drawLine(
      Offset(g + fx + 16, ground),
      Offset(g + fx - 12, ground - 7),
      log,
    );
    drawFire(
      canvas,
      Rect.fromLTWH(g + fx - 14, ground - 14, 28, 8),
      t,
      size: 0.85,
    );
    // Ghar wale: aurten aur bachche alaao ke paas, hero ki taraf dekhte
    for (final (dx, look, sc) in [
      (285.0, Look.woman, 1.0),
      (312.0, Look.villager, 0.6),
      (340.0, Look.woman, 1.0),
      (365.0, Look.villager, 0.62),
    ]) {
      drawFigure(
        canvas,
        look: look,
        foot: Offset(g + dx, ground),
        dir: -1,
        phase: 0,
        moving: false,
        inAir: false,
        time: t + dx,
        wind: wind,
        scale: sc,
      );
    }
    // Jawan: neze liye; shikaari aaye to neze aagay, baazu oopar (jang ki cheekh)
    final stand = world.tribeStands;
    final spear = Paint()
      ..color = palette.ink
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (final dx in [18.0, 52.0]) {
      final foot = Offset(g + dx, ground);
      drawFigure(
        canvas,
        look: Look.villager,
        foot: foot,
        dir: -1,
        phase: 0,
        moving: false,
        inAir: false,
        time: t + dx,
        wind: wind,
        scale: 1.06,
        pose: stand
            ? const FigurePose(
                (0.45, -0.2),
                (-0.45, 0),
                (1.6, 0.1),
                (2.7, 0.3),
                lean: 0.18,
              )
            : null,
      );
      if (stand) {
        canvas.drawLine(
          foot + const Offset(14, -30),
          foot + const Offset(-34, -40),
          spear,
        );
      } else {
        canvas.drawLine(
          foot + const Offset(-8, 0),
          foot + const Offset(-8, -62),
          spear,
        );
      }
    }
  }

  /// [x] pe [y] ki oonchai wali zameen hai?
  bool _hasGround(double x, double y) =>
      world.level.ground.any(
        (s) => x >= s.left && x <= s.right && (s.top - y).abs() < 8,
      ) ||
      ((world.level.terrainTop(x) ?? -100) - y).abs() < 14;

  double _groundAt(double x) {
    var best = 400.0;
    var found = false;
    for (final s in world.level.ground) {
      if (x >= s.left && x <= s.right && (!found || s.top < best)) {
        best = s.top;
        found = true;
      }
    }
    final t = world.level.terrainTop(x);
    if (t != null && (!found || t < best)) best = t;
    return best;
  }

  /// [from]..[to] mein jahan zameen nahi (darya ka paani wahan dikhta hai)
  List<(double, double)> _gaps(double from, double to) {
    final spans = [
      for (final s in world.level.ground)
        if (s.height >= 10) (s.left, s.right),
      for (final t in world.level.terrain) (t.left, t.right),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final out = <(double, double)>[];
    var cursor = from;
    for (final (l, r) in spans) {
      if (r <= cursor) continue;
      if (l > cursor) out.add((cursor, min(l, to)));
      cursor = max(cursor, r);
      if (cursor >= to) break;
    }
    if (cursor < to) out.add((cursor, to));
    return out;
  }

  void _sky(Canvas canvas, Size size) {
    final r = weather.rain;
    final top = Color.lerp(palette.skyTop, const Color(0xFF8C8E90), r)!;
    final bottom = Color.lerp(palette.skyBottom, const Color(0xFF55585A), r)!;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
    if (palette.colorful) {
      // Subah ka sooraj: oopar daayen, naram sunehri chamak
      final sun = Offset(size.width * 0.8, size.height * 0.16);
      final r = size.height * 0.42;
      canvas.drawCircle(
        sun,
        r,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xCCFFF6D0), Color(0x55FFE9A8), Color(0x00FFE9A8)],
            stops: [0, 0.25, 1],
          ).createShader(Rect.fromCircle(center: sun, radius: r)),
      );
      canvas.drawCircle(
        sun,
        size.height * 0.05,
        Paint()..color = const Color(0xFFFFF8E1),
      );
    }
    if (world.level.mood == Mood.fire) {
      final flicker = 0.85 + 0.15 * sin(world.time * 9) * sin(world.time * 5.3);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFFFF9A4A).withValues(
                alpha: 0.28 * flicker,
              ), // neeche se aag ki garam roshni
              Colors.black.withValues(alpha: 0.35),
            ],
          ).createShader(rect),
      );
    }
    // Bijli: aasmaan chamak uthta hai, darakht aur bhi kaale dikhte hain
    if (weather.flash > 0) {
      canvas.drawRect(
        rect,
        Paint()..color = Colors.white.withValues(alpha: 0.65 * weather.flash),
      );
    }
  }

  void _haze(Canvas canvas, double viewW, double amount) {
    final rect = Rect.fromLTWH(0, 0, viewW, viewHeight);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            palette.haze.withValues(alpha: amount + weather.rain * 0.08),
            palette.haze.withValues(alpha: amount * 0.3),
          ],
        ).createShader(rect),
    );
  }

  void _rain(Canvas canvas, int layer) {
    final l = weather.layers[layer];
    if (l.active == 0) return;
    canvas.drawRawPoints(
      ui.PointMode.lines,
      weather.dropLines(layer),
      Paint()
        ..color = const Color(0xFFE8ECEE)
            .withValues(alpha: l.alpha + weather.flash * 0.3)
        ..strokeWidth = l.width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _splashes(Canvas canvas) {
    final drop = Paint()
      ..color = const Color(0xCCDDE2E5)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final points = <Offset>[];
    for (final s in weather.splashes) {
      for (var k = 0; k < s.dx.length; k++) {
        final x = s.x + s.dx[k] * s.age;
        final y = s.y + s.dy[k] * s.age + 0.5 * 900 * s.age * s.age;
        if (y <= s.y) points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(ui.PointMode.points, points, drop);
    // Zameen pe nanhi lehrein (chhote paani ke chhalle)
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final r in weather.ripples) {
      final k = r.age / 0.45;
      ring.color = const Color(0xFFCFD5D8).withValues(alpha: 0.45 * (1 - k));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(r.x, r.y - 0.5),
          width: r.size * (0.4 + k * 1.6),
          height: r.size * (0.12 + k * 0.3),
        ),
        ring,
      );
    }
  }

  void _flyingLeaves(Canvas canvas) {
    final path = Path();
    for (final l in weather.leaves) {
      final dx = cos(l.angle) * 4, dy = sin(l.angle) * 4;
      final nx = -dy * 0.35, ny = dx * 0.35;
      path.addPolygon([
        Offset(l.x - dx, l.y - dy),
        Offset(l.x + nx, l.y + ny),
        Offset(l.x + dx, l.y + dy),
        Offset(l.x - nx, l.y - ny),
      ], true);
    }
    canvas.drawPath(path, Paint()..color = const Color(0xDD080808));
  }

  /// Hilta platform: lakri ka takhta, oopar se do rassiyon pe latka hua
  void _mover(Canvas canvas, Rect r) {
    final rope = Paint()
      ..color = palette.ink
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(r.left + 8, 0), Offset(r.left + 8, r.top), rope);
    canvas.drawLine(Offset(r.right - 8, 0), Offset(r.right - 8, r.top), rope);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      _black,
    );
  }

  /// Shikanja: zameen pe khula jabra, nukeele daant
  void _trap(Canvas canvas, Rect r, {bool closed = false}) {
    if (closed) {
      // Band jabre: dono taraf se oopar uth kar beech mein mile, daant aapas mein phanse hue
      final c = Offset(r.center.dx, r.bottom - 1);
      final jaws = Path()
        ..moveTo(r.left - 4, r.bottom)
        ..lineTo(r.right + 4, r.bottom)
        ..lineTo(r.right + 4, r.bottom - 3)
        ..lineTo(r.left - 4, r.bottom - 3)
        ..close();
      for (final side in [-1.0, 1.0]) {
        jaws.addArc(
          Rect.fromCenter(center: c, width: r.width * 0.9, height: 26),
          side < 0 ? pi : -pi / 2,
          pi / 2,
        );
        for (var k = 0; k < 4; k++) {
          final y = c.dy - 3 - k * 3;
          jaws
            ..moveTo(c.dx + side * 1, y)
            ..lineTo(c.dx - side * 3, y - 1.5)
            ..lineTo(c.dx + side * 1, y - 3)
            ..close();
        }
      }
      canvas.drawPath(jaws, _black);
      canvas.drawPath(
        Path()..addArc(
          Rect.fromCenter(center: c, width: r.width * 0.9, height: 26),
          pi,
          pi,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = palette.ink,
      );
      return;
    }
    final path = Path()
      ..moveTo(r.left - 4, r.bottom)
      ..lineTo(r.right + 4, r.bottom)
      ..lineTo(r.right + 4, r.bottom - 3)
      ..lineTo(r.left - 4, r.bottom - 3)
      ..close();
    // Do jabre, khule hue — har ek pe daant
    for (final side in [-1.0, 1.0]) {
      final hinge = Offset(r.center.dx, r.bottom - 2);
      for (var k = 0; k < 5; k++) {
        final t = k / 4;
        final a = side * (0.25 + t * 1.1);
        final base =
            hinge + Offset(sin(a) * r.width * 0.55, -cos(a) * r.width * 0.2);
        final tip = base + Offset(sin(a) * 2, -9 - (k.isEven ? 2 : 0));
        path
          ..moveTo(base.dx - 2, base.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(base.dx + 2, base.dy)
          ..close();
      }
    }
    canvas.drawPath(path, _black);
    canvas.drawCircle(Offset(r.center.dx, r.bottom - 2), 3, _black);
  }

  /// Rassi pe jhoolta bhari lakkar
  void _pendulum(Canvas canvas, Pendulum p) {
    final bob = p.bobAt(world.time);
    canvas.drawLine(
      Offset(p.pivot.dx, 0),
      p.pivot,
      Paint()
        ..color = palette.ink
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      p.pivot,
      bob,
      Paint()
        ..color = palette.ink
        ..strokeWidth = 2.5,
    );
    // Lakkar: rassi ke seedh mein mota gol tukra, kuch ubhri ganthein
    final a = p.angleAt(world.time);
    canvas.save();
    canvas.translate(bob.dx, bob.dy);
    canvas.rotate(-a);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.radius * 2.6,
          height: p.radius * 1.6,
        ),
        Radius.circular(p.radius * 0.7),
      ),
      _black,
    );
    for (final k in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(k * p.radius * 1.2, 0), p.radius * 0.5, _black);
    }
    canvas.restore();
  }

  /// Darakht se aandhi mein tooti shaakh (props.dart: drawBrokenBranch). Girte waqt ghoomti hai;
  /// zameen pe halki teRhi leti hai.
  void _branch(
    Canvas canvas,
    Offset c,
    double r,
    int seed, {
    required bool falling,
  }) {
    final angle = falling
        ? sin(world.time * 5 + seed) * 0.22
        : (seed.isEven ? 0.05 : -0.05);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    // Kabhi toota sira baayen, kabhi daayen
    if (seed.isOdd) canvas.scale(-1, 1);
    drawBrokenBranch(
      canvas,
      r * 4.6,
      r * 1.1,
      seed,
      world.time,
      world.windAt(c.dx),
      falling: falling,
    );
    canvas.restore();
  }

  void _spikes(Canvas canvas, Rect s) {
    final path = Path();
    const w = 8.0;
    for (var x = s.left; x < s.right; x += w) {
      path
        ..moveTo(x, s.bottom)
        ..lineTo(x + w / 2, s.top)
        ..lineTo(x + w, s.bottom);
    }
    canvas.drawPath(path, _black);
  }

  void _saw(Canvas canvas, Saw saw) {
    final c = saw.centerAt(world.time);
    // Upar se latakti zanjeer
    canvas.drawLine(
      Offset(c.dx, 0),
      c,
      Paint()
        ..color = palette.ink
        ..strokeWidth = 3,
    );
    final path = Path();
    const teeth = 14;
    for (var i = 0; i < teeth * 2; i++) {
      final a = world.time * 8 + i * pi / teeth;
      final r = i.isEven ? saw.radius : saw.radius * 0.78;
      final p = c + Offset(cos(a) * r, sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, _black);
  }

  void _lamp(Canvas canvas, Offset c, {required bool lit}) {
    canvas.drawRect(Rect.fromLTWH(c.dx - 2, c.dy - 70, 4, 70), _black);
    if (lit) {
      canvas.drawCircle(
        Offset(c.dx, c.dy - 74),
        40,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(c.dx, c.dy - 74), radius: 40),
              ),
      );
    }
    canvas.drawCircle(Offset(c.dx, c.dy - 74), 5, _black);
  }

  void _goalLight(Canvas canvas) {
    final c = Offset(world.level.goalX + 40, 300);
    canvas.drawCircle(
      c,
      220,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.8), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: 220)),
    );
  }

  /// Larai mein waar ke lamhe kitne qareeb: 1 = abhi abhi waar hua, 0 = koi nahi
  double _hitPulse() {
    if (world.state != PlayerState.fighting) return 0;
    var best = 0.0;
    for (final h in World.fightHits) {
      final e = (world.fightTime - h) / 0.22;
      if (e >= 0 && e < 1) best = max(best, 1 - e);
    }
    return best;
  }

  double _shake() => sin(world.fightTime * 95) * 3 * _hitPulse();

  /// Waar pe dhool aur chhote zarre
  void _fightDust(Canvas canvas) {
    final p = _hitPulse();
    if (p <= 0) return;
    final e = 1 - p;
    final c = world.pos + const Offset(-12, -26);
    final dust = Paint()
      ..color = const Color(0xFFCFCFCF).withValues(alpha: 0.55 * p);
    for (var k = 0; k < 7; k++) {
      final a = k / 7 * 2 * pi + world.fightTime;
      canvas.drawCircle(
        c + Offset(cos(a), sin(a) * 0.7) * (4 + e * 14),
        1.6 + e * 1.5,
        dust,
      );
    }
  }

  /// Gaddhay ke munh pe patton ka dhakkan (hero ke saamne), aur oopar daurte shikaariyon ke qadmon se
  /// chhat se jharti mitti
  void _hideoutFront(Canvas canvas) {
    final hole = world.level.hideout;
    if (hole == null) return;
    final overhead = [
      for (final b in world.hunters)
        if (world.chaseActive &&
            b.grounded &&
            b.x > hole.left + 6 &&
            b.x < hole.right - 6)
          b.x,
    ];
    drawHideoutFront(
      canvas,
      hole,
      _groundAt(hole.center.dx),
      world.time,
      world.windAt(hole.left),
      [world.pos, for (final b in world.hunters) Offset(b.x, b.y)],
      overhead,
    );
  }

  void _player(Canvas canvas) {
    if (!world.showHero) return;
    final dir = world.facingRight ? 1.0 : -1.0;
    if (world.state == PlayerState.won && world.sitting) {
      // Chattan se tek laga kar baitha, saans leta hua
      final breathe = sin(world.time * 2.2) * 0.6;
      drawFigure(
        canvas,
        look: Look.hero,
        foot: world.pos + Offset(0, 13 + breathe),
        dir: 1,
        phase: 0,
        moving: false,
        inAir: false,
        time: world.time,
        wind: 0,
        pose: const FigurePose(
          (1.5, -2.3),
          (1.35, -2.1),
          (1.0, 0.9),
          (0.7, 1.0),
          lean: -0.14,
        ),
        eyesClosed: world.hiding, // saans roke, aankhen band
      );
      return;
    }
    if (world.state == PlayerState.fighting) {
      final (pose, dx) = heroFight(world.fightTime);
      drawFigure(
        canvas,
        look: Look.hero,
        foot: world.pos + Offset(dx, 0),
        dir: -1,
        phase: 0,
        moving: false,
        inAir: false,
        time: world.time,
        wind: world.windAt(world.pos.dx),
        pose: pose,
        backShield: world.shield,
      );
      return;
    }
    if (world.state == PlayerState.alive &&
        world.time - world.escapeTime < 0.35) {
      // Chhootne ka dhakka
      drawFigure(
        canvas,
        look: Look.hero,
        foot: world.pos,
        dir: -1,
        phase: 0,
        moving: false,
        inAir: false,
        time: world.time,
        pose: escapeShove,
      );
      return;
    }
    if (world.state == PlayerState.dead) {
      final t = world.time - world.deathTime;
      final wind = world.windAt(world.pos.dx);
      void dying({
        double? spear,
        double raise = 0,
        double speed = 1,
        double? from,
      }) => drawDying(
        canvas,
        look: Look.hero,
        foot: world.pos,
        dir: dir,
        fallDir: world.fallDir,
        t: from ?? t * speed,
        time: world.time,
        wind: wind,
        spear: spear,
        raise: raise,
      );
      switch (world.deathKind) {
        case DeathKind.fall || DeathKind.drown:
          drawFalling(
            canvas,
            look: Look.hero,
            foot: world.pos,
            dir: dir,
            time: world.time,
          );
        case DeathKind.pendulum || DeathKind.saw:
          // Takkar se hawa mein gholay; zameen pe aa kar let'na aur tarapna
          if (!world.bodyLanded) {
            drawTumble(
              canvas,
              look: Look.hero,
              foot: world.pos,
              dir: dir,
              angle: world.bodyAngle,
              time: world.time,
            );
          } else {
            dying(from: 0.7 + world.time - world.landTime);
          }
        case DeathKind.burn:
          drawBurning(
            canvas,
            look: Look.hero,
            foot: world.pos,
            dir: dir,
            fallDir: world.fallDir,
            t: t,
            time: world.time,
            wind: wind,
            fire: (c, r, time, size) =>
                drawFire(c, r, time, size: size, wind: wind),
          );
        case DeathKind.spear:
          dying(spear: world.spearAngle);
        case DeathKind.branch:
          dying(speed: 3); // bhaari shaakh — foran dab gaya
        case DeathKind.spike:
          dying(raise: 9); // kaanton ke oopar
        case DeathKind.caught:
          dying(spear: world.spearAngle); // ghonpa hua neza jism mein
        case DeathKind.trap:
          dying();
      }
      return;
    }
    // Dhaal uthana: daurte daurte jhuk kar zameen se utha li (pehle pal mein haath neeche)
    final grab = world.time - world.pickupTime;
    drawFigure(
      canvas,
      look: Look.hero,
      foot: world.pos,
      dir: world.facingRight ? 1 : -1,
      phase: world.walkPhase,
      moving: world.grounded && world.vx != 0,
      inAir: !world.grounded,
      time: world.time,
      wind: world.windAt(world.pos.dx),
      pose: grab < 0.32 ? _scoop : null,
      backShield: grab < 0.18 ? 0 : world.shield,
    );
    if (grab < 0.18) {
      // Haath mein dhaal — abhi peeth pe nahi gayi
      final d = world.facingRight ? 1.0 : -1.0;
      _shieldDisk(canvas, world.pos + Offset(d * 16, -10 - grab * 60), 0.6);
    }
  }

  static const _scoop = FigurePose(
    (0.75, -1.3),
    (-0.6, -0.5),
    (0.45, 0.1),
    (-0.4, 0.6),
    lean: 0.55,
  );

  /// Gol dhaal (chamra tana hua, beech mein ubhaar), [tilt] radian jhuki
  void _shieldDisk(Canvas canvas, Offset c, double tilt, {double glint = 0}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(tilt);
    final r = Rect.fromCenter(center: Offset.zero, width: 13, height: 20);
    canvas.drawOval(r, _black);
    canvas.drawOval(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Color.fromRGBO(225, 225, 225, 0.35 + glint * 0.45),
    );
    canvas.drawCircle(
      Offset.zero,
      1.8,
      Paint()..color = const Color(0x77D8D8D8),
    );
    canvas.restore();
  }

  /// Raaste mein pari dhaal (chhoti chattan se tiki), halki chamak taake nazar aaye; aur toot'ti dhaal ke tukre
  void _shields(Canvas canvas) {
    final level = world.level;
    for (var i = 0; i < level.shields.length; i++) {
      if (world.shieldsTaken.contains(i)) continue;
      final g = level.shields[i];
      canvas.drawOval(
        Rect.fromCenter(center: g + const Offset(7, -2), width: 14, height: 7),
        _black,
      );
      final glint = (sin(world.time * 3 + i) * 0.5 + 0.5);
      _shieldDisk(canvas, g + const Offset(1, -9), 0.45, glint: glint);
    }
    final dir = world.facingRight ? 1.0 : -1.0;
    final back = world.pos + Offset(-dir * 6, -28);
    final hit = world.time - world.shieldHitTime;
    if (hit < 0.2) {
      // Neza laga: chingari jaisi halki chamak
      canvas.drawCircle(
        back,
        6 + hit * 40,
        Paint()..color = Color.fromRGBO(235, 235, 235, 0.5 * (1 - hit / 0.2)),
      );
    }
    final br = world.time - world.shieldBreakTime;
    if (br < 1.2) {
      // Tukre: idhar udhar uchhal kar girte, ghoomte
      for (var k = 0; k < 6; k++) {
        final a = -pi / 2 + (k - 2.5) * 0.45;
        final v = Offset(
          cos(a) * (60 + k * 12) * -dir,
          sin(a) * (150 + k * 15),
        );
        final p = back + v * br + Offset(0, 500 * br * br);
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(br * (6 + k));
        canvas.drawPath(
          Path()..addPolygon(const [
            Offset(-3, -2),
            Offset(4, -3),
            Offset(2, 3),
          ], true),
          Paint()..color = Color.fromRGBO(10, 10, 10, 1 - br / 1.2),
        );
        canvas.restore();
      }
    }
  }

  /// Peeche daurte jangli shikaari
  void _hunters(Canvas canvas, double camX, double viewW) {
    if (!world.chaseActive) return;
    const looks = [Look.feathers, Look.shield, Look.archer];
    final px = world.pos.dx, py = world.pos.dy;
    if (world.state == PlayerState.fighting) {
      // Larai: akele ko ghere mein lete hain — neze wala saamne, kaman wala thora peeche (door, chhota)
      // nishana baandhe, dhaal wala hero ke peeche se ghoom kar doosri taraf se waar karta hai
      final (leadPose, leadDx) = leadFight(world.fightTime);
      final (secondPose, secondDx, circling) = secondFight(world.fightTime);
      // Kaman wala zameen pe khara ho — peeche gaddha ho to doosri taraf
      var archerX = px - 62;
      if (!_hasGround(archerX, py)) archerX = px + 110;
      drawFigure(
        canvas,
        look: Look.archer,
        foot: Offset(archerX, py - 5),
        dir: 1,
        phase: 0,
        moving: false,
        inAir: false,
        time: world.time,
        scale: 0.94,
        pose: const FigurePose((0.2, 0), (-0.25, 0), (1.55, 0), (1.2, 0.6)),
      );
      drawFigure(
        canvas,
        look: Look.shield,
        foot: Offset(px + secondDx, circling ? py - 4 : py),
        dir: circling ? 1 : -1,
        phase: world.time * 9,
        moving: circling,
        inAir: false,
        time: world.time,
        scale: circling ? 0.97 : 1.06,
        pose: secondPose,
      );
      drawFigure(
        canvas,
        look: Look.feathers,
        foot: Offset(px - 24 + leadDx, py),
        dir: 1,
        phase: 0,
        moving: false,
        inAir: false,
        time: world.time,
        scale: 1.06,
        pose: leadPose,
      );
      return;
    }
    if (world.time < world.hunterStunUntil) {
      // Dhakka kha kar gire hue, aakhir mein uth khare hote hain
      final down = world.time - world.escapeTime;
      final rising = world.hunterStunUntil - world.time < 0.35;
      for (var i = 0; i < World.hunterGaps.length; i++) {
        final foot = Offset(world.hunters[i].x, world.hunters[i].y);
        if (rising) {
          drawFigure(
            canvas,
            look: looks[i],
            foot: foot,
            dir: 1,
            phase: 0,
            moving: false,
            inAir: false,
            time: world.time,
            scale: 1.06,
          );
        } else {
          drawDying(
            canvas,
            look: looks[i],
            foot: foot,
            dir: 1,
            fallDir: -1,
            t: min(down * (1 + i * 0.2), 0.9),
            time: world.time + i,
          );
        }
      }
      return;
    }
    for (var i = 0; i < world.hunters.length; i++) {
      // Har shikaari apne jism ki jagah: daurta, koodta, ya khara
      final b = world.hunters[i];
      final x = b.x;
      if (x < camX - 60 || x > camX + viewW + 60) continue;
      drawFigure(
        canvas,
        look: looks[i],
        foot: Offset(x, b.y),
        dir: b.vx.abs() > 1
            ? b.vx.sign
            : world.hunterDir, // jidhar ja raha; khara ho to idhar udhar dekhta
        phase: world.time * 9.5 + i * 1.7,
        moving: b.vx.abs() > 1 && b.grounded,
        inAir: !b.grounded,
        time: world.time + i,
        wind: world.windAt(x),
        scale: 1.06,
      );
    }
  }

  /// Hawa mein ya zameen mein gare neze
  void _spears(Canvas canvas) {
    final shaft = Paint()
      ..color = palette.ink
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (final sp in world.spears) {
      final d = Offset(cos(sp.angle), sin(sp.angle));
      final tip = Offset(sp.x, sp.y);
      canvas.drawLine(tip - d * 38, tip, shaft);
      final n = Offset(-d.dy, d.dx);
      canvas.drawPath(
        Path()..addPolygon([
          tip + d * 5,
          tip - d * 2 + n * 2.4,
          tip - d * 2 - n * 2.4,
        ], true),
        _black,
      );
    }
  }

  void _fogAndVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [palette.fog, palette.fog.withValues(alpha: 0)],
        ).createShader(rect),
    );
    // Baarish mein hawa mein paani ki dhund
    if (weather.rain > 0.05) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFFC8CDD0)
              .withValues(alpha: 0.10 * weather.rain),
      );
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [palette.vignette.withValues(alpha: 0), palette.vignette],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
