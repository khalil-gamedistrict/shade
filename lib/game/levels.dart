// Naye chapters ke levels (1 aur 4 asal level se kaate gaye hain — world.dart ka Level.first).
// Jump ~117 oonchi, ~136 lambi: gaddhay ≤ 100, seedhiyan ≤ 60, saamne ki hawa mein gaddhay chhote.
import 'dart:ui' show Offset, Rect;

import 'world.dart';

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
  rocks: [Rock(1380, 1270), Rock(2750, 2600)],
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
  rocks: [Rock(2700, 2580)],
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
  rocks: [Rock(1650, 1530)],
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
  rocks: [Rock(1850, 1760)],
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
