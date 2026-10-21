// Limbo jaisa look: grey dhundla background, sab kuch kaala silhouette.
// Tarteeb (peeche se aagay): aasmaan → bijli → door ke darakht+baarish → beech ke → game → saamne ke darakht → dhund
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'grass.dart';
import 'trees.dart';
import 'weather.dart';
import 'world.dart';

/// Jungle ki saari darakht layers
class Scenery {
  final far = TreeLayer(
    parallax: 0.2,
    spacing: 55,
    seed: 11,
    color: const Color(0x2E000000),
    minHeight: 520,
    maxHeight: 700,
    thickness: 0.45,
    maxDepth: 6,
    leafiness: 0.3,
    variants: 8,
  );
  final mid = TreeLayer(
    parallax: 0.5,
    spacing: 175,
    seed: 22,
    color: const Color(0x66000000),
    minHeight: 480,
    maxHeight: 650,
    thickness: 0.65,
    leafiness: 0.5,
    variants: 8,
  );
  final near = TreeLayer(
    parallax: 1,
    spacing: 340,
    seed: 33,
    color: const Color(0xE0101010),
    minHeight: 430,
    maxHeight: 560,
    thickness: 0.85,
    maxDepth: 6,
    leafiness: 0.7,
  );
  final front = TreeLayer(
    parallax: 1.4,
    spacing: 1300,
    seed: 44,
    color: const Color(0xFF030303),
    minHeight: 750,
    maxHeight: 900,
    thickness: 1.1,
    maxDepth: 6,
    leafiness: 0.5,
  );

  // Door aur beech ke darakht: har ek ki ek dafa tasveer (image) bana lo, phir har frame
  // sirf woh tasveer hawa ke hisaab se jhuka kar dikhao. Hazaron shakalein dobara banane se bachte hain.
  final _images = <TreeLayer, Map<int, (ui.Image, Rect)>>{};
  double _res = 0;

  void drawCached(
    Canvas canvas,
    TreeLayer layer,
    int i,
    Offset root,
    double sway,
    double res,
  ) {
    if ((res - _res).abs() > 0.05) {
      // Screen ka size badla — tasveerein naye size pe dobara banengi
      for (final m in _images.values) {
        for (final (img, _) in m.values) {
          img.dispose();
        }
      }
      _images.clear();
      _res = res;
    }
    final key = layer.variantOf(i);
    final (image, bounds) = _images
        .putIfAbsent(layer, () => {})
        .putIfAbsent(key, () => _render(layer, key, res));
    canvas.save();
    canvas.translate(root.dx, root.dy);
    canvas.skew(-sway, 0); // oopar ka hissa zyada jhukta hai, jar apni jagah
    if (layer.mirrored(i)) canvas.scale(-1, 1);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      bounds,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  (ui.Image, Rect) _render(TreeLayer layer, int key, double res) {
    final path = Path();
    layer.tree(key).addTo(path, Offset.zero, 0, 0);
    final bounds = path.getBounds().inflate(2);
    final rec = ui.PictureRecorder();
    Canvas(rec)
      ..scale(res)
      ..translate(-bounds.left, -bounds.top)
      ..drawPath(path, Paint()..color = layer.color);
    final image = rec.endRecording().toImageSync(
      (bounds.width * res).ceil(),
      (bounds.height * res).ceil(),
    );
    return (image, bounds);
  }
}

class WorldPainter extends CustomPainter {
  final World world;
  final Scenery scenery;
  final Weather weather;
  WorldPainter(this.world, this.scenery, this.weather, {super.repaint});

  static const viewHeight = 500.0; // itni world height screen pe fit hogi
  static final _black = Paint()..color = const Color(0xFF070707);

  static double viewWidth(Size size) => size.width / (size.height / viewHeight);
  static double cameraX(World world, double viewW) =>
      max(0.0, world.pos.dx - viewW * 0.35);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / viewHeight;
    final viewW = viewWidth(size);
    final camX = cameraX(world, viewW);
    final t = world.time;
    final wind = weather.wind;

    _sky(canvas, size);

    canvas.save();
    canvas.scale(scale);

    // Door ke darakht + door ki baarish
    final res =
        scale * 1.25; // tasveer ki resolution (pixels har view unit mein)
    _cachedLayer(canvas, scenery.far, camX, viewW, 470, wind * 0.4, t, res);
    _rain(canvas, 0);
    _haze(canvas, viewW, 0.18);

    // Beech ke darakht — hawa mein hilte hue
    _cachedLayer(canvas, scenery.mid, camX, viewW, 450, wind * 0.8, t, res);
    _rain(canvas, 1);
    _haze(canvas, viewW, 0.12);

    // --- Game ki duniya (camera ke saath)
    canvas.save();
    canvas.translate(-camX, 0);
    _nearTrees(canvas, camX, viewW, wind, t);
    final grass = Path();
    for (final s in world.level.solids) {
      if (s.right < camX - 40 || s.left > camX + viewW + 40) continue;
      canvas.drawRect(s, _black);
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
    canvas.drawPath(grass, _black);
    for (final s in world.level.spikes) {
      _spikes(canvas, s);
    }
    for (final saw in world.level.saws) {
      _saw(canvas, saw);
    }
    for (final c in world.level.checkpoints.skip(1)) {
      _lamp(
        canvas,
        c,
        lit: world.level.checkpoints.indexOf(c) <= world.checkpoint,
      );
    }
    _goalLight(canvas);
    if (world.state != PlayerState.dead) _player(canvas);
    _splashes(canvas);
    canvas.restore();

    // Saamne wali baarish, saamne ke darakht aur urte patte
    _rain(canvas, 2);
    _frontTrees(canvas, camX, viewW, wind * 0.5, t);
    _flyingLeaves(canvas);

    canvas.restore();

    _fogAndVignette(canvas, size);
  }

  void _sky(Canvas canvas, Size size) {
    final r = weather.rain;
    final top = Color.lerp(
      const Color(0xFFB8B8B8),
      const Color(0xFF8C8E90),
      r,
    )!;
    final bottom = Color.lerp(
      const Color(0xFF6E6E6E),
      const Color(0xFF55585A),
      r,
    )!;
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
            Colors.white.withValues(alpha: amount + weather.rain * 0.08),
            Colors.white.withValues(alpha: amount * 0.3),
          ],
        ).createShader(rect),
    );
  }

  void _cachedLayer(
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
      // Hawa ka jhukaav + har darakht ka apna aahista jhoolna
      final sway =
          wind * 0.035 + sin(t * 1.1 + i * 1.7) * 0.008 * (0.4 + wind.abs());
      scenery.drawCached(canvas, layer, i, Offset(x - shift, rootY), sway, res);
    }
  }

  /// Saamne ke darakht: player inke peeche aaye to yeh halke ho jaate hain, taake woh chhup na jaye
  void _frontTrees(
    Canvas canvas,
    double camX,
    double viewW,
    double wind,
    double t,
  ) {
    final layer = scenery.front;
    final shift = camX * layer.parallax;
    final playerX = world.pos.dx - camX;
    for (final (i, x) in layer.visible(shift - 300, shift + viewW + 300)) {
      final sx = x - shift;
      final path = Path();
      layer.tree(i).addTo(path, Offset(sx, 560), wind, t);
      final near = (1 - ((sx - playerX).abs() - 40) / 160).clamp(0.0, 1.0);
      canvas.drawPath(
        path,
        Paint()..color = layer.color.withValues(alpha: 1 - near * 0.7),
      );
    }
  }

  void _nearTrees(
    Canvas canvas,
    double camX,
    double viewW,
    double wind,
    double t,
  ) {
    final layer = scenery.near;
    final path = Path();
    for (final (i, x) in layer.visible(camX - 250, camX + viewW + 250)) {
      // Sirf zameen pe ugte hain, gaddhay mein nahi
      final ground = world.level.solids.where(
        (s) => x > s.left + 10 && x < s.right - 10 && s.top >= 340,
      );
      if (ground.isEmpty) continue;
      layer
          .tree(i)
          .addTo(
            path,
            Offset(x, ground.first.top + 2),
            world.windAt(x) * 0.9,
            t,
          );
    }
    canvas.drawPath(path, Paint()..color = layer.color);
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
        ..color = const Color(0xFF070707)
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

  void _player(Canvas canvas) {
    final p = world.pos;
    final dir = world.facingRight ? 1.0 : -1.0;
    final phase = world.walkPhase;
    final walking = world.grounded && world.vx != 0;
    final inAir = !world.grounded;
    final x = p.dx, y = p.dy;

    // Chalte waqt sar thora upar neeche, khare hue saans lene se halka sa
    final bob = walking
        ? -sin(phase * 2).abs() * 1.2
        : sin(world.time * 2) * 0.5;

    // Taangen: (ran ka angle, ghutne ka mor)
    final s = sin(phase);
    final (double, double) legA, legB;
    if (inAir) {
      legA = (0.8, -1.3); // aagay wali taang sameti hui
      legB = (-0.35, -0.7);
    } else if (walking) {
      legA = (s * 0.55, -max(0.0, cos(phase)) * 0.9);
      legB = (-s * 0.55, -max(0.0, -cos(phase)) * 0.9);
    } else {
      legA = (0.14, -0.05);
      legB = (-0.12, 0);
    }
    // Baazu: taangon ke ulat jhoolte hain
    final (double, double) armA, armB;
    if (inAir) {
      armA = (2.0, -0.5);
      armB = (-1.1, 0.4);
    } else if (walking) {
      armA = (-s * 0.6, 0.5);
      armB = (s * 0.6, 0.5);
    } else {
      armA = (0.3, 0.25);
      armB = (-0.08, 0.15);
    }

    final hip = Offset(x, y - 16);
    final shoulder = Offset(x + dir * 0.5, y - 27 + bob * 0.5);

    // Peeche wale baazu aur taang pehle (thore patle), taake gehraai lage
    _limb(canvas, shoulder, armB, 5.5, 5.5, 2.8, dir);
    _leg(canvas, hip, legB, dir);

    // Jism — kurta jo neeche se thora phaila hua hai
    final torso = Path()
      ..moveTo(x - 4.5, y - 29 + bob * 0.5)
      ..quadraticBezierTo(x, y - 31 + bob * 0.5, x + 4.5, y - 29 + bob * 0.5)
      ..lineTo(x + 5, y - 14)
      ..quadraticBezierTo(x, y - 13, x - 5, y - 14)
      ..close();
    canvas.drawPath(torso, _black);

    _leg(canvas, hip, legA, dir);
    _limb(canvas, shoulder, armA, 5.5, 5.5, 3.2, dir);

    // Sar — bara aur gol, bachay jaisa
    final head = Offset(x + dir * 1.5, y - 37.5 + bob);
    canvas.drawCircle(head, 9.5, _black);
    // Gardan
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x + dir * 0.8, y - 29.5 + bob),
        width: 5,
        height: 4,
      ),
      _black,
    );

    // Baal — peeche aur upar ki taraf nukeele gucchay
    final hair = Path();
    const spikes = 6;
    for (var k = 0; k <= spikes * 2; k++) {
      final t = -pi * 0.92 + k * (pi * 0.62) / (spikes * 2);
      final back = 1 - k / (spikes * 2); // peeche wale baal lambe
      final r = k.isEven ? 8.8 : 10.8 + back * 2.2 + (k % 4 == 1 ? 0.8 : 0);
      final pt =
          head +
          Offset(
            cos(t) * r * dir - dir * (k.isOdd ? back * 1.5 : 0),
            sin(t) * r,
          );
      k == 0 ? hair.moveTo(pt.dx, pt.dy) : hair.lineTo(pt.dx, pt.dy);
    }
    hair.close();
    canvas.drawPath(hair, _black);

    // Badi chamakti aankhen — har kuch second baad palak jhapakti hain
    final blink = world.time % 3.7 > 3.57;
    final eye = Paint()..color = Colors.white;
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final (dx, w) in [(3.4, 2.9), (7.0, 2.5)]) {
      final c = head + Offset(dir * dx, -0.8);
      final r = Rect.fromCenter(center: c, width: w, height: blink ? 0.6 : 4.2);
      canvas.drawOval(r.inflate(1), glow);
      canvas.drawOval(r, eye);
    }
  }

  void _leg(Canvas canvas, Offset hip, (double, double) a, double dir) {
    final foot = _limb(canvas, hip, a, 8, 8.5, 4.2, dir);
    // Chhota sa joota, aagay ki taraf
    canvas.drawLine(
      foot,
      foot + Offset(dir * 3.5, 0),
      Paint()
        ..color = const Color(0xFF070707)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Do hisson wala azoo (ran+pindli ya baazu+kalaai). Angle neeche se naapa jata hai,
  /// positive = jidhar munh hai. Haath/paon ki jagah wapas karta hai.
  Offset _limb(
    Canvas canvas,
    Offset start,
    (double, double) a,
    double l1,
    double l2,
    double width,
    double dir,
  ) {
    final joint = start + Offset(sin(a.$1) * l1 * dir, cos(a.$1) * l1);
    final end =
        joint + Offset(sin(a.$1 + a.$2) * l2 * dir, cos(a.$1 + a.$2) * l2);
    final paint = Paint()
      ..color = const Color(0xFF070707)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(joint.dx, joint.dy)
        ..lineTo(end.dx, end.dy),
      paint..style = PaintingStyle.stroke,
    );
    return end;
  }

  void _fogAndVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
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
        ..shader = const RadialGradient(
          radius: 0.9,
          colors: [Color(0x00000000), Color(0xCC000000)],
          stops: [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
