// Asli jaisi ghaas: gucchon mein, patli muri hui pattiyan, alag alag lambai,
// kahin kahin lambi dandi pe beej ki baali. Hawa mein lambi patti zyada jhukti hai.
import 'dart:math';
import 'dart:ui';

/// x ke liye hamesha same "random" number 0..1 (taake ghaas har frame wahi rahe)
double _rand(int i, int salt) {
  final h = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return h - h.floorToDouble();
}

class Grass {
  static const cell = 5.5; // har itne faasle pe ek guccha ho sakta hai

  /// [top] zameen ki sateh, [from]..[to] dikhne wala hissa, [windAt] har jagah ki hawa
  static void addTo(
    Path path,
    double top,
    double left,
    double right,
    double from,
    double to,
    double Function(double x) windAt,
    double time,
  ) {
    final a = max(left, from), b = min(right, to);
    if (a >= b) return;

    _turf(path, top, a, b);

    for (var i = (a / cell).floor(); i * cell < b; i++) {
      if (_rand(i, 1) > 0.85) continue; // kahin kahin khaali jagah
      final x = i * cell + _rand(i, 2) * cell;
      if (x < left + 2 || x > right - 2) continue;
      final wind = windAt(x);
      // Guccha: kuch pattiyan ek jagah se phaili hui
      final blades = 4 + (_rand(i, 3) * 7).floor();
      // Lambai dheere dheere badalti hai — kahin ghaas oonchi, kahin chhoti
      final patch = 0.6 + 0.4 * sin(x * 0.013) * sin(x * 0.0071 + 2);
      final clumpH = (9 + _rand(i, 4) * 14) * patch;
      for (var k = 0; k < blades; k++) {
        final r1 = _rand(i * 13 + k, 5), r2 = _rand(i * 13 + k, 6);
        final spread = (k / max(1, blades - 1) - 0.5) * 1.1 + (r1 - 0.5) * 0.4;
        final h = clumpH * (0.55 + r2 * 0.7);
        _blade(
          path,
          x + (r1 - 0.5) * 3,
          top + 1.5,
          h,
          0.9 + r2 * 1.1,
          spread,
          wind,
          time,
          i * 7 + k,
        );
      }
      // Kabhi kabhi ek lambi dandi beej ki baali ke saath
      if (_rand(i, 7) < 0.12) {
        final h = 28 + _rand(i, 8) * 18;
        final tip = _blade(
          path,
          x,
          top + 1.5,
          h,
          0.55,
          (_rand(i, 9) - 0.5) * 0.4,
          wind,
          time,
          i * 11,
        );
        final lean = wind * 0.7 + (_rand(i, 9) - 0.5) * 0.4;
        _seedHead(path, tip, lean, 3 + _rand(i, 10) * 2.5);
      }
    }
  }

  /// Ek patti: neeche chauri, oopar nukeeli, beech se muri hui. Nok ki jagah wapas karta hai.
  static Offset _blade(
    Path path,
    double x,
    double y,
    double h,
    double w,
    double angle,
    double wind,
    double time,
    int seed,
  ) {
    final phase = _rand(seed, 12) * 6.28;
    // Lambi patti hawa mein zyada jhukti hai (h^1.5), aur apni marzi se halka hilti bhi hai
    final sway =
        wind * pow(h, 1.5) * 0.14 +
        sin(time * (2.2 + wind.abs() * 4.5) + phase + x * 0.05) *
            h *
            (0.05 + wind.abs() * 0.1);
    final tip = Offset(
      x + sin(angle) * h + sway,
      y - cos(angle) * h * (1 - min(0.35, (sway.abs() / h) * 0.3)),
    );
    // Mor: beech ka point seedha upar ki taraf, nok sway ki taraf → patti ka qudrati kham
    final ctrl = Offset(x + sin(angle) * h * 0.35 + sway * 0.25, y - h * 0.6);
    path
      ..moveTo(x - w, y)
      ..quadraticBezierTo(ctrl.dx - w * 0.4, ctrl.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(ctrl.dx + w * 0.4, ctrl.dy, x + w, y)
      ..close();
    return tip;
  }

  /// Beej ki baali: dandi ki nok pe chhote chhote daane
  static void _seedHead(Path path, Offset tip, double lean, double len) {
    for (var j = 0; j < 4; j++) {
      final t = j / 3;
      final c = Offset(
        tip.dx + sin(lean) * len * t,
        tip.dy - cos(lean) * len * t,
      );
      path.addOval(Rect.fromCenter(center: c, width: 1.6, height: 2.6));
    }
  }

  /// Zameen ka kinara bilkul seedha nahi hota — chhote chhote ubhaar
  static void _turf(Path path, double top, double a, double b) {
    path.moveTo(a, top + 2);
    for (var x = a; x <= b; x += 3) {
      final bump = (sin(x * 0.11) * 0.6 + sin(x * 0.37 + 1.7) * 0.4 + 1) * 1.3;
      path.lineTo(x, top - bump);
    }
    path
      ..lineTo(b, top + 2)
      ..close();
  }
}
