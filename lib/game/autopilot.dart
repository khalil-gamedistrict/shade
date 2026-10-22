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
  final hazards = [...level.spikes, ...level.traps, ...level.fires];
  final danger = hazards.any((h) => h.overlaps(ahead.inflate(4)));
  // Saamne oonchi cheez (deewar, seedhi, gira patthar)
  final wall = solids.any((s) => s.overlaps(ahead) && s.top < feet - 3);
  // Saamne zameen khatam (gaddha)
  bool groundAt(double gx) => solids.any(
    (s) => gx >= s.left && gx <= s.right && (s.top - feet).abs() < 12,
  );
  final gap = !groundAt(x + 34);

  input.jump = danger || wall || gap;
  return input;
}
