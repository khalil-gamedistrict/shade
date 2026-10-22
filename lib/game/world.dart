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
  final bool log; // darya mein tairta lakkar (rassi wala takhta nahi)
  const Mover(
    this.base, {
    this.dx = 0,
    this.dy = 0,
    this.speed = 1,
    this.phase = 0,
    this.log = false,
  });

  Rect rectAt(double t) {
    final k = sin(t * speed + phase);
    return base.shift(Offset(k * dx, k * dy));
  }
}

/// Oopar se girta patthar: player [triggerX] paar kare to [x] pe girta hai, gir kar rasta rokta hai
class Rock {
  final double x, triggerX, radius;
  const Rock(this.x, this.triggerX, {this.radius = 16});
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

/// Chapter ka mahaul — painter is ke hisaab se khaas cheezen banata hai
enum Mood { forest, fire, river, cliffs, home }

/// Maut kaise hui — girne ka andaaz is pe depend karta hai
enum DeathKind { fall, drown, hazard, spear, caught, burn }

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
  final List<Rock> rocks;
  final List<Pendulum> pendulums;
  final Chase? chase;
  final List<Rect> fires; // zameen pe jalti aag (chhoone se maut)
  final List<double> huts; // peeche jalti jhonpriyan (sirf manzar)
  final Mood mood;
  final double? waterY; // darya: is oonchai pe paani, gire to doob gaye

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
    this.rocks = const [],
    this.pendulums = const [],
    this.chase,
    this.fires = const [],
    this.huts = const [],
    this.mood = Mood.forest,
    this.waterY,
    this.wind = const Profile([]),
    this.rain = const Profile([]),
  });

  double get width => solids.fold(0.0, (m, s) => max(m, s.right));

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
      rocks: [
        for (final r in rocks)
          if (inside(r.x)) Rock(r.x + dx, r.triggerX + dx, radius: r.radius),
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
          if (c.dx > from + 50 && c.dx < to) c + Offset(dx, 0),
      ],
      goalX: goal + dx,
      deathY: deathY,
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
    rocks: [Rock(1680, 1500), Rock(3830, 3680), Rock(6700, 6540)],
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

enum PlayerState { alive, dead, won }

/// Game mein jo kuch hua — UI inhein sun kar sound bajata hai
enum GameEvent {
  step,
  jump,
  land,
  death,
  checkpoint,
  win,
  rock,
  chaseStart,
  spearThrow,
  spearHit,
  spearStick,
  shout,
}

class World {
  static const double playerW = 22, playerH = 44;
  // Dheemi, sochi samjhi chaal (Limbo jaisi) aur hawa mein zara der tairti jump
  static const double speed = 150, gravity = 1150, jumpVelocity = 520;
  static const double respawnDelay = 2.4; // girne aur tarapne ka manzar dikhe
  static const double windPush =
      38; // poori aandhi player ko itna px/s dhakelti hai
  static const double rockGravity = 1100;

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

  // Patthar: 0 = intezar, 1 = gir raha, 2 = zameen pe (rasta rokta hai)
  late final List<int> rockState;
  late final List<double> rockY, rockVy;
  int? _standingOn; // kis hilte platform pe khara hai

  // Maut ka manzar: kaise mara, kis taraf gira, kab
  DeathKind deathKind = DeathKind.hazard;
  double fallDir = 1; // +1 = right ki taraf gira
  double deathTime = 0;

  // Peechha
  static const hunterGaps = [
    0.0,
    42.0,
    86.0,
  ]; // teen shikaari, aagay wale se itna peeche
  static const spearGravity = 620.0;
  bool chaseActive = false;

  /// Trailer ke liye: maut nahi hoti, aur peechha band kiya ja sakta hai
  bool cinematic = false;
  bool allowChase = true;
  bool hunterMoving = false; // daur rahe hain ya gaddhay ke kinare khare
  double hunterX = -1000; // sab se aagay wala shikaari
  double _throwTimer = 0;
  double _grace = 0; // zinda hone ke baad thori mohlat
  double _shoutTimer = 2;
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

  /// Shikaari ke paon ki oonchai — gaddhay pe ho to chhalaang ki kaman
  double hunterFootY(double x) {
    final g = _groundBelow(x);
    if (g < level.deathY) return g;
    final sorted = [...level.solids]..sort((a, b) => a.left.compareTo(b.left));
    Rect? before, after;
    for (final s in sorted) {
      if (s.right <= x) before = s;
      if (s.left >= x && after == null) after = s;
    }
    if (before == null || after == null) return 400;
    final t = (x - before.right) / max(1, after.left - before.right);
    return min(before.top, after.top) -
        sin(t * pi) * min(60, (after.left - before.right) * 0.6);
  }

  World([Level? level]) : level = level ?? Level.first() {
    pos = this.level.checkpoints.first;
    rockState = List.filled(this.level.rocks.length, 0);
    rockY = List.filled(this.level.rocks.length, -40);
    rockVy = List.filled(this.level.rocks.length, 0);
  }

  double _groundBelow(double x) {
    var best = level.deathY;
    for (final s in level.solids) {
      if (x >= s.left && x <= s.right && s.top < best) best = s.top;
    }
    return best;
  }

  /// Zameen pe gira patthar — thos rukawat
  Rect rockRect(int i) {
    final r = level.rocks[i];
    return Rect.fromLTWH(
      r.x - r.radius,
      rockY[i] - r.radius * 0.6,
      r.radius * 2,
      r.radius * 1.6,
    );
  }

  /// Is waqt ki saari thos cheezen: zameen, hilte platform, gire hue patthar
  List<Rect> solidsNow() => [
    ...level.solids,
    for (final m in level.movers) m.rectAt(time),
    for (var i = 0; i < level.rocks.length; i++)
      if (rockState[i] == 2) rockRect(i),
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
    if (state == PlayerState.won) return;
    if (state == PlayerState.dead) {
      deadTimer -= dt;
      // Gaddhay mein gira to girta rahe, paani mein gira to aahista doobe
      if (deathKind == DeathKind.fall) {
        vy += gravity * dt;
        pos += Offset(0, vy * dt);
      } else if (deathKind == DeathKind.drown) {
        vy = min(vy + gravity * dt, 40);
        pos += Offset(0, vy * dt);
      }
      if (deadTimer <= 0) _respawn();
      return;
    }

    // Hilte platform pe khare ho to woh saath le jata hai
    if (_standingOn != null) {
      final m = level.movers[_standingOn!];
      final d = m.rectAt(time).topLeft - m.rectAt(time - dt).topLeft;
      pos += d;
    }
    _updateRocks(dt);
    _updateChase(dt);
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
    pos = Offset(pos.dx + moveX * dt, pos.dy);
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

    if (grounded && !wasGrounded && fallSpeed > 300) events.add(GameEvent.land);

    final oldPhase = walkPhase;
    walkPhase = grounded && vx != 0 ? walkPhase + dt * 8.5 : 0;
    // Har aadhe chakkar pe ek qadam zameen pe parta hai
    if ((walkPhase / pi).floor() > (oldPhase / pi).floor()) {
      events.add(GameEvent.step);
    }

    for (var i = checkpoint + 1; i < level.checkpoints.length; i++) {
      if (pos.dx >= level.checkpoints[i].dx) {
        checkpoint = i;
        events.add(GameEvent.checkpoint);
      }
    }

    final death = _hazard();
    if (death != null) {
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
    if (pos.dy > level.deathY) return DeathKind.fall;
    if (chaseActive && hunterX >= pos.dx - 26) {
      fallDir = 1; // peeche se waar — aagay muun ke bal
      return DeathKind.caught;
    }
    for (final sp in spears) {
      if (!sp.stuck && r.contains(Offset(sp.x, sp.y))) {
        events.add(GameEvent.spearHit);
        fallDir = sp.vx >= 0 ? 1 : -1; // neze ke zor se usi taraf
        spears.remove(sp);
        return DeathKind.spear;
      }
    }
    fallDir = -facing; // baaqi khatre: jhatke se peeche ki taraf
    if (level.fires.any(r.overlaps)) return DeathKind.burn;
    if (level.spikes.any(r.overlaps)) return DeathKind.hazard;
    if (level.traps.any(r.overlaps)) return DeathKind.hazard;
    bool hitsCircle(Offset c, double radius) {
      final nearest = Offset(
        c.dx.clamp(r.left, r.right),
        c.dy.clamp(r.top, r.bottom),
      );
      return (nearest - c).distance < radius;
    }

    for (final p in level.pendulums) {
      if (hitsCircle(p.bobAt(time), p.radius)) {
        fallDir = cos(time * p.speed + p.phase) >= 0
            ? 1
            : -1; // lakkar jidhar ja raha, udhar dhakka
        return DeathKind.hazard;
      }
    }
    for (var i = 0; i < level.rocks.length; i++) {
      final rock = level.rocks[i];
      if (rockState[i] == 1 &&
          hitsCircle(Offset(rock.x, rockY[i]), rock.radius)) {
        return DeathKind.hazard;
      }
    }
    for (final saw in level.saws) {
      if (hitsCircle(saw.centerAt(time), saw.radius)) return DeathKind.hazard;
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
    events.add(GameEvent.death);
  }

  void _updateRocks(double dt) {
    for (var i = 0; i < level.rocks.length; i++) {
      final rock = level.rocks[i];
      if (rockState[i] == 0 && pos.dx >= rock.triggerX) rockState[i] = 1;
      if (rockState[i] != 1) continue;
      rockVy[i] += rockGravity * dt;
      rockY[i] += rockVy[i] * dt;
      final floor = _groundBelow(rock.x) - rock.radius;
      if (rockY[i] >= floor) {
        rockY[i] = floor;
        rockState[i] = 2;
        events.add(GameEvent.rock);
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
    final dist = pos.dx - hunterX;
    if (_throwTimer <= 0 && dist > 110 && dist < 520) {
      final wobble = sin(time * 7.3) * 0.5 + 0.5; // har dafa thora alag waqt
      _throwTimer = chase.throwEvery * (0.75 + wobble * 0.5);
      final sx = hunterX, sy = hunterFootY(hunterX) - 38;
      final t = (dist / 360).clamp(0.75, 1.3);
      final tx = pos.dx + vx * t * 0.8, ty = pos.dy - 24;
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

  void _respawn() {
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
    // Checkpoint ke aage wale patthar dobara oopar — phir se girenge
    for (var i = 0; i < level.rocks.length; i++) {
      if (level.rocks[i].triggerX > pos.dx) {
        rockState[i] = 0;
        rockY[i] = -40;
        rockVy[i] = 0;
      }
    }
    state = PlayerState.alive;
  }
}
