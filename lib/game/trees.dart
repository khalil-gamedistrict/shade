// Code se bane darakht: tana → shaakhen → bareek tehniyan → patte.
// Har frame hawa ke hisaab se har hissa jhukta hai — oopar ki patli tehniyan zyada, tana kam.
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

class _Node {
  final int parent; // -1 = zameen
  final double
  angle; // parent ke hisaab se (radian, 0 = seedha upar, + = right)
  final double length, w0, w1;
  final int depth;
  final double phase; // har tehni apni marzi se hilti hai
  _Node(
    this.parent,
    this.angle,
    this.length,
    this.w0,
    this.w1,
    this.depth,
    this.phase,
  );
}

class _Leaf {
  final int node;
  final double along, angle, size, phase;
  _Leaf(this.node, this.along, this.angle, this.size, this.phase);
}

class Tree {
  final _nodes = <_Node>[];
  final _leaves = <_Leaf>[];
  final double stiffness; // mota tana kam hilta hai

  // Har frame ke hisaab kitaab ke liye (allocation se bachne ke liye pehle se bane)
  late final Float64List _ax, _ay, _bx, _by, _abs;

  /// [height] tane+shaakhon ki lambai, [maxDepth] kitni dafa shaakhen batengi,
  /// [leafiness] 0..1 kitne patte
  Tree(
    int seed, {
    double height = 420,
    int maxDepth = 7,
    double leafiness = 0.6,
    double thickness = 1,
  }) : stiffness = 0.8 + Random(seed).nextDouble() * 0.4 {
    final r = Random(seed);
    final baseW = height * (0.045 + r.nextDouble() * 0.02) * thickness;

    // Tana: kuch tukron mein, thora tedha mera, oopar jaate patla
    const trunkSegs = 5;
    final trunkH = height * (0.45 + r.nextDouble() * 0.15);
    var parent = -1;
    var w = baseW;
    var lean = (r.nextDouble() - 0.5) * 0.12;
    for (var i = 0; i < trunkSegs; i++) {
      final w1 = w * 0.84;
      _nodes.add(
        _Node(parent, lean, trunkH / trunkSegs, w, w1, 0, r.nextDouble() * 6),
      );
      parent = _nodes.length - 1;
      lean = (r.nextDouble() - 0.5) * 0.16;
      // Neeche wale hisson se kabhi kabhi ek sookhi chhoti shaakh
      if (i >= 2 && r.nextDouble() < 0.7) {
        final side = r.nextBool() ? 1 : -1;
        _branch(
          r,
          parent,
          side * (0.7 + r.nextDouble() * 0.5),
          height * (0.12 + r.nextDouble() * 0.12),
          w1 * 0.45,
          2,
          maxDepth - 1,
          leafiness,
        );
      }
      w = w1;
    }
    // Chhatri: oopar se 2-3 bari shaakhen
    final crown = 2 + r.nextInt(2);
    for (var i = 0; i < crown; i++) {
      final a = (i - (crown - 1) / 2) * 0.55 + (r.nextDouble() - 0.5) * 0.3;
      _branch(
        r,
        parent,
        a,
        height * (0.22 + r.nextDouble() * 0.08),
        w * 0.8,
        1,
        maxDepth,
        leafiness,
      );
    }

    final n = _nodes.length;
    _ax = Float64List(n);
    _ay = Float64List(n);
    _bx = Float64List(n);
    _by = Float64List(n);
    _abs = Float64List(n);
  }

  void _branch(
    Random r,
    int parent,
    double angle,
    double len,
    double w,
    int depth,
    int maxDepth,
    double leafiness,
  ) {
    final w1 = max(0.35, w * 0.68);
    final int me;
    if (depth <= 2) {
      // Moti shaakhen beech se thori mur'ti hain — asli lakri seedhi nahi hoti
      final wm = (w + w1) / 2;
      _nodes.add(
        _Node(parent, angle, len * 0.5, w, wm, depth, r.nextDouble() * 6.28),
      );
      _nodes.add(
        _Node(
          _nodes.length - 1,
          (r.nextDouble() - 0.5) * 0.45,
          len * 0.5,
          wm,
          w1,
          depth,
          r.nextDouble() * 6.28,
        ),
      );
    } else {
      _nodes.add(
        _Node(parent, angle, len, w, w1, depth, r.nextDouble() * 6.28),
      );
    }
    me = _nodes.length - 1;

    if (depth >= maxDepth || len < 6) {
      // Aakhri bareek tehni: patte
      if (r.nextDouble() < leafiness) {
        final count = 2 + r.nextInt(4);
        for (var i = 0; i < count; i++) {
          _leaves.add(
            _Leaf(
              me,
              0.35 + r.nextDouble() * 0.65,
              (r.nextDouble() - 0.5) * 2.6,
              3 + r.nextDouble() * 3.5,
              r.nextDouble() * 6.28,
            ),
          );
        }
      }
      return;
    }
    // Do (kabhi teen) hisson mein batna, thore be-tarteeb angles ke saath
    final kids = r.nextDouble() < 0.25 ? 3 : 2;
    final spread = 0.3 + r.nextDouble() * 0.4;
    for (var i = 0; i < kids; i++) {
      final a =
          (i - (kids - 1) / 2) * spread * 2 / (kids - 1).clamp(1, 2) +
          (r.nextDouble() - 0.5) * 0.35;
      // thora sa oopar ki taraf mur'na, jaise roshni ki taraf
      final towardsUp = -angle * 0.12;
      _branch(
        r,
        me,
        a + towardsUp,
        len * (0.66 + r.nextDouble() * 0.16),
        w1,
        depth + 1,
        maxDepth,
        leafiness,
      );
    }
  }

  /// Darakht ko [root] se, [wind] (-1..1) aur [time] ke hisaab se [path] mein add karta hai.
  void addTo(
    Path path,
    Offset root,
    double wind,
    double time, {
    double scale = 1,
  }) {
    final calm = 0.25 + wind.abs();
    for (var i = 0; i < _nodes.length; i++) {
      final n = _nodes[i];
      final d = n.depth + 1.0;
      // Hawa ka jhukaav (oopar wale hisse zyada) + apni marzi ka halka hilna
      final bend = wind * (0.012 + 0.016 * d) / stiffness;
      final flutter =
          sin(time * (1.3 + d * 0.45) + n.phase) * (0.004 + 0.01 * d) * calm;
      final double sx, sy, pa;
      if (n.parent < 0) {
        sx = root.dx;
        sy = root.dy;
        pa = 0;
      } else {
        sx = _bx[n.parent];
        sy = _by[n.parent];
        pa = _abs[n.parent];
      }
      final a = pa + n.angle + bend + flutter;
      _abs[i] = a;
      final len = n.length * scale;
      _ax[i] = sx;
      _ay[i] = sy;
      _bx[i] = sx + sin(a) * len;
      _by[i] = sy - cos(a) * len;

      // Tapered tukra: neeche mota, oopar patla
      final px = cos(a), py = sin(a);
      final h0 = n.w0 * scale / 2, h1 = n.w1 * scale / 2;
      _poly(path, [
        Offset(sx - px * h0, sy - py * h0),
        Offset(sx + px * h0, sy + py * h0),
        Offset(_bx[i] + px * h1, _by[i] + py * h1),
        Offset(_bx[i] - px * h1, _by[i] - py * h1),
      ]);
      // Moti shaakhon ke jor gol, taake tukre nazar na aayen
      if (n.depth <= 2 && h0 > 1.2) {
        path.addOval(Rect.fromCircle(center: Offset(sx, sy), radius: h0));
      }
    }

    // Patte: tehni pe lage, hawa mein tezi se phar-phar
    final flap = 3.5 + wind.abs() * 7;
    for (final l in _leaves) {
      final i = l.node;
      final bx = _ax[i] + (_bx[i] - _ax[i]) * l.along;
      final by = _ay[i] + (_by[i] - _ay[i]) * l.along;
      final a =
          _abs[i] +
          l.angle +
          wind * 0.6 +
          sin(time * flap + l.phase) * (0.15 + wind.abs() * 0.5);
      final s = l.size * scale;
      final dx = sin(a), dy = -cos(a);
      final tip = Offset(bx + dx * s, by + dy * s);
      final mid = Offset(bx + dx * s * 0.45, by + dy * s * 0.45);
      final side = Offset(-dy * s * 0.22, dx * s * 0.22);
      _poly(path, [Offset(bx, by), mid + side, tip, mid - side]);
    }
  }

  /// Saari shakalein ek hi direction (clockwise) mein, warna jahan do overlap
  /// hon wahan path mein "surakh" ban jata hai (nonZero fill rule)
  static void _poly(Path path, List<Offset> p) {
    final cross =
        (p[1].dx - p[0].dx) * (p[2].dy - p[1].dy) -
        (p[1].dy - p[0].dy) * (p[2].dx - p[1].dx);
    path.addPolygon(cross >= 0 ? p : p.reversed.toList(), true);
  }
}

/// Ek parallax layer ke darakht: [spacing] ke faasle pe, seed se hamesha same jagah
class TreeLayer {
  final double parallax, spacing, scale;
  final int maxDepth, seed;
  final double leafiness, minHeight, maxHeight, thickness;
  final Color color;

  /// Door ki layers mein sirf itne alag darakht (aadhe ulte/mirror) — memory bachane ke liye
  final int? variants;
  final _cache = <int, Tree>{};

  TreeLayer({
    required this.parallax,
    required this.spacing,
    required this.color,
    required this.seed,
    this.scale = 1,
    this.maxDepth = 7,
    this.leafiness = 0.6,
    this.minHeight = 380,
    this.maxHeight = 520,
    this.thickness = 1,
    this.variants,
  });

  int variantOf(int i) => variants == null ? i : i % variants!;
  bool mirrored(int i) => variants != null && (i ~/ variants!).isOdd;

  /// Layer ke darakhton ki x jagahen (layer coordinates) jo [from]..[to] mein hain
  Iterable<(int, double)> visible(double from, double to) sync* {
    final first = (from / spacing).floor() - 1;
    final last = (to / spacing).ceil() + 1;
    for (var i = first; i <= last; i++) {
      final jitter = Random(i * 7919 + seed).nextDouble() * spacing * 0.7;
      yield (i, i * spacing + jitter);
    }
  }

  Tree tree(int i) {
    if (_cache.length > 64) _cache.clear();
    return _cache.putIfAbsent(i, () {
      final r = Random(i * 104729 + seed);
      return Tree(
        i * 31 + seed,
        height: minHeight + r.nextDouble() * (maxHeight - minHeight),
        maxDepth: maxDepth,
        leafiness: leafiness,
        thickness: thickness,
      );
    });
  }
}
