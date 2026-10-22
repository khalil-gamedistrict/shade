// Trailer ke liye khud chalne wala hero: aagay khatra, gaddha ya deewar dekh kar koodta hai
import 'dart:ui' show Rect;

import 'world.dart';

/// [stopAt] tak right chalta hai, phir ruk jata hai
Input autopilot(World w, {double stopAt = double.infinity}) {
  final input = Input()..right = w.pos.dx < stopAt;
  if (!w.grounded || !input.right) return input;

  final x = w.pos.dx, feet = w.pos.dy;
  final ahead = Rect.fromLTRB(x + 12, feet - 60, x + 50, feet + 1);
  final level = w.level;
  final solids = w.solidsNow();

  // Khatra saamne
  final hazards = [
    ...level.spikes,
    ...level.traps,
    ...level.fires,
    for (final p in level.pools)
      if (p.deep) Rect.fromLTRB(p.left, p.surface - 4, p.right, p.surface + 60),
  ];
  final danger = hazards.any((h) => h.overlaps(ahead.inflate(4)));
  // Saamne oonchi cheez (deewar, seedhi, giri shaakh)
  final rise = level.terrainTop(x + 16);
  final wall =
      solids.any((s) => s.overlaps(ahead) && s.top < feet - 3) ||
      (rise != null && rise < feet - World.stepUp);
  // Saamne zameen khatam (gaddha)
  // Dhalan pe neeche utarna gaddha nahi — sirf jahan aagay zameen hi na ho (ya bohot neeche)
  bool groundAt(double gx) {
    final t = level.terrainTop(gx);
    if (t != null && t - feet < 40) return true;
    return solids.any(
      (s) => gx >= s.left && gx <= s.right && (s.top - feet).abs() < 12,
    );
  }

  final gap = !groundAt(x + 34);

  input.jump = danger || wall || gap;
  return input;
}
