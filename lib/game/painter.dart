// Limbo jaisa look: grey dhundla background, sab kuch kaala silhouette.
// Tarteeb (peeche se aagay): aasmaan → bijli → door ke darakht+baarish → beech ke → game → saamne ke darakht → dhund
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'grass.dart';
import 'jungle.dart';
import 'weather.dart';
import 'world.dart';

class WorldPainter extends CustomPainter {
  final World world;
  final Jungle jungle;
  final Weather weather;
  WorldPainter(this.world, this.jungle, this.weather, {super.repaint});

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

    jungle.prepare(
      scale,
    ); // pehli dafa saari tasveerein ek saath (baad mein kabhi nahi atke)

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
    canvas.translate(-camX, 0);
    jungle.drawWorldBack(canvas, world, camX, viewW, t, scale);
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
    for (final m in world.level.movers) {
      _mover(canvas, m.rectAt(t));
    }
    for (final trap in world.level.traps) {
      _trap(canvas, trap);
    }
    for (final p in world.level.pendulums) {
      _pendulum(canvas, p);
    }
    for (var i = 0; i < world.level.rocks.length; i++) {
      if (world.rockState[i] == 0) continue; // abhi oopar chhupa hai
      final rock = world.level.rocks[i];
      _rock(canvas, Offset(rock.x, world.rockY[i]), rock.radius, i);
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
    jungle.drawFront(canvas, world, camX, viewW, wind * 0.5, t, scale);
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
      ..color = const Color(0xFF070707)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(r.left + 8, 0), Offset(r.left + 8, r.top), rope);
    canvas.drawLine(Offset(r.right - 8, 0), Offset(r.right - 8, r.top), rope);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      _black,
    );
  }

  /// Shikanja: zameen pe khula jabra, nukeele daant
  void _trap(Canvas canvas, Rect r) {
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
        ..color = const Color(0xFF070707)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      p.pivot,
      bob,
      Paint()
        ..color = const Color(0xFF070707)
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

  /// Ubar-khaabar patthar
  void _rock(Canvas canvas, Offset c, double r, int seed) {
    final rnd = Random(seed * 7 + 3);
    final path = Path();
    for (var k = 0; k < 9; k++) {
      final a = k / 9 * 2 * pi;
      final rr = r * (0.8 + rnd.nextDouble() * 0.3);
      final p = c + Offset(cos(a) * rr * 1.1, sin(a) * rr * 0.85);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, _black);
    // Halki roshni ki lakeer — taake girta patthar kaale patton ke saamne bhi dikhe
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x66E0E0E0),
    );
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

    final hip = Offset(x, y - 21);
    final shoulder = Offset(x + dir * 0.5, y - 35 + bob * 0.5);

    // Kamar pe bandha neza — shikaari ki pehchaan (sab se peeche)
    canvas.drawLine(
      Offset(x - dir * 9, y - 12 + bob * 0.5),
      Offset(x + dir * 5, y - 50 + bob * 0.5),
      Paint()
        ..color = const Color(0xFF070707)
        ..strokeWidth = 1.6,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x + dir * 5, y - 50 + bob * 0.5)
        ..lineTo(x + dir * 3.2, y - 45 + bob * 0.5)
        ..lineTo(x + dir * 6.6, y - 45.6 + bob * 0.5)
        ..close(),
      _black,
    );

    // Peeche wale baazu aur taang pehle (thore patle), taake gehraai lage
    _limb(canvas, shoulder, armB, 7.5, 7, 2.5, dir);
    _leg(canvas, hip, legB, dir);

    // Jism — kurta jo neeche se thora phaila hua hai
    final torso = Path()
      // Chaure kandhe, patli kamar, kamar pe lipta kapra
      ..moveTo(x - 5.5, y - 36 + bob * 0.5)
      ..quadraticBezierTo(x, y - 38 + bob * 0.5, x + 5.5, y - 36 + bob * 0.5)
      ..lineTo(x + 3.8, y - 22)
      ..lineTo(x + 5.2, y - 16)
      ..quadraticBezierTo(x, y - 15, x - 5.2, y - 16)
      ..lineTo(x - 3.8, y - 22)
      ..close();
    canvas.drawPath(torso, _black);

    _leg(canvas, hip, legA, dir);
    _limb(canvas, shoulder, armA, 7.5, 7, 2.9, dir);

    // Sar — jawan aadmi ka, jism ke hisaab se chhota
    final head = Offset(x + dir * 1.2, y - 44.5 + bob);
    canvas.drawCircle(head, 6.3, _black);
    // Gardan
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x + dir * 0.8, y - 38.5 + bob),
        width: 3.6,
        height: 4,
      ),
      _black,
    );

    // Baal — oopar bikhre, peeche bandhi choti jo hawa mein lehrati hai
    final hair = Path();
    const spikes = 6;
    for (var k = 0; k <= spikes * 2; k++) {
      final t = -pi * 0.92 + k * (pi * 0.62) / (spikes * 2);
      final back = 1 - k / (spikes * 2); // peeche wale baal lambe
      final r = k.isEven ? 5.8 : 7.2 + back * 1.6 + (k % 4 == 1 ? 0.6 : 0);
      final pt =
          head +
          Offset(
            cos(t) * r * dir - dir * (k.isOdd ? back * 1.0 : 0),
            sin(t) * r,
          );
      k == 0 ? hair.moveTo(pt.dx, pt.dy) : hair.lineTo(pt.dx, pt.dy);
    }
    hair.close();
    canvas.drawPath(hair, _black);
    final wind = world.windAt(x);
    final tail = head + Offset(-dir * 6, -2);
    final tip =
        tail + Offset(-dir * 7 + wind * 4, 5 + sin(world.time * 5) * 1.2);
    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = const Color(0xFF070707)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    // Badi chamakti aankhen — har kuch second baad palak jhapakti hain
    final blink = world.time % 3.7 > 3.57;
    final eye = Paint()..color = Colors.white;
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final (dx, w) in [(2.4, 2.2), (4.9, 1.9)]) {
      final c = head + Offset(dir * dx, -0.5);
      final r = Rect.fromCenter(center: c, width: w, height: blink ? 0.5 : 3.0);
      canvas.drawOval(r.inflate(1), glow);
      canvas.drawOval(r, eye);
    }
  }

  void _leg(Canvas canvas, Offset hip, (double, double) a, double dir) {
    final foot = _limb(canvas, hip, a, 10.5, 10.8, 3.6, dir);
    // Chhota sa joota, aagay ki taraf
    canvas.drawLine(
      foot,
      foot + Offset(dir * 3.2, 0),
      Paint()
        ..color = const Color(0xFF070707)
        ..strokeWidth = 3.0
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
