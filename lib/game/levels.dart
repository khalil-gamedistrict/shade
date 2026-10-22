// Chapters ke levels (4 asal level se kaata gaya hai — world.dart ka Level.first).
// Jump ~117 oonchi, ~136 lambi: gaddhay ≤ 100, seedhiyan ≤ 60, saamne ki hawa mein gaddhay chhote.
import 'dart:ui' show Offset, Rect;

import 'world.dart';

/// 1 · The Hunt — asli jungle ki zameen: ubar-khaabar farsh, teela, keechar wala naala (paani mein chaal
/// dheemi), chattan jis pe koodna parta hai aur oopar jhoolta lakkar, khai, kaanton wala gadha, gehra talaab
/// (koodo warna doobo), charhai, phir aakhri zameen jahan chhupne ka gaddha hai.
Level hunt() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(120, 400),
    Offset(220, 400),
    Offset(300, 404),
    Offset(380, 401),
    Offset(470, 386),
    Offset(560, 352),
    Offset(640, 332), // teele ki choti
    Offset(700, 336),
    Offset(780, 374),
    Offset(830, 408), // naala
    Offset(900, 416),
    Offset(960, 410),
    Offset(1010, 392),
    Offset(1060, 368),
    Offset(1100, 354),
    Offset(1113, 350),
    Offset(1121, 319), // chattan: seedhi charhai — koodna parta hai
    Offset(1150, 314),
    Offset(1200, 318),
    Offset(1240, 321),
    Offset(1262, 330), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(1350, 372), // khai ke paar, neeche
    Offset(1420, 380),
    Offset(1520, 392),
    Offset(1600, 396),
    Offset(1690, 390),
    Offset(1760, 398),
    Offset(1810, 420), // kaanton wala gadha
    Offset(1860, 422),
    Offset(1915, 400),
    Offset(1975, 396),
    Offset(2000, 400), // gehra talaab
    Offset(2022, 440),
    Offset(2045, 478),
    Offset(2075, 478),
    Offset(2098, 440),
    Offset(2118, 400),
    Offset(2160, 392),
    Offset(2230, 374),
    Offset(2290, 362),
    Offset(2342, 364),
  ]);
  double y(double x) => b.topAt(x) ?? a.topAt(x)!;
  return Level(
    terrain: const [a, b],
    pools: const [Pool(808, 985, 402), Pool(2004, 2114, 406, deep: true)],
    shields: [
      Offset(740, y(740)),
    ], // teele se utarte hue raaste mein pari dhaal
    solids: const [
      Rect.fromLTWH(2420, 400, 340, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [Rect.fromLTWH(1812, y(1836) - 14, 48, 16)],
    traps: [Rect.fromLTWH(320, y(337) - 10, 34, 10)],
    saws: const [Saw(2490, 320, speed: 1.5)],
    pendulums: const [Pendulum(Offset(1190, 122), 150, speed: 1.4)],
    branches: const [Branch(1600, 1470)],
    checkpoints: [
      const Offset(100, 400),
      Offset(1400, y(1400)),
      Offset(2200, y(2200)),
    ],
    goalX: 2580,
    chase: const Chase(startX: 500),
    wind: const Profile([(0, 0.2), (1500, 0.45), (2400, 0.6)]),
    rain: const Profile([(0, 0), (1300, 0.15), (2100, 0.55), (2700, 0.8)]),
  );
}

/// 2 · Ashes — jalta hua gaon: aag ke sholay, girte jalte shehteer, peeche jalti jhonpriyan
Level ashes() => const Level(
  mood: Mood.fire,
  solids: [
    Rect.fromLTWH(-600, 400, 1300, 200),
    // gaddha 700–790
    Rect.fromLTWH(790, 400, 710, 200),
    Rect.fromLTWH(1150, 340, 110, 60), // toota chabootra
    // gaddha 1500–1600
    Rect.fromLTWH(1600, 400, 700, 200),
    Rect.fromLTWH(1900, 320, 40, 80), // jali hui deewar
    // gaddha 2300–2390
    Rect.fromLTWH(2390, 400, 820, 200),
  ],
  spikes: [],
  saws: [],
  fires: [
    Rect.fromLTWH(420, 384, 60, 16),
    Rect.fromLTWH(1000, 384, 70, 16),
    Rect.fromLTWH(1700, 384, 60, 16),
    Rect.fromLTWH(2120, 384, 80, 16),
    Rect.fromLTWH(2620, 384, 60, 16),
  ],
  traps: [Rect.fromLTWH(2010, 390, 34, 10)],
  branches: [Branch(1380, 1270), Branch(2750, 2600)],
  huts: [260, 640, 1080, 1420, 1820, 2230, 2560, 2900],
  checkpoints: [
    Offset(100, 400),
    Offset(850, 400),
    Offset(1650, 400),
    Offset(2440, 400),
  ],
  goalX: 3000,
  chase: Chase(startX: 250),
  wind: Profile([(0, 0.3), (3100, 0.4)]),
);

/// 3 · The River — darya: pattharon pe kood, tairti kashtiyan, paani mein gire to doob gaye
Level river() => const Level(
  mood: Mood.river,
  waterY: 432,
  solids: [
    Rect.fromLTWH(-600, 400, 1200, 200),
    // paani 600–690
    Rect.fromLTWH(690, 396, 100, 204), // patthar
    // paani 790–880
    Rect.fromLTWH(880, 400, 420, 200),
    // bara darya 1300–1860: do tairti kashtiyan aur beech mein patthar
    Rect.fromLTWH(1530, 400, 70, 200),
    Rect.fromLTWH(1860, 400, 540, 200),
    // paani 2400–2490
    Rect.fromLTWH(2490, 400, 720, 200),
  ],
  movers: [
    Mover(
      Rect.fromLTWH(1350, 412, 90, 14),
      dx: 40,
      dy: 3,
      speed: 0.8,
      boat: true,
    ),
    Mover(
      Rect.fromLTWH(1660, 412, 90, 14),
      dx: 45,
      dy: 3,
      speed: 0.9,
      phase: 1.5,
      boat: true,
    ),
  ],
  spikes: [Rect.fromLTWH(1050, 384, 48, 16), Rect.fromLTWH(2050, 384, 48, 16)],
  saws: [],
  pendulums: [Pendulum(Offset(2250, 170), 175, speed: 1.5)],
  branches: [Branch(2700, 2580)],
  traps: [Rect.fromLTWH(2850, 390, 34, 10)],
  checkpoints: [
    Offset(100, 400),
    Offset(920, 400),
    Offset(1900, 400),
    Offset(2530, 400),
  ],
  goalX: 3000,
  chase: Chase(startX: 200),
  wind: Profile([(0, 0.25), (3100, 0.3)]),
  rain: Profile([(0, 0.2), (3100, 0.35)]),
);

/// 5 · The Cliffs — oonchi chattanen, rassi ka pul, gehri khaiyan, saamne se tez hawa
Level cliffs() => const Level(
  mood: Mood.cliffs,
  solids: [
    Rect.fromLTWH(-600, 400, 1100, 200),
    Rect.fromLTWH(500, 340, 200, 260), // chattan ki seedhiyan
    Rect.fromLTWH(700, 280, 200, 320),
    // khai 900–990
    Rect.fromLTWH(990, 280, 260, 320),
    Rect.fromLTWH(1250, 280, 250, 6), // rassi ka pul
    Rect.fromLTWH(1500, 280, 300, 320),
    Rect.fromLTWH(1800, 360, 300, 240), // neeche utarna
    // khai 2100–2190
    Rect.fromLTWH(2190, 360, 310, 240),
    // bari khai 2500–3000: hilte takhte aur ek patli chattan
    Rect.fromLTWH(2700, 330, 80, 18),
    Rect.fromLTWH(3000, 360, 720, 240),
  ],
  movers: [
    Mover(Rect.fromLTWH(2560, 345, 80, 16), dy: 40, speed: 1.1),
    Mover(Rect.fromLTWH(2840, 345, 80, 16), dx: 45, speed: 1.0, phase: 1),
  ],
  spikes: [Rect.fromLTWH(3150, 344, 48, 16)],
  traps: [Rect.fromLTWH(3300, 350, 34, 10)],
  saws: [Saw(2350, 290, speed: 1.6)],
  pendulums: [Pendulum(Offset(1380, 100), 165, speed: 1.5)],
  branches: [Branch(1650, 1530)],
  checkpoints: [
    Offset(100, 400),
    Offset(1030, 280),
    Offset(1840, 360),
    Offset(3040, 360),
  ],
  goalX: 3500,
  chase: Chase(startX: 200),
  wind: Profile([
    (0, 0.3),
    (1000, -0.5),
    (1800, -0.7),
    (2200, 0.2),
    (2600, 0.9),
    (3600, 0.3),
  ]),
  rain: Profile([(0, 0.1), (3600, 0.3)]),
);

/// 6 · Homecoming — moosla dhaar baarish, aakhri daud: shikaariyon se bach kar apne logon tak
Level homecoming() => const Level(
  mood: Mood.home,
  solids: [
    Rect.fromLTWH(-600, 400, 1250, 200),
    // gaddha 650–750
    Rect.fromLTWH(750, 400, 600, 200),
    // gaddha 1350–1440
    Rect.fromLTWH(1440, 400, 560, 200),
    Rect.fromLTWH(1700, 330, 40, 70), // deewar
    // bara gaddha 2000–2500
    Rect.fromLTWH(2230, 360, 80, 18),
    Rect.fromLTWH(2500, 400, 900, 200),
  ],
  movers: [
    Mover(Rect.fromLTWH(2075, 370, 90, 18), dx: 50, speed: 0.9),
    Mover(Rect.fromLTWH(2370, 365, 80, 18), dy: 40, speed: 1.2, phase: 1),
  ],
  spikes: [Rect.fromLTWH(950, 384, 48, 16)],
  traps: [Rect.fromLTWH(2900, 390, 34, 10)],
  saws: [Saw(2700, 320, speed: 1.8)],
  pendulums: [Pendulum(Offset(1150, 170), 175, speed: 1.6)],
  branches: [Branch(1850, 1760)],
  checkpoints: [
    Offset(100, 400),
    Offset(790, 400),
    Offset(1480, 400),
    Offset(2540, 400),
  ],
  goalX: 3150,
  chase: Chase(startX: 200),
  wind: Profile([(0, 0.4), (2000, 0.8), (3400, 0.5)]),
  rain: Profile([(0, 0.6), (1500, 0.9), (3400, 1.0)]),
);
