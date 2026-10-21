// Kahani ke chapters (STORY.md dekho). Jo chapter abhi bana nahi, us ka [level] null hai.
import 'world.dart';

class Chapter {
  final int number;
  final String title;
  final Level Function()? level;
  const Chapter(this.number, this.title, [this.level]);

  bool get ready => level != null;
}

final chapters = <Chapter>[
  Chapter(1, 'Shikaar', () => Level.first().slice(0, 2300, goal: 2280)),
  const Chapter(2, 'Aag'),
  const Chapter(3, 'Zanjeer'),
  Chapter(4, 'Toofan', () => Level.first().slice(2160, 7300, goal: 7150)),
  const Chapter(5, 'Peechha'),
  const Chapter(6, 'Wapsi'),
];
