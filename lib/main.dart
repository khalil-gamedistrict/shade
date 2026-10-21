import 'dart:async';

import 'package:flutter/material.dart';

import 'game.dart';

// CI build ke waqt --dart-define=BUILD_INFO=... se set hota hai
const buildInfo = String.fromEnvironment('BUILD_INFO', defaultValue: 'local');

void main() => runApp(const SnakeApp());

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SnakeGame game;
  Timer? timer;
  int best = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    game = SnakeGame();
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 150), (_) => _tick());
    setState(() {});
  }

  void _tick() {
    setState(() {
      game.step();
      if (game.over) {
        timer?.cancel();
        if (game.score > best) best = game.score;
      }
    });
  }

  void _onSwipe(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    if (v.dx.abs() > v.dy.abs()) {
      game.turn(v.dx > 0 ? Dir.right : Dir.left);
    } else {
      game.turn(v.dy > 0 ? Dir.down : Dir.up);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('🐍 Snake', style: Theme.of(context).textTheme.headlineMedium),
            Text('Score: ${game.score}   ·   Best: $best'),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: game.cols / game.rows,
                  child: GestureDetector(
                    onPanEnd: _onSwipe,
                    onTap: () => game.over ? _start() : null,
                    child: CustomPaint(painter: BoardPainter(game)),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: Text(
                game.over
                    ? 'Game Over — tap karo dobara khelne ke liye'
                    : 'Swipe karo direction badalne ke liye',
                style: TextStyle(
                  color: game.over ? Colors.redAccent : Colors.grey,
                ),
              ),
            ),
            Text(
              'Build: $buildInfo',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class BoardPainter extends CustomPainter {
  final SnakeGame game;
  BoardPainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / game.cols;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF111827),
    );

    Rect cellRect(Point p, double pad) => Rect.fromLTWH(
      p.x * cell + pad,
      p.y * cell + pad,
      cell - pad * 2,
      cell - pad * 2,
    );

    canvas.drawRect(
      cellRect(game.food, cell * 0.15),
      Paint()..color = Colors.redAccent,
    );
    for (var i = 0; i < game.snake.length; i++) {
      final color = i == 0 ? const Color(0xFF86EFAC) : const Color(0xFF22C55E);
      canvas.drawRect(cellRect(game.snake[i], 1), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
