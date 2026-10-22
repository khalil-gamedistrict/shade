import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shade/game/autopilot.dart';
import 'package:shade/game/chapters.dart';
import 'package:shade/game/levels.dart';
import 'package:shade/game/weather.dart';
import 'package:shade/game/world.dart';
import 'package:shade/main.dart';
import 'package:shade/ui/menu.dart';
import 'package:shade/ui/trailer.dart';

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
    expect(w.pos.dx, greaterThan(110));
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
    w.update(2.5, input);
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
    final w = World()..pos = const Offset(505, 400);
    final input = Input()
      ..right = true
      ..jump = true;
    w.update(0.05, input);
    input.jump = false;
    w.update(1.2, input);
    expect(w.state, PlayerState.alive);
    expect(w.pos.dx, greaterThan(640));
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
    w.update(2.5, Input()..right = true);
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

  test('hilta platform pe khare player ko saath le jata hai', () {
    const level = Level(
      solids: [Rect.fromLTWH(0, 400, 100, 200)],
      spikes: [],
      saws: [],
      movers: [Mover(Rect.fromLTWH(200, 300, 100, 18), dx: 80, speed: 1)],
      checkpoints: [Offset(250, 300)],
      goalX: 5000,
    );
    final w = World(level)..update(0.05, Input());
    expect(w.grounded, isTrue);
    final x0 = w.pos.dx;
    w.update(1, Input());
    // Platform sin(t) se chalta hai: 1 second mein ~67 units right
    expect(w.pos.dx - x0, greaterThan(40));
    expect(w.state, PlayerState.alive);
  });

  test('patthar paas jaane pe girta hai, neeche khare ko maarta hai, phir rasta rokta hai', () {
    const level = Level(
      solids: [Rect.fromLTWH(0, 400, 2000, 200)],
      spikes: [],
      saws: [],
      rocks: [Rock(300, 250)],
      checkpoints: [Offset(50, 400), Offset(200, 400)],
      goalX: 1900,
    );
    // Neeche khara rahe to marega
    final under = World(level)..pos = const Offset(300, 400);
    under.update(2, Input());
    expect(under.state, PlayerState.dead);

    // Paas aa kar ruk jaye to patthar aagay gir kar rukawat ban jata hai
    final w = World(level)..pos = const Offset(260, 400);
    w.update(2, Input());
    expect(w.rockState[0], 2);
    expect(w.events, contains(GameEvent.rock));
    w.update(1, Input()..right = true);
    expect(w.pos.dx, lessThan(300 - 16)); // patthar ke paar nahi gaya
    expect(w.state, PlayerState.alive);
  });

  test('jhoolta lakkar aur shikanja maarte hain', () {
    const level = Level(
      solids: [Rect.fromLTWH(0, 400, 2000, 200)],
      spikes: [],
      saws: [],
      traps: [Rect.fromLTWH(600, 390, 34, 10)],
      pendulums: [Pendulum(Offset(300, 200), 175, amplitude: 0.0001)],
      checkpoints: [Offset(50, 400)],
      goalX: 1900,
    );
    expect(
      (World(level)
            ..pos = const Offset(300, 400)
            ..update(0.1, Input()))
          .state,
      PlayerState.dead,
    );
    expect(
      (World(level)
            ..pos = const Offset(615, 400)
            ..update(0.1, Input()))
          .state,
      PlayerState.dead,
    );
  });

  test('asal level ka har khaali gaddha nayi jump se paar ho sakta hai', () {
    expectJumpable(Level.first());
  });

  test('har bana hua chapter theek hai: checkpoint zameen pe, gaddhay paar, goal pe zameen', () {
    for (final c in chapters.where((c) => c.ready)) {
      final level = c.level!();
      expect(
        level.checkpoints.first,
        const Offset(100, 400),
        reason: 'chapter ${c.number}',
      );
      for (final cp in level.checkpoints) {
        final onGround = level.solids.any(
          (s) => s.top == cp.dy && cp.dx > s.left && cp.dx < s.right,
        );
        expect(onGround, isTrue, reason: 'chapter ${c.number} checkpoint $cp');
      }
      expect(
        level.solids.any((s) => level.goalX > s.left && level.goalX < s.right),
        isTrue,
        reason: 'chapter ${c.number} goal',
      );
      expectJumpable(level);
    }
    expect(chapters.length, 6);
  });

  group('peechha', () {
    Level chaseLevel() => const Level(
      solids: [Rect.fromLTWH(-1000, 400, 4000, 200)],
      spikes: [],
      saws: [],
      checkpoints: [Offset(100, 400)],
      goalX: 2900,
      chase: Chase(startX: 100),
    );

    test('khara rahe to shikaari pakar lete hain', () {
      final w = World(chaseLevel());
      w.update(0.1, Input());
      expect(w.chaseActive, isTrue);
      expect(w.events, contains(GameEvent.chaseStart));
      w.update(9, Input()); // daur kar pahunchna + larai + maut
      expect(
        w.deaths,
        greaterThanOrEqualTo(1),
      ); // pakra gaya (phir checkpoint pe zinda)
    });

    test('daurta rahe to shikaari nahi pakar paate', () {
      final w = World(chaseLevel());
      final run = Input()..right = true;
      for (var i = 0; i < 100; i++) {
        w.update(0.1, run);
        w.spears.clear(); // sirf daud naap rahe hain, neze nahi
      }
      expect(w.state, PlayerState.alive);
      expect(w.pos.dx - w.hunterX, greaterThan(26));
    });

    test('shikaari neze phenkte hain, aur khare player ko lagta hai', () {
      // Player oonchi chattan pe (jump se oonchi) — shikaari chadh kar pakar nahi sakte, sirf neze
      const level = Level(
        solids: [
          Rect.fromLTWH(-1000, 400, 4000, 200),
          Rect.fromLTWH(400, 260, 200, 140),
        ],
        spikes: [],
        saws: [],
        checkpoints: [Offset(500, 260)],
        goalX: 2900,
        chase: Chase(startX: 100),
      );
      final w = World(level);
      var thrown = false;
      var hit = false;
      for (var i = 0; i < 160 && !hit; i++) {
        // har teesra neza nishane pe
        w.update(0.1, Input());
        thrown = thrown || w.events.contains(GameEvent.spearThrow);
        hit = hit || w.events.contains(GameEvent.spearHit);
      }
      expect(thrown, isTrue);
      expect(hit, isTrue);
    });

    test('bare gaddhay (hilte platform wale) pe shikaari ruk jate hain', () {
      const level = Level(
        solids: [
          Rect.fromLTWH(-1000, 400, 1500, 200),
          Rect.fromLTWH(800, 400, 2000, 200),
        ],
        spikes: [],
        saws: [],
        movers: [Mover(Rect.fromLTWH(600, 380, 80, 18))],
        checkpoints: [Offset(100, 400)],
        goalX: 2700,
        chase: Chase(startX: 100),
      );
      final w = World(level)..update(0.1, Input());
      w.pos = const Offset(900, 400); // player gaddha paar kar chuka
      w.update(0.5, Input());
      expect(w.hunterX, lessThanOrEqualTo(500 - 40));
    });

    test('marne ke baad shikaari mohlat dete hain', () {
      final w = World(chaseLevel());
      while (w.state != PlayerState.dead) {
        w.update(0.05, Input()); // khara raha: pakra gaya, larai, maut
      }
      w.update(World.respawnDelay + 0.05, Input());
      expect(w.state, PlayerState.alive);
      expect(w.pos.dx - w.hunterX, greaterThan(500));
    });
  });

  group('maut aur naye chapters', () {
    test('aag chhoone se jal kar marta hai', () {
      const level = Level(
        solids: [Rect.fromLTWH(-500, 400, 2000, 200)],
        spikes: [],
        saws: [],
        fires: [Rect.fromLTWH(300, 384, 60, 16)],
        checkpoints: [Offset(100, 400)],
        goalX: 1400,
      );
      final w = World(level);
      w.update(2.5, Input()..right = true);
      expect(w.deaths, 1);
      expect(w.deathKind, DeathKind.burn);
    });

    test(
      'darya mein gire to doob jata hai, aur doobta hua neeche jata hai',
      () {
        final w = World(river())..pos = const Offset(645, 300);
        w.update(0.6, Input());
        expect(w.state, PlayerState.dead);
        expect(w.deathKind, DeathKind.drown);
        final y = w.pos.dy;
        w.update(0.5, Input());
        expect(w.pos.dy, greaterThan(y)); // aahista neeche
      },
    );

    test('neza peeche se lage to aagay ki taraf girta hai', () {
      const level = Level(
        solids: [Rect.fromLTWH(-500, 400, 2000, 200)],
        spikes: [],
        saws: [],
        checkpoints: [Offset(500, 400)],
        goalX: 1400,
      );
      final w = World(level)..update(0.05, Input());
      w.spears.add(Spear(480, 380, 300, 0));
      w.update(0.1, Input());
      expect(w.deathKind, DeathKind.spear);
      expect(w.fallDir, 1);
    });

    test('har chapter bina masle ke chalta hai (10 second daud)', () {
      for (final c in chapters) {
        final w = World(c.level!());
        final run = Input()..right = true;
        for (var i = 0; i < 200; i++) {
          run.jump = i % 15 == 0;
          w.update(0.05, run);
        }
        expect(w.time, greaterThan(9.9), reason: c.title);
      }
    });

    test('chapter naam English mein', () {
      expect(chapters.map((c) => c.title), [
        'The Hunt',
        'Ashes',
        'The River',
        'The Storm',
        'The Cliffs',
        'Homecoming',
      ]);
    });
  });

  group('trailer aur lock', () {
    test('chapter tabhi khulta hai jab pichhla paar ho', () {
      final p = Progress(unlockAll: false); // release jaisa
      expect(p.unlocked(1), isTrue);
      expect(p.unlocked(2), isFalse);
      p.done.add(1);
      expect(p.unlocked(2), isTrue);
      expect(p.unlocked(3), isFalse);
    });

    test('trailer ke har shot mein hero khud aage barhta hai, gaddhay mein nahi girta', () {
      for (final shot in trailerShots) {
        final w = World(shot.level())
          ..pos = shot.start
          ..cinematic = true;
        for (var t = 0.0; t < shot.duration; t += 1 / 60) {
          w.update(1 / 60, t >= shot.runAt ? autopilot(w) : Input());
        }
        expect(w.pos.dy, lessThanOrEqualTo(410), reason: 'shot ${shot.start}');
        expect(
          w.pos.dx,
          greaterThan(shot.start.dx + 100),
          reason: 'shot ${shot.start}',
        );
      }
    });
  });

  group('har maut ka apna andaaz', () {
    Level flat({
      List<Rect> spikes = const [],
      List<Rect> traps = const [],
      List<Saw> saws = const [],
      List<Pendulum> pendulums = const [],
      List<Rock> rocks = const [],
    }) => Level(
      solids: const [Rect.fromLTWH(-1000, 400, 4000, 200)],
      spikes: spikes,
      traps: traps,
      saws: saws,
      pendulums: pendulums,
      rocks: rocks,
      checkpoints: const [Offset(500, 400)],
      goalX: 2900,
    );

    World runInto(Level level, {double x = 500}) {
      final w = World(level)..pos = Offset(x, 400);
      for (var i = 0; i < 120 && w.state == PlayerState.alive; i++) {
        w.update(1 / 60, Input());
      }
      return w;
    }

    test('har khatra apni qism ki maut deta hai', () {
      expect(
        runInto(flat(spikes: [const Rect.fromLTWH(490, 384, 20, 16)]))
            .deathKind,
        DeathKind.spike,
      );
      final trapped = runInto(
        flat(traps: [const Rect.fromLTWH(490, 390, 34, 10)]),
      );
      expect(trapped.deathKind, DeathKind.trap);
      expect(trapped.closedTrap, 0); // shikanja band hua
      expect(
        runInto(flat(saws: [const Saw(500, 370, range: 0)])).deathKind,
        DeathKind.saw,
      );
      expect(
        runInto(flat(rocks: [const Rock(500, 0)])).deathKind,
        DeathKind.rock,
      );
    });

    test('bhaari lakkar hawa mein uchhaal kar door phenkta hai, jism zameen pe aa kar rukta hai', () {
      // Lakkar neeche se tezi se guzar raha hai (phase 0 pe sab se tez)
      final w = World(
        flat(pendulums: [const Pendulum(Offset(500, 200), 175, speed: 2)]),
      )..pos = const Offset(500, 400);
      w.update(1 / 60, Input());
      expect(w.deathKind, DeathKind.pendulum);
      expect(w.bodyLanded, isFalse); // hawa mein
      w.update(2.0, Input());
      expect(w.bodyLanded, isTrue);
      expect(w.pos.dy, 400); // zameen pe
      expect((w.pos.dx - 500).abs(), greaterThan(150));
    });

    test('lakkar (bhaari) saw (halki) se zyada door phenkta hai', () {
      final log = World(
        flat(pendulums: [const Pendulum(Offset(500, 200), 175, speed: 2)]),
      )..pos = const Offset(500, 400);
      final saw = World(flat(saws: [const Saw(470, 370, range: 0)]))
        ..pos = const Offset(500, 400);
      for (final w in [log, saw]) {
        w.update(1 / 60, Input());
        w.update(2.5, Input());
      }
      expect((log.pos.dx - 500).abs(), greaterThan((saw.pos.dx - 500).abs()));
    });

    test('lambi maut ka manzar pura dikhta hai (aag zyada der)', () {
      const level = Level(
        solids: [Rect.fromLTWH(-1000, 400, 4000, 200)],
        spikes: [],
        saws: [],
        fires: [Rect.fromLTWH(490, 384, 30, 16)],
        checkpoints: [Offset(300, 400)], // aag se door
        goalX: 2900,
      );
      final w = World(level)
        ..pos = const Offset(500, 400)
        ..update(1 / 60, Input());
      expect(w.deathKind, DeathKind.burn);
      w.update(2.6, Input());
      expect(w.state, PlayerState.dead); // ab bhi jal raha hai
      w.update(1.0, Input());
      expect(w.state, PlayerState.alive);
    });
  });

  group('larai aur Break Free', () {
    Level chaseLevel() => const Level(
      solids: [Rect.fromLTWH(-1000, 400, 4000, 200)],
      spikes: [],
      saws: [],
      checkpoints: [Offset(100, 400)],
      goalX: 2900,
      chase: Chase(
        startX: 100,
        throwEvery: 999,
      ), // sirf pakarne ka test, neze nahi
    );

    World caught() {
      final w = World(chaseLevel());
      while (w.state == PlayerState.alive) {
        w.update(0.05, Input());
        w.spears.clear(); // sirf pakarna jaanch rahe hain
      }
      return w;
    }

    test('pakre jaane pe pehle larai hoti hai, phir maut', () {
      final w = caught();
      expect(w.state, PlayerState.fighting);
      expect(w.events, contains(GameEvent.fightStart));
      w.update(World.fightDuration - 0.2, Input());
      expect(w.state, PlayerState.fighting);
      expect(w.events, contains(GameEvent.fightHit));
      w.update(0.3, Input());
      expect(w.state, PlayerState.dead);
      expect(w.deathKind, DeathKind.caught);
    });

    test('Break Free se chhoot jata hai, shikaari gir jaate hain, sirf ek dafa milta hai', () {
      final w = caught()..update(1, Input());
      expect(w.escape(), isTrue);
      expect(w.state, PlayerState.alive);
      // Shikaari gire hue — bhaagne ka mauqa
      final run = Input()..right = true;
      w.update(1.5, run);
      expect(w.state, PlayerState.alive);
      expect(w.pos.dx - w.hunterX, greaterThan(150));
      // Dobara pakra gaya to ab chhootne ka mauqa nahi
      while (w.state == PlayerState.alive) {
        w.update(0.05, Input());
        w.spears.clear();
      }
      expect(w.state, PlayerState.fighting);
      expect(w.escape(), isFalse);
    });

    test('ad ke dauraan larai ruki rehti hai', () {
      final w = caught()..fightPaused = true;
      w.update(10, Input());
      expect(w.state, PlayerState.fighting);
    });
  });

  group('panah', () {
    test('har chapter ke aakhir mein panah (chattan ka chhajja) hai', () {
      for (final c in chapters) {
        expect(c.level!().refuge.length, 2, reason: c.title);
      }
    });

    test('goal pe hero chhajje ke neeche baith jata hai, shikaari dhoond kar laut jaate hain', () {
      final level = chapters.first.level!();
      final w = World(level)
        ..pos = Offset(level.goalX - 30, 400)
        ..chaseActive = true
        ..hunterX = level.goalX - 400;
      final run = Input()..right = true;
      while (w.state != PlayerState.won) {
        w.update(1 / 60, run);
        w.spears.clear();
      }
      w.update(2.5, Input());
      expect(w.sitting, isTrue);
      expect(w.pos.dx, closeTo(level.goalX + 70, 1));
      final nearest = w.hunterX;
      w.update(4, Input());
      expect(w.hunterDir, -1); // laut rahe hain
      expect(w.hunterX, lessThan(nearest - 100));
      expect(w.state, PlayerState.won); // panah mein mehfooz
    });
  });

  group('shikaari bhi insaan hain', () {
    World chaseOn(
      List<Rect> solids, {
      List<Rect> spikes = const [],
      double playerX = 900,
      double playerY = 400,
    }) {
      final w = World(
        Level(
          solids: solids,
          spikes: spikes,
          saws: const [],
          checkpoints: [Offset(playerX, playerY)],
          goalX: 5000,
          chase: const Chase(startX: 0, throwEvery: 999),
        ),
      )..update(1 / 60, Input());
      return w;
    }

    test('kaanton ke oopar se koodte hain, aar paar nahi chalte', () {
      final w = chaseOn(
        const [Rect.fromLTWH(-1000, 400, 3000, 200)],
        spikes: const [Rect.fromLTWH(600, 384, 48, 16)],
      );
      var jumpedAtSpike = false;
      for (var i = 0; i < 60 * 6 && w.state == PlayerState.alive; i++) {
        w.update(1 / 60, Input());
        w.spears.clear();
        final lead = w.hunters.first;
        if (lead.x > 590 && lead.x < 660 && lead.y < 384) jumpedAtSpike = true;
        // Kaanton ke andar kabhi khara nahi
        expect(
          lead.x > 600 && lead.x < 648 && lead.y >= 399 && lead.grounded,
          isFalse,
        );
      }
      expect(jumpedAtSpike, isTrue);
    });

    test('aam gaddha kood kar paar karte hain', () {
      final w = chaseOn(const [
        Rect.fromLTWH(-1000, 400, 1500, 200),
        Rect.fromLTWH(590, 400, 2000, 200),
      ]);
      for (var i = 0; i < 60 * 6 && w.state == PlayerState.alive; i++) {
        w.update(1 / 60, Input());
        w.spears.clear();
      }
      expect(w.hunters.first.x, greaterThan(600)); // gaddha (500–590) paar
      expect(w.hunters.first.y, 400);
    });

    test('jump se oonchi chattan pe nahi chadh sakte, aur wahan khare hero ko pakar nahi sakte', () {
      final w = chaseOn(
        const [
          Rect.fromLTWH(-1000, 400, 3000, 200),
          Rect.fromLTWH(800, 260, 200, 140),
        ],
        playerX: 900,
        playerY: 260,
      );
      for (var i = 0; i < 60 * 8; i++) {
        w.update(1 / 60, Input());
        w.spears.clear();
        expect(w.state, isNot(PlayerState.fighting));
      }
      expect(w.hunters.first.x, lessThan(800)); // chattan ke neeche ruke
    });
  });
}

void expectJumpable(Level level) {
  final jumpTime = 2 * World.jumpVelocity / World.gravity;
  final jumpHeight =
      World.jumpVelocity * World.jumpVelocity / (2 * World.gravity);
  // Zameen ke hisse jahan khara ho sakte hain (deewarein bhi)
  final surfaces = [...level.solids]..sort((a, b) => a.left.compareTo(b.left));
  var reach = surfaces.first;
  for (final next in surfaces.skip(1)) {
    if (next.left <= reach.right) {
      if (next.right > reach.right) reach = next;
      continue;
    }
    final gap = next.left - reach.right;
    final hasMover = level.movers.any(
      (m) => m.base.right > reach.right && m.base.left < next.left,
    );
    if (!hasMover) {
      // Sab se buri hawa: saamne ki hawa poori, peeche ki hawa sirf 40%
      final w = level.wind.at((reach.right + next.left) / 2);
      final push = (w < 0 ? w : w * 0.4) * World.windPush;
      final distance = jumpTime * (World.speed + push);
      expect(
        gap - World.playerW,
        lessThan(distance * 0.85),
        reason: 'gaddha ${reach.right}–${next.left}',
      );
      expect(
        reach.top - next.top,
        lessThan(jumpHeight * 0.85),
        reason: 'oonchai ${next.left}',
      );
    }
    reach = next;
  }
}
