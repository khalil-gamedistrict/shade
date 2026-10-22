// Game ki physics aur level — Flutter UI se alag, taake test ho sake.
import 'dart:math';
import 'dart:ui' show Offset, Rect;

class Input {
  bool left = false;
  bool right = false;
  bool jump = false;
}

/// Upar neeche ghoomne wala saw blade
class Saw {
  final double x, baseY, range, speed, radius;
  const Saw(
    this.x,
    this.baseY, {
    this.range = 70,
    this.speed = 2,
    this.radius = 30,
  });

  Offset centerAt(double t) => Offset(x, baseY + sin(t * speed) * range);
}

/// Hilta platform: [base] jagah se sin lehar mein [dx] (idhar udhar) aur [dy] (oopar neeche) chalta hai
class Mover {
  final Rect base;
  final double dx, dy, speed, phase;
  final bool boat; // darya mein kashti (rassi wala takhta nahi)
  const Mover(
    this.base, {
    this.dx = 0,
    this.dy = 0,
    this.speed = 1,
    this.phase = 0,
    this.boat = false,
  });

  Rect rectAt(double t) {
    final k = sin(t * speed + phase);
    return base.shift(Offset(k * dx, k * dy));
  }
}

/// Darakht se toot kar girti bhaari shaakh: player [triggerX] paar kare to chatak kar [x] pe girti hai,
/// zameen pe gir kar leti hui lakdi rasta rokti hai (us ke oopar se koodna parta hai)
class Branch {
  final double x, triggerX, radius;
  const Branch(this.x, this.triggerX, {this.radius = 16});
}

/// Rassi pe jhoolta lakkar: [pivot] se [length] lamba, [amplitude] radian tak jhoolta hai
class Pendulum {
  final Offset pivot;
  final double length, amplitude, speed, phase, radius;
  const Pendulum(
    this.pivot,
    this.length, {
    this.amplitude = 0.9,
    this.speed = 1.6,
    this.phase = 0,
    this.radius = 20,
  });

  double angleAt(double t) => amplitude * sin(t * speed + phase);
  Offset bobAt(double t) {
    final a = angleAt(t);
    return pivot + Offset(sin(a) * length, cos(a) * length);
  }
}

/// Ooncha-neecha qudrati zameen ka tukra: [points] (x, sath ki oonchai) — beech mein naram (smooth) mor,
/// neeche [bottom] tak bhari hui. Teelay, dhalan, gadhe. Pehle aur aakhri point pe khatam (wahan se gaddha).
class Terrain {
  final List<Offset> points;
  final double bottom;
  const Terrain(this.points, {this.bottom = 650});

  double get left => points.first.dx;
  double get right => points.last.dx;

  /// [x] pe sath ki oonchai; tukre se bahar null
  double? topAt(double x) {
    if (x < left || x > right) return null;
    var i = 1;
    while (i < points.length - 1 && points[i].dx < x) {
      i++;
    }
    // Catmull-Rom: points se guzarta naram mor
    final p1 = points[i - 1], p2 = points[i];
    final p0 = i >= 2 ? points[i - 2] : p1;
    final p3 = i + 1 < points.length ? points[i + 1] : p2;
    final t = (x - p1.dx) / max(1e-6, p2.dx - p1.dx);
    final m1 = (p2.dy - p0.dy) / max(1e-6, p2.dx - p0.dx) * (p2.dx - p1.dx);
    final m2 = (p3.dy - p1.dy) / max(1e-6, p3.dx - p1.dx) * (p2.dx - p1.dx);
    final t2 = t * t, t3 = t2 * t;
    return (2 * t3 - 3 * t2 + 1) * p1.dy +
        (t3 - 2 * t2 + t) * m1 +
        (-2 * t3 + 3 * t2) * p2.dy +
        (t3 - t2) * m2;
  }
}

/// Khara paani (talaab, keechar wala naala): [left]..[right] mein [surface] tak paani.
/// [deep] = doobne wala (koodna parta hai); warna ghutnon tak — chaal dheemi.
class Pool {
  final double left, right, surface;
  final bool deep;
  const Pool(this.left, this.right, this.surface, {this.deep = false});
}

/// Chapter ka mahaul — painter is ke hisaab se khaas cheezen banata hai
enum Mood { forest, fire, river, cliffs, home }

/// Maut kaise hui — girne ka andaaz is pe depend karta hai
enum DeathKind {
  fall, // gaddhay mein
  drown, // paani mein
  spike, // kaanton pe
  trap, // shikanje mein paon
  pendulum, // bhaari jhoolta lakkar — door uchhal kar
  saw, // saw ki takkar — thora uchhal kar
  branch, // darakht se tooti bhaari shaakh — neeche dab gaya
  spear, // neza laga
  caught, // shikaariyon ne pakar liya
  burn, // aag mein jal gaya
}

/// Peechha: player [startX] paar kare to jangli shikaari peeche se daurte aate hain
class Chase {
  final double startX;
  final double speed; // player (150) se thore dheeme — rukoge to pakar lenge
  final double maxBehind; // is se zyada peeche nahi rehte (hamesha qareeb)
  final double throwEvery; // har itne second baad neza
  const Chase({
    this.startX = 0,
    this.speed = 128,
    this.maxBehind = 470,
    this.throwEvery = 3.2,
  });
}

/// Ek shikaari ka jism: hero jaisi physics — chalna, koodna, girna (paon [x], [y] pe)
class HunterBody {
  double x, y, vx = 0, vy = 0;
  bool grounded = true;
  HunterBody(this.x, this.y);
}

/// Phenka hua neza: hawa mein kaman ki tarah, zameen pe gir kar gar jata hai
class Spear {
  double x, y, vx, vy, age = 0;
  bool stuck = false;
  Spear(this.x, this.y, this.vx, this.vy);
  double get angle => atan2(vy, vx);
}

/// Level ke saath badalti cheez (hawa, baarish): (x, value) points, beech mein smooth
class Profile {
  final List<(double, double)> points;
  const Profile(this.points);

  double at(double x) {
    if (points.isEmpty) return 0;
    if (x <= points.first.$1) return points.first.$2;
    for (var i = 1; i < points.length; i++) {
      final (x1, v1) = points[i];
      if (x <= x1) {
        final (x0, v0) = points[i - 1];
        final t = (x - x0) / (x1 - x0);
        final smooth = t * t * (3 - 2 * t);
        return v0 + (v1 - v0) * smooth;
      }
    }
    return points.last.$2;
  }
}

class Level {
  final List<Rect> solids;
  final List<Rect> spikes;
  final List<Saw> saws;
  final List<Offset> checkpoints;
  final double goalX;
  final double deathY;
  final List<Rect> traps; // shikanje (bear traps)
  final List<Mover> movers;
  final List<Branch> branches;
  final List<Pendulum> pendulums;
  final Chase? chase;
  final List<Rect> fires; // zameen pe jalti aag (chhoone se maut)
  final List<double> huts; // peeche jalti jhonpriyan (sirf manzar)
  final Mood mood;
  final double? waterY; // darya: is oonchai pe paani, gire to doob gaye
  final List<Terrain> terrain; // ooncha-neecha zameen (teelay, dhalan)
  final List<Pool> pools; // khara paani

  /// Hawa: + right ki taraf, - left ki taraf. 1 = aandhi
  final Profile wind;

  /// Baarish: 0 = sookha, 1 = moosla dhaar
  final Profile rain;

  const Level({
    required this.solids,
    required this.spikes,
    required this.saws,
    required this.checkpoints,
    required this.goalX,
    this.deathY = 650,
    this.traps = const [],
    this.movers = const [],
    this.branches = const [],
    this.pendulums = const [],
    this.chase,
    this.fires = const [],
    this.huts = const [],
    this.mood = Mood.forest,
    this.waterY,
    this.terrain = const [],
    this.pools = const [],
    this.wind = const Profile([]),
    this.rain = const Profile([]),
  });

  double get width => max(
    solids.fold(0.0, (m, s) => max(m, s.right)),
    terrain.fold(0.0, (m, t) => max(m, t.right)),
  );

  /// [x] pe ooncha-neecha zameen ki sath (sab se oonchi), na ho to null
  double? terrainTop(double x) {
    double? best;
    for (final t in terrain) {
      final y = t.topAt(x);
      if (y != null && (best == null || y < best)) best = y;
    }
    return best;
  }

  /// [x] pe paani (agar koi talaab hai)
  Pool? poolAt(double x) {
    for (final p in pools) {
      if (x >= p.left && x <= p.right) return p;
    }
    return null;
  }

  static final _hideoutCache = Expando<(Rect?, List<Rect>)>();

  /// Chhupne ki jagah: goal pe zameen ke neeche khokhla gaddha — oopar mitti aur jaron ki patli chhat,
  /// munh ([holeX] pe) patton se dhaka. Shikaari us ke oopar se guzar jaate hain.
  /// Trailer ke manzar jaise levels (goal bahut door) mein null.
  Rect? get hideout => _hideout.$1;

  /// Goal ke baad ki zameen (hideout ho to): shikaari hero ke oopar se guzar kar aagay daurte chale jaate hain,
  /// is liye level ki zameen jahan khatam ho wahan se aagay tak barha di jaati hai.
  List<Rect> get runoff => _hideout.$2;

  (Rect?, List<Rect>) get _hideout => _hideoutCache[this] ??= () {
    Rect? ground;
    for (final s in solids) {
      if (goalX - 10 >= s.left &&
          goalX + 130 <= s.right &&
          s.height >= 90 &&
          (ground == null || s.top < ground.top)) {
        ground = s;
      }
    }
    if (ground == null) return (null, const <Rect>[]);
    final hole = Rect.fromLTRB(
      goalX - 8,
      ground.top + 12,
      goalX + 128,
      ground.top + 68,
    );
    final end = goalX + 2000;
    final extra =
        ground.right < end && !solids.any((s) => s.left >= ground!.right)
        ? [Rect.fromLTRB(ground.right - 2, ground.top, end, ground.bottom)]
        : const <Rect>[];
    return (hole, extra);
  }();

  /// Zameen + goal ke baad ki zameen
  List<Rect> get ground => runoff.isEmpty ? solids : [...solids, ...runoff];

  /// Level ka [from]..[to] hissa alag chapter ke liye: sab kuch khiska kar [from] ko x=100 pe le aata hai,
  /// aur shuru mein thori zameen jor deta hai (taake player peeche gir na sake).
  /// [from] kisi zameen (top 400) ke shuru pe hona chahiye.
  Level slice(double from, double to, {required double goal}) {
    final dx = 100 - from;
    Rect sh(Rect r) => r.shift(Offset(dx, 0));
    bool inside(double x) => x >= from - 1 && x <= to;
    Profile shp(Profile p) =>
        Profile([for (final (x, v) in p.points) (x + dx, v)]);
    return Level(
      solids: [
        const Rect.fromLTRB(-600, 400, 101, 600),
        for (final s in solids)
          if (s.right > from && s.left < to) sh(s),
      ],
      spikes: [
        for (final s in spikes)
          if (inside(s.left)) sh(s),
      ],
      traps: [
        for (final s in traps)
          if (inside(s.left)) sh(s),
      ],
      saws: [
        for (final s in saws)
          if (inside(s.x))
            Saw(
              s.x + dx,
              s.baseY,
              range: s.range,
              speed: s.speed,
              radius: s.radius,
            ),
      ],
      pendulums: [
        for (final p in pendulums)
          if (inside(p.pivot.dx))
            Pendulum(
              p.pivot + Offset(dx, 0),
              p.length,
              amplitude: p.amplitude,
              speed: p.speed,
              phase: p.phase,
              radius: p.radius,
            ),
      ],
      branches: [
        for (final r in branches)
          if (inside(r.x)) Branch(r.x + dx, r.triggerX + dx, radius: r.radius),
      ],
      movers: [
        for (final m in movers)
          if (inside(m.base.left))
            Mover(
              sh(m.base),
              dx: m.dx,
              dy: m.dy,
              speed: m.speed,
              phase: m.phase,
            ),
      ],
      checkpoints: [
        const Offset(100, 400),
        for (final c in checkpoints)
          if (c.dx > from + 50 && c.dx < min(to, goal - 50)) c + Offset(dx, 0),
      ],
      goalX: goal + dx,
      deathY: deathY,
      terrain: [
        for (final t in terrain)
          if (t.right > from && t.left < to)
            Terrain([
              for (final p in t.points) p + Offset(dx, 0),
            ], bottom: t.bottom),
      ],
      pools: [
        for (final p in pools)
          if (inside(p.left))
            Pool(p.left + dx, p.right + dx, p.surface, deep: p.deep),
      ],
      chase: chase == null
          ? null
          : Chase(
              startX: max(chase!.startX + dx, 100),
              speed: chase!.speed,
              maxBehind: chase!.maxBehind,
              throwEvery: chase!.throwEvery,
            ),
      wind: shp(wind),
      rain: shp(rain),
    );
  }

  // Jump: ~117 oonchi, ~136 lambi (bina hawa ke). Saamne ki hawa mein ~110, peeche ki aandhi mein ~165.
  // Is liye gaddhay: aam ≤ 110, saamne ki hawa mein ≤ 85, seedhiyan ≤ 85 oonchi.
  static Level first() => const Level(
    solids: [
      // --- 1: jungle ki shuruaat
      Rect.fromLTWH(0, 400, 520, 200),
      // gaddha 520–610
      Rect.fromLTWH(610, 400, 390, 200),
      Rect.fromLTWH(1000, 345, 200, 255), // ooncha hissa, oopar jhoolta lakkar
      Rect.fromLTWH(1200, 400, 100, 200),
      // gaddha 1300–1395
      // --- 2: baarish shuru, peeche se hawa
      Rect.fromLTWH(1395, 400, 655, 200),
      Rect.fromLTWH(1980, 320, 40, 80), // deewar
      // gaddha 2050–2160
      Rect.fromLTWH(2160, 400, 260, 200),
      // --- 3: moosla dhaar baarish, bara gaddha 2420–2960 hilte platformon ke saath
      Rect.fromLTWH(2640, 345, 80, 18),
      Rect.fromLTWH(2960, 400, 520, 200),
      // --- 4: saamne se tez hawa
      // gaddha 3480–3560
      Rect.fromLTWH(3560, 400, 690, 200),
      Rect.fromLTWH(4120, 330, 40, 70), // deewar
      // gaddha 4250–4330
      Rect.fromLTWH(4330, 400, 390, 200),
      Rect.fromLTWH(4720, 345, 160, 255), // seedhiyan
      Rect.fromLTWH(4880, 290, 140, 310),
      Rect.fromLTWH(5020, 400, 180, 200),
      // --- 5: toofan — peeche se aandhi, bara gaddha 5200–5880
      Rect.fromLTWH(5290, 370, 80, 18),
      Rect.fromLTWH(5640, 365, 80, 18),
      Rect.fromLTWH(5880, 400, 1420, 200),
    ],
    spikes: [
      Rect.fromLTWH(760, 384, 48, 16),
      Rect.fromLTWH(1850, 384, 64, 16),
      Rect.fromLTWH(3380, 384, 48, 16),
      Rect.fromLTWH(4450, 384, 48, 16),
      Rect.fromLTWH(5120, 384, 40, 16),
      Rect.fromLTWH(6450, 384, 64, 16),
    ],
    traps: [
      Rect.fromLTWH(300, 390, 34, 10),
      Rect.fromLTWH(3120, 390, 34, 10),
      Rect.fromLTWH(4600, 390, 34, 10),
      Rect.fromLTWH(6850, 390, 34, 10),
    ],
    saws: [
      Saw(2330, 320, speed: 1.5),
      Saw(3990, 320, speed: 1.5),
      Saw(6300, 320, speed: 1.8),
      Saw(6990, 310, speed: 2.2, range: 80),
    ],
    pendulums: [
      Pendulum(Offset(1100, 150), 150, speed: 1.4),
      Pendulum(Offset(3260, 170), 175, speed: 1.5, phase: 1),
      Pendulum(Offset(6110, 160), 185, speed: 1.7, phase: 2),
    ],
    branches: [Branch(1680, 1500), Branch(3830, 3680), Branch(6700, 6540)],
    movers: [
      Mover(Rect.fromLTWH(2505, 370, 90, 18), dx: 60, speed: 0.9),
      Mover(Rect.fromLTWH(2790, 360, 80, 18), dy: 45, speed: 1.2),
      Mover(Rect.fromLTWH(5450, 350, 90, 18), dx: 50, speed: 1.0, phase: 1),
      Mover(Rect.fromLTWH(5770, 360, 70, 18), dy: 40, speed: 1.3, phase: 2),
    ],
    checkpoints: [
      Offset(60, 400),
      Offset(1440, 400),
      Offset(2200, 400),
      Offset(3000, 400),
      Offset(3600, 400),
      Offset(4950, 290),
      Offset(5930, 400),
    ],
    goalX: 7150,
    chase: Chase(startX: 400),
    wind: Profile([
      (0, 0.2),
      (1400, 0.45),
      (2300, 0.9),
      (3000, 0.3),
      (3700, -0.85),
      (4500, -0.7),
      (4900, 0.15),
      (5300, 1.0),
      (6300, 0.8),
      (7000, 0.25),
    ]),
    rain: Profile([
      (0, 0),
      (1200, 0.15),
      (2000, 0.55),
      (2600, 1.0),
      (3300, 0.4),
      (4000, 0.05),
      (4800, 0.35),
      (5400, 1.0),
      (6600, 0.9),
      (7300, 0.5),
    ]),
  );
}

enum PlayerState { alive, fighting, dead, won }

/// Game mein jo kuch hua — UI inhein sun kar sound bajata hai
enum GameEvent {
  step,
  wade, // paani mein qadam (chhap-chhap)
  jump,
  land,
  death,
  checkpoint,
  win,
  branchBreak, // shaakh toot'ne ki karak
  branchLand,
  bodyLand, // takkar se uchhla jism zameen pe gira
  chaseStart,
  spearThrow,
  spearHit,
  spearStick,
  shout,
  fightStart, // shikaariyon ne pakar liya — larai shuru
  fightHit, // larai mein waar
  escape, // hero chhoot kar bhaag nikla
  rustle, // patton ka dhakkan sarsaraya (hero gaddhay mein gira)
}

class World {
  static const double playerW = 22, playerH = 44;
  // Dheemi, sochi samjhi chaal (Limbo jaisi) aur hawa mein zara der tairti jump
  static const double speed = 150, gravity = 1150, jumpVelocity = 520;
  static const double respawnDelay = 2.4; // girne aur tarapne ka manzar dikhe
  static const double windPush =
      38; // poori aandhi player ko itna px/s dhakelti hai
  static const double branchGravity = 1100;

  final Level level;
  late Offset pos; // player ka bottom-center
  double vx = 0, vy = 0;
  bool grounded = false;
  bool facingRight = true;
  double walkPhase = 0;
  double time = 0;
  double deadTimer = 0;
  int checkpoint = 0;
  int deaths = 0;
  PlayerState state = PlayerState.alive;
  final List<GameEvent> events = [];

  // Shaakh: 0 = darakht pe, 1 = gir rahi, 2 = zameen pe (rasta rokti hai)
  late final List<int> branchState;
  late final List<double> branchY, branchVy;
  int? _standingOn; // kis hilte platform pe khara hai

  // Maut ka manzar: kaise mara, kis taraf gira, kab
  DeathKind deathKind = DeathKind.spike;
  double fallDir = 1; // +1 = right ki taraf gira
  double deathTime = 0;
  // Takkar ke baad jism ki physics: hawa mein uchhalna, gholay khana, zameen pe ghisatna
  Offset bodyVel = Offset.zero;
  double bodyAngle = 0, bodySpin = 0;
  bool bodyLanded = true;
  double landTime = 0;
  double spearAngle = 0; // jism mein gare neze ka zawiya
  int? closedTrap; // kaun sa shikanja band hua

  // Peechha
  static const hunterGaps = [
    0.0,
    42.0,
    86.0,
  ]; // teen shikaari, aagay wale se itna peeche
  static const spearGravity = 620.0;
  bool chaseActive = false;

  // Panah: hero zameen ke neeche gaddhay mein gir kar chhup jata hai, shikaari oopar aa kar rukte hain,
  // dhoondte hain, phir us ke oopar se guzar kar aagay daur jaate hain
  double refugeTime = 0;
  bool sitting = false;
  bool _dropping = false;
  double hunterDir = 1; // shikaariyon ka munh
  int _refugeStage =
      0; // 0 = aa rahe, 1 = oopar ruk kar dhoondh rahe, 2 = aagay bhaag gaye
  double _searchStart = 0;
  double passedTime = -1; // jab shikaari aagay bhaage (refugeTime)
  double refugeDoneAt = -1; // jab manzar khatam hua (refugeTime)
  static const holeX = 16.0,
      seatX = 74.0; // goalX se: gaddhay ka munh, andar baithne ki jagah
  static const searchLength = 2.4;

  // Larai: pakre jaane pe fauran maut nahi — [fightDuration] tak larai, phir maut.
  // Is dauraan ek dafa (ad dekh kar) chhoot kar bhaag sakte hain.
  static const fightDuration = 3.4;
  static const fightHits = [
    0.6,
    1.25,
    1.6,
    2.0,
    2.8,
    3.4,
  ]; // waar ke lamhe (awaaz, dhool, jhatka)
  double fightTime = 0;
  bool fightPaused = false; // ad chal raha ho to larai ruki rahe
  bool escapeUsed = false; // har chapter mein sirf ek dafa
  double escapeTime = -10;
  double hunterStunUntil =
      -10; // chhootne pe shikaari gir jaate hain, thori der baad uthte hain

  /// Trailer ke liye: maut nahi hoti, aur peechha band kiya ja sakta hai
  bool cinematic = false;
  bool allowChase = true;
  bool hunterMoving = false; // daur rahe hain ya gaddhay ke kinare khare
  // Shikaari: [hunterX] woh jagah jahan aagay wala shikaari pahunchna chahta hai (peechha, gaddhay, panah ka
  // hisaab). Asal jism [hunters] hain — hero jaisi physics se chalte aur koodte hue wahan tak jaate hain.
  double _hx = -1000;
  double get hunterX => _hx;
  set hunterX(double v) {
    final far = (v - _hx).abs() > 80;
    _hx = v;
    if (far) _snapHunters(); // bari chhalaang (shuru, zinda hona, nazar se door) — jism wahin rakh do
  }

  final hunters = [for (var i = 0; i < 3; i++) HunterBody(-1000, 400)];

  /// Shikaariyon ki jaagah zameen pe: agar wahan gaddha ho to peeche ki zameen pe
  void _snapHunters() {
    for (var i = 0; i < hunters.length; i++) {
      var x = _hx - hunterGaps[i];
      var ground = _groundBelow(x);
      // Wahan gaddha ho to pehle aage (gaddhay ke paar, jidhar sab ja rahe hain) zameen dhoondo, phir peeche
      for (final step in [15.0, -15.0]) {
        var probe = x;
        for (var k = 0; k < 40 && ground >= level.deathY; k++) {
          probe += step;
          final g = _groundBelow(probe);
          if (g < level.deathY) {
            x = probe;
            ground = g;
          }
        }
      }
      hunters[i]
        ..x = x
        ..y = ground >= level.deathY ? 400 : ground
        ..vx = 0
        ..vy = 0
        ..grounded = true;
    }
  }

  double _throwTimer = 0;
  double _grace = 0; // zinda hone ke baad thori mohlat
  double _shoutTimer = 2;
  int _throws = 0;
  final spears = <Spear>[];
  late final List<(double, double)> _bigGaps =
      _findBigGaps(); // jin gaddhon pe shikaari ruk jate hain

  List<(double, double)> _findBigGaps() {
    final sorted = [...level.solids]..sort((a, b) => a.left.compareTo(b.left));
    final out = <(double, double)>[];
    var right = sorted.first.right;
    for (final s in sorted.skip(1)) {
      if (s.left > right &&
          level.movers.any(
            (m) => m.base.left < s.left && m.base.right > right,
          )) {
        out.add((right, s.left));
      }
      right = max(right, s.right);
    }
    return out;
  }

  World([Level? level]) : level = level ?? Level.first() {
    pos = this.level.checkpoints.first;
    branchState = List.filled(this.level.branches.length, 0);
    branchY = List.filled(this.level.branches.length, -40);
    branchVy = List.filled(this.level.branches.length, 0);
  }

  double _groundBelow(double x) {
    var best = level.deathY;
    for (final s in level.ground) {
      if (x >= s.left && x <= s.right && s.top < best) best = s.top;
    }
    final t = level.terrainTop(x);
    if (t != null && t < best) best = t;
    return best;
  }

  /// Paon paani ki sath se neeche (talaab mein khara/chal raha)
  bool _inWater(Offset feet) {
    final p = level.poolAt(feet.dx);
    return p != null && feet.dy > p.surface + 2;
  }

  /// Is se zyada oonchi dhalan/chattan pe chal kar nahi chadh sakte — koodna parta hai
  static const stepUp = 12.0;

  /// Ooncha-neecha zameen pe chalna: [x] se [nx] tak jaa sakte hain? (aagay seedhi oonchi deewar/teela nahi)
  bool _terrainBlocks(double x, double nx, double feet) {
    final top = level.terrainTop(nx);
    if (top == null || top >= feet - 0.5) return false;
    // Paon sath se neeche (andar) aa rahe hain: thori oonchai chadh lo, zyada ho to ruk jao
    if (top < feet - stepUp) return true;
    final here = level.terrainTop(x);
    // Bohot tez charhai (45° se zyada) — chal kar nahi
    return here != null && (here - top) > (nx - x).abs() * 1.2 + 0.5;
  }

  /// Gir rahe/chal rahe jism ko ooncha-neecha zameen pe tikao. Jo pehle se zameen pe tha woh dhalan pe neeche
  /// utarte hue bhi chipka rahe. Wapas: nayi (y, zameen pe?) — ya null agar zameen nahi chhui.
  double? _terrainLand(double x, double y, double vy, bool wasGrounded) {
    if (vy < 0) return null;
    final top = level.terrainTop(x);
    if (top == null) return null;
    final reach = wasGrounded ? 10.0 : 0.0;
    if (y >= top - reach && y <= top + 40) return top;
    return null;
  }

  /// Girti/giri hui shaakh — zameen pe thos rukawat
  Rect branchRect(int i) {
    final r = level.branches[i];
    // Leti hui lambi lakdi: chaurai radius ka ~4.6 guna, oonchai ~1.1 guna
    return Rect.fromLTWH(
      r.x - r.radius * 2.3,
      branchY[i] - r.radius * 0.55,
      r.radius * 4.6,
      r.radius * 1.1,
    );
  }

  /// Is waqt ki saari thos cheezen: zameen, hilte platform, giri hui shaakhen
  List<Rect> solidsNow() => [
    ...level.solids,
    for (final m in level.movers) m.rectAt(time),
    ...level.runoff,
    for (var i = 0; i < level.branches.length; i++)
      if (branchState[i] == 2) branchRect(i),
  ];

  /// Is jagah abhi hawa kitni hai — level ki hawa + jhonke (gusts) jo waqt ke saath aate jaate hain
  double windAt(double x) {
    final base = level.wind.at(x);
    final gust =
        0.7 + 0.2 * sin(time * 0.9 + x * 0.003) + 0.1 * sin(time * 2.7 + 1.3);
    return base * gust;
  }

  double rainAt(double x) => level.rain.at(x);

  Rect get playerRect =>
      Rect.fromLTWH(pos.dx - playerW / 2, pos.dy - playerH, playerW, playerH);

  void update(double dt, Input input) {
    // Bara dt (lag) physics ko tor deta hai, is liye chhote steps mein todo
    while (dt > 1e-6) {
      final s = min(dt, 1 / 120);
      _step(s, input);
      dt -= s;
    }
  }

  void _step(double dt, Input input) {
    time += dt;
    if (state == PlayerState.won) {
      _updateRefuge(dt);
      _updateHunterBodies(dt);
      return;
    }
    if (state == PlayerState.fighting) {
      _updateFight(dt);
      return;
    }
    if (state == PlayerState.dead) {
      deadTimer -= dt;
      // Gaddhay mein gira to girta rahe, paani mein gira to aahista doobe
      if (deathKind == DeathKind.fall) {
        vy += gravity * dt;
        pos += Offset(0, vy * dt);
      } else if (deathKind == DeathKind.drown) {
        vy = min(vy + gravity * dt, 40);
        pos += Offset(0, vy * dt);
      } else {
        _updateBody(dt);
      }
      _updateBranches(dt); // jo shaakh gir rahi thi woh zameen tak gire
      _updateHunterBodies(
        dt,
      ); // koodta shikaari hawa mein jam na jaye — zameen pe utre
      if (deadTimer <= 0) _respawn();
      return;
    }

    // Hilte platform pe khare ho to woh saath le jata hai
    if (_standingOn != null) {
      final m = level.movers[_standingOn!];
      final d = m.rectAt(time).topLeft - m.rectAt(time - dt).topLeft;
      pos += d;
    }
    _updateBranches(dt);
    _updateChase(dt);
    _updateHunterBodies(dt);
    _updateSpears(dt);
    final solids = solidsNow();

    vx = (input.right ? speed : 0) - (input.left ? speed : 0);
    if (vx != 0) facingRight = vx > 0;
    if (input.jump && grounded) {
      vy = -jumpVelocity;
      grounded = false;
      events.add(GameEvent.jump);
    }
    vy += gravity * dt;

    // Pehle horizontal move aur takkar, phir vertical
    // Zameen pe khare ho to hawa nahi dhakelti (warna khare khare gaddhay mein gir jao)
    final pushed = !grounded || vx != 0;
    final moveX = vx + (pushed ? windAt(pos.dx) * windPush : 0);
    // Paani mein chaal dheemi (ghutnon tak paani)
    final wading = _inWater(pos);
    final nx = pos.dx + moveX * dt * (wading ? 0.55 : 1);
    if (!_terrainBlocks(pos.dx, nx, pos.dy)) pos = Offset(nx, pos.dy);
    for (final s in solids) {
      final r = playerRect;
      if (!r.overlaps(s)) continue;
      pos = Offset(
        moveX > 0 ? s.left - playerW / 2 : s.right + playerW / 2,
        pos.dy,
      );
    }

    final wasGrounded = grounded;
    final fallSpeed = vy;
    grounded = false;
    _standingOn = null;
    pos = Offset(pos.dx, pos.dy + vy * dt);
    for (var k = 0; k < solids.length; k++) {
      final s = solids[k];
      if (!playerRect.overlaps(s)) continue;
      if (vy > 0) {
        pos = Offset(pos.dx, s.top);
        grounded = true;
        final m = k - level.solids.length;
        if (m >= 0 && m < level.movers.length) _standingOn = m;
      } else {
        pos = Offset(pos.dx, s.bottom + playerH);
      }
      vy = 0;
    }
    if (!grounded) {
      final land = _terrainLand(pos.dx, pos.dy, vy, wasGrounded);
      if (land != null) {
        pos = Offset(pos.dx, land);
        grounded = true;
        vy = 0;
      }
    }

    if (grounded && !wasGrounded && fallSpeed > 300) events.add(GameEvent.land);

    final oldPhase = walkPhase;
    walkPhase = grounded && vx != 0 ? walkPhase + dt * 8.5 : 0;
    // Har aadhe chakkar pe ek qadam zameen pe parta hai
    if ((walkPhase / pi).floor() > (oldPhase / pi).floor()) {
      events.add(wading ? GameEvent.wade : GameEvent.step);
    }

    for (var i = checkpoint + 1; i < level.checkpoints.length; i++) {
      if (pos.dx >= level.checkpoints[i].dx) {
        checkpoint = i;
        events.add(GameEvent.checkpoint);
      }
    }

    final death = _hazard();
    if (death == DeathKind.caught) {
      _startFight();
    } else if (death != null) {
      _die(death);
    } else if (pos.dx >= level.goalX) {
      state = PlayerState.won;
      events.add(GameEvent.win);
    }
  }

  DeathKind? _hazard() {
    if (cinematic) return null;
    final r = playerRect.deflate(3); // thori riayat
    final facing = facingRight ? 1.0 : -1.0;
    final water = level.waterY;
    if (water != null && pos.dy > water + 12) return DeathKind.drown;
    final pool = level.poolAt(pos.dx);
    if (pool != null && pool.deep && pos.dy > pool.surface + 14) {
      return DeathKind.drown;
    }
    if (pos.dy > level.deathY) return DeathKind.fall;
    final lead = hunters.first;
    // Larai zameen pe hi: hawa mein (kood ke beech) koi kisi ko nahi pakarta
    final reach =
        grounded &&
        lead.grounded &&
        lead.x >= pos.dx - 26 &&
        (lead.y - pos.dy).abs() < 30; // oonchi jagah pe nahi pakar sakte
    if (chaseActive && time >= hunterStunUntil && reach) {
      fallDir = 1; // peeche se waar — aagay muun ke bal
      return DeathKind.caught;
    }
    for (final sp in spears) {
      if (!sp.stuck && r.contains(Offset(sp.x, sp.y))) {
        events.add(GameEvent.spearHit);
        fallDir = sp.vx >= 0 ? 1 : -1; // neze ke zor se usi taraf
        spearAngle = sp.angle;
        bodyVel = Offset(
          fallDir * 70,
          0,
        ); // halka sa dhakka — do qadam ladkhadata hai
        spears.remove(sp);
        return DeathKind.spear;
      }
    }
    fallDir = facing; // aag, kaante, shikanja: aagay ki taraf
    if (level.fires.any(r.overlaps)) return DeathKind.burn;
    if (level.spikes.any(r.overlaps)) return DeathKind.spike;
    for (var i = 0; i < level.traps.length; i++) {
      if (level.traps[i].overlaps(r)) {
        closedTrap = i;
        return DeathKind.trap;
      }
    }
    bool hitsCircle(Offset c, double radius) {
      final nearest = Offset(
        c.dx.clamp(r.left, r.right),
        c.dy.clamp(r.top, r.bottom),
      );
      return (nearest - c).distance < radius;
    }

    for (final p in level.pendulums) {
      if (hitsCircle(p.bobAt(time), p.radius)) {
        // Bhaari lakkar: jitna tez jhool raha tha, utni door phenkta hai
        final swing =
            p.amplitude *
            p.speed *
            cos(time * p.speed + p.phase); // radian/second
        final bobVx = swing * p.length * cos(p.angleAt(time));
        fallDir = bobVx >= 0 ? 1 : -1;
        bodyVel = Offset(fallDir * (200 + bobVx.abs() * 0.9), -300);
        bodySpin = fallDir * 9;
        return DeathKind.pendulum;
      }
    }
    for (var i = 0; i < level.branches.length; i++) {
      if (branchState[i] == 1 && branchRect(i).overlaps(r)) {
        return DeathKind.branch;
      }
    }
    for (final saw in level.saws) {
      final c = saw.centerAt(time);
      if (hitsCircle(c, saw.radius)) {
        // Saw halki hai: kam door uchhalta hai, saw se door ki taraf
        fallDir = pos.dx >= c.dx ? 1 : -1;
        bodyVel = Offset(fallDir * 190, -210);
        bodySpin = fallDir * 7;
        return DeathKind.saw;
      }
    }
    return null;
  }

  void _die(DeathKind kind) {
    state = PlayerState.dead;
    deathKind = kind;
    deathTime = time;
    deadTimer = respawnDelay;
    deaths++;
    hunterMoving = false;
    vx = 0;
    bodyAngle = 0;
    // Jo takkar se uchhla woh hawa mein hai; baaqi zameen pe
    bodyLanded = !(kind == DeathKind.pendulum || kind == DeathKind.saw);
    landTime = time;
    if (kind != DeathKind.pendulum &&
        kind != DeathKind.saw &&
        kind != DeathKind.spear) {
      bodyVel = Offset.zero;
    }
    // Lambi maut (aag, uchhalna) ka manzar pura dikhe
    deadTimer = switch (kind) {
      DeathKind.burn => 3.4,
      DeathKind.pendulum || DeathKind.saw => 3.0,
      _ => respawnDelay,
    };
    events.add(GameEvent.death);
  }

  /// Maut ke baad jism: hawa mein ho to gravity aur gholay, zameen pe aaye to ghisat kar ruk jaye
  void _updateBody(double dt) {
    if (bodyVel == Offset.zero && bodyLanded) return;
    if (!bodyLanded) {
      bodyVel += Offset(0, gravity * dt);
      bodyAngle += bodySpin * dt;
    } else {
      bodyVel = Offset(bodyVel.dx * exp(-5 * dt), 0); // ghisatte hue dheema
      if (bodyVel.dx.abs() < 2) bodyVel = Offset.zero;
    }
    final next = pos + bodyVel * dt;
    // Deewar se takra kar ruk jaye
    final blocked = solidsNow().any(
      (s) => s.contains(next + const Offset(0, -10)),
    );
    pos = blocked ? Offset(pos.dx, next.dy) : next;
    if (blocked) bodyVel = Offset(0, bodyVel.dy);
    final ground = _groundBelow(pos.dx);
    if (!bodyLanded &&
        bodyVel.dy > 0 &&
        pos.dy >= ground &&
        ground < level.deathY) {
      pos = Offset(pos.dx, ground);
      bodyLanded = true;
      landTime = time;
      events.add(GameEvent.bodyLand);
      bodyVel = Offset(bodyVel.dx * 0.6, 0);
    } else if (bodyLanded && pos.dy < ground - 1) {
      bodyLanded = false; // kinare se gir gaya
    }
  }

  void _updateBranches(double dt) {
    for (var i = 0; i < level.branches.length; i++) {
      final branch = level.branches[i];
      if (branchState[i] == 0 && pos.dx >= branch.triggerX) {
        branchState[i] = 1;
        events.add(
          GameEvent.branchBreak,
        ); // oopar shaakh chatakti hai — khatre ki ghanti
      }
      if (branchState[i] != 1) continue;
      branchVy[i] += branchGravity * dt;
      branchY[i] += branchVy[i] * dt;
      final floor =
          _groundBelow(branch.x) - branch.radius * 0.55; // zameen pe leti hui
      if (branchY[i] >= floor) {
        branchY[i] = floor;
        branchState[i] = 2;
        events.add(GameEvent.branchLand);
      }
    }
  }

  void _updateChase(double dt) {
    final chase = level.chase;
    if (chase == null || !allowChase) return;
    if (!chaseActive) {
      if (pos.dx < chase.startX) return;
      chaseActive = true;
      hunterX = pos.dx - chase.maxBehind;
      _throwTimer = 1.5;
      events.add(GameEvent.chaseStart);
    }

    if (time < hunterStunUntil) {
      hunterMoving = false; // abhi gire hue hain
      return;
    }

    // Daurte aate hain, lekin kabhi bahut peeche nahi rehte
    final hunterBefore = hunterX;
    _grace -= dt;
    final behind = chase.maxBehind + (_grace > 0 ? 180 : 0);
    hunterX = max(hunterX + chase.speed * dt, pos.dx - behind);
    // Bare gaddhay (hilte platform wale) paar nahi kar sakte: kinare pe ruk jate hain,
    // phir jab player kaafi aage nikal jaye to doosre raaste se phir peeche aa jate hain
    for (final (left, right) in _bigGaps) {
      if (hunterX > left - 40 && hunterX < right) {
        if (pos.dx < right + 380) {
          hunterX = left - 40;
        } else {
          hunterX = max(right + 10, pos.dx - behind);
        }
      }
    }

    hunterMoving = hunterX > hunterBefore + 0.01;

    // Beech beech mein jang ki cheekhein
    _shoutTimer -= dt;
    if (_shoutTimer <= 0) {
      _shoutTimer = 3.5 + (sin(time * 3.1) * 0.5 + 0.5) * 4;
      events.add(GameEvent.shout);
    }

    // Neze phenkna — player jahan hoga wahan ka andaza laga kar
    _throwTimer -= dt;
    final dist = pos.dx - hunters.first.x;
    if (_throwTimer <= 0 &&
        dist > 110 &&
        dist < 520 &&
        hunters.first.grounded) {
      final wobble = sin(time * 7.3) * 0.5 + 0.5; // har dafa thora alag waqt
      _throwTimer = chase.throwEvery * (0.75 + wobble * 0.5);
      final sx = hunters.first.x, sy = hunters.first.y - 38;
      final t = (dist / 360).clamp(0.75, 1.3);
      // Har teesra neza seedha nishane pe; baaqi aas paas girte hain (darate hain) —
      // asal khatra pakra jaana hai, taake larai ka manzar aur Break Free khel mein aayen
      final aimed = _throws++ % 3 == 2;
      final miss = aimed
          ? 0.0
          : (sin(time * 5.1) >= 0 ? 1 : -1) * (30 + 22 * sin(time * 2.3).abs());
      final tx = pos.dx + vx * t * 0.8 + miss, ty = pos.dy - 24;
      spears.add(
        Spear(
          sx,
          sy,
          (tx - sx) / t,
          (ty - sy - 0.5 * spearGravity * t * t) / t,
        ),
      );
      events.add(GameEvent.spearThrow);
    }
  }

  /// Hawa mein neze: kaman mein girte, zameen ya deewar mein gar jaate
  void _updateSpears(double dt) {
    for (final sp in spears) {
      sp.age += dt;
      if (sp.stuck) continue;
      sp.vy += spearGravity * dt;
      sp.x += sp.vx * dt;
      sp.y += sp.vy * dt;
      if (sp.y >= _groundBelow(sp.x) ||
          solidsNow().any((s) => s.contains(Offset(sp.x, sp.y)))) {
        sp.stuck = true; // zameen ya deewar mein gar gaya
        events.add(GameEvent.spearStick);
      }
    }
    spears.removeWhere((sp) => sp.age > 6 || sp.y > level.deathY);
  }

  /// Har shikaari apni jagah ([hunterX] - faasla) ki taraf daurta hai — hero jitni hi raftaar aur jump,
  /// aagay khatra, deewar ya gaddha dekh kar koodta hai. Gaddhay mein gira to bahar (baad mein peeche se aayega).
  /// Hero jaisi kood ka raasta chal kar dekho: kisi zameen pe utrega (oonchi, barabar ya neechi)?
  bool _jumpLands(double x, double y, double vx, List<Rect> solids) {
    var py = y;
    for (var t = 0.02; t < 2; t += 0.02) {
      final nx = x + vx * t;
      final ny = y - jumpVelocity * t + gravity * t * t / 2;
      if (ny > py) {
        // Neeche aa raha hai: is qadam mein kisi zameen ki sath paar ki?
        final hit = solids.any(
          (s) => nx >= s.left && nx <= s.right && s.top >= py && s.top <= ny,
        );
        if (hit) return true;
        // Ooncha-neecha zameen pe utra — lekin gehre paani mein nahi
        final top = level.terrainTop(nx);
        if (top != null && ny >= top && py <= top + 6) {
          return !(level.poolAt(nx)?.deep ?? false);
        }
      }
      if (ny > y + 220) return false;
      py = ny;
    }
    return false;
  }

  void _updateHunterBodies(double dt) {
    if (!chaseActive) return;
    final solids = [
      ...level.ground,
      for (var i = 0; i < level.branches.length; i++)
        if (branchState[i] == 2) branchRect(i),
    ];
    final hazards = [
      ...level.spikes,
      ...level.traps,
      ...level.fires,
      for (final p in level.pools)
        if (p.deep)
          Rect.fromLTRB(p.left, p.surface - 4, p.right, p.surface + 60),
    ];
    final stunned = time < hunterStunUntil;
    for (var i = 0; i < hunters.length; i++) {
      final b = hunters[i];
      var target = _hx - hunterGaps[i];
      // Manzil gaddhay mein ho to apni taraf ke kinare pe ruko (insaan paani/khai mein nahi chalta)
      if (_groundBelow(target) >= level.deathY) {
        final step = (b.x - target).sign * 10;
        for (var k = 0; k < 80 && step != 0; k++) {
          target += step;
          final onGround = _groundBelow(target) < level.deathY;
          final passedBody = (b.x - target).sign != step.sign;
          if (onGround || passedBody) break;
        }
        target += step * 1.5; // kinare se thora andar (zameen ki taraf)
      }
      final dx = target - b.x;
      // Insaani raftaar: hero se tez kabhi nahi
      // Zameen pe raftaar chuno; hawa mein (koodte waqt) raftaar wahi rehti hai
      if (b.grounded) {
        b.vx = stunned || dx.abs() < 3
            ? 0
            : dx.sign * min(speed, max(60, dx.abs() * 4));
      }
      final dir = b.vx.sign;
      if (b.grounded && dir != 0) {
        final ahead = dir > 0
            ? Rect.fromLTRB(b.x + 10, b.y - 60, b.x + 50, b.y + 1)
            : Rect.fromLTRB(b.x - 50, b.y - 60, b.x - 10, b.y + 1);
        final danger = hazards.any((h) => h.overlaps(ahead.inflate(4)));
        // Saamne oonchi cheez: deewar, ya teele ki itni oonchi/tez charhai ke chal kar na chadh saken
        final rise = level.terrainTop(b.x + dir * 14);
        final wall =
            solids.any((s) => s.overlaps(ahead) && s.top < b.y - 3) ||
            (rise != null && rise < b.y - stepUp) ||
            _terrainBlocks(b.x, b.x + dir * 3, b.y);
        final slope = level.terrainTop(b.x + dir * 24);
        final edge =
            !(slope != null && (slope - b.y).abs() < 12) &&
            !solids.any(
              (s) =>
                  b.x + dir * 24 >= s.left &&
                  b.x + dir * 24 <= s.right &&
                  (s.top - b.y).abs() < 12,
            );
        // Aage sirf neeche zameen hai (seedhi/chabootre/dhalan se utarna) — kood ke bajaye chal kar utro
        bool groundNear(double x, double y, double below) {
          final t = level.terrainTop(x);
          if (t != null && t >= y - 90 && t <= y + below) {
            return !(level.poolAt(x)?.deep ?? false);
          }
          return solids.any(
            (s) =>
                x >= s.left &&
                x <= s.right &&
                s.top >= y - 90 &&
                s.top <= y + below,
          );
        }

        final stepDown =
            edge &&
            !danger &&
            !wall &&
            groundNear(b.x + dir * 40, b.y + 13, 140);
        if ((danger || wall || edge) && !stepDown) {
          // Koodne se pehle dekho kahan giroge: sab se tez kood jo zameen pe utaare (gaddhay mein nahi)
          double? jumpSpeed;
          for (final v in [speed, speed * 0.82, speed * 0.66, speed * 0.52]) {
            if (_jumpLands(b.x, b.y, dir * v, solids)) {
              jumpSpeed = v;
              break;
            }
          }
          // Khatra abhi thora door hai aur yahan se kood ke paar nahi — chalte raho, kinare ke qareeb se koodo
          final step = Rect.fromLTRB(
            min(b.x, b.x + dir * 16),
            b.y - 4,
            max(b.x, b.x + dir * 16),
            b.y + 1,
          );
          final closeDanger = hazards.any((h) => h.overlaps(step));
          if (jumpSpeed == null && danger && !wall && !edge && !closeDanger) {
            // aagay barho
          } else if (jumpSpeed == null) {
            b.vx = 0; // mehfooz landing nahi — kinare pe ruk kar intezar (insaan andhi chhalaang nahi lagata)
          } else {
            b.vy = -jumpVelocity; // hero jitna hi oonchaa
            b.vx = dir * jumpSpeed;
            b.grounded = false;
          }
        }
      }
      b.vy += gravity * dt;
      // Pehle aagay, deewar se takkar; phir oopar neeche, zameen pe tikna. Paani mein dheeme.
      final nx = b.x + b.vx * dt * (_inWater(Offset(b.x, b.y)) ? 0.55 : 1);
      if (!_terrainBlocks(b.x, nx, b.y)) b.x = nx;
      for (final s in solids) {
        final r = Rect.fromLTWH(
          b.x - playerW / 2,
          b.y - playerH,
          playerW,
          playerH,
        );
        if (!r.overlaps(s)) continue;
        b.x = b.vx > 0 ? s.left - playerW / 2 : s.right + playerW / 2;
      }
      final wasGrounded = b.grounded;
      b.grounded = false;
      b.y += b.vy * dt;
      for (final s in solids) {
        final r = Rect.fromLTWH(
          b.x - playerW / 2,
          b.y - playerH,
          playerW,
          playerH,
        );
        if (!r.overlaps(s)) continue;
        if (b.vy > 0) {
          b.y = s.top;
          b.grounded = true;
        } else {
          b.y = s.bottom + playerH;
        }
        b.vy = 0;
      }
      if (!b.grounded) {
        final land = _terrainLand(b.x, b.y, b.vy, wasGrounded);
        if (land != null) {
          b
            ..y = land
            ..vy = 0
            ..grounded = true;
        }
      }
      if (b.y > level.deathY) {
        // Gaddhay mein gir gaya — kuch der baad peeche se, nazar se door
        b
          ..x = _hx - hunterGaps[i] - 420
          ..y = 400
          ..vy = 0;
        final g = _groundBelow(b.x);
        if (g < level.deathY) b.y = g;
      }
    }
  }

  void _updateRefuge(double dt) {
    final firstFrame = refugeTime == 0;
    refugeTime += dt;
    // Shikaari bohot peeche reh gaye hon to bhi panah tak pahunchen (oopar se guzarne ka manzar dikhe)
    if (firstFrame && chaseActive && hunterX < level.goalX - 700) {
      hunterX = level.goalX - 700;
    }
    _hideHero(dt);
    if (!chaseActive) {
      if (sitting && refugeDoneAt < 0) refugeDoneAt = refugeTime;
      return;
    }
    // Shikaari: daurte hue gaddhay ke oopar aa kar rukte hain, idhar udhar dekhte hain (hero neeche saans
    // roke), phir cheekh kar aagay — hero ke oopar se — bhaag jaate hain
    final stopAt = level.goalX + seatX + 6; // aagay wala theek hero ke oopar
    switch (_refugeStage) {
      case 0:
        hunterDir = 1;
        hunterMoving = hunterX < stopAt;
        if (hunterMoving) {
          hunterX = min(stopAt, hunterX + 135 * dt);
        } else {
          _refugeStage = 1;
          _searchStart = refugeTime;
        }
      case 1:
        hunterMoving = false;
        final k = refugeTime - _searchStart;
        // Aagay dekho, peeche mur kar, phir aagay — "kahan gaya?"
        hunterDir = k < 0.7 || k > 1.6 ? 1 : -1;
        if (k > searchLength) {
          _refugeStage = 2;
          passedTime = refugeTime;
          events.add(GameEvent.shout); // "aagay!"
        }
      default:
        hunterDir = 1;
        hunterMoving = true;
        hunterX += 150 * dt;
        if (refugeDoneAt < 0 && refugeTime - passedTime > 2.6) {
          refugeDoneAt = refugeTime;
        }
    }
  }

  /// Hero gaddhay ke munh tak chalta hai, patton ke beech se andar gir jata hai, phir rengh kar
  /// andar ki taraf baith jata hai. Hideout na ho (trailer) to wahin zameen pe baith jata hai.
  void _hideHero(double dt) {
    final hole = level.hideout;
    final entry = level.goalX + (hole == null ? seatX : holeX);
    if (!_dropping && !sitting && pos.dx < entry) {
      facingRight = true;
      vx = 80;
      pos = Offset(min(entry, pos.dx + 80 * dt), pos.dy);
      walkPhase += dt * 6;
      grounded = true;
      return;
    }
    if (hole == null) {
      vx = 0;
      walkPhase = 0;
      sitting = true;
      return;
    }
    if (!_dropping && !sitting && pos.dy < hole.bottom) {
      _dropping = true;
      grounded = false;
      vy = 0;
      events.add(GameEvent.rustle); // patton ka dhakkan sarsaraya
    }
    if (_dropping) {
      vy += gravity * dt;
      pos = Offset(pos.dx, min(hole.bottom, pos.dy + vy * dt));
      if (pos.dy >= hole.bottom) {
        _dropping = false;
        grounded = true;
        vy = 0;
        events.add(GameEvent.land);
      }
      return;
    }
    final seat = level.goalX + seatX;
    if (pos.dx < seat) {
      vx = 55;
      pos = Offset(min(seat, pos.dx + 55 * dt), pos.dy);
      walkPhase += dt * 5;
    } else {
      vx = 0;
      walkPhase = 0;
      sitting = true;
    }
  }

  /// Hero neeche gaddhay mein hai (zameen ki sath se neeche)
  bool get underground {
    final hole = level.hideout;
    return state == PlayerState.won && hole != null && pos.dy > hole.top - 8;
  }

  /// Hero aankhen band, saans roke — jab tak shikaari oopar hain
  bool get hiding =>
      chaseActive &&
      state == PlayerState.won &&
      (passedTime < 0 || refugeTime - passedTime < 1.4);

  /// Panah ka manzar mukammal (shikaari aagay nikal gaye / hero baith gaya)
  bool get refugeDone => refugeDoneAt >= 0;

  void _startFight() {
    state = PlayerState.fighting;
    fightTime = 0;
    fightPaused = false;
    vx = vy = 0;
    hunterX = pos.dx - 24;
    hunterMoving = false;
    spears.clear();
    facingRight = false; // palat kar muqabla
    events.add(GameEvent.fightStart);
  }

  void _updateFight(double dt) {
    if (fightPaused) return;
    final before = fightTime;
    fightTime += dt;
    for (final h in fightHits) {
      if (before < h && fightTime >= h) events.add(GameEvent.fightHit);
    }
    if (fightTime >= fightDuration) {
      // Saamne se aakhri waar — peeche (shikaariyon se door) girta hai, neza jism mein gara hua
      fallDir = 1;
      spearAngle = 0;
      _die(DeathKind.caught);
    }
  }

  /// Larai ke dauraan ek dafa (ad ke badle): hero dhakka de kar chhoot jata hai, shikaari gir jaate hain
  bool escape() {
    if (state != PlayerState.fighting || escapeUsed) return false;
    escapeUsed = true;
    state = PlayerState.alive;
    fightPaused = false;
    escapeTime = time;
    hunterStunUntil = time + 1.6;
    hunterX = pos.dx - 46; // dhakke se peeche gire
    _grace = 3; // uth kar bhi foran qareeb na aa jayen
    facingRight = true;
    events.add(GameEvent.escape);
    return true;
  }

  void _respawn() {
    closedTrap = null;
    bodyVel = Offset.zero;
    bodyLanded = true;
    pos = level.checkpoints[checkpoint];
    vx = vy = 0;
    _standingOn = null;
    // Shikaari phir peeche se — thori mohlat ke saath
    spears.clear();
    if (chaseActive) {
      hunterX = pos.dx - (level.chase?.maxBehind ?? 470) - 180;
      _throwTimer = 2.5;
      _grace = 2;
    }
    // Checkpoint ke aage wali shaakhen dobara darakht pe — phir se girengi
    for (var i = 0; i < level.branches.length; i++) {
      if (level.branches[i].triggerX > pos.dx) {
        branchState[i] = 0;
        branchY[i] = -40;
        branchVy[i] = 0;
      }
    }
    state = PlayerState.alive;
  }
}
