// Limbo jaisa look: grey dhundla background, sab kuch kaala silhouette.
// Tarteeb (peeche se aagay): aasmaan → bijli → door ke darakht+baarish → beech ke → game → saamne ke darakht → dhund
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'figures.dart';
import 'grass.dart';
import 'props.dart';
import 'jungle.dart';
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
    final level = world.level;
    for (var i = 0; i < level.huts.length; i++) {
      final x = level.huts[i];
      if (x < camX - 150 || x > camX + viewW + 150) continue;
      drawHut(canvas, x, _groundAt(x), t, world.windAt(x), i);
    }
    final waterY = level.waterY;
    if (waterY != null) {
      for (final (l, r) in _gaps(camX - 20, camX + viewW + 20)) {
        drawWater(canvas, l, r, waterY, t);
      }
    }
    final grass = Path();
    for (final s in world.level.solids) {
      if (s.right < camX - 40 || s.left > camX + viewW + 40) continue;
      if (s.height < 10) {
        drawBridge(canvas, s, t, world.windAt(s.center.dx)); // rassi ka pul
        continue;
      }
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
      m.log ? drawLog(canvas, m.rectAt(t)) : _mover(canvas, m.rectAt(t));
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
    _goalLight(canvas);
    extra?.call(canvas);
    _hunters(canvas, camX, viewW);
    _player(canvas);
    // Patthar player ke baad — neeche dabi laash patthar ke neeche dikhe
    for (var i = 0; i < world.level.rocks.length; i++) {
      if (world.rockState[i] == 0) continue; // abhi oopar chhupa hai
      final rock = world.level.rocks[i];
      _rock(canvas, Offset(rock.x, world.rockY[i]), rock.radius, i);
    }
    _spears(canvas);
    _splashes(canvas);
    canvas.restore();

    // Saamne wali baarish, saamne ke darakht aur urte patte
    _rain(canvas, 2);
    jungle.drawFront(canvas, world, camX, viewW, wind * 0.5, t, scale);
    _flyingLeaves(canvas);

    canvas.restore();

    _fogAndVignette(canvas, size);
  }

  double _groundAt(double x) {
    var best = 400.0;
    var found = false;
    for (final s in world.level.solids) {
      if (x >= s.left && x <= s.right && (!found || s.top < best)) {
        best = s.top;
        found = true;
      }
    }
    return best;
  }

  /// [from]..[to] mein jahan zameen nahi (darya ka paani wahan dikhta hai)
  List<(double, double)> _gaps(double from, double to) {
    final spans = [
      for (final s in world.level.solids)
        if (s.height >= 10) (s.left, s.right),
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
          ..color = const Color(0xFF070707),
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
    final dir = world.facingRight ? 1.0 : -1.0;
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
        case DeathKind.rock:
          dying(speed: 3); // bhaari patthar — foran dab gaya
        case DeathKind.spike:
          dying(raise: 9); // kaanton ke oopar
        case DeathKind.trap || DeathKind.caught:
          dying();
      }
      return;
    }
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
    );
  }

  /// Peeche daurte jangli shikaari
  void _hunters(Canvas canvas, double camX, double viewW) {
    if (!world.chaseActive) return;
    const looks = [Look.feathers, Look.shield, Look.archer];
    for (var i = 0; i < World.hunterGaps.length; i++) {
      final x = world.hunterX - World.hunterGaps[i];
      if (x < camX - 60 || x > camX + viewW + 60) continue;
      final footY = world.hunterFootY(x);
      final onGround = world.level.solids.any(
        (s) => x >= s.left && x <= s.right && (s.top - footY).abs() < 1,
      );
      drawFigure(
        canvas,
        look: looks[i],
        foot: Offset(x, footY),
        dir: 1,
        phase: world.time * 9.5 + i * 1.7,
        moving: world.hunterMoving,
        inAir: !onGround,
        time: world.time + i,
        wind: world.windAt(x),
        scale: 1.06,
      );
    }
  }

  /// Hawa mein ya zameen mein gare neze
  void _spears(Canvas canvas) {
    final shaft = Paint()
      ..color = const Color(0xFF070707)
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
