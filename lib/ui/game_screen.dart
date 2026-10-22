// Khelne wali screen: game loop, controls, aur chapter khatam hone pe aage barhna
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/jungle.dart';
import '../game/painter.dart';
import '../game/sound.dart';
import '../game/weather.dart';
import '../game/world.dart';
import '../services/ads.dart';

// CI build ke waqt --dart-define=BUILD_INFO=... se set hota hai
const buildInfo = String.fromEnvironment('BUILD_INFO', defaultValue: 'local');

class GameScreen extends StatefulWidget {
  final Level level;
  final Jungle jungle; // darakhton ki tasveerein — saare chapters mein ek hi
  final Sound? sound; // tests mein null, kyunke wahan audio plugin nahi hota
  final VoidCallback onComplete; // chapter khatam
  final VoidCallback onExit; // menu pe wapas
  final AdService ads; // larai se chhootne ke badle ad
  const GameScreen({
    super.key,
    required this.level,
    required this.jungle,
    required this.onComplete,
    required this.onExit,
    required this.ads,
    this.sound,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final World world = World(widget.level);
  final input = Input();
  final frame = ValueNotifier(0); // har frame pe painter ko redraw karwata hai
  late final Ticker ticker;
  Duration last = Duration.zero;
  PlayerState shownState = PlayerState.alive;
  Sound? get sound => widget.sound;
  bool _leaving = false;
  bool _adShowing = false;
  Jungle get jungle => widget.jungle;
  final weather = Weather();

  @override
  void initState() {
    super.initState();
    weather.onThunder = (near) => sound?.thunder(near);
    ticker = createTicker(_onFrame)..start();
    HardwareKeyboard.instance.addHandler(_onKey);
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
    final dt = (elapsed - last).inMicroseconds / 1e6;
    last = elapsed;
    final step = dt.clamp(0, 0.05).toDouble();
    world.update(step, input);
    // Pehle frame pe screen abhi lay out nahi hui hoti — tab size poochna crash karta hai
    // aur ticker hamesha ke liye ruk jata hai, is liye pehle hasSize check karo
    final box = context.findRenderObject() as RenderBox?;
    final size = box != null && box.hasSize ? box.size : null;
    if (size != null && size.height > 0) {
      final viewW = WorldPainter.viewWidth(size);
      weather.update(step, world, WorldPainter.cameraX(world, viewW), viewW);
    }
    if (input.left || input.right || input.jump) sound?.startLoops();
    sound?.setWeather(wind: world.windAt(world.pos.dx), rain: weather.rain);
    // Sab se qareeb shikaari, aur koi daur raha hai? (panah pe bhi — oopar se guzarte qadam)
    var gap = double.infinity;
    var huntersRunning = false;
    if (world.chaseActive) {
      for (final b in world.hunters) {
        final d = world.pos.dx - b.x;
        if (d.abs() < gap.abs()) gap = d;
        huntersRunning |= b.grounded && b.vx.abs() > 1;
      }
    }
    sound?.setChase(
      active: world.chaseActive && world.state == PlayerState.alive,
      running: world.vx != 0,
      hunterGap: gap,
      huntersRunning:
          huntersRunning &&
          (world.state == PlayerState.alive || world.state == PlayerState.won),
    );
    for (final e in world.events) {
      // Maut ki awaaz us ki qism ke hisaab se (aag, neza, paani...)
      e == GameEvent.death ? sound?.playDeath(world.deathKind) : sound?.play(e);
    }
    world.events.clear();
    frame.value++;
    // Larai mein waqt ki patti, panah mein line aur fade — har frame
    final animating =
        world.state == PlayerState.fighting || world.state == PlayerState.won;
    if (animating) setState(() {});
    if (world.state != shownState) {
      setState(() => shownState = world.state);
    }
    // Panah ka manzar khatam: line dikha kar fade, phir agla chapter
    if (_afterRefuge > _fadeAt + 1.6 && !_leaving) {
      _leaving = true;
      widget.onComplete();
    }
  }

  /// Shikaari chale jaane (manzar mukammal) ke baad kitne second guzre
  double get _afterRefuge =>
      world.refugeDone ? world.refugeTime - world.refugeDoneAt : -1;
  static const _fadeAt = 3.6;

  // Emulator / keyboard ke liye: arrow keys + space
  bool _onKey(KeyEvent e) {
    final down = e is! KeyUpEvent;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      input.left = down;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      input.right = down;
    } else if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      input.jump = down;
    } else if (key == LogicalKeyboardKey.keyE && down) {
      _breakFree();
    } else if (key == LogicalKeyboardKey.escape && !down) {
      widget.onExit();
    } else {
      return false;
    }
    return true;
  }

  /// Larai ke dauraan ek dafa: ad dekho, poora dekha to hero chhoot kar bhaag nikalta hai
  Future<void> _breakFree() async {
    final canEscape = world.state == PlayerState.fighting && !world.escapeUsed;
    if (!canEscape || _adShowing) return;
    world.fightPaused = true; // ad ke dauraan larai ruki rahe
    setState(() => _adShowing = true);
    final rewarded = await widget.ads.showRewarded(context);
    if (!mounted) return;
    _adShowing = false;
    if (rewarded) {
      world.escape();
    } else {
      world.fightPaused = false; // ad chhod diya — larai jari
    }
    setState(() {});
  }

  @override
  void dispose() {
    ticker.dispose();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  Widget _breakFreeButton() {
    final left = (1 - world.fightTime / World.fightDuration).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: _breakFree,
      child: Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
        decoration: BoxDecoration(
          color: const Color(0xDD111111),
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'BREAK FREE',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 14,
                  color: Colors.white60,
                ),
                SizedBox(width: 6),
                Text(
                  'Watch an ad  ·  E',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Larai ka bacha waqt
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: left,
                minHeight: 3,
                backgroundColor: Colors.white12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    jungle.dpr = MediaQuery.devicePixelRatioOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WorldPainter(world, jungle, weather, repaint: frame),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Row(
              children: [
                _HoldButton(
                  icon: Icons.arrow_back_ios_new,
                  onChanged: (v) => input.left = v,
                ),
                const SizedBox(width: 16),
                _HoldButton(
                  icon: Icons.arrow_forward_ios,
                  onChanged: (v) => input.right = v,
                ),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: _HoldButton(
              icon: Icons.keyboard_double_arrow_up,
              size: 84,
              onChanged: (v) => input.jump = v,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white38),
              onPressed: widget.onExit,
            ),
          ),
          Positioned(
            top: 12,
            right: 16,
            child: Text(
              'Build $buildInfo',
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ),
          if (world.state == PlayerState.fighting &&
              !world.escapeUsed &&
              !_adShowing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(child: _breakFreeButton()),
            ),
          if (shownState == PlayerState.won)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70,
              child: IgnorePointer(
                child: Opacity(
                  opacity:
                      ((_afterRefuge - 0.2).clamp(0.0, 0.8) / 0.8) *
                      (1 -
                          ((_afterRefuge - _fadeAt + 0.4).clamp(0.0, 0.6) /
                              0.6)),
                  child: const Text(
                    'Safe — for now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 4,
                      color: Color(0xFFEDEDED),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),
          // Chapter khatam: screen aahista kaali ho jaati hai
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: shownState == PlayerState.won && _afterRefuge > _fadeAt
                  ? 1
                  : 0,
              duration: const Duration(milliseconds: 1500),
              child: const ColoredBox(
                color: Colors.black,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Jab tak dabaya hua hai, true; chhorne pe false. Har button alag ungli se chal sakta hai.
class _HoldButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final ValueChanged<bool> onChanged;
  const _HoldButton({
    required this.icon,
    required this.onChanged,
    this.size = 72,
  });

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool pressed = false;

  void _set(bool v) {
    setState(() => pressed = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: pressed ? 0.3 : 0.12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(widget.icon, color: Colors.white70),
      ),
    );
  }
}
