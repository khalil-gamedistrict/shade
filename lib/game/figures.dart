// Insaani silhouettes: hero aur jangli shikaari. Sab ka ek hi daurne wala jism (aagay jhuka hua,
// oonche ghutne, zor se hilte baazu), phir har ek ki pehchaan alag — baal, taaj, hathiyar.
import 'dart:math';

import 'package:flutter/material.dart';

import 'palette.dart';

enum Look {
  hero, // lambe khule baal, kaan mein gol baali, langot
  feathers, // pankhon wala taaj, neza
  shield, // sar pe juda, gol dhaal, neza
  archer, // kalgi (mohawk), kaman, peeth pe tarkash
  villager, // gaon ka aadmi (ya bachcha, chhote scale pe): chhote baal, langot
  woman, // lambe baal, ghutnon tak ghaghra
}

Color get _ink =>
    palette.ink; // kirdar ka saaya (rangeen chapter mein gehra bhoora)

/// Bahar se tay kiya hua pose (maut ka manzar waghera): (ran/baazu ka angle, ghutne/kohni ka mor)
class FigurePose {
  final (double, double) legA, legB, armA, armB;
  final double lean;
  const FigurePose(this.legA, this.legB, this.armA, this.armB, {this.lean = 0});
}

Paint get _fill => Paint()..color = _ink;

/// [foot]: paon ki jagah, [dir]: 1 = right ki taraf munh, [phase]: daud ka chakkar
void drawFigure(
  Canvas canvas, {
  required Look look,
  required Offset foot,
  required double dir,
  required double phase,
  required bool moving,
  required bool inAir,
  required double time,
  double wind = 0,
  double scale = 1,
  FigurePose? pose,
  bool eyesClosed = false,
  int backShield = 0, // peeth pe dhaal: kitne neze aur rok sakti hai (0 = nahi); kam = zyada daraarein
}) {
  canvas.save();
  canvas.translate(foot.dx, foot.dy);
  canvas.scale(scale);
  final hero = look == Look.hero;

  final s = sin(phase), c = cos(phase);
  final bob = pose != null
      ? 0.0
      : (moving ? -sin(phase * 2).abs() * 1.6 : sin(time * 2) * 0.5);
  // daurte waqt aagay jhuka hua
  final lean = pose?.lean ?? (moving ? 0.17 : (inAir ? 0.06 : 0.0));

  // Taangen: (ran ka angle, ghutne ka mor)
  (double, double) legA, legB;
  if (inAir) {
    legA = (0.95, -1.45);
    legB = (-0.45, -0.85);
  } else if (moving) {
    legA = (s * 0.78, -max(0.0, c) * 1.3);
    legB = (-s * 0.78, -max(0.0, -c) * 1.3);
  } else {
    legA = (0.14, -0.05);
    legB = (-0.12, 0);
  }
  // Baazu: kohni muri hui, taangon ke ulat zor se jhoolte
  (double, double) armA, armB;
  if (inAir) {
    armA = (2.0, -0.5);
    armB = (-1.1, 0.4);
  } else if (moving) {
    armA = (-s * 0.95, 1.25);
    armB = (s * 0.95, 1.25);
  } else {
    armA = (0.3, 0.25);
    armB = (-0.08, 0.15);
  }

  if (pose != null) {
    (legA, legB, armA, armB) = (pose.legA, pose.legB, pose.armA, pose.armB);
  }

  const hip = Offset(0, -21);
  final shoulder = Offset(dir * 0.5, -35 + bob * 0.5);

  // Peeche wali taang
  _leg(canvas, hip, legB, dir);

  // Oopar ka jism aagay jhukta hai (kulhe ke gird)
  canvas.save();
  canvas.translate(hip.dx, hip.dy);
  canvas.rotate(dir * lean);
  canvas.translate(-hip.dx, -hip.dy);

  if (backShield > 0) {
    // Peeth pe bandhi gol dhaal (chamra/lakdi): halka kinara taake kaale jism ke saath bhi dikhe
    final c = Offset(-dir * 6, -28 + bob * 0.5);
    canvas.drawCircle(c, 9.5, _fill);
    canvas.drawCircle(
      c,
      9.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0x77D8D8D8),
    );
    canvas.drawCircle(c, 2, Paint()..color = const Color(0x66D8D8D8));
    // Har roke hue neze ki daraar
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xAAE0E0E0);
    for (var k = 0; k < 3 - backShield; k++) {
      final a = 0.8 + k * 2.1;
      final p1 = c + Offset(cos(a), sin(a)) * 2.5;
      final p2 = c + Offset(cos(a + 0.3), sin(a + 0.3)) * 6;
      final p3 = c + Offset(cos(a - 0.1), sin(a - 0.1)) * 9.5;
      canvas.drawPath(
        Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy),
        crack,
      );
    }
  }
  final backHand = _limb(canvas, shoulder, armB, 7.5, 7, 2.5, dir);
  if (look == Look.shield) {
    // Gol dhaal peeche wale baazu pe
    canvas.drawCircle(backHand + Offset(-dir * 1, -2), 8.5, _fill);
  }
  if (look == Look.archer) {
    // Peeth pe tarkash (teer daan) aur us mein teer
    final q = Offset(-dir * 4, -33 + bob * 0.5);
    canvas.drawPath(
      Path()..addPolygon([
        q,
        q + Offset(-dir * 4, 2),
        q + Offset(-dir * 1, 16),
        q + Offset(dir * 3, 14),
      ], true),
      _fill,
    );
    for (var k = 0; k < 3; k++) {
      canvas.drawLine(
        q + Offset(-dir * k * 1.4, 0),
        q + Offset(-dir * (2 + k * 1.4), -6),
        _stroke(1),
      );
    }
  }

  // Dhar: chaure kandhe, patli kamar (shikaari thore bhaari)
  final w = hero ? 5.5 : 6.3;
  canvas.drawPath(
    Path()
      ..moveTo(-w, -36 + bob * 0.5)
      ..quadraticBezierTo(0, -38 + bob * 0.5, w, -36 + bob * 0.5)
      ..lineTo(3.9, -22)
      ..lineTo(4.4, -18)
      ..lineTo(-4.4, -18)
      ..lineTo(-3.9, -22)
      ..close(),
    _fill,
  );

  // Langot: aagay aur peeche latakte kapre — daurte waqt peeche ki taraf lehrate hain
  final flap = moving ? sin(phase * 2) * 1.5 - 2.5 : wind * 1.5;
  if (look == Look.woman) {
    // Ghaghra: kamar se ghutnon tak, daurte waqt peeche lehrata
    canvas.drawPath(
      Path()
        ..moveTo(-4.4, -19)
        ..lineTo(4.4, -19)
        ..lineTo(dir * (6.5 + flap * 0.4), -8)
        ..lineTo(dir * (-6.5 + flap * 0.8), -8.5)
        ..close(),
      _fill,
    );
  }
  for (final side in look == Look.woman ? const <double>[] : [1.0, -1.0]) {
    final x0 = dir * side * 0.5;
    canvas.drawPath(
      Path()
        ..moveTo(x0 + dir * side * 0.5, -19)
        ..lineTo(x0 + dir * side * 4.5, -19)
        ..lineTo(
          x0 + dir * (side * 3 + flap * (side > 0 ? 0.6 : 1.2)),
          side > 0 ? -10 : -11.5,
        )
        ..lineTo(
          x0 + dir * (side * 1 + flap * (side > 0 ? 0.6 : 1.2)),
          side > 0 ? -10.5 : -12,
        )
        ..close(),
      _fill,
    );
  }

  // Gardan aur sar
  final head = Offset(dir * 1.2, -44.5 + bob);
  canvas.drawRect(
    Rect.fromCenter(
      center: Offset(dir * 0.8, -38.5 + bob),
      width: 3.6,
      height: 4,
    ),
    _fill,
  );
  canvas.drawCircle(head, 6.3, _fill);

  switch (look) {
    case Look.hero:
      _longHair(canvas, head, dir, moving, time, wind);
      // Kaan mein gol baali (ear plug) — halki si chamak ke saath
      final ear = head + Offset(-dir * 0.6, 1.4);
      canvas.drawCircle(ear, 2.0, _fill);
      canvas.drawCircle(
        ear,
        1.3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = const Color(0x66D8D8D8),
      );
      if (!eyesClosed) _eyes(canvas, head, dir, time, angry: false);
    case Look.villager:
      // Chhote baal — sar pe topi jaisi
      canvas.drawPath(
        Path()..addArc(
          Rect.fromCircle(center: head + const Offset(0, -0.8), radius: 6.9),
          pi * 0.95,
          pi * 1.15,
        ),
        _fill,
      );
      if (!eyesClosed) _eyes(canvas, head, dir, time, angry: false);
    case Look.woman:
      _longHair(canvas, head, dir, moving, time, wind);
      if (!eyesClosed) _eyes(canvas, head, dir, time, angry: false);
    case Look.feathers:
      // Pankhon ka taaj: sar ke peeche pankhe ki tarah phaile lambe pankh, bandh (band) ke saath
      for (var k = 0; k < 7; k++) {
        final a = -dir * (-0.35 + k * 0.27) + sin(time * 3 + k) * 0.04;
        final base = head + Offset(-dir * 2.5, -2.5);
        final len = 19.0 + (3 - (k - 3).abs()) * 2.5;
        canvas.drawPath(_feather(base, a, len), _fill);
      }
      canvas.drawRect(
        Rect.fromCenter(
          center: head + const Offset(0, -3.8),
          width: 13.5,
          height: 2.6,
        ),
        _fill,
      );
      if (!eyesClosed) _eyes(canvas, head, dir, time, angry: true);
    case Look.shield:
      // Sar ke oopar bandha juda aur chhoti choti
      canvas.drawCircle(head + Offset(-dir * 1.5, -7), 3.2, _fill);
      canvas.drawLine(
        head + Offset(-dir * 2.5, -7),
        head + Offset(-dir * 8, -3 + sin(time * 6) * 1.5),
        _stroke(2),
      );
      if (!eyesClosed) _eyes(canvas, head, dir, time, angry: true);
    case Look.archer:
      // Kalgi: sar ke beech se seedhi khari
      final crest = Path()..moveTo(head.dx - dir * 6, head.dy - 2);
      for (var k = 0; k <= 8; k++) {
        final a = -pi / 2 - dir * (1.2 - k * 0.3);
        final r = k.isEven ? 6.5 : 10.5;
        final pt = head + Offset(cos(a) * r, sin(a) * r);
        crest.lineTo(pt.dx, pt.dy);
      }
      crest.close();
      canvas.drawPath(crest, _fill);
      if (!eyesClosed) _eyes(canvas, head, dir, time, angry: true);
  }

  // Aagay wala baazu (aur hathiyar)
  final hand = _limb(canvas, shoulder, armA, 7.5, 7, 2.9, dir);
  if (look == Look.feathers || look == Look.shield) {
    // Neza: daurte waqt aagay-oopar ki taraf; larai jaise pose mein kalaai ki seedh mein (waar dikhe)
    final Offset d;
    if (pose != null) {
      final fore =
          armA.$1 + armA.$2; // kalaai ka zawiya (neeche se, munh ki taraf +)
      d = Offset(sin(fore) * dir, cos(fore));
    } else {
      const a = -0.35;
      d = Offset(cos(a) * dir, sin(a));
    }
    final tail = hand - d * 20, tip = hand + d * 30;
    canvas.drawLine(tail, tip, _stroke(1.6));
    final n = Offset(-d.dy, d.dx);
    canvas.drawPath(
      Path()..addPolygon([tip + d * 6, tip + n * 2.2, tip - n * 2.2], true),
      _fill,
    );
  }
  if (look == Look.archer) {
    // Kaman: aagay wale haath mein, dhanush ki shakal
    final bow = Path()..moveTo(hand.dx - dir * 2, hand.dy - 14);
    bow.quadraticBezierTo(
      hand.dx + dir * 9,
      hand.dy,
      hand.dx - dir * 2,
      hand.dy + 14,
    );
    canvas.drawPath(bow, _stroke(1.8)..style = PaintingStyle.stroke);
    canvas.drawLine(
      Offset(hand.dx - dir * 2, hand.dy - 14),
      Offset(hand.dx - dir * 2, hand.dy + 14),
      _stroke(0.6),
    );
  }
  canvas.restore();

  // Aagay wali taang (sab se upar)
  _leg(canvas, hip, legA, dir);
  canvas.restore();
}

/// Maut: jhatka → girna (gravity ki tarah tez hota hua) → zameen se takra kar halka uchhalna →
/// tarapna (jhatke jo dheere dheere band hon) → saakit. [t] = maut ke baad ka waqt (second),
/// [fallDir] = kis taraf gira (+1 right). Paon zameen pe tike rehte hain, jism un ke gird ghoomta hai.
void drawDying(
  Canvas canvas, {
  required Look look,
  required Offset foot,
  required double dir,
  required double fallDir,
  required double t,
  required double time,
  double wind = 0,
  double? spear, // jism mein gare neze ka zawiya (duniya ke hisaab se)
  double raise = 0, // let'ne ke baad kitna oopar (kaanton pe)
}) {
  const jolt = 0.2, impact = 0.7;
  // Gira kitna: jhatke ke baad tezi pakarta hua (t^2), aakhir mein 90° — zameen pe let gaya
  final f = ((t - jolt) / (impact - jolt)).clamp(0.0, 1.0);
  var angle = fallDir * pi / 2 * 0.94 * f * f;
  if (t > impact) {
    final k = t - impact;
    angle -=
        fallDir *
        0.09 *
        sin(k * 16) *
        exp(-k * 7); // zameen se takra kar uchhalna
  }

  // Tarapna: zameen pe jhatke, waqt ke saath kamzor (2 second mein band)
  final writhe = t > impact ? exp(-(t - impact) * 2.2) : 0.0;
  double jerk(double freq, double seed) => sin(time * freq + seed) * writhe;

  final FigurePose pose;
  if (spear != null && t < impact) {
    // Neza laga: dono haath seene pe, ghutne jawab dete hain
    final k = (t / jolt).clamp(0.0, 1.0);
    pose = FigurePose(
      (0.35 * k, -1.0 * k),
      (-0.2 * k, -0.8 * k),
      (0.9, 2.1),
      (0.6, 2.3),
      lean: 0.2 * k,
    );
  } else if (t < jolt) {
    // Jhatka: jism akarta hai, baazu oopar uchhalte hain, ghutne jawab dete hain
    final k = t / jolt;
    pose = FigurePose(
      (0.25 * k, -0.7 * k),
      (-0.15 * k, -0.5 * k),
      (-2.4 * k, 0.4),
      (2.2 * k, 0.3),
      lean: -0.15 * k,
    );
  } else if (t < impact) {
    // Girte hue: haath sahara dhoondhte hain, taangen dheeli
    final w = sin(time * 22) * 0.3;
    pose = FigurePose(
      (0.5, -1.0 + w * 0.5),
      (-0.25, -0.6),
      (-2.0 + w, 0.5),
      (1.6 - w, 0.6),
      lean: -0.1,
    );
  } else {
    // Zameen pe: haath paon phaile, tarapte hue
    pose = FigurePose(
      (0.35 + jerk(27, 0) * 0.45, -0.7 + jerk(31, 1) * 0.6),
      (-0.2 + jerk(23, 2) * 0.35, -0.4 + jerk(29, 3) * 0.5),
      (-1.6 + jerk(25, 4) * 0.5, 0.5 + jerk(33, 5) * 0.4),
      (0.45 + jerk(21, 6) * 0.35, 0.5),
      lean: jerk(19, 7) * 0.06,
    );
  }

  canvas.save();
  // Let'te hue jism ki motaai — thora oopar uthao taake aadha zameen mein na dhanse
  canvas.translate(foot.dx, foot.dy - 4 * f - raise * f);
  canvas.rotate(angle);
  drawFigure(
    canvas,
    look: look,
    foot: Offset.zero,
    dir: dir,
    phase: 0,
    moving: false,
    inAir: false,
    time: time,
    wind: wind,
    pose: pose,
    eyesClosed: t > impact + 0.15,
  );
  if (spear != null) {
    // Seene mein gara neza — jism ke saath ghoomta hai
    final a = spear - angle;
    final d = Offset(cos(a), sin(a));
    const at = Offset(0, -28);
    canvas.drawLine(at - d * 30, at + d * 9, _stroke(1.7));
    final n = Offset(-d.dy, d.dx);
    final tip = at + d * 9;
    canvas.drawPath(
      Path()..addPolygon([
        tip + d * 5,
        tip - d * 2 + n * 2.4,
        tip - d * 2 - n * 2.4,
      ], true),
      _fill,
    );
  }
  canvas.restore();
}

/// Bhaari takkar ke baad hawa mein: gholay khata, haath paon phaile, kamar ke gird ghoomta
void drawTumble(
  Canvas canvas, {
  required Look look,
  required Offset foot,
  required double dir,
  required double angle,
  required double time,
}) {
  const center = Offset(0, -22);
  final w = sin(time * 15);
  canvas.save();
  canvas.translate(foot.dx + center.dx, foot.dy + center.dy);
  canvas.rotate(angle);
  canvas.translate(-center.dx, -center.dy);
  drawFigure(
    canvas,
    look: look,
    foot: Offset.zero,
    dir: dir,
    phase: 0,
    moving: false,
    inAir: true,
    time: time,
    pose: FigurePose(
      (0.7 + w * 0.3, -0.5),
      (-0.6 - w * 0.3, -0.3),
      (2.1 + w * 0.3, 0.4),
      (-1.8 - w * 0.3, 0.3),
    ),
  );
  canvas.restore();
}

/// Aag mein jalna: kapron mein aag, ghabra kar haath hilata ladkhadata hai, phir girta hai aur
/// zameen pe jalta hua tarapta hai — aag dheere dheere bujhti hai, dhuaan uthta hai
void drawBurning(
  Canvas canvas, {
  required Look look,
  required Offset foot,
  required double dir,
  required double fallDir,
  required double t,
  required double time,
  double wind = 0,
  required void Function(Canvas, Rect, double, double) fire,
}) {
  const panic = 1.2;
  if (t < panic) {
    final x = foot + Offset(sin(t * 7) * 5, 0);
    drawFigure(
      canvas,
      look: look,
      foot: x,
      dir: dir,
      phase: t * 16,
      moving: true,
      inAir: false,
      time: time,
      wind: wind,
      pose: FigurePose(
        (sin(t * 16) * 0.6, -max(0.0, cos(t * 16)) * 1.1),
        (-sin(t * 16) * 0.6, -max(0.0, -cos(t * 16)) * 1.1),
        (2.7 + sin(t * 13) * 0.5, 0.4 + sin(t * 17) * 0.3),
        (2.4 + cos(t * 11) * 0.5, 0.5),
        lean: -0.08,
      ),
    );
    // Jism pe aag — kamar se sar tak
    fire(canvas, Rect.fromLTWH(x.dx - 9, x.dy - 30, 18, 12), time, 0.6);
    fire(canvas, Rect.fromLTWH(x.dx - 6, x.dy - 6, 12, 6), time + 0.5, 0.35);
    return;
  }
  final k = t - panic;
  drawDying(
    canvas,
    look: look,
    foot: foot,
    dir: dir,
    fallDir: fallDir,
    t: k,
    time: time,
    wind: wind,
  );
  // Let'e hue jism pe aag, waqt ke saath bujhti hui
  final fade = (1 - (k - 1.2) / 1.4).clamp(0.0, 1.0);
  if (fade > 0) {
    final lying = (k / 0.7).clamp(0.0, 1.0);
    for (var j = 1; j <= 3; j++) {
      final along = Offset(fallDir * j * 13 * lying, -j * 13 * (1 - lying) - 4);
      fire(
        canvas,
        Rect.fromLTWH(foot.dx + along.dx - 7, foot.dy + along.dy - 4, 14, 6),
        time + j,
        0.45 * fade,
      );
    }
  }
  // Dhuaan
  for (var j = 0; j < 4; j++) {
    final rise = (time * 22 + j * 30) % 110;
    canvas.drawCircle(
      foot +
          Offset(
            fallDir * 20 + sin(time + j) * 6 + wind * rise * 0.4,
            -10 - rise,
          ),
      2.5 + rise * 0.06,
      Paint()
        ..color = const Color(0xFF3A3C3D)
            .withValues(alpha: 0.22 * (1 - rise / 110) * min(1, k)),
    );
  }
}

/// Doobna/gaddhay mein girna: haath paon chalaata hua neeche jata hai
void drawFalling(
  Canvas canvas, {
  required Look look,
  required Offset foot,
  required double dir,
  required double time,
}) {
  final w = sin(time * 14);
  drawFigure(
    canvas,
    look: look,
    foot: foot,
    dir: dir,
    phase: 0,
    moving: false,
    inAir: true,
    time: time,
    pose: FigurePose(
      (0.6 + w * 0.4, -1.1),
      (-0.4 - w * 0.4, -0.7),
      (-2.6 + w * 0.6, 0.3),
      (2.4 - w * 0.6, 0.2),
      lean: -0.2,
    ),
  );
}

Paint _stroke(double w) => Paint()
  ..color = _ink
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

/// Lambe khule baal: sar ke peeche se latakti latein, daurte waqt peeche ki taraf lehrati
void _longHair(
  Canvas canvas,
  Offset head,
  double dir,
  bool moving,
  double time,
  double wind,
) {
  // Sar pe baalon ki topi
  canvas.drawPath(
    Path()..addArc(
      Rect.fromCircle(center: head + const Offset(0, -0.5), radius: 7),
      pi * 0.9,
      pi * 1.3,
    ),
    _fill,
  );
  for (var k = 0; k < 5; k++) {
    final root = head + Offset(-dir * (3 + k * 0.6), -4 + k * 1.6);
    final len = 13.0 + k * 1.5;
    // Daurte waqt latein peeche ki taraf udti hain, khare hue neeche latakti hain
    final stream = moving ? 0.85 : 0.25 + wind.abs() * 0.3;
    final wave = sin(time * (moving ? 13 : 3) + k * 1.3) * (moving ? 2.2 : 0.8);
    final end =
        root +
        Offset(-dir * len * stream + wind * 3, len * (1 - stream) + 3 + wave);
    final ctrl = root + Offset(-dir * len * 0.45, len * 0.2 + wave * 0.5);
    canvas.drawPath(
      Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 - k * 0.25
        ..strokeCap = StrokeCap.round,
    );
  }
}

Path _feather(Offset base, double a, double len) {
  final d = Offset(sin(a), -cos(a));
  final n = Offset(-d.dy, d.dx);
  final tip = base + d * len;
  final mid = base + d * len * 0.6;
  // Pankh: neeche patli dandi, oopar chaura, nok gol si
  return Path()..addPolygon([
    base + n * 0.6,
    mid + n * 2.6,
    tip + n * 0.8,
    tip - n * 0.8,
    mid - n * 2.6,
    base - n * 0.6,
  ], true);
}

/// Hero ki aankhen badi aur chamakti; shikaariyon ki patli, ghusse wali
void _eyes(
  Canvas canvas,
  Offset head,
  double dir,
  double time, {
  required bool angry,
}) {
  final blink = !angry && time % 3.7 > 3.57;
  final eye = Paint()..color = angry ? const Color(0xFFD9D9D9) : Colors.white;
  final glow = Paint()
    ..color = Colors.white.withValues(alpha: angry ? 0.2 : 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  for (final (dx, w) in [(2.4, 2.2), (4.9, 1.9)]) {
    final c = head + Offset(dir * dx, angry ? -1 : -0.5);
    final r = Rect.fromCenter(
      center: c,
      width: w + (angry ? 0.6 : 0),
      height: blink ? 0.5 : (angry ? 1.1 : 3.0),
    );
    canvas.drawOval(r.inflate(1), glow);
    canvas.drawOval(r, eye);
  }
}

void _leg(Canvas canvas, Offset hip, (double, double) a, double dir) {
  final foot = _limb(canvas, hip, a, 10.5, 10.8, 3.6, dir);
  canvas.drawLine(foot, foot + Offset(dir * 3.2, 0), _stroke(3.0));
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
  canvas.drawPath(
    Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(joint.dx, joint.dy)
      ..lineTo(end.dx, end.dy),
    Paint()
      ..color = _ink
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke,
  );
  return end;
}
