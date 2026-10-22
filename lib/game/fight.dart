// Larai ki choreography: hero aur shikaariyon ke pose waqt ke saath (keyframes), beech mein smooth.
// Hero baayen munh kiye (shikaari baayen hain), shikaari daayen munh kiye.
import 'dart:ui' show lerpDouble;

import 'figures.dart';

typedef _Key = (double t, FigurePose pose, double dx);

(double, double) _lerp2((double, double) a, (double, double) b, double k) =>
    (lerpDouble(a.$1, b.$1, k)!, lerpDouble(a.$2, b.$2, k)!);

/// Keyframes ke beech [t] pe pose aur aagay/peeche khiskaav (dx)
(FigurePose, double) _at(List<_Key> keys, double t) {
  if (t <= keys.first.$1) return (keys.first.$2, keys.first.$3);
  for (var i = 1; i < keys.length; i++) {
    final (t1, p1, d1) = keys[i];
    if (t <= t1) {
      final (t0, p0, d0) = keys[i - 1];
      var k = (t - t0) / (t1 - t0);
      k = k * k * (3 - 2 * k); // shuru aur aakhir mein naram
      return (
        FigurePose(
          _lerp2(p0.legA, p1.legA, k),
          _lerp2(p0.legB, p1.legB, k),
          _lerp2(p0.armA, p1.armA, k),
          _lerp2(p0.armB, p1.armB, k),
          lean: lerpDouble(p0.lean, p1.lean, k)!,
        ),
        lerpDouble(d0, d1, k)!,
      );
    }
  }
  return (keys.last.$2, keys.last.$3);
}

// Pose: (ran, ghutna), (ran, ghutna), (baazu, kohni), (baazu, kohni)
const _guard = FigurePose(
  (0.15, -0.25),
  (-0.2, -0.15),
  (1.9, 0.9),
  (1.65, 1.0),
  lean: 0.05,
);
// Neza nok se ghonpa jata hai, danday ki tarah ghumaya nahi jata:
// peeche kheencho (dono haath kamar ke paas, neza leta hua, nok saamne) → qadam barha kar seedha ghonpo
const _cock = FigurePose(
  (0.25, -0.35),
  (-0.35, -0.1),
  (0.15, 1.42),
  (-0.15, 1.6),
  lean: -0.06,
);
const _thrust = FigurePose(
  (0.6, -0.2),
  (-0.55, 0),
  (1.52, 0.04),
  (1.25, 0.3),
  lean: 0.3,
);

/// Hero: palat kar dhakka, waar rokna, mukka — phir waar khaa kar ladkhadana, ghutne tekna
final _hero = <_Key>[
  (0.0, const FigurePose((0.1, 0), (-0.1, 0), (0.3, 0.3), (-0.1, 0.2)), 0),
  (0.35, _guard, 0),
  (
    0.6,
    const FigurePose(
      (0.3, -0.1),
      (-0.35, 0),
      (1.45, 0.05),
      (1.35, 0.1),
      lean: 0.18,
    ),
    -4,
  ), // dhakka
  (0.9, _guard, 0),
  (
    1.25,
    const FigurePose(
      (0.2, -0.45),
      (-0.2, -0.3),
      (2.8, 0.2),
      (2.6, 0.3),
      lean: -0.05,
    ),
    0,
  ), // waar roka
  (
    1.6,
    const FigurePose(
      (0.35, -0.15),
      (-0.4, 0),
      (1.55, 0.0),
      (0.6, 1.4),
      lean: 0.2,
    ),
    -5,
  ), // mukka
  (
    2.0,
    const FigurePose(
      (0.3, -0.9),
      (-0.1, -0.6),
      (-1.2, 0.4),
      (-0.9, 0.3),
      lean: -0.25,
    ),
    6,
  ), // waar laga
  (
    2.45,
    const FigurePose(
      (0.25, -0.6),
      (-0.2, -0.4),
      (1.8, 1.0),
      (1.6, 1.1),
      lean: 0.05,
    ),
    3,
  ), // sambhalna
  (
    2.8,
    const FigurePose(
      (0.4, -1.1),
      (-0.1, -0.8),
      (-1.5, 0.3),
      (-1.0, 0.4),
      lean: -0.3,
    ),
    8,
  ), // phir laga
  (
    3.1,
    const FigurePose(
      (0.6, -1.6),
      (0.2, -1.4),
      (-0.6, 0.8),
      (-0.4, 0.7),
      lean: -0.1,
    ),
    8,
  ), // ghutne
  (
    3.4,
    const FigurePose(
      (0.7, -1.8),
      (0.3, -1.6),
      (-0.4, 0.9),
      (-0.3, 0.8),
      lean: -0.15,
    ),
    8,
  ),
];

/// Aagay wala shikaari (neza): jhapat'ta hai, dhakka khaata hai, mukka khaata hai, phir waar pe waar
final _lead = <_Key>[
  (
    0.0,
    const FigurePose((0.4, -0.2), (-0.3, 0), (1.4, 0.1), (0.5, 0.6), lean: 0.2),
    0,
  ),
  (
    0.45,
    const FigurePose(
      (0.4, -0.2),
      (-0.3, 0),
      (1.5, 0.1),
      (0.6, 0.6),
      lean: 0.22,
    ),
    2,
  ),
  (
    0.7,
    const FigurePose(
      (0.2, -0.6),
      (-0.3, -0.3),
      (2.2, 0.4),
      (-1.5, 0.3),
      lean: -0.25,
    ),
    -12,
  ), // dhakka laga
  (
    1.0,
    const FigurePose((0.2, -0.3), (-0.3, -0.1), (1.0, 1.0), (0.3, 0.8)),
    -10,
  ),
  (
    1.65,
    const FigurePose(
      (0.1, -0.7),
      (-0.2, -0.4),
      (2.0, 0.5),
      (-1.6, 0.4),
      lean: -0.3,
    ),
    -16,
  ), // mukka laga
  (1.82, _cock, -12),
  (2.0, _thrust, -2),
  (2.5, _cock, -9),
  (2.8, _thrust, 0),
  (3.15, _cock, -7),
  (3.4, _thrust, 2),
];

/// Doosra shikaari (dhaal): qareeb aata hai, oopar se waar karta hai (hero rokta hai), phir saath deta hai
final _second = <_Key>[
  (0.0, const FigurePose((0.1, 0), (-0.1, 0), (0.3, 0.3), (-0.1, 0.2)), -70),
  (0.8, const FigurePose((0.3, -0.2), (-0.3, 0), (0.8, 0.6), (0.3, 0.5)), -60),
  (1.08, _cock, -60),
  (1.25, _thrust, -50),
  (1.8, const FigurePose((0.2, -0.2), (-0.2, 0), (1.0, 0.7), (0.4, 0.5)), -58),
  (2.6, _cock, -60),
  (2.8, _thrust, -50),
  (3.4, const FigurePose((0.2, -0.2), (-0.2, 0), (1.0, 0.7), (0.4, 0.5)), -54),
];

(FigurePose, double) heroFight(double t) => _at(_hero, t);
(FigurePose, double) leadFight(double t) => _at(_lead, t);
(FigurePose, double) secondFight(double t) => _at(_second, t);

/// Chhootne pe hero ka dhakka (pehle 0.35 second)
const escapeShove = FigurePose(
  (0.35, -0.1),
  (-0.4, 0),
  (1.45, 0.0),
  (1.35, 0.05),
  lean: 0.22,
);
