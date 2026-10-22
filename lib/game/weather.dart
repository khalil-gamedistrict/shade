// Baarish, chheente, bijli aur hawa mein urte patte.
// Sab "view" coordinates mein (screen ki height = 500 units), camera ke saath parallax.
import 'dart:math';
import 'dart:typed_data';

import 'world.dart';

/// Baarish ki ek gehraai wali layer: door wali boondein patli, aahista aur halki
class RainLayer {
  final int maxDrops;
  final double speed, length, width, alpha, parallax;
  final bool hitsGround; // sirf saamne wali layer zameen pe chheente banati hai
  final xs = <double>[], ys = <double>[], speeds = <double>[];
  int active = 0;

  RainLayer({
    required this.maxDrops,
    required this.speed,
    required this.length,
    required this.width,
    required this.alpha,
    required this.parallax,
    this.hitsGround = false,
  });
}

class Splash {
  double x, y, age = 0;
  final double size;
  final List<double> dx, dy; // urti hui nanhi boondon ki raftaar
  Splash(this.x, this.y, this.size, this.dx, this.dy);
}

class FlyingLeaf {
  double x, y, vy, spin, angle;
  FlyingLeaf(this.x, this.y, this.vy, this.spin, this.angle);
}

class Weather {
  final _r = Random(3);
  // Boondein chhoti aur patli, lekin bohot zyada — asli baarish ki tarah ghani
  final layers = [
    RainLayer(
      maxDrops: 700,
      speed: 520,
      length: 6,
      width: 0.5,
      alpha: 0.15,
      parallax: 0.3,
    ),
    RainLayer(
      maxDrops: 600,
      speed: 760,
      length: 10,
      width: 0.7,
      alpha: 0.22,
      parallax: 0.6,
    ),
    RainLayer(
      maxDrops: 480,
      speed: 1050,
      length: 16,
      width: 0.95,
      alpha: 0.33,
      parallax: 1,
      hitsGround: true,
    ),
  ];
  final splashes = <Splash>[];
  final ripples = <Splash>[];
  final leaves = <FlyingLeaf>[];

  double rain = 0; // abhi kitni baarish (smooth)
  double wind = 0;
  double flash = 0; // bijli ki chamak 0..1
  double _flashTime = -1;
  double _nextLightning = 8;
  double _lastCam = double.nan;
  double time = 0;

  /// Bijli girne pe: true = qareeb (zor ki kadak), false = door ki garaj
  void Function(bool near)? onThunder;

  void update(double dt, World world, double camX, double viewW) {
    time += dt;
    final camDelta = _lastCam.isNaN ? 0.0 : camX - _lastCam;
    _lastCam = camX;
    final center = camX + viewW * 0.4;
    rain += (world.rainAt(center) - rain) * min(1, dt * 0.8);
    wind = world.windAt(center);

    for (final l in layers) {
      _updateLayer(l, dt, world, camX, camDelta, viewW);
    }
    _updateSplashes(dt);
    _updateLeaves(dt, camDelta, viewW);
    _updateLightning(dt);
  }

  void _updateLayer(
    RainLayer l,
    double dt,
    World world,
    double camX,
    double camDelta,
    double viewW,
  ) {
    final want = (l.maxDrops * rain).round();
    while (l.xs.length < want) {
      l.xs.add(_r.nextDouble() * (viewW + 200) - 100);
      l.ys.add(-_r.nextDouble() * 500);
      l.speeds.add(l.speed * (0.85 + _r.nextDouble() * 0.3));
    }
    l.active = min(want, l.xs.length);
    final slant = wind * 0.35;
    for (var i = 0; i < l.active; i++) {
      l.ys[i] += l.speeds[i] * dt;
      l.xs[i] += slant * l.speeds[i] * dt - camDelta * l.parallax;
      if (l.xs[i] < -100) l.xs[i] += viewW + 200;
      if (l.xs[i] > viewW + 100) l.xs[i] -= viewW + 200;

      var floor = 520.0;
      if (l.hitsGround) {
        final top = _groundTop(world.level, l.xs[i] + camX);
        if (top != null) floor = top;
      } else {
        floor = 430 + (i % 7) * 10; // door ki zameen dhund mein chhupi hai
      }
      if (l.ys[i] >= floor) {
        if (l.hitsGround && floor < 520) _splash(l.xs[i] + camX, floor);
        l.ys[i] = -_r.nextDouble() * 60 - l.length;
        l.xs[i] = _r.nextDouble() * (viewW + 200) - 100;
      }
    }
  }

  double? _groundTop(Level level, double x) {
    double? best;
    for (final s in level.ground) {
      if (x >= s.left && x <= s.right && (best == null || s.top < best)) {
        best = s.top;
      }
    }
    final t = level.terrainTop(x);
    if (t != null && (best == null || t < best)) best = t;
    return best;
  }

  void _splash(double x, double y) {
    if (splashes.length < 350) {
      final n = 2 + _r.nextInt(3);
      splashes.add(
        Splash(
          x,
          y,
          1,
          List.generate(n, (_) => (_r.nextDouble() - 0.5) * 90 + wind * 25),
          List.generate(n, (_) => -(50 + _r.nextDouble() * 90)),
        ),
      );
    }
    if (ripples.length < 160 && _r.nextDouble() < 0.4) {
      ripples.add(Splash(x, y, 4 + _r.nextDouble() * 6, const [], const []));
    }
  }

  void _updateSplashes(double dt) {
    for (final s in splashes) {
      s.age += dt;
    }
    splashes.removeWhere((s) => s.age > 0.32);
    for (final r in ripples) {
      r.age += dt;
    }
    ripples.removeWhere((r) => r.age > 0.45);
  }

  void _updateLeaves(double dt, double camDelta, double viewW) {
    // Tez hawa mein darakhton se toot kar urte patte
    final want = (max(0.0, wind.abs() - 0.35) * 40).round();
    while (leaves.length < want) {
      final fromLeft = wind > 0;
      leaves.add(
        FlyingLeaf(
          fromLeft
              ? -20 - _r.nextDouble() * 200
              : viewW + 20 + _r.nextDouble() * 200,
          _r.nextDouble() * 380,
          (_r.nextDouble() - 0.3) * 40,
          (_r.nextDouble() - 0.5) * 12,
          _r.nextDouble() * 6,
        ),
      );
    }
    for (final l in leaves) {
      l.x += (wind * 380 + sin(time * 3 + l.angle) * 40) * dt - camDelta;
      l.y += (l.vy + sin(time * 2 + l.spin) * 30) * dt;
      l.angle += l.spin * dt;
    }
    leaves.removeWhere(
      (l) =>
          l.x < -260 ||
          l.x > viewW + 260 ||
          l.y > 520 ||
          leaves.length > want + 5,
    );
  }

  void _updateLightning(double dt) {
    if (_flashTime >= 0) {
      _flashTime += dt;
      // Asli bijli: ek tez chamak, phir ek do chhoti jhapak
      final t = _flashTime;
      flash = t < 0.08
          ? 1
          : t < 0.16
          ? 0.25
          : t < 0.24
          ? 0.8
          : max(0.0, 0.6 * (1 - (t - 0.24) / 0.6));
      if (t > 0.9) {
        _flashTime = -1;
        flash = 0;
      }
      return;
    }
    if (rain < 0.6) return;
    _nextLightning -= dt;
    if (_nextLightning <= 0) strike(near: _r.nextDouble() < rain - 0.3);
  }

  /// Abhi bijli girao (trailer jaise manzar ke liye bhi)
  void strike({bool near = true}) {
    _flashTime = 0;
    _nextLightning = 7 + _r.nextDouble() * 10;
    onThunder?.call(near);
  }

  /// [layer] index ki boondein lines ki shakal mein (drawRawPoints ke liye)
  Float32List dropLines(int layer) {
    final l = layers[layer];
    final out = Float32List(l.active * 4);
    final slant = wind * 0.35;
    for (var i = 0; i < l.active; i++) {
      final x = l.xs[i], y = l.ys[i];
      out[i * 4] = x;
      out[i * 4 + 1] = y;
      out[i * 4 + 2] = x - slant * l.length;
      out[i * 4 + 3] = y - l.length;
    }
    return out;
  }
}
