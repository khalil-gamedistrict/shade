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

class Level {
  final List<Rect> solids;
  final List<Rect> spikes;
  final List<Saw> saws;
  final List<Offset> checkpoints;
  final double goalX;
  final double deathY;

  const Level({
    required this.solids,
    required this.spikes,
    required this.saws,
    required this.checkpoints,
    required this.goalX,
    this.deathY = 650,
  });

  static Level first() => Level(
    solids: [
      const Rect.fromLTWH(0, 400, 600, 200),
      // gaddha 600–700
      const Rect.fromLTWH(700, 400, 500, 200),
      const Rect.fromLTWH(1200, 340, 300, 260), // seedhi upar
      const Rect.fromLTWH(1500, 400, 150, 200),
      // gaddha 1650–1770
      const Rect.fromLTWH(1770, 400, 630, 200),
      const Rect.fromLTWH(2000, 320, 40, 80), // deewar, kood ke paar karo
      // bara gaddha 2400–2900, beech mein platforms
      const Rect.fromLTWH(2490, 360, 100, 20),
      const Rect.fromLTWH(2690, 330, 100, 20),
      const Rect.fromLTWH(2900, 400, 800, 200),
    ],
    spikes: [
      const Rect.fromLTWH(900, 384, 48, 16),
      const Rect.fromLTWH(2200, 384, 64, 16),
      const Rect.fromLTWH(3350, 384, 48, 16),
    ],
    saws: const [Saw(3150, 320)],
    checkpoints: const [Offset(60, 400), Offset(1820, 400), Offset(2960, 400)],
    goalX: 3600,
  );
}

enum PlayerState { alive, dead, won }

class World {
  static const double playerW = 22, playerH = 44;
  static const double speed = 220, gravity = 1800, jumpVelocity = 650;
  static const double respawnDelay = 1.2;

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

  World([Level? level]) : level = level ?? Level.first() {
    pos = this.level.checkpoints.first;
  }

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
    }
    vy += gravity * dt;

    // Pehle horizontal move aur takkar, phir vertical
    pos = Offset(pos.dx + vx * dt, pos.dy);
    for (final s in level.solids) {
      final r = playerRect;
      if (!r.overlaps(s)) continue;
      pos = Offset(
        vx > 0 ? s.left - playerW / 2 : s.right + playerW / 2,
        pos.dy,
      );
    }

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

    walkPhase = grounded && vx != 0 ? walkPhase + dt * 12 : 0;

    for (var i = checkpoint + 1; i < level.checkpoints.length; i++) {
      if (pos.dx >= level.checkpoints[i].dx) checkpoint = i;
    }

    if (_touchesHazard()) {
      _die();
    } else if (pos.dx >= level.goalX) {
      state = PlayerState.won;
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
  }

  void _respawn() {
    pos = level.checkpoints[checkpoint];
    vx = vy = 0;
    state = PlayerState.alive;
  }
}
