// Snake game ki logic — Flutter UI se alag, taake asaani se test ho sake.
import 'dart:math';

enum Dir { up, down, left, right }

class Point {
  final int x, y;
  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Point && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class SnakeGame {
  final int cols, rows;
  final Random _rng;
  late List<Point> snake;
  late Point food;
  Dir dir = Dir.right;
  Dir _nextDir = Dir.right;
  int score = 0;
  bool over = false;

  SnakeGame({this.cols = 20, this.rows = 20, Random? rng})
    : _rng = rng ?? Random() {
    final mid = Point(cols ~/ 2, rows ~/ 2);
    snake = [mid, Point(mid.x - 1, mid.y), Point(mid.x - 2, mid.y)];
    food = _placeFood();
  }

  Dir get nextDir => _nextDir;

  void turn(Dir d) {
    // Ulta mur kar khud ko nahi kha sakte
    const opposite = {
      Dir.up: Dir.down,
      Dir.down: Dir.up,
      Dir.left: Dir.right,
      Dir.right: Dir.left,
    };
    if (opposite[dir] != d) _nextDir = d;
  }

  void step() {
    if (over) return;
    dir = _nextDir;
    final h = snake.first;
    final head = switch (dir) {
      Dir.up => Point(h.x, h.y - 1),
      Dir.down => Point(h.x, h.y + 1),
      Dir.left => Point(h.x - 1, h.y),
      Dir.right => Point(h.x + 1, h.y),
    };

    final hitWall =
        head.x < 0 || head.y < 0 || head.x >= cols || head.y >= rows;
    if (hitWall || snake.contains(head)) {
      over = true;
      return;
    }

    snake.insert(0, head);
    if (head == food) {
      score++;
      food = _placeFood();
    } else {
      snake.removeLast();
    }
  }

  Point _placeFood() {
    final free = [
      for (var y = 0; y < rows; y++)
        for (var x = 0; x < cols; x++)
          if (!snake.contains(Point(x, y))) Point(x, y),
    ];
    return free[_rng.nextInt(free.length)];
  }
}
