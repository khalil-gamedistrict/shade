import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
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
    await tester.pumpWidget(const ShadeApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ShadeApp), findsOneWidget);
  });
}
