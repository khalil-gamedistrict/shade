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
    // Pehle checkpoint (1400) ke baad raaste mein pari dhaal
    shields: [Offset(1450, y(1450))],
    solids: const [
      Rect.fromLTWH(2420, 400, 340, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [Rect.fromLTWH(1812, y(1836) - 14, 48, 16)],
    traps: [Rect.fromLTWH(320, y(337) - 10, 34, 10)],
    saws: const [],
    pendulums: const [Pendulum(Offset(1190, 122), 150, speed: 1.4)],
    branches: const [Branch(1600, 1470)],
    checkpoints: [
      const Offset(100, 400),
      Offset(1400, y(1400)),
      Offset(2200, y(2200)),
    ],
    goalX: 2580,
    // Pehla chapter: sab se aasaan — shikaari dheeme, door, kam neze
    chase: const Chase(
      startX: 500,
      speed: 112,
      maxBehind: 570,
      throwEvery: 4.6,
      aimEvery: 5,
    ),
    wind: const Profile([(0, 0.2), (1500, 0.45), (2400, 0.6)]),
    rain: const Profile([(0, 0), (1300, 0.15), (2100, 0.55), (2700, 0.8)]),
  );
}

/// 2 · Ashes — jalta hua gaon: aag ke sholay, girte jalte shehteer, peeche jalti jhonpriyan. Zameen ubar-khaabar,
/// barsaati paani ka gadha.
Level ashes() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(120, 400),
    Offset(220, 400),
    Offset(300, 392),
    Offset(380, 400),
    Offset(500, 400), // aag
    Offset(560, 386),
    Offset(620, 378),
    Offset(702, 390),
  ]);
  const b = Terrain([
    Offset(790, 400),
    Offset(850, 401),
    Offset(920, 396),
    Offset(980, 400),
    Offset(1090, 400), // aag
    Offset(1130, 402),
    Offset(1290, 402), // toota chabootra
    Offset(1340, 396),
    Offset(1420, 400),
    Offset(1502, 394),
  ]);
  const c = Terrain([
    Offset(1600, 400),
    Offset(1660, 400),
    Offset(1780, 400), // aag
    Offset(1805, 410),
    Offset(1832, 418), // barsaati paani
    Offset(1858, 410),
    Offset(1882, 400),
    Offset(2050, 400), // jali deewar, shikanja
    Offset(2090, 397),
    Offset(2120, 400),
    Offset(2210, 400), // aag
    Offset(2250, 392),
    Offset(2302, 386),
  ]);
  const d = Terrain([
    Offset(2390, 400),
    Offset(2450, 398),
    Offset(2520, 404),
    Offset(2600, 400),
    Offset(2700, 400), // aag
    Offset(2760, 392),
    Offset(2830, 386),
    Offset(2900, 398),
    Offset(2944, 400),
  ]);
  double y(double x) => [a, b, c, d].map((t) => t.topAt(x)).nonNulls.first;
  Rect fire(double x, double w) => Rect.fromLTWH(x, y(x + w / 2) - 16, w, 16);
  return Level(
    mood: Mood.fire,
    terrain: const [a, b, c, d],
    pools: const [Pool(1800, 1864, 405)],
    solids: [
      const Rect.fromLTWH(1150, 340, 110, 62), // toota chabootra
      Rect.fromLTWH(1900, 320, 40, y(1920) - 320 + 2), // jali hui deewar
      const Rect.fromLTWH(
        2940,
        400,
        270,
        200,
      ), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: const [],
    saws: const [],
    fires: [
      fire(420, 60),
      fire(1000, 70),
      fire(1700, 60),
      fire(2120, 80),
      fire(2620, 60),
    ],
    traps: [Rect.fromLTWH(2010, y(2027) - 10, 34, 10)],
    branches: const [Branch(1380, 1270), Branch(2750, 2600)],
    huts: const [260, 640, 1080, 1420, 1820, 2230, 2560, 2900],
    checkpoints: [
      const Offset(100, 400),
      Offset(850, y(850)),
      Offset(1650, y(1650)),
      Offset(2440, y(2440)),
    ],
    goalX: 3000,
    chase: const Chase(
      startX: 250,
      speed: 118,
      maxBehind: 530,
      throwEvery: 4.0,
      aimEvery: 4,
    ),
    wind: const Profile([(0, 0.3), (3100, 0.4)]),
  );
}

/// 3 · The River — darya: pattharon pe kood, tairti kashtiyan, paani mein gire to doob gaye. Kinaare
/// ooncha-neecha, ek dal-dal (ghutnon tak paani).
Level river() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(150, 400),
    Offset(250, 400),
    Offset(330, 392),
    Offset(420, 380),
    Offset(500, 388),
    Offset(560, 398),
    Offset(602, 402),
  ]);
  const b = Terrain([
    Offset(880, 400),
    Offset(950, 398),
    Offset(1010, 400),
    Offset(1110, 400), // kaante
    Offset(1170, 390),
    Offset(1240, 396),
    Offset(1302, 402),
  ]);
  const c = Terrain([
    Offset(1860, 400),
    Offset(1930, 394),
    Offset(1990, 400),
    Offset(2110, 400), // kaante
    Offset(2140, 404),
    Offset(2160, 440),
    Offset(2185, 470), // gehra gadha
    Offset(2210, 440),
    Offset(2232, 404),
    Offset(2320, 400), // jhoolta lakkar
    Offset(2360, 396),
    Offset(2402, 400),
  ]);
  const d = Terrain([
    Offset(2490, 400),
    Offset(2550, 402),
    Offset(2595, 412),
    Offset(2635, 418), // dal-dal
    Offset(2675, 412),
    Offset(2715, 400),
    Offset(2800, 398),
    Offset(2900, 400), // shikanja
    Offset(2944, 400),
  ]);
  double y(double x) => [a, b, c, d].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    mood: Mood.river,
    waterY: 432,
    terrain: const [a, b, c, d],
    pools: const [Pool(2585, 2700, 405), Pool(2148, 2224, 408, deep: true)],
    solids: const [
      Rect.fromLTWH(690, 396, 100, 204), // patthar
      Rect.fromLTWH(1530, 400, 70, 200), // darya ke beech patthar
      Rect.fromLTWH(2940, 400, 270, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    movers: const [
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
    spikes: [
      Rect.fromLTWH(1050, y(1074) - 14, 48, 16),
      Rect.fromLTWH(2050, y(2074) - 14, 48, 16),
    ],
    saws: const [Saw(470, 300, speed: 1.4), Saw(1180, 300, speed: 1.6)],
    pendulums: const [Pendulum(Offset(2290, 170), 175, speed: 1.5)],
    branches: const [Branch(2780, 2660)],
    traps: [
      Rect.fromLTWH(180, y(197) - 10, 34, 10),
      Rect.fromLTWH(2850, y(2867) - 10, 34, 10),
    ],
    checkpoints: [
      const Offset(100, 400),
      Offset(920, y(920)),
      Offset(1900, y(1900)),
      Offset(2530, y(2530)),
    ],
    goalX: 3000,
    chase: const Chase(
      startX: 200,
      speed: 123,
      maxBehind: 500,
      throwEvery: 3.6,
      aimEvery: 3,
    ),
    wind: const Profile([(0, 0.25), (3100, 0.3)]),
    rain: const Profile([(0, 0.2), (3100, 0.35)]),
  );
}

/// 5 · The Cliffs — pathreeli chattanen (charhai pe koodna), rassi ka pul, gehri khaiyan, saamne se tez hawa
Level cliffs() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(150, 400),
    Offset(250, 400),
    Offset(330, 394),
    Offset(410, 384),
    Offset(470, 368),
    Offset(498, 360),
    Offset(508, 342), // pehli chattan — koodo
    Offset(560, 338),
    Offset(640, 334),
    Offset(690, 332),
    Offset(702, 300), // doosri chattan — koodo
    Offset(760, 284),
    Offset(840, 280),
    Offset(902, 284),
  ]);
  const b = Terrain([
    Offset(990, 282),
    Offset(1050, 276),
    Offset(1120, 272),
    Offset(1190, 276),
    Offset(1230, 280),
    Offset(1252, 280), // rassi ka pul
  ]);
  const c = Terrain([
    Offset(1498, 280),
    Offset(1560, 276),
    Offset(1640, 272),
    Offset(1720, 278),
    Offset(1790, 286),
    Offset(1840, 326), // neeche utarna
    Offset(1880, 350),
    Offset(1950, 360),
    Offset(2040, 356),
    Offset(2102, 362),
  ]);
  const d = Terrain([
    Offset(2190, 362),
    Offset(2260, 356),
    Offset(2350, 360),
    Offset(2430, 354),
    Offset(2502, 360),
  ]);
  const e = Terrain([
    Offset(3000, 360),
    Offset(3060, 356),
    Offset(3120, 360),
    Offset(3200, 360), // kaante
    Offset(3260, 360),
    Offset(3350, 360), // shikanja
    Offset(3400, 352),
    Offset(3444, 360),
  ]);
  double y(double x) => [a, b, c, d, e].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    mood: Mood.cliffs,
    terrain: const [a, b, c, d, e],
    solids: const [
      Rect.fromLTWH(1250, 280, 250, 6), // rassi ka pul
      Rect.fromLTWH(2700, 330, 80, 18),
      Rect.fromLTWH(3440, 360, 280, 240), // aakhri zameen (chhupne ka gaddha)
    ],
    movers: const [
      Mover(Rect.fromLTWH(2560, 345, 80, 16), dy: 40, speed: 1.1),
      Mover(Rect.fromLTWH(2840, 345, 80, 16), dx: 45, speed: 1.0, phase: 1),
    ],
    spikes: [
      Rect.fromLTWH(2000, y(2024) - 14, 48, 16),
      Rect.fromLTWH(3150, y(3174) - 14, 48, 16),
    ],
    traps: [
      Rect.fromLTWH(200, y(217) - 10, 34, 10),
      Rect.fromLTWH(2225, y(2242) - 10, 34, 10),
      Rect.fromLTWH(3300, y(3317) - 10, 34, 10),
    ],
    saws: const [
      Saw(1120, 200, speed: 1.7),
      Saw(2350, 290, speed: 1.6),
      Saw(3080, 290, speed: 1.9),
    ],
    pendulums: const [
      Pendulum(Offset(1380, 100), 165, speed: 1.5),
      Pendulum(Offset(1920, 125), 175, speed: 1.7, phase: 1),
    ],
    branches: const [Branch(1650, 1530), Branch(3380, 3250)],
    checkpoints: [
      const Offset(100, 400),
      Offset(1030, y(1030)),
      Offset(1960, y(1960)),
      Offset(3040, y(3040)),
    ],
    goalX: 3500,
    chase: const Chase(
      startX: 200,
      speed: 133,
      maxBehind: 440,
      throwEvery: 2.8,
      aimEvery: 2,
    ),
    wind: const Profile([
      (0, 0.3),
      (1000, -0.5),
      (1800, -0.7),
      (2200, 0.2),
      (2600, 0.9),
      (3600, 0.3),
    ]),
    rain: const Profile([(0, 0.1), (3600, 0.3)]),
  );
}

/// 6 · Homecoming — moosla dhaar baarish, aakhri daud: shikaariyon se bach kar apne logon tak. Teelay, keechar.
Level homecoming() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(150, 400),
    Offset(250, 400),
    Offset(340, 388),
    Offset(430, 372),
    Offset(520, 380),
    Offset(600, 394),
    Offset(652, 400),
  ]);
  const b = Terrain([
    Offset(750, 400),
    Offset(790, 402),
    Offset(830, 412),
    Offset(865, 418), // keechar
    Offset(900, 410),
    Offset(930, 400),
    Offset(1010, 400), // kaante
    Offset(1100, 400),
    Offset(1200, 400), // jhoolta lakkar
    Offset(1260, 392),
    Offset(1352, 398),
  ]);
  const c = Terrain([
    Offset(1440, 400),
    Offset(1500, 396),
    Offset(1580, 384),
    Offset(1640, 392),
    Offset(1690, 400),
    Offset(1900, 400), // deewar, shaakh
    Offset(1960, 394),
    Offset(2002, 400),
  ]);
  const d = Terrain([
    Offset(2500, 400),
    Offset(2560, 398),
    Offset(2640, 402),
    Offset(2760, 400), // aari
    Offset(2810, 394),
    Offset(2850, 400),
    Offset(2950, 400), // shikanja
    Offset(2995, 404),
    Offset(3050, 400),
    Offset(3094, 400),
  ]);
  double y(double x) => [a, b, c, d].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    mood: Mood.home,
    terrain: const [a, b, c, d],
    pools: const [Pool(815, 912, 405)],
    solids: [
      Rect.fromLTWH(1700, 330, 40, y(1720) - 330 + 2), // deewar
      const Rect.fromLTWH(2230, 360, 80, 18),
      const Rect.fromLTWH(
        3090,
        400,
        310,
        200,
      ), // aakhri zameen (chhupne ka gaddha)
    ],
    movers: const [
      Mover(Rect.fromLTWH(2075, 370, 90, 18), dx: 50, speed: 0.9),
      Mover(Rect.fromLTWH(2370, 365, 80, 18), dy: 40, speed: 1.2, phase: 1),
    ],
    spikes: [
      Rect.fromLTWH(950, y(974) - 14, 48, 16),
      Rect.fromLTWH(2790, y(2814) - 14, 40, 16),
    ],
    traps: [
      Rect.fromLTWH(200, y(217) - 10, 34, 10),
      Rect.fromLTWH(1220, y(1237) - 10, 34, 10),
      Rect.fromLTWH(2900, y(2917) - 10, 34, 10),
    ],
    saws: const [
      Saw(860, 330, speed: 1.8), // keechar ke oopar
      Saw(1600, 300, speed: 2.0),
      Saw(2700, 320, speed: 1.8),
    ],
    pendulums: const [
      Pendulum(Offset(1150, 170), 175, speed: 1.6),
      Pendulum(Offset(2600, 170), 175, speed: 1.9, phase: 2),
    ],
    branches: const [Branch(1850, 1760), Branch(3010, 2890)],
    checkpoints: [
      const Offset(100, 400),
      Offset(790, y(790)),
      Offset(1480, y(1480)),
      Offset(2540, y(2540)),
    ],
    goalX: 3150,
    // Aakhri chapter: sab se mushkil
    chase: const Chase(
      startX: 200,
      speed: 138,
      maxBehind: 410,
      throwEvery: 2.4,
      aimEvery: 2,
    ),
    wind: const Profile([(0, 0.4), (2000, 0.8), (3400, 0.5)]),
    rain: const Profile([(0, 0.6), (1500, 0.9), (3400, 1.0)]),
  );
}
