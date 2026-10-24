// Chapters ke levels (4 asal level se kaata gaya hai — world.dart ka Level.first).
// Jump ~117 oonchi, ~136 lambi: gaddhay ≤ 100, seedhiyan ≤ 60, saamne ki hawa mein gaddhay chhote.
import 'dart:math';
import 'dart:ui' show Offset, Rect;

import 'world.dart';

/// Gira hua bara darakht [x]..[x]+[w] pe: tana zameen se 32px oopar (jhuk kar neeche se), oopar itna ooncha
/// jhund ke kood ke paar na ho. [ground] us jagah ki zameen (sab se oonchi jagah se naapa).
Rect fallenTree(double x, double w, double Function(double) ground) {
  var g = double.infinity;
  for (var k = 0.0; k <= w; k += 5) {
    g = min(g, ground(x + k));
  }
  return Rect.fromLTRB(x, g - 175, x + w, g - 32);
}

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
    logs: [fallenTree(185, 85, y)],
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
    // Set 1 (Chapter 1–2): sab se aasaan — shikaari dheeme, door, kam neze
    chase: const Chase(
      startX: 500,
      speed: 114,
      maxBehind: 550,
      throwEvery: 4.3,
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
    logs: [fallenTree(2850, 70, y)],
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
    // Set 1 (Chapter 1–2): Hunt jaisi hi mushkil
    chase: const Chase(
      startX: 250,
      speed: 114,
      maxBehind: 550,
      throwEvery: 4.3,
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
    logs: [fallenTree(1110, 70, y)],
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
    // Set 2 (Chapter 3–4)
    chase: const Chase(
      startX: 200,
      speed: 122,
      maxBehind: 510,
      throwEvery: 3.8,
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
    logs: [fallenTree(1545, 70, y)],
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
    // Set 3 (Chapter 5–6)
    chase: const Chase(
      startX: 200,
      speed: 130,
      maxBehind: 460,
      throwEvery: 3.2,
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

/// 6 · The Thicket — ghani jhaari-jungle: tang ghumaavdaar raasta, shikaariyon ke lagaye
/// shikanjon ki qataar (jaanwaron ke raaste pe), bailon jaisa jhoolta lakkar, baar baar
/// gire darakht jin ke neeche jhukna parta hai. Khushk mausam, halki hawa.
Level theThicket() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(270, 406),
    Offset(330, 400), // gira darakht
    Offset(420, 394),
    Offset(480, 402),
    Offset(540, 410), // pehla shikanja
    Offset(600, 404),
    Offset(660, 396),
    Offset(702, 400),
  ]);
  const b = Terrain([
    Offset(780, 400),
    Offset(830, 406),
    Offset(880, 412), // doosra shikanja
    Offset(930, 404),
    Offset(990, 396),
    Offset(1040, 388),
    Offset(1060, 352), // chattan — koodo
    Offset(1110, 348),
    Offset(1170, 352),
    Offset(1230, 360), // teesra shikanja
    Offset(1290, 372),
    Offset(1340, 384),
    Offset(1392, 398),
    Offset(1460, 404),
  ]);
  const c = Terrain([
    Offset(1520, 400),
    Offset(1580, 394),
    Offset(1640, 400), // gira darakht
    Offset(1740, 406),
    Offset(1800, 398),
    Offset(1850, 400), // khai ka kinara
  ]);
  const d = Terrain([
    Offset(1940, 384), // khai ke paar
    Offset(2000, 390),
    Offset(2060, 400),
    Offset(2120, 408), // kaanton wala gadha
    Offset(2170, 412),
    Offset(2220, 400),
    Offset(2300, 396),
    Offset(2360, 400), // chautha shikanja
    Offset(2420, 404),
    Offset(2480, 400),
    Offset(2560, 398),
    Offset(2620, 400),
  ]);
  double y(double x) => [a, b, c, d].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(345, 80, y), fallenTree(1655, 75, y)],
    mood: Mood.forest,
    terrain: const [a, b, c, d],
    pools: const [],
    solids: const [
      Rect.fromLTWH(2660, 400, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [Rect.fromLTWH(2122, y(2146) - 14, 48, 16)],
    saws: const [],
    traps: [
      Rect.fromLTWH(540, y(554) - 10, 34, 10),
      Rect.fromLTWH(880, y(894) - 10, 34, 10),
      Rect.fromLTWH(1250, y(1264) - 10, 34, 10),
      Rect.fromLTWH(2360, y(2374) - 10, 34, 10),
    ],
    pendulums: const [
      Pendulum(Offset(950, 130), 160, speed: 1.6),
      Pendulum(Offset(2240, 150), 160, speed: 1.7, phase: 1),
    ],
    branches: const [Branch(1300, 1180), Branch(2000, 1880)],
    checkpoints: [
      const Offset(100, 400),
      Offset(950, y(950)),
      Offset(1700, y(1700)),
      Offset(2340, y(2340)),
    ],
    goalX: 2970,
    // Set 3 (Chapter 5–6)
    chase: const Chase(
      startX: 200,
      speed: 130,
      maxBehind: 460,
      throwEvery: 3.2,
      aimEvery: 2,
    ),
    wind: const Profile([(0, 0.2), (3000, 0.25)]),
  );
}

/// 7 · The Swamp — daldal: ghutnon tak keechar jo chaal dheemi kar deta hai, choti-badi
/// khaaren (dal-dal mein doob jao), paani ke neeche chhupe shikanje, girre tanon ka dher.
/// Beech mein do sthir patthar oonchi keechar ke oopar paar karne ke liye. Saamne se
/// mustaqil hawa keechar mein chalna aur mushkil kar deti hai.
Level theSwamp() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(280, 408),
    Offset(340, 416), // keechar shuru
    Offset(400, 410),
    Offset(460, 400),
    Offset(540, 400),
    Offset(610, 406),
    Offset(680, 416), // pehla dal-dal (uthla)
    Offset(740, 420),
    Offset(800, 412),
    Offset(860, 402),
    Offset(920, 400),
    Offset(1000, 400), // kaante
    Offset(1080, 400),
    Offset(1140, 396),
    Offset(1180, 392), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(1260, 384),
    Offset(1320, 392),
    Offset(1380, 400),
    Offset(1420, 420),
    Offset(1443, 440),
    Offset(1465, 478), // gehra dal-dal
    Offset(1495, 478),
    Offset(1518, 440),
    Offset(1538, 400),
    Offset(1600, 400), // gira darakht
    Offset(1700, 400),
    Offset(1760, 408), // doosra shikanja
    Offset(1820, 414),
    Offset(1880, 406),
    Offset(1940, 400),
    Offset(2000, 400),
    Offset(2060, 396),
    Offset(2090, 392), // patthron se pehle
  ]);
  const c = Terrain([
    Offset(2430, 400),
    Offset(2490, 400),
    Offset(2540, 408), // teesra shikanja
    Offset(2590, 414),
    Offset(2630, 440),
    Offset(2650, 470), // doosra gehra dal-dal
    Offset(2670, 440),
    Offset(2690, 412),
    Offset(2730, 404),
    Offset(2780, 400),
    Offset(2860, 400),
    Offset(2940, 400),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1600, 90, y)],
    mood: Mood.river,
    terrain: const [a, b, c],
    pools: const [
      Pool(684, 856, 406),
      Pool(1424, 1534, 406, deep: true),
      Pool(2634, 2694, 408, deep: true),
    ],
    solids: const [
      Rect.fromLTWH(2150, 400, 80, 16), // keechar se ubhra patthar
      Rect.fromLTWH(2290, 392, 80, 18),
      Rect.fromLTWH(2940, 400, 350, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [Rect.fromLTWH(1000, y(1024) - 14, 48, 16)],
    saws: const [],
    traps: [
      Rect.fromLTWH(260, y(274) - 10, 34, 10),
      Rect.fromLTWH(760, y(774) - 10, 34, 10),
      Rect.fromLTWH(1760, y(1774) - 10, 34, 10),
      Rect.fromLTWH(2430, y(2444) - 10, 34, 10),
    ],
    pendulums: const [
      Pendulum(Offset(1320, 130), 155, speed: 1.6),
      Pendulum(Offset(1950, 140), 155, speed: 1.7, phase: 1),
    ],
    branches: const [Branch(1900, 1790), Branch(2800, 2700)],
    checkpoints: [
      const Offset(100, 400),
      Offset(900, y(900)),
      Offset(1700, y(1700)),
      Offset(2500, y(2500)),
    ],
    goalX: 3100,
    // Set 4 (Chapter 7–8)
    chase: const Chase(
      startX: 200,
      speed: 137,
      maxBehind: 420,
      throwEvery: 2.6,
      aimEvery: 2,
    ),
    // Saamne se mustaqil hawa: keechar mein daudna mushkil
    wind: const Profile([(0, 0.6), (3100, 0.65)]),
    rain: const Profile([(0, 0.5), (3100, 0.6)]),
  );
}

/// 8 · The Ravine — tangi raat ki khaai: pathreeli oonchi-neechi zameen, latakte patthar
/// (girte pendulum), rassi ke pul, aur tez ultey-seedhe jhonke jo rasta mushkil kar dete hain.
Level theRavine() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(280, 390),
    Offset(350, 372),
    Offset(400, 352),
    Offset(412, 330), // pehli chattan — koodo
    Offset(470, 324),
    Offset(540, 320),
    Offset(600, 316),
    Offset(612, 280), // doosri chattan — koodo
    Offset(670, 270),
    Offset(740, 266),
  ]);
  const b = Terrain([
    Offset(820, 264),
    Offset(880, 260),
    Offset(940, 264),
    Offset(980, 268),
    Offset(1002, 268), // rassi ka pul
  ]);
  const c = Terrain([
    Offset(1250, 268),
    Offset(1310, 264),
    Offset(1380, 260),
    Offset(1450, 266),
    Offset(1510, 276),
    Offset(1550, 310), // neeche utarna
    Offset(1600, 334),
    Offset(1670, 340),
    Offset(1740, 336),
  ]);
  const d = Terrain([
    Offset(1820, 336),
    Offset(1890, 332),
    Offset(1960, 336),
    Offset(2030, 330),
    Offset(2100, 336),
    Offset(2102, 336), // rassi ka doosra pul
  ]);
  const e = Terrain([
    Offset(2350, 336),
    Offset(2410, 330),
    Offset(2480, 336),
    Offset(2560, 336), // kaante
    Offset(2620, 336),
    Offset(2700, 336), // shikanja
    Offset(2750, 328),
    Offset(2800, 336),
  ]);
  double y(double x) =>
      [a, b, c, d, e].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1380, 70, y)],
    mood: Mood.cliffs,
    terrain: const [a, b, c, d, e],
    solids: const [
      Rect.fromLTWH(1000, 268, 250, 6), // pehla rassi pul
      Rect.fromLTWH(2098, 336, 255, 6), // doosra rassi pul
      Rect.fromLTWH(2800, 336, 520, 240), // aakhri zameen (chhupne ka gaddha)
    ],
    movers: const [
      Mover(Rect.fromLTWH(1980, 320, 80, 16), dy: 42, speed: 1.2),
    ],
    spikes: [
      Rect.fromLTWH(1560, y(1584) - 14, 48, 16),
      Rect.fromLTWH(2560, y(2584) - 14, 48, 16),
    ],
    traps: [
      Rect.fromLTWH(200, y(217) - 10, 34, 10),
      Rect.fromLTWH(1300, y(1314) - 10, 34, 10),
      Rect.fromLTWH(2700, y(2717) - 10, 34, 10),
    ],
    saws: const [
      Saw(500, 170, speed: 1.9),
      Saw(1430, 190, speed: 1.8),
      Saw(2450, 250, speed: 2.0),
    ],
    pendulums: const [
      Pendulum(Offset(900, 90), 160, speed: 1.7),
      Pendulum(Offset(1850, 180), 150, speed: 1.8, phase: 1),
    ],
    branches: const [Branch(1500, 1390)],
    checkpoints: [
      const Offset(100, 400),
      Offset(920, y(920)),
      Offset(1850, y(1850)),
      Offset(2420, y(2420)),
    ],
    goalX: 3150,
    // Set 4 (Chapter 7–8)
    chase: const Chase(
      startX: 200,
      speed: 137,
      maxBehind: 420,
      throwEvery: 2.6,
      aimEvery: 2,
    ),
    wind: const Profile([
      (0, 0.3),
      (800, -0.6),
      (1600, 0.8),
      (2200, -0.7),
      (3200, 0.3),
    ]),
  );
}

/// 9 · The Flood — khushk naala achanak sailaab mein badalta hai: jaise jaise aagay badho,
/// paani aur baarish barhti jaati hai, phir behta malba (tairte takhte jin pe koodna parta
/// hai) raaste mein aa jaata hai, aakhri hissa taqreeban doobi hui zameen.
Level theFlood() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(290, 394),
    Offset(360, 400), // abhi khushk naala
    Offset(440, 400),
    Offset(520, 404),
    Offset(602, 400), // kaante
    Offset(680, 400),
    Offset(760, 400),
  ]);
  const b = Terrain([
    Offset(840, 400),
    Offset(900, 406),
    Offset(960, 414), // halka paani shuru
    Offset(1020, 406),
    Offset(1080, 400),
    Offset(1160, 400), // doosre kaante
    Offset(1220, 400),
    Offset(1280, 396),
    Offset(1320, 392),
  ]);
  const c = Terrain([
    Offset(1400, 392),
    Offset(1460, 400),
    Offset(1520, 404), // paani barh raha — gehra
    Offset(1540, 440),
    Offset(1565, 470),
    Offset(1590, 440),
    Offset(1612, 404),
    Offset(1700, 400), // gira darakht
    Offset(1790, 400),
    Offset(1850, 396),
    Offset(1880, 392), // behte malbe se pehle
  ]);
  const d = Terrain([
    Offset(2220, 400), // shikanja
    Offset(2280, 400),
    Offset(2340, 404), // sailaab ka hissa — gehra
    Offset(2360, 440),
    Offset(2385, 470),
    Offset(2410, 440),
    Offset(2432, 404),
    Offset(2520, 400), // behta malba (aari jaisa)
    Offset(2580, 400),
    Offset(2640, 400),
  ]);
  double y(double x) => [a, b, c, d].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1700, 80, y)],
    mood: Mood.river,
    terrain: const [a, b, c, d],
    pools: const [
      Pool(964, 1036, 410),
      Pool(1528, 1604, 406, deep: true),
      Pool(2348, 2424, 406, deep: true),
    ],
    solids: const [
      Rect.fromLTWH(2640, 400, 500, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    movers: const [
      // behta malba — sailaab mein tairte takhte, in pe koodna parta hai
      Mover(
        Rect.fromLTWH(1940, 412, 80, 14),
        dx: 40,
        dy: 3,
        speed: 1.0,
        boat: true,
      ),
      Mover(
        Rect.fromLTWH(2080, 412, 80, 14),
        dx: 45,
        dy: 3,
        speed: 1.1,
        phase: 1.2,
        boat: true,
      ),
    ],
    spikes: [
      Rect.fromLTWH(602, y(626) - 14, 48, 16),
      Rect.fromLTWH(2580, y(2594) - 14, 48, 16),
    ],
    saws: const [Saw(1000, 170, speed: 1.8), Saw(2520, 300, speed: 2.0)],
    traps: [
      Rect.fromLTWH(350, y(364) - 10, 34, 10),
      Rect.fromLTWH(1160, y(1174) - 10, 34, 10),
    ],
    pendulums: const [
      Pendulum(Offset(900, 130), 155, speed: 1.6),
      Pendulum(Offset(2000, 140), 155, speed: 1.7, phase: 1),
    ],
    branches: const [Branch(1850, 1740), Branch(2500, 2420)],
    checkpoints: [
      const Offset(100, 400),
      Offset(900, y(900)),
      Offset(1780, y(1780)),
      Offset(2320, y(2320)),
    ],
    goalX: 2960,
    // Set 5 (Chapter 9–10)
    chase: const Chase(
      startX: 200,
      speed: 140,
      maxBehind: 405,
      throwEvery: 2.4,
      aimEvery: 2,
    ),
    // Baarish aur hawa aagay badhte hue tezi se barhti hai — sailaab ka ehsaas
    wind: const Profile([(0, 0.2), (2960, 0.7)]),
    rain: const Profile([(0, 0.1), (900, 0.3), (1800, 0.7), (2960, 1.0)]),
  );
}

/// 10 · The Hollow — ghana andhera jungle farsh: makri ke jaalon jaisi latakti bailen,
/// tang raasta, zeher-bhare kaanton ki qataar. Khushk, halki hawa.
Level theHollow() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(280, 406),
    Offset(340, 400), // gira darakht
    Offset(430, 394),
    Offset(500, 400),
    Offset(600, 404),
    Offset(680, 398),
    Offset(740, 392), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(820, 388),
    Offset(900, 394),
    Offset(980, 400),
    Offset(1060, 404), // zeher kaante
    Offset(1140, 400),
    Offset(1220, 396),
    Offset(1300, 404),
    Offset(1380, 440), // gehra dal-dal
    Offset(1400, 470),
    Offset(1425, 440),
    Offset(1448, 404),
    Offset(1520, 400),
    Offset(1600, 400), // shikanja
    Offset(1680, 404),
    Offset(1760, 400),
    Offset(1840, 396),
    Offset(1920, 392), // khai ka kinara
  ]);
  const c = Terrain([
    Offset(2000, 388),
    Offset(2080, 394),
    Offset(2160, 400),
    Offset(2240, 404),
    Offset(2320, 400),
    Offset(2400, 396),
    Offset(2480, 400),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(340, 85, y)],
    mood: Mood.forest,
    terrain: const [a, b, c],
    pools: const [Pool(1388, 1444, 406, deep: true)],
    solids: const [
      Rect.fromLTWH(2480, 400, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [Rect.fromLTWH(1060, y(1074) - 14, 48, 16)],
    saws: const [
      Saw(900, 180, speed: 1.7),
      Saw(2240, 190, speed: 1.9),
      Saw(500, 170, speed: 1.6),
    ],
    traps: [Rect.fromLTWH(1600, y(1614) - 10, 34, 10)],
    pendulums: const [
      Pendulum(Offset(1180, 120), 160, speed: 1.6),
      Pendulum(Offset(2080, 130), 165, speed: 1.8, phase: 1),
      Pendulum(Offset(1760, 125), 160, speed: 1.9, phase: 2),
    ],
    branches: const [Branch(1760, 1660), Branch(2320, 2220)],
    checkpoints: [
      const Offset(100, 400),
      Offset(900, y(900)),
      Offset(1700, y(1700)),
      Offset(2300, y(2300)),
    ],
    goalX: 2900,
    // Set 5 (Chapter 9–10)
    chase: const Chase(
      startX: 200,
      speed: 140,
      maxBehind: 405,
      throwEvery: 2.4,
      aimEvery: 2,
    ),
    wind: const Profile([(0, 0.2), (2900, 0.25)]),
  );
}

/// 11 · The Web — daldali zameen jahan bhaari "ande ki thailiyon" jaisi cheezein jhoolti
/// hain, tang ghumaavdaar raasta.
Level theWeb() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(280, 408),
    Offset(340, 414), // keechar
    Offset(410, 406),
    Offset(480, 400),
    Offset(560, 400), // shikanja
    Offset(640, 404),
    Offset(720, 392), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(800, 388),
    Offset(880, 394),
    Offset(960, 400),
    Offset(1040, 404), // kaante
    Offset(1120, 400),
    Offset(1200, 396),
    Offset(1280, 404),
    Offset(1300, 440), // gehra
    Offset(1320, 470),
    Offset(1345, 440),
    Offset(1368, 404),
    Offset(1440, 400),
    Offset(1520, 400), // gira darakht (1520–1600)
    Offset(1620, 400),
    Offset(1700, 404), // shikanja
    Offset(1780, 400),
    Offset(1860, 396),
    Offset(1940, 392), // khai ka kinara
  ]);
  const c = Terrain([
    Offset(2020, 388),
    Offset(2100, 394),
    Offset(2180, 400),
    Offset(2260, 404),
    Offset(2340, 400),
    Offset(2420, 396),
    Offset(2500, 400),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1520, 80, y)],
    mood: Mood.forest,
    terrain: const [a, b, c],
    pools: const [Pool(1308, 1364, 406, deep: true)],
    solids: const [
      Rect.fromLTWH(2500, 400, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [Rect.fromLTWH(1040, y(1054) - 14, 48, 16)],
    saws: const [
      Saw(650, 300, speed: 1.7),
      Saw(1150, 290, speed: 1.8),
      Saw(1900, 290, speed: 1.8),
      Saw(2300, 290, speed: 1.9),
    ],
    traps: [
      Rect.fromLTWH(560, y(574) - 10, 34, 10),
      Rect.fromLTWH(1700, y(1714) - 10, 34, 10),
    ],
    pendulums: const [
      Pendulum(Offset(950, 110), 165, speed: 1.6),
      Pendulum(Offset(1800, 115), 168, speed: 1.7, phase: 1),
      Pendulum(Offset(2260, 125), 160, speed: 1.9, phase: 2),
    ],
    branches: const [Branch(1200, 1090), Branch(2100, 1990)],
    checkpoints: [
      const Offset(100, 400),
      Offset(880, y(880)),
      Offset(1620, y(1620)),
      Offset(2340, y(2340)),
    ],
    goalX: 2920,
    // Set 6 (Chapter 11–12)
    chase: const Chase(
      startX: 200,
      speed: 142,
      maxBehind: 392,
      throwEvery: 2.3,
      aimEvery: 2,
    ),
    wind: const Profile([(0, 0.2), (2920, 0.3)]),
  );
}

/// 12 · The Ruins — purane khandar: toote patthar ke chabootre, giri mehraaben, dhool.
Level theRuins() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(290, 396),
    Offset(370, 400),
    Offset(450, 404), // kaante
    Offset(530, 400),
    Offset(610, 396),
    Offset(690, 392), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(770, 388),
    Offset(850, 384), // oonchi chattan — koodo
    Offset(860, 350),
    Offset(930, 346),
    Offset(1010, 350),
    Offset(1080, 364),
    Offset(1150, 388),
    Offset(1220, 400),
    Offset(1300, 400), // shikanja
    Offset(1380, 404),
    Offset(1420, 440), // gehra
    Offset(1440, 470),
    Offset(1465, 440),
    Offset(1488, 404),
    Offset(1560, 400),
    Offset(1640, 400),
    Offset(1720, 396),
    Offset(1800, 392), // khai ka kinara
  ]);
  const c = Terrain([
    Offset(1880, 388),
    Offset(1960, 384),
    Offset(2040, 388),
    Offset(2120, 392),
    Offset(2200, 388),
    Offset(2280, 392),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1560, 80, y)],
    mood: Mood.cliffs,
    terrain: const [a, b, c],
    pools: const [Pool(1428, 1484, 406, deep: true)],
    solids: const [
      Rect.fromLTWH(770, 350, 90, 60), // toota chabootra
      Rect.fromLTWH(2280, 392, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [Rect.fromLTWH(1300, y(1314) - 14, 48, 16)],
    saws: const [
      Saw(950, 260, speed: 1.9),
      Saw(2040, 280, speed: 2.0),
      Saw(2200, 280, speed: 2.0),
      Saw(600, 300, speed: 1.7),
    ],
    traps: [Rect.fromLTWH(450, y(464) - 10, 34, 10)],
    pendulums: const [
      Pendulum(Offset(1650, 110), 170, speed: 1.8),
      Pendulum(Offset(1000, 100), 170, speed: 1.9, phase: 1),
    ],
    branches: const [Branch(1150, 1040), Branch(1750, 1640)],
    checkpoints: [
      const Offset(100, 400),
      Offset(870, y(870)),
      Offset(1600, y(1600)),
      Offset(2120, y(2120)),
    ],
    goalX: 2700,
    // Set 6 (Chapter 11–12)
    chase: const Chase(
      startX: 200,
      speed: 142,
      maxBehind: 392,
      throwEvery: 2.3,
      aimEvery: 2,
    ),
    wind: const Profile([(0, 0.3), (1200, -0.4), (2000, 0.5), (2700, 0.3)]),
  );
}

/// 13 · The Crushers — khandar mein chupe bhaari patthar ke jhoolte deadfall traps.
Level theCrushers() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(290, 404),
    Offset(370, 400),
    Offset(450, 396), // kaante
    Offset(530, 400),
    Offset(610, 404),
    Offset(690, 392), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(770, 388),
    Offset(850, 394),
    Offset(930, 400),
    Offset(1010, 404), // shikanja
    Offset(1090, 400),
    Offset(1170, 396),
    Offset(1250, 404),
    Offset(1270, 440), // gehra
    Offset(1290, 470),
    Offset(1315, 440),
    Offset(1338, 404),
    Offset(1410, 400),
    Offset(1490, 400), // kaante
    Offset(1570, 404),
    Offset(1650, 400),
    Offset(1730, 396),
    Offset(1810, 392), // khai ka kinara
  ]);
  const c = Terrain([
    Offset(1890, 388),
    Offset(1970, 384),
    Offset(2050, 388),
    Offset(2130, 392),
    Offset(2210, 388),
    Offset(2290, 392),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1410, 75, y)],
    mood: Mood.cliffs,
    terrain: const [a, b, c],
    pools: const [Pool(1278, 1334, 406, deep: true)],
    solids: const [
      Rect.fromLTWH(2290, 392, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [Rect.fromLTWH(1650, y(1664) - 14, 48, 16)],
    saws: const [
      Saw(600, 300, speed: 1.8),
      Saw(1200, 290, speed: 1.9),
      Saw(1900, 280, speed: 2.0),
      Saw(2200, 280, speed: 2.0),
    ],
    traps: [Rect.fromLTWH(1010, y(1024) - 10, 34, 10)],
    pendulums: const [
      Pendulum(Offset(950, 95), 175, speed: 1.9),
      Pendulum(Offset(1650, 100), 175, speed: 2.0, phase: 1),
      Pendulum(Offset(2130, 105), 170, speed: 2.1, phase: 2),
    ],
    branches: const [Branch(1800, 1690), Branch(2050, 1940)],
    checkpoints: [
      const Offset(100, 400),
      Offset(850, y(850)),
      Offset(1580, y(1580)),
      Offset(2130, y(2130)),
    ],
    goalX: 2710,
    // Set 7 (Chapter 13–14)
    chase: const Chase(
      startX: 200,
      speed: 144,
      maxBehind: 380,
      throwEvery: 2.15,
      aimEvery: 1,
    ),
    wind: const Profile([(0, 0.3), (2700, 0.4)]),
  );
}

/// 14 · The Undertow — ek purani doobi hui tanki/ghaar, behta malba, andheri gehrai.
Level theUndertow() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(290, 400),
    Offset(370, 400), // kaante
    Offset(450, 400),
    Offset(530, 400),
  ]);
  const b = Terrain([
    Offset(610, 400),
    Offset(690, 406),
    Offset(770, 414), // halka paani
    Offset(850, 406),
    Offset(930, 400),
    Offset(1010, 400), // shikanja
    Offset(1090, 404),
    Offset(1120, 440), // gehra
    Offset(1140, 470),
    Offset(1165, 440),
    Offset(1188, 404),
    Offset(1260, 400),
    Offset(1340, 400), // gira darakht (1340–1420)
    Offset(1440, 400),
    Offset(1520, 404), // kaante
    Offset(1600, 400),
  ]);
  const c = Terrain([
    Offset(1680, 400),
    Offset(1760, 406),
    Offset(1840, 414), // halka paani
    Offset(1920, 406),
    Offset(2000, 400),
    Offset(2080, 400), // shikanja
    Offset(2160, 404),
    Offset(2240, 400),
    Offset(2320, 400),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1340, 80, y)],
    mood: Mood.river,
    terrain: const [a, b, c],
    pools: const [
      Pool(700, 850, 410),
      Pool(1128, 1184, 406, deep: true),
      Pool(1770, 1920, 412),
    ],
    solids: const [
      Rect.fromLTWH(2320, 400, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    movers: const [
      Mover(
        Rect.fromLTWH(1900, 412, 80, 14),
        dx: 40,
        dy: 3,
        speed: 1.0,
        boat: true,
      ),
    ],
    spikes: [Rect.fromLTWH(1520, y(1534) - 14, 48, 16)],
    saws: const [
      Saw(1700, 300, speed: 1.8),
      Saw(2160, 300, speed: 1.9),
      Saw(500, 300, speed: 1.7),
    ],
    traps: [
      Rect.fromLTWH(370, y(384) - 10, 34, 10),
      Rect.fromLTWH(1010, y(1024) - 10, 34, 10),
    ],
    pendulums: const [
      Pendulum(Offset(950, 90), 175, speed: 1.9),
      Pendulum(Offset(1440, 95), 175, speed: 2.0, phase: 1),
    ],
    branches: const [Branch(2080, 1970), Branch(1260, 1150)],
    checkpoints: [
      const Offset(100, 400),
      Offset(700, y(700)),
      Offset(1440, y(1440)),
      Offset(2080, y(2080)),
    ],
    goalX: 2520,
    // Set 7 (Chapter 13–14)
    chase: const Chase(
      startX: 200,
      speed: 144,
      maxBehind: 380,
      throwEvery: 2.15,
      aimEvery: 1,
    ),
    wind: const Profile([(0, 0.4), (2500, 0.45)]),
    rain: const Profile([(0, 0.4), (2500, 0.6)]),
  );
}

/// 15 · The Spire — ek purani oonchi minar: tang pathreeli charhai, rassi ke pul, tez hawa.
Level theSpire() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(280, 390),
    Offset(350, 372),
    Offset(400, 352),
    Offset(412, 330), // chattan — koodo
    Offset(470, 324),
    Offset(540, 320),
    Offset(600, 300), // doosri chattan — koodo
    Offset(612, 270),
    Offset(670, 260),
    Offset(740, 256),
  ]);
  const b = Terrain([
    Offset(820, 254),
    Offset(880, 250),
    Offset(940, 254),
    Offset(980, 258),
    Offset(1002, 258), // rassi ka pul
  ]);
  const c = Terrain([
    Offset(1250, 258),
    Offset(1310, 254),
    Offset(1380, 250),
    Offset(1450, 256),
    Offset(1510, 264), // kaante
    Offset(1580, 272),
    Offset(1650, 280),
    Offset(1660, 316), // neeche utarna
    Offset(1710, 340),
    Offset(1780, 346),
  ]);
  const d = Terrain([
    Offset(1860, 346),
    Offset(1930, 342),
    Offset(1950, 378), // doosri utraai
    Offset(1970, 410),
    Offset(1990, 440), // gehra
    Offset(2010, 470),
    Offset(2035, 440),
    Offset(2058, 410),
    Offset(2130, 400),
    Offset(2210, 400), // shikanja
    Offset(2290, 404),
  ]);
  double y(double x) =>
      [a, b, c, d].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1650, 60, y)],
    mood: Mood.cliffs,
    terrain: const [a, b, c, d],
    pools: const [Pool(1994, 2050, 406, deep: true)],
    solids: const [
      Rect.fromLTWH(1000, 258, 250, 6), // rassi ka pul
      Rect.fromLTWH(2290, 404, 700, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    movers: const [
      Mover(Rect.fromLTWH(2070, 385, 80, 16), dy: 40, speed: 1.2),
    ],
    spikes: [Rect.fromLTWH(1510, y(1534) - 14, 48, 16)],
    saws: const [
      Saw(500, 150, speed: 1.9),
      Saw(1380, 170, speed: 1.9),
      Saw(2040, 320, speed: 2.0),
      Saw(740, 110, speed: 1.8),
      Saw(1150, 100, speed: 1.9),
    ],
    traps: [Rect.fromLTWH(200, y(217) - 10, 34, 10)],
    pendulums: const [
      Pendulum(Offset(880, 90), 155, speed: 1.9),
      Pendulum(Offset(1600, 100), 155, speed: 2.0, phase: 1),
      Pendulum(Offset(2240, 150), 155, speed: 2.1, phase: 2),
    ],
    branches: const [Branch(1850, 1740), Branch(2250, 2170)],
    checkpoints: [
      const Offset(100, 400),
      Offset(920, y(920)),
      Offset(1870, y(1870)),
      Offset(2080, y(2080)),
    ],
    goalX: 2800,
    // Set 8 (Chapter 15–16)
    chase: const Chase(
      startX: 200,
      speed: 146,
      maxBehind: 368,
      throwEvery: 2.0,
      aimEvery: 1,
    ),
    wind: const Profile([
      (0, 0.3),
      (900, -0.6),
      (1700, 0.8),
      (2300, -0.5),
      (2800, 0.3),
    ]),
  );
}

/// 16 · The Hunting Ground — sab tarah ke khatron ka milaap, regular chapters mein sab se
/// mushkil (Homecoming se pehle).
Level theHuntingGround() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(280, 406),
    Offset(340, 400), // gira darakht
    Offset(430, 394),
    Offset(500, 400), // kaante
    Offset(580, 404),
    Offset(660, 398),
    Offset(740, 392), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(820, 388),
    Offset(900, 394),
    Offset(980, 400), // shikanja
    Offset(1060, 404),
    Offset(1140, 400),
    Offset(1220, 396),
    Offset(1300, 404),
    Offset(1320, 440), // gehra
    Offset(1340, 470),
    Offset(1365, 440),
    Offset(1388, 404),
    Offset(1460, 400),
    Offset(1540, 400), // kaante
    Offset(1620, 404),
    Offset(1700, 400),
    Offset(1780, 396),
    Offset(1860, 392), // khai ka kinara
  ]);
  const c = Terrain([
    Offset(1940, 388),
    Offset(2020, 384),
    Offset(2100, 388),
    Offset(2180, 392),
    Offset(2260, 388),
    Offset(2340, 392),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(340, 90, y)],
    mood: Mood.forest,
    terrain: const [a, b, c],
    pools: const [Pool(1328, 1384, 406, deep: true)],
    solids: const [
      Rect.fromLTWH(2340, 392, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [
      Rect.fromLTWH(500, y(514) - 14, 48, 16),
      Rect.fromLTWH(1540, y(1554) - 14, 48, 16),
    ],
    saws: const [
      Saw(950, 260, speed: 2.0),
      Saw(1700, 280, speed: 2.1),
      Saw(2100, 290, speed: 2.1),
      Saw(600, 300, speed: 1.8),
    ],
    traps: [Rect.fromLTWH(980, y(994) - 10, 34, 10)],
    pendulums: const [
      Pendulum(Offset(1220, 100), 175, speed: 2.0),
      Pendulum(Offset(2020, 105), 175, speed: 2.1, phase: 1),
      Pendulum(Offset(1600, 95), 175, speed: 2.1, phase: 2),
    ],
    branches: const [Branch(1780, 1670)],
    checkpoints: [
      const Offset(100, 400),
      Offset(900, y(900)),
      Offset(1620, y(1620)),
      Offset(2180, y(2180)),
    ],
    goalX: 2750,
    // Set 8 (Chapter 15–16)
    chase: const Chase(
      startX: 200,
      speed: 146,
      maxBehind: 368,
      throwEvery: 2.0,
      aimEvery: 1,
    ),
    wind: const Profile([(0, 0.3), (2750, 0.4)]),
  );
}

/// 17 · The Last Light — dhalta sooraj, khandaron mein lagi aag, "trial and death" ka
/// ehsaas — har qadam pe khatra.
Level theLastLight() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(290, 394),
    Offset(370, 400), // aag
    Offset(450, 404),
    Offset(530, 400),
    Offset(610, 396),
    Offset(690, 392), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(770, 388),
    Offset(850, 394),
    Offset(930, 400), // aag
    Offset(1010, 404),
    Offset(1090, 400), // shikanja
    Offset(1170, 396),
    Offset(1250, 404),
    Offset(1270, 440), // gehra
    Offset(1290, 470),
    Offset(1315, 440),
    Offset(1338, 404),
    Offset(1410, 400), // aag
    Offset(1490, 400),
    Offset(1570, 404),
    Offset(1650, 400),
    Offset(1730, 396),
    Offset(1810, 392), // khai ka kinara
  ]);
  const c = Terrain([
    Offset(1890, 388),
    Offset(1970, 384),
    Offset(2050, 388), // aag
    Offset(2130, 392),
    Offset(2210, 388),
    Offset(2290, 392),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  Rect fire(double x, double w) => Rect.fromLTWH(x, y(x + w / 2) - 16, w, 16);
  return Level(
    logs: [fallenTree(1410, 75, y)],
    mood: Mood.fire,
    terrain: const [a, b, c],
    pools: const [Pool(1278, 1334, 406, deep: true)],
    solids: const [
      Rect.fromLTWH(2290, 392, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    fires: [fire(370, 50), fire(930, 60), fire(1410, 50), fire(2050, 60)],
    spikes: [Rect.fromLTWH(1090, y(1104) - 14, 48, 16)],
    saws: const [Saw(600, 300, speed: 1.9), Saw(2200, 300, speed: 2.0)],
    traps: [Rect.fromLTWH(1570, y(1584) - 10, 34, 10)],
    pendulums: const [
      Pendulum(Offset(950, 90), 175, speed: 2.0),
      Pendulum(Offset(1980, 95), 175, speed: 2.1, phase: 1),
    ],
    branches: const [Branch(1800, 1690), Branch(1200, 1090)],
    checkpoints: [
      const Offset(100, 400),
      Offset(850, y(850)),
      Offset(1650, y(1650)),
      Offset(2130, y(2130)),
    ],
    goalX: 2710,
    // Set 9 (Chapter 17–18)
    chase: const Chase(
      startX: 200,
      speed: 147.5,
      maxBehind: 358,
      throwEvery: 1.9,
      aimEvery: 1,
    ),
    wind: const Profile([(0, 0.3), (2700, 0.4)]),
  );
}

/// 18 · The Narrow Path — aakhri tangi raah ghar se pehle, sab se khatarnaak "regular"
/// chapter.
Level theNarrowPath() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(280, 406),
    Offset(340, 400), // shikanja
    Offset(420, 394),
    Offset(500, 400),
    Offset(580, 404),
    Offset(660, 398),
    Offset(740, 392), // khai ka kinara
  ]);
  const b = Terrain([
    Offset(820, 388),
    Offset(900, 394),
    Offset(980, 400), // kaante
    Offset(1060, 404),
    Offset(1140, 400),
    Offset(1220, 396),
    Offset(1300, 404),
    Offset(1320, 440), // gehra
    Offset(1340, 470),
    Offset(1365, 440),
    Offset(1388, 404),
    Offset(1460, 400), // gira darakht (1460–1540)
    Offset(1560, 400),
    Offset(1640, 400), // shikanja
    Offset(1720, 404),
    Offset(1800, 400),
    Offset(1880, 396),
    Offset(1960, 392), // khai ka kinara
  ]);
  const c = Terrain([
    Offset(2040, 388),
    Offset(2120, 384),
    Offset(2200, 388),
    Offset(2280, 392),
    Offset(2360, 388),
    Offset(2440, 392),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1460, 80, y)],
    mood: Mood.forest,
    terrain: const [a, b, c],
    pools: const [Pool(1328, 1384, 406, deep: true)],
    solids: const [
      Rect.fromLTWH(2440, 392, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    spikes: [
      Rect.fromLTWH(340, y(354) - 14, 48, 16),
      Rect.fromLTWH(1640, y(1654) - 14, 48, 16),
    ],
    saws: const [
      Saw(950, 260, speed: 2.1),
      Saw(1800, 280, speed: 2.1),
      Saw(2200, 290, speed: 2.2),
      Saw(600, 300, speed: 1.9),
    ],
    traps: [Rect.fromLTWH(980, y(994) - 10, 34, 10)],
    pendulums: const [
      Pendulum(Offset(1220, 95), 178, speed: 2.1),
      Pendulum(Offset(2120, 100), 178, speed: 2.2, phase: 1),
      Pendulum(Offset(1550, 90), 178, speed: 2.2, phase: 2),
    ],
    branches: const [Branch(1900, 1790), Branch(2300, 2220)],
    checkpoints: [
      const Offset(100, 400),
      Offset(900, y(900)),
      Offset(1720, y(1720)),
      Offset(2280, y(2280)),
    ],
    goalX: 2850,
    // Set 9 (Chapter 17–18)
    chase: const Chase(
      startX: 200,
      speed: 147.5,
      maxBehind: 358,
      throwEvery: 1.9,
      aimEvery: 1,
    ),
    wind: const Profile([(0, 0.3), (2850, 0.4)]),
  );
}

/// 19 · The Deep — aakhri azmaish Homecoming se pehle: sab khatre ikathe, shikaari ab tak
/// ke sab se tez.
Level theDeep() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(130, 400),
    Offset(210, 400),
    Offset(290, 394),
    Offset(370, 400), // kaante
    Offset(450, 404),
    Offset(530, 400),
  ]);
  const b = Terrain([
    Offset(610, 396),
    Offset(690, 400),
    Offset(770, 406), // halka paani
    Offset(850, 400),
    Offset(930, 400), // shikanja
    Offset(1010, 404),
    Offset(1030, 440), // gehra
    Offset(1050, 470),
    Offset(1075, 440),
    Offset(1098, 404),
    Offset(1170, 400),
    Offset(1250, 400), // gira darakht (1250–1330)
    Offset(1350, 400),
    Offset(1430, 404), // kaante
    Offset(1510, 400),
    Offset(1590, 396),
    Offset(1670, 392), // khai ka kinara
  ]);
  const c = Terrain([
    Offset(1750, 388),
    Offset(1830, 384),
    Offset(1910, 388), // shikanja
    Offset(1990, 392),
    Offset(2070, 388),
    Offset(2150, 392),
  ]);
  double y(double x) => [a, b, c].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1250, 80, y)],
    mood: Mood.river,
    terrain: const [a, b, c],
    pools: const [
      Pool(740, 850, 408),
      Pool(1038, 1094, 406, deep: true),
    ],
    solids: const [
      Rect.fromLTWH(2150, 392, 580, 200), // aakhri zameen (chhupne ka gaddha)
    ],
    movers: const [
      Mover(Rect.fromLTWH(1900, 370, 80, 16), dy: 42, speed: 1.3),
    ],
    spikes: [Rect.fromLTWH(1430, y(1444) - 14, 48, 16)],
    saws: const [
      Saw(1590, 300, speed: 2.2),
      Saw(600, 150, speed: 2.0),
      Saw(1750, 150, speed: 2.1),
    ],
    traps: [
      Rect.fromLTWH(370, y(384) - 10, 34, 10),
    ],
    pendulums: const [
      Pendulum(Offset(1830, 95), 175, speed: 2.2),
      Pendulum(Offset(1150, 90), 175, speed: 2.2, phase: 1),
      Pendulum(Offset(700, 100), 170, speed: 2.0, phase: 2),
    ],
    branches: const [Branch(1980, 1870), Branch(1560, 1480)],
    checkpoints: [
      const Offset(100, 400),
      Offset(680, y(680)),
      Offset(1350, y(1350)),
      Offset(1990, y(1990)),
    ],
    goalX: 2550,
    // Set 10 (Chapter 19–20)
    chase: const Chase(
      startX: 200,
      speed: 149,
      maxBehind: 350,
      throwEvery: 1.8,
      aimEvery: 1,
    ),
    wind: const Profile([(0, 0.4), (2500, 0.5)]),
    rain: const Profile([(0, 0.3), (2500, 0.5)]),
  );
}

/// 20 · Homecoming — moosla dhaar baarish, aakhri daud: shikaariyon se bach kar apne logon tak. Teelay, keechar.
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
    logs: [fallenTree(520, 75, y)],
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
      Saw(1950, 290, speed: 2.1),
      Saw(500, 300, speed: 1.9),
    ],
    pendulums: const [
      Pendulum(Offset(1150, 170), 175, speed: 1.6),
      Pendulum(Offset(2600, 170), 175, speed: 1.9, phase: 2),
      Pendulum(Offset(1480, 160), 175, speed: 2.0, phase: 1),
      Pendulum(Offset(2300, 165), 175, speed: 2.1, phase: 2),
    ],
    branches: const [Branch(1850, 1760), Branch(3010, 2890)],
    checkpoints: [
      const Offset(100, 400),
      Offset(790, y(790)),
      Offset(1480, y(1480)),
      Offset(2540, y(2540)),
    ],
    goalX: 3150,
    // Set 10 (Chapter 19–20): aakhri chapter, sab se mushkil
    chase: const Chase(
      startX: 200,
      speed: 149,
      maxBehind: 350,
      throwEvery: 1.8,
      aimEvery: 1,
    ),
    wind: const Profile([(0, 0.4), (2000, 0.8), (3400, 0.5)]),
    rain: const Profile([(0, 0.6), (1500, 0.9), (3400, 1.0)]),
  );
}

/// SHELVED — abhi active chapters list mein nahi (chapters.dart dekho). Tajrubaati chapter
/// tha: subah ka rangeen jungle, sunehri dhoop, phool, titliyan, saaf naala, aakhir mein
/// qabeela khara ho kar shikaariyon ko bhaga deta hai. Zaroorat padi to baad mein wapas
/// list mein shamil kiya ja sakta hai — function jaan boojh kar yahan rakha gaya hai.
Level home() {
  const a = Terrain([
    Offset(-600, 400),
    Offset(150, 400),
    Offset(250, 400),
    Offset(320, 392),
    Offset(400, 376),
    Offset(470, 370), // teela (oopar aari)
    Offset(540, 382),
    Offset(610, 396),
    Offset(652, 400),
  ]);
  const b = Terrain([
    Offset(740, 400),
    Offset(780, 400), // checkpoint
    Offset(880, 400), // kaante
    Offset(930, 410),
    Offset(965, 418), // naala
    Offset(1000, 412),
    Offset(1035, 400),
    Offset(1100, 400),
    Offset(1200, 400), // jhoolta lakkar
    Offset(1250, 392),
    Offset(1320, 380),
    Offset(1378, 372),
    Offset(1390, 330), // chattan — koodo
    Offset(1460, 326),
    Offset(1530, 330),
    Offset(1552, 336),
  ]);
  const c = Terrain([
    Offset(1640, 380),
    Offset(1660, 382), // checkpoint
    Offset(1700, 386),
    Offset(1780, 398),
    Offset(1850, 400),
    Offset(1950, 400), // shikanja, aari
    Offset(2000, 402),
    Offset(2080, 400), // shaakh
    Offset(2120, 404),
    Offset(2140, 440),
    Offset(2165, 470), // gehra talaab
    Offset(2190, 440),
    Offset(2212, 404),
    Offset(2260, 400),
    Offset(2380, 400), // kaante
    Offset(2420, 396),
    Offset(2462, 400),
  ]);
  const d = Terrain([
    Offset(2550, 400),
    Offset(2570, 400), // checkpoint
    Offset(2620, 398),
    Offset(2700, 400), // aari
    Offset(2760, 404),
    Offset(2840, 400), // shikanja
    Offset(2900, 392), // jhoolta lakkar
    Offset(2960, 400),
    Offset(3002, 400),
  ]);
  double y(double x) => [a, b, c, d].map((t) => t.topAt(x)).nonNulls.first;
  return Level(
    logs: [fallenTree(1700, 70, y)],
    mood: Mood.dawn,
    home: true,
    terrain: const [a, b, c, d],
    pools: const [Pool(925, 1040, 404), Pool(2128, 2204, 408, deep: true)],
    solids: const [
      Rect.fromLTWH(
        3000,
        400,
        1600,
        200,
      ), // apna gaon (aagay tak — kinara nazar na aaye)
    ],
    spikes: [
      Rect.fromLTWH(820, y(844) - 14, 48, 16),
      Rect.fromLTWH(2330, y(2354) - 14, 48, 16),
    ],
    traps: [
      Rect.fromLTWH(1880, y(1897) - 10, 34, 10),
      Rect.fromLTWH(2800, y(2817) - 10, 34, 10),
    ],
    saws: const [
      Saw(500, 290, speed: 1.8),
      Saw(1960, 320, speed: 2.0),
      Saw(2660, 320, speed: 2.1),
    ],
    pendulums: const [
      Pendulum(Offset(1150, 170), 175, speed: 1.8),
      Pendulum(Offset(2900, 165), 175, speed: 2.0, phase: 1),
    ],
    branches: const [Branch(1500, 1420), Branch(2040, 1930)],
    checkpoints: [
      const Offset(100, 400),
      Offset(780, y(780)),
      Offset(1660, y(1660)),
      Offset(2570, y(2570)),
    ],
    goalX: 3100,
    // Sab se mushkil: shikaari sab se tez, sab se qareeb, sab se zyada neze
    chase: const Chase(
      startX: 200,
      speed: 142,
      maxBehind: 390,
      throwEvery: 2.1,
      aimEvery: 2,
    ),
    wind: const Profile([(0, 0.2), (3200, 0.3)]),
  );
}
