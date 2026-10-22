// Kahani ke chapters (STORY.md dekho). Jo chapter abhi bana nahi, us ka [level] null hai.
import 'levels.dart';
import 'world.dart';

class Chapter {
  final int number;
  final String title;
  final Level Function()? level;
  const Chapter(this.number, this.title, [this.level]);

  bool get ready => level != null;
}

final chapters = <Chapter>[
  Chapter(1, 'The Hunt', () => Level.first().slice(0, 2300, goal: 2240)),
  const Chapter(2, 'Ashes', ashes),
  const Chapter(3, 'The River', river),
  Chapter(4, 'The Storm', () => Level.first().slice(2160, 7300, goal: 7050)),
  const Chapter(5, 'The Cliffs', cliffs),
  const Chapter(6, 'Homecoming', homecoming),
];
