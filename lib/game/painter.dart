// Limbo jaisa look: grey dhundla background, sab kuch kaala silhouette
import 'dart:math';

import 'package:flutter/material.dart';

import 'world.dart';

class WorldPainter extends CustomPainter {
  final World world;
  WorldPainter(this.world, {super.repaint});

  static const viewHeight = 500.0; // itni world height screen pe fit hogi
  static final _black = Paint()..color = const Color(0xFF070707);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / viewHeight;
    final viewW = size.width / scale;
    final camX = max(0.0, world.pos.dx - viewW * 0.35);

    _background(canvas, size, camX, scale);

    canvas.save();
    canvas.scale(scale);
    canvas.translate(-camX, 0);

    for (final s in world.level.solids) {
      canvas.drawRect(s, _black);
      _grass(canvas, s);
    }
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

    canvas.restore();

    _fogAndVignette(canvas, size);
  }

  void _background(Canvas canvas, Size size, double camX, double scale) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB8B8B8), Color(0xFF6E6E6E)],
        ).createShader(Offset.zero & size),
    );
    // Door ke darakht — do layers, parallax ke saath (door wale aahista chalte hain)
    _trees(canvas, size, camX * 0.2, scale, const Color(0x40000000), 0.9, 1);
    _trees(canvas, size, camX * 0.5, scale, const Color(0x80000000), 1.2, 2);
  }

  void _trees(
    Canvas canvas,
    Size size,
    double offset,
    double scale,
    Color color,
    double h,
    int seed,
  ) {
    final paint = Paint()..color = color;
    const spacing = 140.0;
    final first = (offset / spacing).floor() - 1;
    for (var i = first; i < first + size.width / scale / spacing + 3; i++) {
      final rnd = Random(i * 31 + seed);
      final x = (i * spacing - offset + rnd.nextDouble() * 60) * scale;
      final w = (8 + rnd.nextDouble() * 14) * scale;
      final top = size.height * (0.05 + rnd.nextDouble() * 0.25) / h;
      canvas.drawRect(Rect.fromLTRB(x, top, x + w, size.height), paint);
      // Shaakhen
      final branch = Paint()
        ..color = color
        ..strokeWidth = w * 0.3;
      for (var b = 0; b < 3; b++) {
        final y = top + (size.height - top) * (0.1 + b * 0.15);
        final dir = rnd.nextBool() ? 1 : -1;
        canvas.drawLine(
          Offset(x + w / 2, y),
          Offset(x + w / 2 + dir * w * 3, y - w * 2),
          branch,
        );
      }
    }
  }

  void _grass(Canvas canvas, Rect s) {
    final rnd = Random(s.left.toInt());
    final path = Path()..moveTo(s.left, s.top);
    for (var x = s.left; x < s.right; x += 6) {
      path.lineTo(x + 3, s.top - 2 - rnd.nextDouble() * 6);
      path.lineTo(min(x + 6, s.right), s.top);
    }
    path.close();
    canvas.drawPath(path, _black);
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
    final legSwing = sin(world.walkPhase) * 6;

    final leg = Paint()
      ..color = const Color(0xFF070707)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    // Taangen
    canvas.drawLine(
      Offset(p.dx - 3, p.dy - 16),
      Offset(p.dx - 3 + legSwing, p.dy - 1),
      leg,
    );
    canvas.drawLine(
      Offset(p.dx + 3, p.dy - 16),
      Offset(p.dx + 3 - legSwing, p.dy - 1),
      leg,
    );
    // Jism
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p.dx - 7, p.dy - 32, 14, 18),
        const Radius.circular(4),
      ),
      _black,
    );
    // Baazu
    canvas.drawLine(
      Offset(p.dx, p.dy - 28),
      Offset(p.dx - legSwing * 0.8, p.dy - 17),
      leg..strokeWidth = 3.5,
    );
    // Sar
    final head = Offset(p.dx + dir * 1, p.dy - 37);
    canvas.drawCircle(head, 9, _black);
    // Chamakti aankhen
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(head + Offset(dir * 3, -1), 1.8, eye);
    canvas.drawCircle(head + Offset(dir * 7, -1), 1.5, eye);
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
