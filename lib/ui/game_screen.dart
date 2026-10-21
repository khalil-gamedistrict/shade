// Khelne wali screen: game loop, controls, aur chapter khatam hone pe aage barhna
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/jungle.dart';
import '../game/painter.dart';
import '../game/sound.dart';
import '../game/weather.dart';
import '../game/world.dart';

// CI build ke waqt --dart-define=BUILD_INFO=... se set hota hai
const buildInfo = String.fromEnvironment('BUILD_INFO', defaultValue: 'local');

class GameScreen extends StatefulWidget {
  final Level level;
  final Sound? sound; // tests mein null, kyunke wahan audio plugin nahi hota
  final VoidCallback onComplete; // chapter khatam
  final VoidCallback onExit; // menu pe wapas
  const GameScreen({
    super.key,
    required this.level,
    required this.onComplete,
    required this.onExit,
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
  final jungle = Jungle();
  final weather = Weather();

  @override
  void initState() {
    super.initState();
    weather.onThunder = (near) => sound?.thunder(near);
    ticker = createTicker(_onFrame)..start();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void _onFrame(Duration elapsed) {
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
    sound?.setChase(
      active: world.chaseActive && world.state == PlayerState.alive,
      closeness: 1 - (world.pos.dx - world.hunterX) / 470,
      running: world.vx != 0,
    );
    for (final e in world.events) {
      sound?.play(e);
    }
    world.events.clear();
    frame.value++;
    if (world.state != shownState) {
      setState(() => shownState = world.state);
      // Roshni tak pahunch gaya — thori der baad agla chapter
      if (world.state == PlayerState.won && !_leaving) {
        _leaving = true;
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) widget.onComplete();
        });
      }
    }
  }

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
    } else if (key == LogicalKeyboardKey.escape && !down) {
      widget.onExit();
    } else {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    ticker.dispose();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
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
          // Chapter khatam: screen aahista kaali ho jaati hai
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: shownState == PlayerState.won ? 1 : 0,
              duration: const Duration(milliseconds: 2200),
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
