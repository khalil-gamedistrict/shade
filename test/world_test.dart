import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shade/game/weather.dart';
import 'package:shade/game/world.dart';
import 'package:shade/main.dart';

// Chhota test level: zameen, ek spike, ek deewar, ek gaddha
Level testLevel() => const Level(
  solids: [
    Rect.fromLTWH(0, 400, 1500, 200),
    Rect.fromLTWH(500, 300, 40, 100),
    // gaddha 1500–1600
    Rect.fromLTWH(1600, 400, 400, 200),
  ],
  spikes: [Rect.fromLTWH(300, 384, 40, 16)],
  saws: [],
  checkpoints: [Offset(50, 400), Offset(200, 400)],
  goalX: 1800,
);

void main() {
  test('player zameen pe khara rehta hai, neeche nahi girta', () {
    final w = World(testLevel());
    w.update(1, Input());
    expect(w.pos.dy, 400);
    expect(w.grounded, isTrue);
  });

  test('right dabane se aagay chalta hai', () {
    final w = World(testLevel());
    w.update(0.5, Input()..right = true);
    expect(w.pos.dx, greaterThan(140));
  });

  test('jump sirf zameen se hota hai', () {
    final w = World(testLevel());
    w.update(0.1, Input()..jump = true);
    expect(w.pos.dy, lessThan(400));
  });

  test('deewar ke aar paar nahi ja sakta', () {
    final w = World(testLevel())..pos = const Offset(450, 400);
    w.update(1, Input()..right = true);
    expect(w.pos.dx, lessThanOrEqualTo(500 - World.playerW / 2));
  });

  test('spike pe marta hai aur checkpoint pe wapas aata hai', () {
    final w = World(testLevel());
    final input = Input()..right = true;
    w.update(1.5, input);
    expect(w.state, PlayerState.dead);
    expect(w.deaths, 1);

    w.update(World.respawnDelay + 0.1, Input());
    expect(w.state, PlayerState.alive);
    expect(w.pos.dx, 200); // doosra checkpoint guzar chuka tha
  });

  test('gaddhay mein girne se marta hai', () {
    final w = World(testLevel())..pos = const Offset(1550, 300);
    w.update(1, Input());
    expect(w.state, PlayerState.dead);
  });

  test('goal tak pohanchne pe jeet', () {
    final w = World(testLevel())..pos = const Offset(1700, 400);
    w.update(1, Input()..right = true);
    expect(w.state, PlayerState.won);
  });

  test('asal level mein pehla gaddha kood ke paar ho sakta hai', () {
    final w = World()..pos = const Offset(580, 400);
    final input = Input()
      ..right = true
      ..jump = true;
    w.update(0.05, input);
    input.jump = false;
    w.update(1, input);
    expect(w.state, PlayerState.alive);
    expect(w.pos.dx, greaterThan(700));
  });

  testWidgets('game screen khulti hai', (tester) async {
    await tester.pumpWidget(const ShadeApp(sound: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ShadeApp), findsOneWidget);
  });

  test('jump aur maut pe events bante hain (sound ke liye)', () {
    final w = World(testLevel());
    w.update(0.05, Input()..jump = true);
    expect(w.events, contains(GameEvent.jump));
    w.update(1.5, Input()..right = true);
    expect(
      w.events,
      containsAll([
        GameEvent.land,
        GameEvent.step,
        GameEvent.checkpoint,
        GameEvent.death,
      ]),
    );
  });

  test('profile beech ki values smooth nikalta hai', () {
    const p = Profile([(0, 0), (100, 1)]);
    expect(p.at(-50), 0);
    expect(p.at(50), closeTo(0.5, 0.001));
    expect(p.at(500), 1);
  });

  test('tez hawa chalte player ko dhakelti hai, khare ko nahi', () {
    const windy = Level(
      solids: [Rect.fromLTWH(0, 400, 3000, 200)],
      spikes: [],
      saws: [],
      checkpoints: [Offset(500, 400)],
      goalX: 2900,
      wind: Profile([(0, 1)]),
    );
    final still = World(windy)
      ..update(0.05, Input()); // pehle zameen pe tik jaye
    final x = still.pos.dx;
    still.update(1, Input());
    expect(still.pos.dx, x);

    final walking = World(windy);
    walking.update(1, Input()..right = true);
    expect(walking.pos.dx, greaterThan(500 + World.speed + 20));
  });

  test('asal level ke saare checkpoints zameen pe hain', () {
    final level = Level.first();
    for (final c in level.checkpoints) {
      final onGround = level.solids.any(
        (s) => s.top == c.dy && c.dx > s.left && c.dx < s.right,
      );
      expect(onGround, isTrue, reason: 'checkpoint $c');
    }
    expect(level.goalX, greaterThan(7000));
  });

  test('baarish wali jagah pe boondein banti hain aur bijli chamakti hai', () {
    final w = World()..pos = const Offset(5600, 300);
    final weather = Weather();
    var thunders = 0;
    weather.onThunder = (_) => thunders++;
    for (var i = 0; i < 60 * 30; i++) {
      weather.update(1 / 60, w, 5300, 1000);
    }
    expect(weather.rain, greaterThan(0.8));
    expect(weather.layers.last.active, greaterThan(100));
    expect(weather.splashes, isNotEmpty);
    expect(thunders, greaterThan(0));
  });
}
