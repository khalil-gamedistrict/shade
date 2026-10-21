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
    this.wind = const Profile([]),
    this.rain = const Profile([]),
  });

  double get width => solids.fold(0.0, (m, s) => max(m, s.right));

  static Level first() => const Level(
    solids: [
      // --- Hissa 1: jungle ki shuruaat, halki hawa
      Rect.fromLTWH(0, 400, 600, 200),
      // gaddha 600–700
      Rect.fromLTWH(700, 400, 500, 200),
      Rect.fromLTWH(1200, 340, 300, 260), // seedhi upar
      Rect.fromLTWH(1500, 400, 150, 200),
      // gaddha 1650–1770
      Rect.fromLTWH(1770, 400, 630, 200),
      Rect.fromLTWH(2000, 320, 40, 80), // deewar, kood ke paar karo
      // --- Hissa 2: baarish shuru, bara gaddha 2400–2900 beech mein platforms
      Rect.fromLTWH(2490, 360, 100, 20),
      Rect.fromLTWH(2690, 330, 100, 20),
      Rect.fromLTWH(2900, 400, 800, 200),
      // --- Hissa 3: saamne se tez hawa (aage barhna mushkil)
      // gaddha 3700–3800
      Rect.fromLTWH(3800, 400, 700, 200),
      Rect.fromLTWH(4200, 320, 40, 80),
      // gaddha 4500–4620
      Rect.fromLTWH(4620, 400, 180, 200),
      Rect.fromLTWH(4800, 340, 200, 260), // seedhiyan
      Rect.fromLTWH(5000, 280, 150, 320),
      Rect.fromLTWH(5150, 400, 150, 200),
      // --- Hissa 4: toofan — moosla dhaar baarish, peeche se aandhi, gaddhay pe platforms
      Rect.fromLTWH(5390, 370, 80, 20),
      Rect.fromLTWH(5560, 350, 80, 20),
      Rect.fromLTWH(5730, 370, 80, 20),
      Rect.fromLTWH(5900, 400, 1300, 200),
    ],
    spikes: [
      Rect.fromLTWH(900, 384, 48, 16),
      Rect.fromLTWH(2200, 384, 64, 16),
      Rect.fromLTWH(3350, 384, 48, 16),
      Rect.fromLTWH(4000, 384, 48, 16),
      Rect.fromLTWH(5220, 384, 48, 16),
      Rect.fromLTWH(6500, 384, 64, 16),
    ],
    saws: [
      Saw(3150, 320),
      Saw(4380, 320),
      Saw(6250, 320, speed: 2.4),
      Saw(6750, 310, speed: 3, range: 80),
    ],
    checkpoints: [
      Offset(60, 400),
      Offset(1820, 400),
      Offset(2960, 400),
      Offset(3850, 400),
      Offset(5060, 280),
      Offset(5960, 400),
    ],
    goalX: 7050,
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
      (7100, 0.5),
    ]),
  );
}

enum PlayerState { alive, dead, won }

/// Game mein jo kuch hua — UI inhein sun kar sound bajata hai
enum GameEvent { step, jump, land, death, checkpoint, win }

class World {
  static const double playerW = 22, playerH = 44;
  static const double speed = 220, gravity = 1800, jumpVelocity = 650;
  static const double respawnDelay = 1.2;
  static const double windPush =
      55; // poori aandhi player ko itna px/s dhakelti hai

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

  World([Level? level]) : level = level ?? Level.first() {
    pos = this.level.checkpoints.first;
  }

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
    for (final s in level.solids) {
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
    pos = Offset(pos.dx, pos.dy + vy * dt);
    for (final s in level.solids) {
      if (!playerRect.overlaps(s)) continue;
      if (vy > 0) {
        pos = Offset(pos.dx, s.top);
        grounded = true;
      } else {
        pos = Offset(pos.dx, s.bottom + playerH);
      }
      vy = 0;
    }

    if (grounded && !wasGrounded && fallSpeed > 300) events.add(GameEvent.land);

    final oldPhase = walkPhase;
    walkPhase = grounded && vx != 0 ? walkPhase + dt * 12 : 0;
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

  void _respawn() {
    pos = level.checkpoints[checkpoint];
    vx = vy = 0;
    state = PlayerState.alive;
  }
}
