// Jungle ke paude — code se bane silhouette. Har function shakalein (Path) wapas karta hai,
// jo ek dafa tasveer ban jaati hain (jungle.dart), phir sirf hawa mein jhulayi jaati hain.
// Sab shakalein root (0,0) ke hisaab se: y manfi = oopar.
import 'dart:math';
import 'dart:ui';

Offset _bez(Offset a, Offset c, Offset b, double t) {
  final u = 1 - t;
  return a * (u * u) + c * (2 * u * t) + b * (t * t);
}

/// Patla tapered tukra (dandi/tehni)
Path _stem(List<Offset> pts, double w0, double w1) {
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i < pts.length; i++) {
    final a = pts[max(0, i - 1)], b = pts[min(pts.length - 1, i + 1)];
    final d = b - a;
    final len = max(1e-6, d.distance);
    final n = Offset(-d.dy / len, d.dx / len);
    final w = (w0 + (w1 - w0) * i / (pts.length - 1)) / 2;
    left.add(pts[i] + n * w);
    right.add(pts[i] - n * w);
  }
  return Path()..addPolygon([...left, ...right.reversed], true);
}

/// Nukeela patta: [base] se [angle] ki taraf, lambai [len], chaurai [width]
Path _leaf(Offset base, double angle, double len, double width) {
  final d = Offset(sin(angle), -cos(angle));
  final n = Offset(-d.dy, d.dx);
  final tip = base + d * len;
  return Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(
      (base + d * len * 0.45 + n * width).dx,
      (base + d * len * 0.45 + n * width).dy,
      tip.dx,
      tip.dy,
    )
    ..quadraticBezierTo(
      (base + d * len * 0.45 - n * width).dx,
      (base + d * len * 0.45 - n * width).dy,
      base.dx,
      base.dy,
    )
    ..close();
}

/// Fern: zameen se phaili hui muri dandiyan, har dandi pe dono taraf chhoti pattiyan
List<Path> fern(int seed, double size) {
  final r = Random(seed);
  final out = <Path>[];
  final fronds = 6 + r.nextInt(5);
  for (var f = 0; f < fronds; f++) {
    final spread = (f / (fronds - 1) - 0.5) * 2; // -1..1
    final a = spread * 1.25 + (r.nextDouble() - 0.5) * 0.25;
    final len = size * (0.65 + r.nextDouble() * 0.4) * (1 - spread.abs() * 0.2);
    // Bahar wali dandiyan zyada jhuki hui
    final end = Offset(
      sin(a) * len * 1.05,
      -cos(a) * len * 0.55 + spread.abs() * len * 0.35,
    );
    final ctrl = Offset(sin(a) * len * 0.35, -len * 0.75);
    final pts = [
      for (var i = 0; i <= 14; i++) _bez(Offset.zero, ctrl, end, i / 14),
    ];
    out.add(_stem(pts, 1.8, 0.4));
    for (var i = 2; i < pts.length; i++) {
      final t = i / pts.length;
      final d = pts[min(pts.length - 1, i + 1)] - pts[i - 1];
      final dir = atan2(d.dx, -d.dy);
      final pl = size * 0.16 * (1 - t * 0.75);
      for (final side in [-1, 1]) {
        out.add(_leaf(pts[i], dir + side * (1.0 - t * 0.3), pl, pl * 0.28));
      }
    }
  }
  return out;
}

/// Jhaari: beech mein bhara hua gol guccha, kinaron pe alag alag patte
List<Path> bush(int seed, double size) {
  final r = Random(seed);
  final out = <Path>[];
  final w = size * (1.1 + r.nextDouble() * 0.5),
      h = size * (0.6 + r.nextDouble() * 0.3);
  // Bhara hua beech (taake jhaari ke beech se aasmaan na dikhe)
  for (var k = 0; k < 5; k++) {
    final cx = (r.nextDouble() - 0.5) * w * 0.6;
    final rr = h * (0.35 + r.nextDouble() * 0.2);
    out.add(
      Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, -rr * 0.8), radius: rr)),
    );
  }
  // Kinaron pe patte
  final leaves = 160 + r.nextInt(80);
  for (var k = 0; k < leaves; k++) {
    final t = r.nextDouble() * pi;
    final rad = sqrt(r.nextDouble()) * 0.35 + 0.7;
    final p = Offset(cos(t) * w * 0.5 * rad, -sin(t) * h * rad);
    final ls = size * (0.05 + r.nextDouble() * 0.07);
    out.add(
      _leaf(
        p,
        atan2(p.dx, -p.dy) + (r.nextDouble() - 0.5) * 1.6,
        ls,
        ls * 0.35,
      ),
    );
  }
  return out;
}

/// Bare chaure patton wala paudha (tasveer jaise jungle ke)
List<Path> broadleaf(int seed, double size) {
  final r = Random(seed);
  final out = <Path>[];
  final n = 3 + r.nextInt(4);
  for (var k = 0; k < n; k++) {
    final spread = n == 1 ? 0.0 : (k / (n - 1) - 0.5) * 2;
    final a = spread * 0.9 + (r.nextDouble() - 0.5) * 0.3;
    final stemLen = size * (0.45 + r.nextDouble() * 0.35);
    final end = Offset(sin(a) * stemLen, -cos(a) * stemLen);
    final ctrl = Offset(sin(a) * stemLen * 0.2, -stemLen * 0.7);
    final pts = [
      for (var i = 0; i <= 10; i++) _bez(Offset.zero, ctrl, end, i / 10),
    ];
    out.add(_stem(pts, 2.4, 1.2));
    // Patta neeche ki taraf latka hua
    final leafLen = size * (0.24 + r.nextDouble() * 0.1);
    out.add(
      _leaf(
        end,
        a +
            spread.sign * (0.9 + r.nextDouble() * 0.7) +
            (spread == 0 ? 0.6 : 0),
        leafLen,
        leafLen * 0.38,
      ),
    );
  }
  return out;
}

/// Oopar se latakti bail: halki si jhol, chhote patte, neeche se mur'ti hui
List<Path> vine(int seed, double length) {
  final r = Random(seed);
  final out = <Path>[];
  final sag = (r.nextDouble() - 0.5) * length * 0.25;
  final end = Offset(sag * 0.4, length);
  final ctrl = Offset(sag, length * 0.5);
  final pts = [
    for (var i = 0; i <= 24; i++) _bez(Offset.zero, ctrl, end, i / 24),
  ];
  out.add(_stem(pts, 2.2, 1.0));
  for (var i = 2; i < pts.length; i += 1) {
    if (r.nextDouble() < 0.15) continue;
    final side = i.isEven ? 1 : -1;
    final ls = 5 + r.nextDouble() * 6;
    out.add(
      _leaf(pts[i], pi + side * (0.6 + r.nextDouble() * 0.6), ls, ls * 0.4),
    );
  }
  // Neeche ka chhota kunda (curl)
  final tip = pts.last;
  final curl = [
    for (var i = 0; i <= 8; i++)
      tip + Offset(sin(i / 8 * 4) * 6, cos(i / 8 * 4) * -6 + 6),
  ];
  out.add(_stem(curl, 1.0, 0.4));
  return out;
}
