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

// Mushkil 10 "sets" mein barhti hai — har set mein 2 chapter taqreeban barabar mushkil,
// phir agla set un se mushkil-tar (shikaari tez, qareeb, zyada aur zyada nishane wale neze).
// Set 1 (1–2) ~114 · Set 2 (3–4) ~122 · Set 3 (5–6) ~130 · Set 4 (7–8) ~137 · Set 5 (9–10) ~140
// Set 6 (11–12) ~142 · Set 7 (13–14) ~144 · Set 8 (15–16) ~146 · Set 9 (17–18) ~147.5
// Set 10 (19–20) ~149 (World.speed = 150 ke bohot qareeb — aakhri, sab se mushkil).
// (Khatron ki tadaad bhi set ke hisaab se barhti hai — levels.dart.)
const stormChase = Chase(
  startX: 100,
  speed: 122,
  maxBehind: 510,
  throwEvery: 3.8,
  aimEvery: 3,
);

final chapters = <Chapter>[
  const Chapter(1, 'The Hunt', hunt),
  const Chapter(2, 'Ashes', ashes),
  const Chapter(3, 'The River', river),
  Chapter(
    4,
    'The Storm',
    () => Level.first().slice(2160, 7300, goal: 7050, chase: stormChase),
  ),
  const Chapter(5, 'The Cliffs', cliffs),
  const Chapter(6, 'The Thicket', theThicket),
  const Chapter(7, 'The Swamp', theSwamp),
  const Chapter(8, 'The Ravine', theRavine),
  const Chapter(9, 'The Flood', theFlood),
  const Chapter(10, 'The Hollow', theHollow),
  const Chapter(11, 'The Web', theWeb),
  const Chapter(12, 'The Ruins', theRuins),
  const Chapter(13, 'The Crushers', theCrushers),
  const Chapter(14, 'The Undertow', theUndertow),
  const Chapter(15, 'The Spire', theSpire),
  const Chapter(16, 'The Hunting Ground', theHuntingGround),
  const Chapter(17, 'The Last Light', theLastLight),
  const Chapter(18, 'The Narrow Path', theNarrowPath),
  const Chapter(19, 'The Deep', theDeep),
  const Chapter(20, 'Homecoming', homecoming),
];

// Chapter "Home" (rangeen subah, qabeela shikaariyon ko bhaga deta hai): tajrubaati tha,
// filhaal active list se bahar hai. Level function (`home()`) levels.dart ke aakhir mein
// mojood hai — zaroorat padi to baad mein wapas list mein shamil ho sakta hai.
