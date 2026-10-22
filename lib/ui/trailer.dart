// Game shuru hone se pehle chhota sa trailer: asli game ke manzar, hero khud chalta hai (autopilot),
// neeche ek ek line. Skip button / Esc / Space se chhod sakte hain.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/autopilot.dart';
import '../game/chapters.dart';
import '../game/jungle.dart';
import '../game/levels.dart';
import '../game/painter.dart';
import '../game/sound.dart';
import '../game/weather.dart';
import '../game/world.dart';

/// Trailer ka ek manzar
class TrailerShot {
  final Level Function() level;
  final Offset start;
  final double duration;
  final List<(double, double, String)> captions; // (shuru, khatam, line)
  final bool chase; // shikaari shuru se peeche
  final bool allowChase;
  final double stopAt;
  final double? lightningAt;
  const TrailerShot({
    required this.level,
    required this.start,
    required this.duration,
    required this.captions,
    this.chase = false,
    this.allowChase = true,
    this.stopAt = double.infinity,
    this.lightningAt,
  });
}

const _hunterGap = 260.0; // shikaari itne peeche — screen pe dikhte rahen

final trailerShots = <TrailerShot>[
  // Jungle mein chalta hua... phir jang ki cheekh aur peeche se shikaari
  TrailerShot(
    level: Level.first,
    start: const Offset(100, 400),
    duration: 6.5,
    captions: const [
      (0.6, 2.9, 'The jungle was his home.'),
      (3.4, 6.2, 'Until they came for him.'),
    ],
  ),
  // Jalta gaon, peeche shikaari, neze
  TrailerShot(
    level: ashes,
    start: const Offset(850, 400),
    duration: 5,
    chase: true,
    captions: const [(0.8, 4.6, 'Run.')],
  ),
  // Toofan aur bijli
  TrailerShot(
    level: chapters[3].level!,
    start: const Offset(3880, 400),
    duration: 5,
    chase: true,
    lightningAt: 1.6,
    captions: const [(0.6, 4.6, 'Through fire. Through the storm.')],
  ),
  // Gaddhay mein intezar karti biwi
  TrailerShot(
    level: homecoming,
    start: const Offset(2940, 400),
    duration: 5,
    allowChase: false,
    stopAt: 3110,
    captions: const [(0.8, 4.7, 'She is waiting.')],
  ),
];

class TrailerScreen extends StatefulWidget {
  final Jungle jungle;
  final Sound? sound;
  final VoidCallback onDone;
  const TrailerScreen({
    super.key,
    required this.jungle,
    required this.onDone,
    this.sound,
  });

  @override
  State<TrailerScreen> createState() => _TrailerScreenState();
}

class _TrailerScreenState extends State<TrailerScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _frame = ValueNotifier(0);
  int _shot = 0;
  double _t = 0; // is shot mein guzra waqt
  double _titleTime = -1; // aakhri "SHADE" card
  late World _world;
  late Weather _weather;
  Duration _last = Duration.zero;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _begin(0);
    _ticker = createTicker(_onFrame)..start();
  }

  void _begin(int i) {
    final shot = trailerShots[i];
    _world = World(shot.level())
      ..pos = shot.start
      ..cinematic = true
      ..allowChase = shot.allowChase;
    if (shot.chase) {
      _world
        ..chaseActive = true
        ..hunterX = shot.start.dx - _hunterGap;
    }
    _weather = Weather()..onThunder = (near) => widget.sound?.thunder(near);
    // Baarish pehle se barasti ho, khaali aasmaan se shuru na ho
    for (var k = 0; k < 120; k++) {
      _weather.update(1 / 60, _world, WorldPainter.cameraX(_world, 1100), 1100);
    }
    _shot = i;
    _t = 0;
  }

  void _onFrame(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6)
        .clamp(0, 0.05)
        .toDouble();
    _last = elapsed;
    if (_titleTime >= 0) {
      _titleTime += dt;
      if (_titleTime > 3.6) _finish();
      setState(() {});
      return;
    }
    final shot = trailerShots[_shot];
    _t += dt;
    _world.update(dt, autopilot(_world, stopAt: shot.stopAt));
    if (_world.chaseActive) {
      // Shikaari screen pe dikhte rahen
      _world.hunterX = max(_world.hunterX, _world.pos.dx - _hunterGap);
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final viewW = WorldPainter.viewWidth(box.size);
      _weather.update(dt, _world, WorldPainter.cameraX(_world, viewW), viewW);
    }
    final lightning = shot.lightningAt;
    if (lightning != null && _t - dt < lightning && _t >= lightning) {
      _weather.strike();
    }
    for (final e in _world.events) {
      if (e != GameEvent.step || _t > 0.3) widget.sound?.play(e);
    }
    _world.events.clear();
    _frame.value++;

    if (_t >= shot.duration) {
      if (_shot + 1 < trailerShots.length) {
        _begin(_shot + 1);
      } else {
        _titleTime = 0;
      }
    }
    setState(() {}); // captions aur fade
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // Har shot ke shuru aur aakhir mein kaala fade
  double get _black {
    final d = trailerShots[_shot].duration;
    if (_t < 0.6) return 1 - _t / 0.6;
    if (d - _t < 0.6) return 1 - (d - _t) / 0.6;
    return 0;
  }

  String? get _caption {
    for (final (from, to, text) in trailerShots[_shot].captions) {
      if (_t >= from && _t <= to) return text;
    }
    return null;
  }

  double get _captionOpacity {
    for (final (from, to, _) in trailerShots[_shot].captions) {
      if (_t >= from && _t <= to) {
        return min(1.0, min(_t - from, to - _t) / 0.4);
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    widget.jungle.dpr = MediaQuery.devicePixelRatioOf(context);
    final h = MediaQuery.sizeOf(context).height;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _finish,
        const SingleActivator(LogicalKeyboardKey.space): _finish,
        const SingleActivator(LogicalKeyboardKey.enter): _finish,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              if (_titleTime < 0) ...[
                Positioned.fill(
                  child: CustomPaint(
                    painter: WorldPainter(
                      _world,
                      widget.jungle,
                      _weather,
                      repaint: _frame,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: _black),
                  ),
                ),
                // Film jaisi kaali pattiyan
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: h * 0.1,
                  child: const ColoredBox(color: Colors.black),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: h * 0.1,
                  child: const ColoredBox(color: Colors.black),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: h * 0.14,
                  child: Opacity(
                    opacity: _captionOpacity,
                    child: Text(
                      _caption ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 4,
                        color: Color(0xFFEDEDED),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ] else
                Center(
                  child: Opacity(
                    opacity: (min(_titleTime, 3.6 - _titleTime) / 0.8).clamp(
                      0.0,
                      1.0,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SHADE',
                          style: TextStyle(
                            fontSize: 64,
                            letterSpacing: 18,
                            color: Color(0xFFE8E8E8),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'run home',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 4,
                            color: Color(0x66E8E8E8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                right: 16,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip  ›',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
