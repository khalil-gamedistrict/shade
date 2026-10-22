// Chapters ki khaas cheezen: aag, jalti jhonpriyan, darya, tairte lakkar, rassi ka pul.
// Limbo jaisa: sab kaala silhouette — sirf aag asli rang mein (narangi), taake andhere mein chamke.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const _ink = Color(0xFF070707);
final _fill = Paint()..color = _ink;

double _hash(int i, int salt) {
  final h = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return h - h.floorToDouble();
}

// ---- Aag: asli aag ki tarah sainkron chamakti lapten (particles), jama ho kar chamakti hain

/// Ek naram, lambi (aansoo jaisi) chamakti lapat — sab lapten isi tasveer se banti hain (ek dafa banti hai)
ui.Image? _spark;
ui.Image get _sparkImage => _spark ??= () {
  final rec = ui.PictureRecorder();
  Canvas(rec)
    ..scale(1, 2) // 32x64: oopar neeche lambi
    ..drawCircle(
      const Offset(16, 16),
      16,
      Paint()
        ..shader =
            const RadialGradient(
              colors: [Color(0xFFFFFFFF), Color(0x88FFFFFF), Color(0x00FFFFFF)],
              stops: [0, 0.4, 1],
            ).createShader(
              Rect.fromCircle(center: const Offset(16, 16), radius: 16),
            ),
    );
  return rec.endRecording().toImageSync(32, 64);
}();

// Lapat ka rang umar ke saath: safed-peela (neeche, sab se garam) → narangi → gehra laal → ghayab
const _flameStops = [
  (0.0, Color(0xFFFFF6DC)),
  (0.18, Color(0xFFFFD27A)),
  (0.45, Color(0xFFFF9636)),
  (0.75, Color(0xFFD9441C)),
  (1.0, Color(0xFF6E1A0A)),
];

Color _flameColor(double u, double alpha) {
  for (var k = 1; k < _flameStops.length; k++) {
    final (u1, c1) = _flameStops[k];
    if (u <= u1) {
      final (u0, c0) = _flameStops[k - 1];
      return Color.lerp(c0, c1, (u - u0) / (u1 - u0))!.withValues(alpha: alpha);
    }
  }
  return _flameStops.last.$2.withValues(alpha: alpha);
}

/// Aag: [r] = khatre wala hissa (zameen pe). Lapten neeche se uthti hain, oopar jaate hue beech ki taraf
/// simat kar patli hoti hain, hawa mein lehrati hain; gird garam roshni aur urti chingariyan.
void drawFire(
  Canvas canvas,
  Rect r,
  double t, {
  double size = 1,
  double wind = 0,
}) {
  final base = Offset(r.center.dx, r.bottom);
  final flicker = 0.85 + 0.15 * sin(t * 13) * sin(t * 7.3 + 1);

  // Zameen aur aas paas pe garam roshni
  final glowR = (60 + r.width * 0.8) * size;
  canvas.drawCircle(
    base + Offset(0, -10 * size),
    glowR,
    Paint()
      ..blendMode = BlendMode.plus
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFF8C32).withValues(alpha: 0.32 * flicker),
              const Color(0x00FF8C32),
            ],
          ).createShader(
            Rect.fromCircle(
              center: base + Offset(0, -10 * size),
              radius: glowR,
            ),
          ),
  );

  final img = _sparkImage;
  final half = r.width / 2;
  final n = (r.width * 2.2).clamp(44, 150).round();
  final transforms = <RSTransform>[], rects = <Rect>[], colors = <Color>[];
  const src = Rect.fromLTWH(0, 0, 32, 64);
  for (var i = 0; i < n; i++) {
    final h1 = _hash(i, 21),
        h2 = _hash(i, 22),
        h3 = _hash(i, 23),
        h4 = _hash(i, 24);
    final wisp =
        i % 4 ==
        0; // kuch lambi patli lapten jo saanp ki tarah lehrati oopar jaati hain
    final u =
        (t * (wisp ? 0.8 + h1 * 0.4 : 1.1 + h1 * 0.7) + h2) % 1; // umar 0..1
    final x0 = r.left + (0.15 + h3 * 0.7) * r.width;
    final centered = pow(
      1 - ((x0 - base.dx).abs() / max(1, half)) * 0.6,
      1.5,
    ); // beech ki lapten oonchi
    final height = (46 + h4 * 44) * size * centered * (wisp ? 1.6 : 1);
    final swayAmp = (wisp ? 7.0 : 3.5) * size;
    // Oopar jaate hue beech ki taraf simatna + lehrana + hawa
    final x =
        x0 +
        (base.dx - x0) * u * 0.75 +
        sin(t * 7 + i * 1.7 + u * 4) * swayAmp * u +
        wind * u * 18 * size;
    final y = base.dy - 3 - u * height;
    final radius =
        pow(1 - u, 0.9) * (wisp ? 3.5 + h1 * 2.5 : 4.5 + h1 * 4) * size;
    final alpha = pow(1 - u, 1.1) * (wisp ? 0.45 : 0.34) * flicker;
    transforms.add(
      RSTransform.fromComponents(
        rotation:
            (cos(t * 7 + i * 1.7 + u * 4) * 0.35 + wind * 0.4) *
            u, // lapat lehar ke saath jhukti
        scale: radius / 16,
        anchorX: 16,
        anchorY: 40,
        translateX: x,
        translateY: y,
      ),
    );
    rects.add(src);
    colors.add(_flameColor(u, alpha.toDouble()));
  }
  // Chingariyan: chhoti, tez, oopar door tak, tedhi meedhi
  for (var i = 0; i < 12; i++) {
    final life = (t * (0.35 + _hash(i, 2) * 0.3) + _hash(i, 3)) % 1;
    final x =
        r.left +
        _hash(i, 4) * r.width +
        sin(t * 4 + i * 2.1) * 10 * life +
        wind * life * 40;
    final y = r.bottom - 12 - life * (90 + _hash(i, 5) * 60) * size;
    transforms.add(
      RSTransform.fromComponents(
        rotation: 0,
        scale: (1.6 * (1 - life * 0.6)) / 32 * size,
        anchorX: 32,
        anchorY: 32,
        translateX: x,
        translateY: y,
      ),
    );
    rects.add(src);
    final twinkle = 0.6 + 0.4 * sin(t * 25 + i * 3);
    colors.add(const Color(0xFFFFB24D).withValues(alpha: (1 - life) * twinkle));
  }
  // Sab lapten ek saath, jama hoti roshni (additive) — andar ka hissa khud safed-peela chamakta hai
  canvas.drawAtlas(
    img,
    transforms,
    rects,
    colors,
    BlendMode.modulate,
    null,
    Paint()..blendMode = BlendMode.plus,
  );
}

/// Jalti jhonpri: deewarein, phoos ki chhat (tooti hui), chhat pe aag, oopar uthta dhuaan
void drawHut(
  Canvas canvas,
  double x,
  double ground,
  double t,
  double wind,
  int seed, {
  bool burning = true, // false = sabut jhonpri (hamla hone se pehle)
}) {
  // Dhuaan sab se peeche
  for (var k = burning ? 5 : -1; k >= 0; k--) {
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
        alpha: burning
            ? 0.35 + 0.15 * sin(t * 11 + seed)
            : 0.22 + 0.04 * sin(t * 3 + seed),
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
  if (burning) {
    // Ek taraf se jal kar toota hua
    roof
      ..lineTo(x + 8, ground - 96)
      ..lineTo(x - 2, ground - 90);
  } else {
    roof.lineTo(x, ground - 98);
  }
  roof.close();
  canvas.drawPath(roof, Paint()..color = const Color(0xFF141414));
  if (!burning) return;
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
