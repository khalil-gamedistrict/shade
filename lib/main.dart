import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'game/painter.dart';
import 'game/world.dart';

// CI build ke waqt --dart-define=BUILD_INFO=... se set hota hai
const buildInfo = String.fromEnvironment('BUILD_INFO', defaultValue: 'local');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ShadeApp());
}

class ShadeApp extends StatelessWidget {
  const ShadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  World world = World();
  final input = Input();
  final frame = ValueNotifier(0); // har frame pe painter ko redraw karwata hai
  late final Ticker ticker;
  Duration last = Duration.zero;
  PlayerState shownState = PlayerState.alive;

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_onFrame)..start();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  void _onFrame(Duration elapsed) {
    final dt = (elapsed - last).inMicroseconds / 1e6;
    last = elapsed;
    world.update(dt.clamp(0, 0.05), input);
    frame.value++;
    if (world.state != shownState) setState(() => shownState = world.state);
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
    } else {
      return false;
    }
    return true;
  }

  void _restart() => setState(() {
    world = World();
    shownState = world.state;
  });

  @override
  void dispose() {
    ticker.dispose();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: WorldPainter(world, repaint: frame)),
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
            top: 12,
            right: 16,
            child: Text(
              'Build $buildInfo',
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ),
          if (shownState == PlayerState.won)
            Positioned.fill(
              child: GestureDetector(
                onTap: _restart,
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      'Tum ne raasta dhoond liya.\n\nMautein: ${world.deaths}\n\nTap karo dobara khelne ke liye',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
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
