// Game shuru hone se pehle chhota sa trailer: asli game ke manzar, hero khud chalta hai (autopilot),
// neeche ek ek line. Skip button / Esc / Space se chhod sakte hain.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/autopilot.dart';
import '../game/chapters.dart';
import '../game/figures.dart';
import '../game/jungle.dart';
import '../game/levels.dart';
import '../game/painter.dart';
import '../game/props.dart';
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
  final double? lightningAt;
  final bool camp; // gaon ka manzar: alaao, jhonpriyan, naachte log
  final double? raidAt; // is waqt jang ki cheekh aur shikaari aate hain
  final double runAt; // is waqt se hero bhaagta hai (pehle khara rehta hai)
  const TrailerShot({
    required this.level,
    required this.start,
    required this.duration,
    required this.captions,
    this.chase = false,
    this.lightningAt,
    this.camp = false,
    this.raidAt,
    this.runAt = 0,
  });
}

const _hunterGap = 260.0; // shikaari itne peeche — screen pe dikhte rahen

/// Gaon ka khula maidan — trailer ke pehle manzar ke liye
Level _village() => const Level(
  solids: [Rect.fromLTWH(-600, 400, 5000, 200)],
  spikes: [],
  saws: [],
  checkpoints: [Offset(540, 400)],
  goalX: 9000,
  chase: Chase(startX: 99999), // khud shuru nahi hota — hamla script se
  wind: Profile([(0, 0.15)]),
);

final trailerShots = <TrailerShot>[
  // Qabeela hansi khushi... phir jang ki cheekh, shikaari, sab bhaagte hain, hero bhi
  TrailerShot(
    level: _village,
    start: const Offset(540, 400),
    duration: 8,
    camp: true,
    raidAt: 3.2,
    runAt: 4.2,
    captions: const [
      (0.6, 3.0, 'They lived in peace.'),
      (3.5, 7.4, 'Until the hunters came.'),
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
];

/// Gaon ka ek fard — kya kar raha hai, aur hamle pe kitni der baad bhaagta hai
enum _Act { dance, circle, idle }

class _Villager {
  final Look look;
  final double x,
      scale,
      dir,
      flee; // flee = hamle ke kitni der baad bhaagta hai
  final _Act act;
  const _Villager(
    this.look,
    this.x,
    this.act, {
    this.scale = 1,
    this.dir = 1,
    this.flee = 0,
  });
}

const _fireX = 432.0;
const _villagers = [
  _Villager(Look.villager, 372, _Act.dance, flee: 0.15),
  _Villager(Look.woman, 492, _Act.dance, dir: -1, flee: 0.3),
  _Villager(
    Look.villager,
    0,
    _Act.circle,
    scale: 0.62,
    flee: 0.05,
  ), // bachcha aag ke gird
  _Villager(Look.woman, 610, _Act.idle, dir: -1, flee: 0.0),
  _Villager(
    Look.villager,
    634,
    _Act.idle,
    scale: 0.6,
    dir: -1,
    flee: 0.0,
  ), // maa ke saath bachcha
  _Villager(Look.villager, 690, _Act.idle, dir: -1, flee: 0.45),
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
      ..facingRight = !shot.camp; // gaon mein aag ki taraf dekh raha hai
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

  /// Kisi frame mein error aaye to report karo, lekin ticker kabhi na ruke (warna screen jam jaati hai)
  void _onFrame(Duration elapsed) {
    try {
      _tick(elapsed);
    } catch (e, st) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: st, library: 'shade'),
      );
    }
  }

  void _tick(Duration elapsed) {
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
    final raid = shot.raidAt;
    if (raid != null && _t - dt < raid && _t >= raid) {
      // Jang ki cheekh — shikaari baayen se jhapat'te hain
      _world
        ..chaseActive = true
        ..hunterX = WorldPainter.cameraX(_world, 1100) - 30;
      widget.sound?.play(GameEvent.chaseStart);
    }
    _world.update(dt, _t >= shot.runAt ? autopilot(_world) : Input());
    if (_world.chaseActive && _t >= shot.runAt) {
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

  /// Gaon: do sabut jhonpriyan, alaao, naachte/khelte log — hamle ke baad sab daayen bhaagte hain
  void _drawCamp(Canvas canvas) {
    final t = _t, time = _world.time, wind = _world.windAt(_fireX);
    drawHut(canvas, 250, 400, time, wind, 1, burning: false);
    drawHut(canvas, 790, 400, time, wind, 2, burning: false);
    // Alaao: lakdiyan aur aag
    final log = Paint()
      ..color = const Color(0xFF070707)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(_fireX - 18, 400),
      const Offset(_fireX + 14, 393),
      log,
    );
    canvas.drawLine(
      const Offset(_fireX + 18, 400),
      const Offset(_fireX - 14, 393),
      log,
    );
    drawFire(
      canvas,
      const Rect.fromLTWH(_fireX - 15, 386, 30, 8),
      time,
      size: 0.9,
    );

    final raid = trailerShots[_shot].raidAt ?? double.infinity;
    for (var i = 0; i < _villagers.length; i++) {
      final v = _villagers[i];
      final fleeAt = raid + 0.3 + v.flee;
      var x = v.act == _Act.circle ? _fireX + sin(t * 1.7) * 58 : v.x;
      if (t >= fleeAt) {
        // Ghabra kar daayen bhaagna, har koi apni raftaar se
        x += (t - fleeAt) * (175 + i * 9);
        drawFigure(
          canvas,
          look: v.look,
          foot: Offset(x, 400),
          dir: 1,
          phase: t * 11 + i,
          moving: true,
          inAir: false,
          time: time,
          wind: wind,
          scale: v.scale,
        );
        continue;
      }
      switch (v.act) {
        case _Act.dance:
          // Naach: baazu oopar baari baari, halki uchhal
          final k = sin(t * 6 + i);
          drawFigure(
            canvas,
            look: v.look,
            foot: Offset(x, 400 - k.abs() * 3),
            dir: v.dir,
            phase: 0,
            moving: false,
            inAir: false,
            time: time,
            wind: wind,
            scale: v.scale,
            pose: FigurePose(
              (0.2 + k * 0.25, -0.4),
              (-0.2 - k * 0.25, -0.3),
              (2.6 + k * 0.4, 0.3),
              (2.3 - k * 0.4, 0.4),
            ),
          );
        case _Act.circle:
          drawFigure(
            canvas,
            look: v.look,
            foot: Offset(x, 400),
            dir: cos(t * 1.7) >= 0 ? 1 : -1,
            phase: t * 10,
            moving: true,
            inAir: false,
            time: time,
            wind: wind,
            scale: v.scale,
          );
        case _Act.idle:
          drawFigure(
            canvas,
            look: v.look,
            foot: Offset(x, 400),
            dir: v.dir,
            phase: 0,
            moving: false,
            inAir: false,
            time: time + i,
            wind: wind,
            scale: v.scale,
          );
      }
    }
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
                      extra: trailerShots[_shot].camp ? _drawCamp : null,
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
