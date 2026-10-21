// Chapters ki khaas cheezen: aag, jalti jhonpriyan, darya, tairte lakkar, rassi ka pul, biwi ka gaddha.
// Limbo jaisa: sab kaala silhouette; aag aur roshni safed chamak ki tarah.
import 'dart:math';

import 'package:flutter/material.dart';

import 'figures.dart';

const _ink = Color(0xFF070707);
final _fill = Paint()..color = _ink;

double _hash(int i, int salt) {
  final h = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return h - h.floorToDouble();
}

/// Aag: thartharate sholay, gird roshni, oopar urti chingariyan. [r] = khatre wala hissa (zameen pe)
void drawFire(Canvas canvas, Rect r, double t, {double size = 1}) {
  final c = Offset(r.center.dx, r.bottom);
  final flicker = 0.8 + 0.2 * sin(t * 13) * sin(t * 7.3 + 1);
  // Gird ki roshni
  canvas.drawCircle(
    c + Offset(0, -12 * size),
    70 * size,
    Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.42 * flicker),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: c + Offset(0, -12 * size),
              radius: 70 * size,
            ),
          ),
  );
  // Sholay: neeche chaure, oopar nukeele, har ek apni taal pe lehrata
  final tongues = max(3, (r.width / 9).round());
  final flame = Path();
  for (var i = 0; i < tongues; i++) {
    final x = r.left + (i + 0.5) * r.width / tongues;
    final h =
        (18 + _hash(i, 1) * 16) *
        size *
        (0.75 + 0.25 * sin(t * (9 + i) + i * 2));
    final lean = sin(t * 6 + i * 1.7) * 4 * size;
    final w = r.width / tongues * 0.8;
    flame
      ..moveTo(x - w, r.bottom)
      ..quadraticBezierTo(
        x - w * 0.6 + lean * 0.3,
        r.bottom - h * 0.6,
        x + lean,
        r.bottom - h,
      )
      ..quadraticBezierTo(
        x + w * 0.6 + lean * 0.3,
        r.bottom - h * 0.6,
        x + w,
        r.bottom,
      )
      ..close();
  }
  canvas.drawPath(flame, Paint()..color = const Color(0xFFDDDDDA));
  // Andar ka zyada chamakta hissa
  canvas.drawPath(
    flame.transform(
      (Matrix4.identity()
            ..translateByDouble(c.dx, c.dy, 0, 1)
            ..scaleByDouble(0.6, 0.55, 1, 1)
            ..translateByDouble(-c.dx, -c.dy, 0, 1))
          .storage,
    ),
    Paint()..color = Colors.white,
  );
  // Chingariyan
  final ember = Paint()..color = Colors.white;
  for (var i = 0; i < 8; i++) {
    final life = (t * (0.45 + _hash(i, 2) * 0.3) + _hash(i, 3)) % 1;
    final p = Offset(
      r.left + _hash(i, 4) * r.width + sin(t * 3 + i) * 8 * life,
      r.bottom - 10 - life * 110 * size,
    );
    ember.color = Colors.white.withValues(alpha: (1 - life) * 0.9);
    canvas.drawCircle(p, 1.3 * (1 - life * 0.5), ember);
  }
}

/// Jalti jhonpri: deewarein, phoos ki chhat (tooti hui), chhat pe aag, oopar uthta dhuaan
void drawHut(
  Canvas canvas,
  double x,
  double ground,
  double t,
  double wind,
  int seed,
) {
  // Dhuaan sab se peeche
  for (var k = 5; k >= 0; k--) {
    final rise = (t * 18 + k * 34) % 210;
    final p = Offset(
      x + wind * rise * 0.5 + sin(t * 0.8 + k) * 10,
      ground - 105 - rise,
    );
    canvas.drawCircle(
      p,
      16 + rise * 0.18,
      Paint()
        ..color = const Color(0xFF3E4041)
            .withValues(alpha: 0.28 * (1 - rise / 210)),
    );
  }
  final walls = Rect.fromLTWH(x - 38, ground - 46, 76, 46);
  canvas.drawRect(walls, Paint()..color = const Color(0xFF141414));
  // Darwaze ki jagah se andar ki aag ki roshni
  canvas.drawRect(
    Rect.fromLTWH(x - 9, ground - 30, 18, 30),
    Paint()
      ..color = Colors.white.withValues(
        alpha: 0.35 + 0.15 * sin(t * 11 + seed),
      ),
  );
  // Phoos ki chhat — kinara be-tarteeb, ek taraf se jal kar toota hua
  final roof = Path()..moveTo(x - 56, ground - 44);
  for (var k = 0; k <= 10; k++) {
    roof.lineTo(
      x - 56 + k * 11.2,
      ground - 44 + (k.isEven ? 3 : 0) + _hash(seed * 11 + k, 5) * 3,
    );
  }
  roof
    ..lineTo(x + 8, ground - 96)
    ..lineTo(x - 2, ground - 90)
    ..close();
  canvas.drawPath(roof, Paint()..color = const Color(0xFF141414));
  drawFire(
    canvas,
    Rect.fromLTWH(x - 30, ground - 75, 46, 8),
    t + seed,
    size: 1.3,
  );
}

/// Darya: paani ki sateh pe lehrein, neeche andhera
void drawWater(Canvas canvas, double left, double right, double y, double t) {
  final body = Rect.fromLTRB(left, y, right, 620);
  canvas.drawRect(
    body,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF34383A), Color(0xFF0E0F10)],
      ).createShader(body),
  );
  final wave = Path()..moveTo(left, y);
  for (var x = left; x <= right; x += 6) {
    wave.lineTo(
      x,
      y + sin(x * 0.08 + t * 2.4) * 1.6 + sin(x * 0.031 - t * 1.3) * 1.2,
    );
  }
  canvas.drawPath(
    wave,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x99C8CDD0),
  );
  // Sateh pe chamakti lakeerein
  final glint = Paint()
    ..color = const Color(0x55D8DCDE)
    ..strokeWidth = 1;
  for (var i = (left / 40).floor(); i * 40 < right; i++) {
    final gx = i * 40 + _hash(i, 7) * 30 + sin(t * 1.5 + i) * 5;
    if (gx < left || gx > right) continue;
    final gy = y + 6 + _hash(i, 8) * 14;
    canvas.drawLine(
      Offset(gx, gy),
      Offset(gx + 6 + _hash(i, 9) * 10, gy),
      glint,
    );
  }
}

/// Tairta lakkar: chhaal ki lakeerein, kinaron pe gol kate hue sire
void drawLog(Canvas canvas, Rect r) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
    _fill,
  );
  final bark = Paint()
    ..color = const Color(0xFF2A2A2A)
    ..strokeWidth = 0.8;
  for (var x = r.left + 10; x < r.right - 10; x += 13) {
    canvas.drawLine(Offset(x, r.top + 3), Offset(x + 7, r.top + 3), bark);
    canvas.drawLine(
      Offset(x + 4, r.bottom - 4),
      Offset(x + 11, r.bottom - 4),
      bark,
    );
  }
  canvas.drawCircle(
    Offset(r.right - r.height / 2, r.center.dy),
    r.height * 0.32,
    Paint()..color = const Color(0xFF2A2A2A),
  );
}

/// Rassi ka pul: takhte, dono taraf jhoolti rassiyan, kinaron pe khambe
void drawBridge(Canvas canvas, Rect r, double t, double wind) {
  final sway = sin(t * 1.3) * 1.2 + wind * 2;
  for (var x = r.left; x < r.right - 3; x += 9) {
    final k = (x - r.left) / r.width;
    final sag = sin(k * pi) * 3 + sin(k * pi) * sway * 0.3;
    canvas.drawRect(Rect.fromLTWH(x + 1, r.top + sag, 7, 4.5), _fill);
  }
  final rope = Paint()
    ..color = _ink
    ..strokeWidth = 1.3
    ..style = PaintingStyle.stroke;
  for (final h in [0.0, 26.0]) {
    final p = Path()..moveTo(r.left, r.top - h);
    p.quadraticBezierTo(
      r.center.dx + sway,
      r.top - h + 10 + (h > 0 ? 8 : 0),
      r.right,
      r.top - h,
    );
    canvas.drawPath(p, rope);
  }
  // Oopar aur neeche ki rassi ko jorti patli dooriyan
  for (var x = r.left + 20; x < r.right - 10; x += 20) {
    final k = (x - r.left) / r.width;
    final top = r.top - 26 + sin(k * pi) * 18 / 2 + 2;
    canvas.drawLine(
      Offset(x, top),
      Offset(x, r.top + sin(k * pi) * 3),
      Paint()
        ..color = _ink
        ..strokeWidth = 0.7,
    );
  }
  for (final x in [r.left, r.right]) {
    canvas.drawRect(Rect.fromLTWH(x - 2, r.top - 32, 4, 34), _fill);
  }
}

/// Aakhri manzil: zameen mein gaddha, andar barhta paani, aur biwi — oopar haath barhaye hue
void drawWifePit(Canvas canvas, double x, double ground, double t) {
  // Umeed ki roshni
  canvas.drawCircle(
    Offset(x, ground - 20),
    120,
    Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(x, ground - 20), radius: 120),
          ),
  );
  // Gaddhe ka andar: andhera, neeche paani ki chamakti sateh
  final pit = Rect.fromLTWH(x - 28, ground, 56, 70);
  canvas.drawRect(
    pit,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF16181A), Color(0xFF2C3033)],
      ).createShader(pit),
  );
  final water = ground + 26 + sin(t * 1.7) * 1.5;
  canvas.drawRect(
    Rect.fromLTRB(pit.left, water, pit.right, pit.bottom),
    Paint()..color = const Color(0xFF3C4144),
  );
  canvas.drawLine(
    Offset(pit.left, water),
    Offset(pit.right, water),
    Paint()
      ..color = const Color(0xAAD0D4D6)
      ..strokeWidth = 1,
  );
  // Biwi: kamar tak paani mein, sar zameen se jhaankta hua, ek haath oopar bahar ki taraf
  canvas.save();
  canvas.clipRect(
    Rect.fromLTRB(pit.left - 30, ground - 80, pit.right + 30, water + 1),
  );
  drawFigure(
    canvas,
    look: Look.hero,
    foot: Offset(x - 4, water + 10),
    dir: 1, // aate hue shohar ki taraf
    phase: 0,
    moving: false,
    inAir: false,
    time: t,
    pose: FigurePose(
      (0.1, 0),
      (-0.1, 0),
      (2.3 + sin(t * 2.2) * 0.12, 0.55),
      (0.5, 0.6),
    ),
  );
  canvas.restore();
  // Kinare ke chhote patthar (sirf dono kinaron pe)
  for (final k in [-1.0, 1.0]) {
    canvas.drawCircle(Offset(x + k * 31, ground + 1), 3.2, _fill);
    canvas.drawCircle(Offset(x + k * 36, ground + 2), 2.4, _fill);
  }
}
