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
  const Mover(
    this.base, {
    this.dx = 0,
    this.dy = 0,
    this.speed = 1,
    this.phase = 0,
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
    this.wind = const Profile([]),
    this.rain = const Profile([]),
  });

  double get width => solids.fold(0.0, (m, s) => max(m, s.right));

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
enum GameEvent { step, jump, land, death, checkpoint, win, rock }

class World {
  static const double playerW = 22, playerH = 44;
  // Dheemi, sochi samjhi chaal (Limbo jaisi) aur hawa mein zara der tairti jump
  static const double speed = 150, gravity = 1150, jumpVelocity = 520;
  static const double respawnDelay = 1.2;
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

    if (_touchesHazard()) {
      _die();
    } else if (pos.dx >= level.goalX) {
      state = PlayerState.won;
      events.add(GameEvent.win);
    }
  }

  bool _touchesHazard() {
    final r = playerRect.deflate(3); // thori riayat
    if (pos.dy > level.deathY) return true;
    if (level.spikes.any(r.overlaps)) return true;
    if (level.traps.any(r.overlaps)) return true;
    bool hitsCircle(Offset c, double radius) {
      final nearest = Offset(
        c.dx.clamp(r.left, r.right),
        c.dy.clamp(r.top, r.bottom),
      );
      return (nearest - c).distance < radius;
    }

    for (final p in level.pendulums) {
      if (hitsCircle(p.bobAt(time), p.radius)) return true;
    }
    for (var i = 0; i < level.rocks.length; i++) {
      final rock = level.rocks[i];
      if (rockState[i] == 1 &&
          hitsCircle(Offset(rock.x, rockY[i]), rock.radius)) {
        return true;
      }
    }
    for (final saw in level.saws) {
      final c = saw.centerAt(time);
      final nearest = Offset(
        c.dx.clamp(r.left, r.right),
        c.dy.clamp(r.top, r.bottom),
      );
      if ((nearest - c).distance < saw.radius) return true;
    }
    return false;
  }

  void _die() {
    state = PlayerState.dead;
    deadTimer = respawnDelay;
    deaths++;
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

  void _respawn() {
    pos = level.checkpoints[checkpoint];
    vx = vy = 0;
    _standingOn = null;
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
