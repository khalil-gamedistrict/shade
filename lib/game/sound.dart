// Game ki awaazen. Files: assets/sounds/*.ogg (tools/prepare_sounds.py se bani, sab CC0)
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'world.dart';

class Sound {
  final _r = Random();

  // Har event ke liye files ka group (random mein se ek bajti hai, taake mashini na lage) aur volume
  static const _groups = <GameEvent, (List<String>, double)>{
    GameEvent.step: (
      ['step1', 'step2', 'step3', 'step4', 'step5', 'step6'],
      0.35,
    ),
    GameEvent.wade: (['wade1', 'wade2', 'wade3', 'wade4'], 0.45),
    GameEvent.crouch: (['rustle'], 0.2),
    GameEvent.jump: (['jump'], 0.5),
    GameEvent.shieldPickup: (['rustle'], 0.5),
    GameEvent.shieldBlock: (
      ['spear_stick'],
      1.0,
    ), // neza lakdi/chamre ki dhaal pe
    GameEvent.shieldBreak: (
      ['branch_crack'],
      1.0,
    ), // dhaal chatak kar toot'ti hai
    GameEvent.land: (['land'], 0.55),
    GameEvent.checkpoint: (['checkpoint'], 0.45),
    GameEvent.win: (['win'], 0.7),
    GameEvent.branchLand: (['land'], 1.0), // shaakh girne ki dhamak
    GameEvent.branchBreak: (['branch_crack'], 0.9), // oopar shaakh chatakti hai
    GameEvent.bodyLand: (['land'], 0.7), // takkar se uchhla jism zameen pe
    GameEvent.chaseStart: (['warcry'], 0.8),
    GameEvent.spearThrow: (['spear_throw1', 'spear_throw2'], 0.6),
    GameEvent.spearHit: (['spear_stick'], 0.8),
    GameEvent.spearStick: (['spear_stick'], 0.3),
    GameEvent.shout: (
      ['shout1', 'shout2', 'shout3', 'shout4', 'shout5', 'shout6'],
      0.5,
    ),
    GameEvent.fightStart: (
      ['shout1', 'shout2', 'shout3', 'shout4', 'shout5', 'shout6'],
      0.7,
    ),
    GameEvent.fightHit: (['land'], 0.85), // waar ki dhamak
    GameEvent.escape: (['jump'], 0.8),
    GameEvent.rustle: (['rustle'], 0.7),
  };
  final _players = <String, AudioPlayer>{};

  // Har maut ki apni awaaz: (file, volume, kitni der baad ms). 'grunt'/'stab' ke kai variant — random.
  static const _deaths = <DeathKind, List<(String, double, int)>>{
    DeathKind.fall: [('scream_fall', 0.8, 0)],
    DeathKind.drown: [('splash', 0.9, 0), ('bubbles', 0.6, 450)],
    DeathKind.spike: [('stab', 0.8, 0), ('grunt', 0.8, 80)],
    DeathKind.trap: [('trap_snap', 1.0, 0), ('grunt', 0.85, 120)],
    DeathKind.pendulum: [('body_hit', 1.0, 0), ('grunt', 0.8, 60)],
    DeathKind.saw: [('body_hit', 0.8, 0), ('grunt', 0.8, 60)],
    DeathKind.branch: [('land', 1.0, 0), ('grunt', 0.8, 90)],
    DeathKind.spear: [
      ('stab', 0.8, 0),
      ('spear_stick', 0.6, 0),
      ('grunt', 0.8, 120),
    ],
    DeathKind.caught: [('stab', 0.9, 0), ('hit_moan', 0.8, 150)],
    DeathKind.burn: [('fire_whoosh', 0.9, 0), ('scream_burn', 0.8, 250)],
  };
  static const _variants = {'grunt': 4, 'stab': 3};
  final _last = <GameEvent, int>{};

  // Lagataar chalti awaazen: jungle, hawa, baarish, peechhe ka dhol, hero ki saans
  final _forest = AudioPlayer();
  final _wind = AudioPlayer();
  final _rain = AudioPlayer();
  final _drums = AudioPlayer();
  final _breath = AudioPlayer();
  final _hunters = AudioPlayer(); // peeche daurte shikaariyon ke qadam
  double _pan = 0;
  final _thunderNear = AudioPlayer();
  final _thunderFar = AudioPlayer();
  bool _loopsStarted = false;
  final _vol = <AudioPlayer, double>{};

  List<AudioPlayer> get _loops => [
    _forest,
    _wind,
    _rain,
    _drums,
    _breath,
    _hunters,
  ];

  Future<void> load() async {
    for (final list in _deaths.values) {
      for (final (name, _, _) in list) {
        for (final f in _files(name)) {
          if (_players.containsKey(f)) continue;
          final p = AudioPlayer();
          await p.setReleaseMode(ReleaseMode.stop);
          await p.setSource(AssetSource('sounds/$f.ogg'));
          _players[f] = p;
        }
      }
    }
    for (final (files, _) in _groups.values) {
      for (final f in files) {
        if (_players.containsKey(f)) continue;
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource('sounds/$f.ogg'));
        _players[f] = p;
      }
    }
    for (final (p, name) in [
      (_forest, 'forest'),
      (_wind, 'wind'),
      (_rain, 'rain'),
      (_drums, 'drums'),
      (_breath, 'breath'),
      (_hunters, 'hunters_run'),
    ]) {
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setSource(AssetSource('sounds/$name.ogg'));
    }
    await _thunderNear.setSource(AssetSource('sounds/thunder.ogg'));
    await _thunderFar.setSource(AssetSource('sounds/thunder_far.ogg'));
  }

  /// Browser pehli dafa click/key dabane se pehle awaaz chalne nahi deta,
  /// is liye loops pehle input pe shuru hote hain.
  void startLoops() {
    if (_loopsStarted) return;
    _loopsStarted = true;
    for (final p in _loops) {
      p
        ..setVolume(0)
        ..resume();
    }
  }

  /// Har frame: jahan player hai wahan ki hawa aur baarish ke hisaab se volume
  void setWeather({required double wind, required double rain}) {
    if (!_loopsStarted) return;
    _fade(_forest, 0.4 * (1 - rain * 0.6));
    _fade(_wind, 0.06 + 0.6 * min(1.0, wind.abs()));
    _fade(_rain, 0.8 * rain);
  }

  /// Peechha: shikaari jitne qareeb, dhol utna tez; daurte hue hero ki saans.
  /// [hunterGap] = hero se sab se qareeb shikaari ka faasla (+ = shikaari baayen). Un ke qadmon ki awaaz
  /// faasle ke saath — door halki, qareeb aate aate tez — aur jidhar woh hain usi kaan mein zyada.
  void setChase({
    required bool active,
    required bool running,
    required double hunterGap,
    required bool huntersRunning,
  }) {
    if (!_loopsStarted) return;
    _near = _nearness(hunterGap);
    _fade(_drums, active ? 0.15 + 0.5 * _near : 0);
    _fade(_breath, active && running ? 0.6 : 0);
    _fade(
      _hunters,
      huntersRunning ? 0.05 + 0.95 * _near * _near : 0,
      speed: 0.15,
    );
    final pan = (-hunterGap / 600).clamp(-0.7, 0.7);
    if ((pan - _pan).abs() > 0.03) {
      _pan = pan;
      _hunters.setBalance(pan);
    }
  }

  double _near = 0;

  /// 1 = bilkul saath, 0 = 800px ya zyada door
  static double _nearness(double gap) => (1 - gap.abs() / 800).clamp(0.0, 1.0);

  // Volume aahista badlo, aur sirf tab bhejo jab farq mehsoos ho (har frame bhejna mehnga hai)
  void _fade(AudioPlayer p, double target, {double speed = 0.08}) {
    final cur = _vol[p] ?? 0;
    final next = cur + (target - cur) * speed;
    if ((next - cur).abs() < 0.004) return;
    _vol[p] = next;
    p.setVolume(next);
  }

  void thunder(bool near) {
    // Roshni pehle, awaaz baad mein — jitni door bijli, utni der
    final delay = near ? 200 + _r.nextInt(500) : 1200 + _r.nextInt(2000);
    Future.delayed(Duration(milliseconds: delay), () {
      final p = near ? _thunderNear : _thunderFar;
      p
        ..stop()
        ..setVolume(near ? 0.9 : 0.6)
        ..resume();
    });
  }

  static List<String> _files(String name) {
    final n = _variants[name];
    return n == null ? [name] : [for (var i = 1; i <= n; i++) '$name$i'];
  }

  /// Har maut ki qism ki saari files (test ke liye — har ek disk pe honi chahiye)
  static Map<DeathKind, List<String>> deathFiles() => {
    for (final MapEntry(:key, :value) in _deaths.entries)
      key: [for (final (name, _, _) in value) ..._files(name)],
  };

  /// Maut: us ki qism ke hisaab se awaazon ka mix (kuch thori der se)
  void playDeath(DeathKind kind) {
    for (final (name, volume, delay)
        in _deaths[kind] ?? const <(String, double, int)>[]) {
      final files = _files(name);
      final player = _players[files[_r.nextInt(files.length)]];
      if (player == null) continue;
      void go() => player
        ..stop()
        ..setVolume(volume * (0.9 + _r.nextDouble() * 0.2))
        ..resume();
      delay == 0 ? go() : Future.delayed(Duration(milliseconds: delay), go);
    }
  }

  // Shikaariyon ki awaazen: door hon to halki
  static const _voices = {
    GameEvent.chaseStart,
    GameEvent.shout,
    GameEvent.fightStart,
  };

  void play(GameEvent e) {
    final group = _groups[e];
    if (group == null) return;
    final (files, volume) = group;
    // Pichhli dafa wali file dobara na bajao
    var i = _r.nextInt(files.length);
    if (files.length > 1 && i == _last[e]) i = (i + 1) % files.length;
    _last[e] = i;
    final player = _players[files[i]];
    if (player == null) return;
    player
      ..stop()
      ..setVolume(
        volume *
            (0.85 + _r.nextDouble() * 0.3) *
            (_voices.contains(e) ? 0.3 + 0.7 * _near : 1),
      )
      ..resume();
  }

  void dispose() {
    for (final p in [
      ..._players.values,
      ..._loops,
      _thunderNear,
      _thunderFar,
    ]) {
      p.dispose();
    }
  }
}
