// Chapters ki khaas cheezen: aag, jalti jhonpriyan, darya, kashtiyan, rassi ka pul.
// Limbo jaisa: sab kaala silhouette — sirf aag asli rang mein (narangi), taake andhere mein chamke.
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'palette.dart';

Color get _ink => palette.ink;
Paint get _fill => Paint()..color = _ink;

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
  // Rangeen subah mein mitti ki deewarein aur sunehri phoos; warna kaale saaye
  final colorful = palette.colorful;
  canvas.drawRect(
    walls,
    Paint()
      ..color = colorful ? const Color(0xFF7A5232) : const Color(0xFF141414),
  );
  // Darwaze ki jagah se andar ki aag ki roshni
  canvas.drawRect(
    Rect.fromLTWH(x - 9, ground - 30, 18, 30),
    Paint()
      ..color = (colorful ? const Color(0xFF2A1A0E) : Colors.white).withValues(
        alpha: colorful
            ? 0.9
            : burning
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
  canvas.drawPath(
    roof,
    Paint()
      ..color = colorful ? const Color(0xFFB98A3E) : const Color(0xFF141414),
  );
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

/// Chhupne ka gaddha: zameen ke neeche khokhli jagah (purani jaron ke neeche ki khoh). Kaali zameen mein
/// halka andhera — taake andar ka kaala hero dikhe. [hole] andar ka hissa, [ground] zameen ki sath.
/// Munh [hole.left]+8..+40 pe patli chhat se oopar khulta hai. Chhat se jarein latakti hain.
void drawHideoutBack(Canvas canvas, Rect hole, double ground, double t) {
  // Be-tarteeb gol khoh: neeche se chapti, oopar se ubar-khaabar
  final c = hole.center;
  final rx = hole.width / 2, ry = hole.height / 2;
  final pocket = Path();
  const n = 26;
  for (var i = 0; i <= n; i++) {
    final a = i / n * 2 * pi;
    var y = sin(a);
    y = y > 0
        ? pow(y, 0.7).toDouble()
        : y; // farsh: mitti ke dheer, seedhi lakeer nahi (paani jaisa na lage)
    final wob = 1 + (_hash(i % n, 71) - 0.5) * 0.26;
    final p = c + Offset(cos(a) * rx * wob, y * ry * wob);
    i == 0 ? pocket.moveTo(p.dx, p.dy) : pocket.lineTo(p.dx, p.dy);
  }
  pocket.close();
  // Munh: chhat mein tircha surakh, oopar zameen tak
  final mouthL = hole.left + 8, mouthR = hole.left + 40;
  final mouth = Path()
    ..moveTo(mouthL - 2, ground + 1)
    ..lineTo(mouthL + 4, hole.top + 10)
    ..lineTo(mouthR + 6, hole.top + 12)
    ..lineTo(mouthR, ground + 1)
    ..close();
  final shape = Path.combine(PathOperation.union, pocket, mouth);
  final bounds = Rect.fromLTRB(hole.left, ground, hole.right, hole.bottom);
  canvas.drawPath(
    shape,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.55, -0.9), // roshni munh se aati hai
        radius: 1.25,
        colors: [Color(0xFF47443F), Color(0xFF2A2826), Color(0xFF121110)],
        stops: [0, 0.45, 1],
      ).createShader(bounds),
  );
  // Mitti ki deewarein: zarre aur kankar (sookhi khoh — chikni sath nahi)
  canvas.save();
  canvas.clipPath(shape);
  final grain = Paint();
  for (var k = 0; k < 140; k++) {
    final p = Offset(
      hole.left + _hash(k, 92) * hole.width,
      ground + _hash(k, 93) * (hole.bottom - ground),
    );
    grain.color = _hash(k, 94) < 0.6
        ? const Color(0x33000000)
        : const Color(0x14FFFFFF);
    canvas.drawCircle(p, 0.6 + _hash(k, 95) * 1.4, grain);
  }
  // Farsh pe mitti ka dheer (aagay ki taraf utha hua)
  canvas.drawPath(
    Path()
      ..moveTo(hole.left, hole.bottom + 4)
      ..quadraticBezierTo(
        hole.left + hole.width * 0.3,
        hole.bottom - 9,
        hole.left + hole.width * 0.55,
        hole.bottom - 2,
      )
      ..quadraticBezierTo(
        hole.left + hole.width * 0.8,
        hole.bottom + 3,
        hole.right,
        hole.bottom - 6,
      )
      ..lineTo(hole.right, hole.bottom + 10)
      ..lineTo(hole.left, hole.bottom + 10)
      ..close(),
    Paint()..color = const Color(0xCC0B0B0A),
  );
  canvas.restore();
  // Farsh pe chhote kankar aur mitti ke dheer
  for (var k = 0; k < 9; k++) {
    final x = hole.left + 14 + _hash(k, 72) * (hole.width - 28);
    final r = 1.2 + _hash(k, 73) * 2.2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, hole.bottom - 1 - r * 0.3),
        width: r * 2.4,
        height: r * 1.3,
      ),
      _fill,
    );
  }
  // Chhat se latakti jarein — oopar ke darakht ki, mitti mein se nikli hui, aahista hilti
  final root = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < 11; k++) {
    final x = mouthR + 6 + _hash(k, 74) * (hole.right - mouthR - 14);
    final top = Offset(x, hole.top + 4 + _hash(k, 75) * 4);
    final len = 6 + _hash(k, 76) * (hole.height * 0.55);
    final sway = sin(t * 0.9 + k * 1.7) * 1.2;
    root.strokeWidth = 0.6 + _hash(k, 77) * 1.4;
    final end = top + Offset((_hash(k, 78) - 0.5) * 10 + sway, len);
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(
        top.dx + (_hash(k, 79) - 0.5) * 8,
        top.dy + len * 0.55,
        end.dx,
        end.dy,
      );
    // Shaakh dar shaakh: beech se ek patli jar alag
    if (_hash(k, 80) < 0.6) {
      final mid = top + Offset((end.dx - top.dx) * 0.5, len * 0.5);
      path
        ..moveTo(mid.dx, mid.dy)
        ..quadraticBezierTo(
          mid.dx + 4,
          mid.dy + len * 0.2,
          mid.dx + 3 + sway,
          mid.dy + len * 0.35,
        );
    }
    canvas.drawPath(path, root);
  }
}

/// Gaddhay ke munh pe gire patton aur fern ka dhakkan (hero ke saamne). [pushers] (hero, shikaariyon ke
/// paon) ke qareeb patte dab jaate hain. [overhead]: jo shikaari abhi chhat ke oopar hain — un ke qadmon se
/// chhat se mitti jharti hai.
void drawHideoutFront(
  Canvas canvas,
  Rect hole,
  double ground,
  double t,
  double wind,
  List<Offset> pushers,
  List<double> overhead,
) {
  final mouthL = hole.left + 8, mouthR = hole.left + 40;
  // Mitti ke zarre: chhat se gir kar farsh tak
  final dirt = Paint()..color = const Color(0xFF0E0E0E);
  for (var h = 0; h < overhead.length; h++) {
    for (var k = 0; k < 6; k++) {
      final u = (t * 1.3 + _hash(k + h * 7, 81)) % 1;
      final x = (overhead[h] + (_hash(k + h * 7, 82) - 0.5) * 18).clamp(
        mouthR + 4,
        hole.right - 8,
      );
      final y = hole.top + 6 + u * u * (hole.height - 10);
      canvas.drawCircle(Offset(x, y), 0.7 + _hash(k, 83) * 0.7, dirt);
    }
  }
  // Fern ki pattiyan dono kinaron se munh ke oopar jhuki — sath pe dhakkan
  final stem = Paint()
    ..color = _ink
    ..strokeWidth = 1.1
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < 7; k++) {
    final fromLeft = k.isEven;
    final base = Offset(
      fromLeft
          ? mouthL - 10 + _hash(k, 84) * 8
          : mouthR + 10 - _hash(k, 84) * 8,
      ground + 1,
    );
    final dir = fromLeft ? 1.0 : -1.0;
    final len = 22 + _hash(k, 85) * 14;
    // Hawa ka jhoolna; paas se guzarne wale paon / girta hero pattiyan neeche dabaata hai
    var droop = 0.12 + sin(t * 1.3 + k) * 0.05 + wind * 0.06 * dir;
    for (final p in pushers) {
      final d = (p.dx - (base.dx + dir * len * 0.5)).abs();
      if (d < 24 && p.dy > ground - 50 && p.dy < hole.bottom + 4) {
        droop += (24 - d) / 24 * 0.9;
      }
    }
    final a = -0.35 + droop + _hash(k, 86) * 0.2; // pehle oopar, phir jhuk kar
    final tip = base + Offset(dir * len * cos(a), len * sin(a));
    final ctrl = base + Offset(dir * len * 0.45, -8 + droop * 10);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy),
      stem,
    );
    // Pattiyan: chhoti, jor dar jor (sir se chhoti)
    for (var j = 1; j <= 7; j++) {
      final f = j / 8;
      final q = Offset(
        (1 - f) * (1 - f) * base.dx +
            2 * f * (1 - f) * ctrl.dx +
            f * f * tip.dx,
        (1 - f) * (1 - f) * base.dy +
            2 * f * (1 - f) * ctrl.dy +
            f * f * tip.dy,
      );
      final size = 4.5 * (1 - f * 0.6);
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(q.dx, q.dy);
        canvas.rotate(dir * (0.6 + f * 0.6) + side * 1.1 + droop * 0.4);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(1.4, size * 0.5, 0, size)
            ..quadraticBezierTo(-1.4, size * 0.5, 0, 0),
          _fill,
        );
        canvas.restore();
      }
    }
  }
  // Munh ke oopar bikhre sookhe patte aur tehniyan (sath ke barabar)
  final twig = Paint()
    ..color = _ink
    ..strokeWidth = 1.3
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < 4; k++) {
    final x = mouthL + _hash(k, 87) * (mouthR - mouthL);
    final y = ground + 1 + _hash(k, 88) * 2;
    final l = 10 + _hash(k, 89) * 10;
    final a = (_hash(k, 90) - 0.5) * 0.5;
    canvas.drawLine(
      Offset(x - cos(a) * l / 2, y - sin(a) * l / 2),
      Offset(x + cos(a) * l / 2, y + sin(a) * l / 2),
      twig,
    );
  }
}

/// Aandhi mein darakht se tooti shaakh — kati hui lakdi nahi: mota sira chira hua (lambi kirchiyan, andar ki
/// halki lakdi dikhti hai), aagay patli hoti, teRhi, gaanthon wali; beech se ek shaakh phooti hui, sire pe
/// tehniyan aur patton ke guchhe. Beech (0,0) pe, [len] lambi, [thick] moti. Toota sira baayen (-x).
void drawBrokenBranch(
  Canvas canvas,
  double len,
  double thick,
  int seed,
  double t,
  double wind, {
  required bool falling,
}) {
  final half = len / 2;
  double h(int i) => _hash(i + seed * 31, 91);
  // Darmiyani lakeer (halki teRhi) aur har jagah moti'i: mote sire se patle sire tak
  const n = 9;
  Offset mid(double f) => Offset(
    -half + f * len,
    sin(f * 2.6 + seed) * thick * 0.12 + f * f * thick * 0.15,
  );
  double width(double f) {
    final knot = (h((f * n).round()) - 0.5) * 0.12; // gaanthein
    return thick * (1 - f * 0.62 + knot);
  }

  final top = <Offset>[], bottom = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final f = i / n;
    final w = width(f) / 2;
    top.add(mid(f) + Offset(0, -w));
    bottom.add(mid(f) + Offset(0, w));
  }
  final wood = Path()..moveTo(top.first.dx, top.first.dy);
  for (final p in top.skip(1)) {
    wood.lineTo(p.dx, p.dy);
  }
  // Patla sira: gol nahi, aagay tehniyon mein khatam
  wood.lineTo(half + 3, mid(1).dy);
  for (final p in bottom.reversed) {
    wood.lineTo(p.dx, p.dy);
  }
  // Toota sira: aari se kata seedha nahi — reshe khinch kar toote, lambi chhoti kirchiyan
  const splinters = 7;
  final b0 = bottom.first, t0 = top.first;
  for (var i = 1; i < splinters; i++) {
    final f = i / splinters;
    final y = b0.dy + (t0.dy - b0.dy) * f;
    final reach = (i.isOdd ? 4 + h(i + 40) * 12 : h(i + 50) * 3);
    wood.lineTo(b0.dx - reach, y);
    wood.lineTo(
      b0.dx + 1 + h(i + 60) * 3,
      y + (t0.dy - b0.dy) / splinters * 0.5,
    );
  }
  wood.close();
  final fill = Paint()..color = _ink;
  canvas.drawPath(wood, fill);

  // Beech se phooti shaakh (oopar ki taraf), aage do tehniyan
  final forkF = 0.35 + h(1) * 0.15;
  final forkBase = mid(forkF) + Offset(0, -width(forkF) * 0.3);
  final forkAngle = -0.75 - h(2) * 0.35; // oopar-aagay
  final forkLen = len * (0.36 + h(3) * 0.12);
  final forkTip =
      forkBase + Offset(cos(forkAngle) * forkLen, sin(forkAngle) * forkLen);
  // Jor pe moti, aagay patli — lakdi ki tarah, danda nahi
  final forkCtrl = forkBase + Offset(forkLen * 0.55, -forkLen * 0.2);
  Offset bez(double f) => Offset(
    (1 - f) * (1 - f) * forkBase.dx +
        2 * f * (1 - f) * forkCtrl.dx +
        f * f * forkTip.dx,
    (1 - f) * (1 - f) * forkBase.dy +
        2 * f * (1 - f) * forkCtrl.dy +
        f * f * forkTip.dy,
  );
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i <= 6; i++) {
    final f = i / 6;
    final d = bez(min(1, f + 0.01)) - bez(max(0, f - 0.01));
    final nrm = Offset(-d.dy, d.dx) / d.distance;
    final w = thick * (0.42 - f * 0.3) / 2;
    left.add(bez(f) + nrm * w);
    right.add(bez(f) - nrm * w);
  }
  canvas.drawPath(Path()..addPolygon([...left, ...right.reversed], true), fill);
  final limb = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  // Ek chhota toota thoonth (pehle se tooti tehni)
  final stubF = 0.62 + h(4) * 0.1;
  final stub = mid(stubF) + Offset(0, width(stubF) * 0.4);
  canvas.drawLine(stub, stub + Offset(5, 7), limb..strokeWidth = thick * 0.2);

  // Tehniyan aur patte: patle sire aur phooti shaakh ke sire pe
  final twig = Paint()
    ..color = _ink
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  final sway = falling
      ? sin(t * 9 + seed) * 0.25
      : sin(t * 1.5 + seed) * 0.05 + wind * 0.05;
  var leafI = 0;
  void spray(Offset from, double angle, int count, double reach) {
    for (var k = 0; k < count; k++) {
      final a =
          angle + (k - (count - 1) / 2) * 0.5 + (h(k + leafI) - 0.5) * 0.3;
      final l = reach * (0.6 + h(k + leafI + 7) * 0.5);
      final end = from + Offset(cos(a) * l, sin(a) * l);
      canvas.drawLine(from, end, twig);
      // Patton ka guchha: chhote, nukeele, alag alag rukh (sir se chhote)
      final leaves = 3 + (h(k + leafI + 11) * 3).floor();
      for (var j = 0; j < leaves; j++) {
        leafI++;
        final along = Offset.lerp(from, end, 0.55 + j / leaves * 0.45)!;
        final size = 4.5 + h(leafI + 13) * 2.5;
        canvas.save();
        canvas.translate(along.dx, along.dy);
        canvas.rotate(
          a + (j.isEven ? 1 : -1) * (0.7 + h(leafI + 17) * 0.6) + sway,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(size * 0.5, -size * 0.32, size, 0)
            ..quadraticBezierTo(size * 0.5, size * 0.32, 0, 0),
          fill,
        );
        canvas.restore();
      }
      leafI += 3;
    }
  }

  spray(Offset(half + 2, mid(1).dy), -0.15, 4, thick * 1.2);
  spray(mid(0.8) + Offset(0, -width(0.8) * 0.4), -0.9, 2, thick * 0.8);
  spray(forkTip, forkAngle + 0.15, 4, thick);

  // Chiri hui andar ki lakdi — toote sire pe halki lakeerein (sirf wahan rang halka)
  final inner = Paint()
    ..color = const Color(0x88C8C2B8)
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 4; i++) {
    final y = b0.dy + (t0.dy - b0.dy) * (0.2 + i * 0.2);
    final x = b0.dx + 1 - h(i + 70) * 2;
    canvas.drawLine(
      Offset(x, y),
      Offset(x - 3 - h(i + 80) * 7, y + 0.4),
      inner,
    );
  }
  // Chhaal: lambai mein reshe, seedhe kate chhalle nahi
  final bark = Paint()
    ..color = const Color(0x2EBFBFBF)
    ..strokeWidth = 0.7
    ..style = PaintingStyle.stroke;
  for (var k = 0; k < 3; k++) {
    final y0 = (k - 1) * thick * 0.18;
    final path = Path()..moveTo(-half + 8, mid(0.08).dy + y0);
    for (var i = 2; i <= 7; i++) {
      final f = i / n;
      final p =
          mid(f) + Offset(0, y0 * (1 - f * 0.6) + (h(i * 3 + k) - 0.5) * 1.5);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, bark);
  }
  // Halki roshni ki lakeer — taake andhere patton ke saamne bhi shaakh dikhe
  canvas.drawPath(
    wood,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x44E0E0E0),
  );
}
