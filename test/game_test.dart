import 'package:flutter_test/flutter_test.dart';
import 'package:snake_game/game.dart';
import 'package:snake_game/main.dart';

void main() {
  test('snake aagay chalta hai', () {
    final g = SnakeGame(cols: 10, rows: 10);
    final head = g.snake.first;
    g.food = const Point(0, 0);
    g.step();
    expect(g.snake.first, Point(head.x + 1, head.y));
    expect(g.snake.length, 3);
  });

  test('khana kha kar snake lamba hota hai aur score barhta hai', () {
    final g = SnakeGame(cols: 10, rows: 10);
    g.food = Point(g.snake.first.x + 1, g.snake.first.y);
    g.step();
    expect(g.snake.length, 4);
    expect(g.score, 1);
  });

  test('deewar se takrane pe game over', () {
    final g = SnakeGame(cols: 10, rows: 10);
    g.food = const Point(0, 0);
    for (var i = 0; i < 10; i++) {
      g.step();
    }
    expect(g.over, isTrue);
  });

  test('ulta nahi mur sakta', () {
    final g = SnakeGame(cols: 10, rows: 10);
    g.turn(Dir.left);
    expect(g.nextDir, Dir.right);
  });

  testWidgets('app khulti hai aur score dikhata hai', (tester) async {
    await tester.pumpWidget(const SnakeApp());
    expect(find.textContaining('Score: 0'), findsOneWidget);
  });
}
