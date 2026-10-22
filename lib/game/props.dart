// Chapters ki khaas cheezen: aag, jalti jhonpriyan, darya, kashtiyan, rassi ka pul.
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

/// Lakri ki kashti (bagal se): dono sire oopar mure aur nukeele, gol pait, kinare ki patti, takhton ki
/// lakeerein, beech ki patti, aur paani mein dooba chappu. Lehron ke saath halki jhoolti hai.
/// [r] = kashti ki thos sateh (jis pe hero khara hota hai), [waterY] = paani ki sateh.
void drawBoat(Canvas canvas, Rect r, double t, double waterY, int seed) {
  final c = Offset(r.center.dx, r.top);
  final tilt = sin(t * 1.3 + seed) * 0.035; // lehron pe jhoolna
  // Paani ki chhoti lehrein dono taraf
  final ripple = Paint()
    ..color = const Color(0x77C8CDD0)
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;
  for (var k = 0; k < 3; k++) {
    final u = (t * 0.8 + k / 3) % 1;
    for (final side in [-1.0, 1.0]) {
      final x = c.dx + side * (r.width / 2 + 6 + u * 22);
      canvas.drawLine(
        Offset(x, waterY + 1),
        Offset(x + side * 8 * (1 - u), waterY + 1),
        ripple..color = Color.fromRGBO(200, 205, 208, 0.45 * (1 - u)),
      );
    }
  }

  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(tilt);
  final hw = r.width / 2;
  final keel = waterY - r.top + 5; // pait thora sa paani mein
  // Pait: peeche (baayen) ki nok, kinara neeche aata hai, aage (daayen) ki nok zyada oonchi;
  // neeche chhichhla gol pait jo dono siron pe nukeela ho kar milta hai
  final hull = Path()
    ..moveTo(-hw - 8, -10)
    ..quadraticBezierTo(-hw + 6, -3, -hw + 18, -2)
    ..lineTo(hw - 18, -2)
    ..quadraticBezierTo(hw - 2, -3, hw + 10, -13)
    ..quadraticBezierTo(hw + 6, keel * 0.35, hw - 26, keel)
    ..lineTo(-hw + 24, keel)
    ..quadraticBezierTo(-hw - 2, keel * 0.35, -hw - 8, -10)
    ..close();
  // Gehri lakri (silhouette mein halka sa bhoora asar)
  canvas.drawPath(
    hull,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A211A), Color(0xFF0C0907)],
      ).createShader(Rect.fromLTRB(-hw - 10, -14, hw + 12, keel)),
  );
  canvas.save();
  canvas.clipPath(hull);
  // Takhton ki halki lakeerein, kinare ki golai ke saath
  final plank = Paint()
    ..color = const Color(0x2EA88A6A)
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;
  for (final y in [keel * 0.55, keel * 0.85]) {
    canvas.drawPath(
      Path()
        ..moveTo(-hw - 6, y - 7)
        ..quadraticBezierTo(0, y + 1, hw + 8, y - 8),
      plank,
    );
  }
  // Beech ki patti
  canvas.drawPath(
    Path()
      ..moveTo(-hw - 8, 2)
      ..quadraticBezierTo(0, 9, hw + 10, 1)
      ..lineTo(hw + 10, 4.5)
      ..quadraticBezierTo(0, 12.5, -hw - 8, 5.5)
      ..close(),
    Paint()..color = const Color(0x66905A3A),
  );
  canvas.restore();
  // Kinare ki patti (oopar ki roshni)
  canvas.drawPath(
    Path()
      ..moveTo(-hw - 8, -10)
      ..quadraticBezierTo(-hw + 6, -3, -hw + 18, -2)
      ..lineTo(hw - 18, -2)
      ..quadraticBezierTo(hw - 2, -3, hw + 10, -13),
    Paint()
      ..color = const Color(0x88C7AE8E)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round,
  );
  // Chappu: kinare pe tika, paani mein dooba
  final oar = Paint()
    ..color = const Color(0xFF1C1610)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final grip = Offset(-hw * 0.25, -7);
  final blade = Offset(-hw * 0.9 - 14, keel + 10);
  canvas.drawLine(grip, blade, oar);
  canvas.drawOval(
    Rect.fromCenter(center: blade, width: 6, height: 12),
    Paint()..color = const Color(0xFF1C1610),
  );
  canvas.restore();
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

/// Panah: bari chattan jis ka oopar wala hissa chhajje ki tarah aage nikla hai. [roof] chhajja, [wall] pichhli
/// deewar (dono asal mein thos hain). Kinare ubar-khaabar, chhajje se latakti jarein, kinare se tapakte qatre,
/// neeche halka saaya — andar sookha.
void drawRefuge(
  Canvas canvas,
  Rect roof,
  Rect wall,
  double ground,
  double t,
  double wind,
  double rain,
) {
  // Neeche ka saaya (panah ka ehsaas)
  final shelter = Rect.fromLTRB(roof.left + 6, roof.bottom, wall.left, ground);
  canvas.drawRect(
    shelter,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55000000), Color(0x22000000)],
      ).createShader(shelter),
  );
  // Chattan: deewar neeche se, oopar se ubhra hua, aage nukeela chhajja
  final rock = Path()..moveTo(wall.right + 8, ground);
  final topY = roof.top;
  final pts = <Offset>[
    Offset(wall.right + 10, ground - 40),
    Offset(wall.right + 4, topY + 14),
    Offset(wall.right - 10, topY - 6),
    Offset(wall.center.dx, topY - 12),
    Offset(roof.center.dx + 20, topY - 4),
    Offset(roof.center.dx - 25, topY - 9),
    Offset(roof.left + 18, topY - 2),
    Offset(roof.left - 4, topY + 8), // aage ki nok
    Offset(roof.left + 2, roof.bottom + 2),
    Offset(roof.left + 30, roof.bottom - 2),
    Offset(roof.center.dx, roof.bottom + 3),
    Offset(wall.left - 12, roof.bottom + 6),
    Offset(wall.left - 4, roof.bottom + 30), // deewar ke saath gola
    Offset(wall.left, ground - 20),
    Offset(wall.left - 6, ground),
  ];
  // Har kinare pe chhote ubhaar aur gadhe — qudrati patthar, seedhi lakeerein nahi
  for (var i = 0; i < pts.length; i++) {
    final a = i == 0 ? Offset(wall.right + 8, ground) : pts[i - 1];
    final b = pts[i];
    for (var k = 1; k <= 3; k++) {
      final f = k / 4;
      final n = Offset(-(b - a).dy, (b - a).dx) / max(1, (b - a).distance);
      final p = Offset.lerp(a, b, f)! + n * (_hash(i * 5 + k, 41) - 0.5) * 7;
      rock.lineTo(p.dx, p.dy);
    }
    rock.lineTo(b.dx, b.dy);
  }
  rock.close();
  canvas.drawPath(rock, _fill);
  // Chattan ki daraarein (halki si)
  final crack = Paint()
    ..color = const Color(0x22FFFFFF)
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;
  canvas.drawPath(
    Path()
      ..moveTo(wall.center.dx + 6, topY + 6)
      ..lineTo(wall.center.dx - 2, topY + 30)
      ..lineTo(wall.center.dx + 8, topY + 52),
    crack,
  );
  // Chhajje se latakti jarein aur bailen — hawa mein halki hilti hui
  final root = Paint()
    ..color = _ink
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < 7; k++) {
    final x = roof.left + 12 + k * (roof.width - 50) / 6;
    final len = 10 + _hash(k, 31) * 26;
    final sway = sin(t * 1.4 + k) * 2 + wind * 4;
    final top = Offset(x, roof.bottom + 1);
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(
          top.dx + sway * 0.4,
          top.dy + len * 0.5,
          top.dx + sway,
          top.dy + len,
        ),
      root,
    );
  }
  // Baarish mein chhajje ke kinare se tapakte qatre
  if (rain > 0.1) {
    final drop = Paint()
      ..color = const Color(0xFFD5DADD).withValues(alpha: 0.75 * rain);
    for (var k = 0; k < 4; k++) {
      final u = (t * 1.2 + _hash(k, 33)) % 1;
      final x = roof.left + 4 + _hash(k, 34) * 30;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, roof.bottom + 4 + u * (ground - roof.bottom - 4)),
          width: 1.4,
          height: 3.2,
        ),
        drop,
      );
    }
  }
}
