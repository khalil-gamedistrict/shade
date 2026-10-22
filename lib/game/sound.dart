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
    GameEvent.jump: (['jump'], 0.5),
    GameEvent.land: (['land'], 0.55),
    GameEvent.death: (['death'], 0.9),
    GameEvent.checkpoint: (['checkpoint'], 0.45),
    GameEvent.win: (['win'], 0.7),
    GameEvent.branchLand: (['land'], 1.0), // shaakh girne ki dhamak
    GameEvent.chaseStart: (['warcry'], 0.8),
    GameEvent.spearThrow: (['spear_throw1', 'spear_throw2'], 0.6),
    GameEvent.spearHit: (['spear_stick'], 0.8),
    GameEvent.spearStick: (['spear_stick'], 0.3),
    GameEvent.shout: (['shout1', 'shout2', 'shout3'], 0.45),
    GameEvent.fightStart: (['shout1', 'shout2', 'shout3'], 0.7),
    GameEvent.fightHit: (['land'], 0.85), // waar ki dhamak
    GameEvent.escape: (['jump'], 0.8),
  };
  final _players = <String, AudioPlayer>{};
  final _last = <GameEvent, int>{};

  // Lagataar chalti awaazen: jungle, hawa, baarish, peechhe ka dhol, hero ki saans
  final _forest = AudioPlayer();
  final _wind = AudioPlayer();
  final _rain = AudioPlayer();
  final _drums = AudioPlayer();
  final _breath = AudioPlayer();
  final _thunderNear = AudioPlayer();
  final _thunderFar = AudioPlayer();
  bool _loopsStarted = false;
  final _vol = <AudioPlayer, double>{};

  List<AudioPlayer> get _loops => [_forest, _wind, _rain, _drums, _breath];

  Future<void> load() async {
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

  /// Peechha: shikaari jitne qareeb, dhol utna tez; daurte hue hero ki saans
  void setChase({
    required bool active,
    required double closeness,
    required bool running,
  }) {
    if (!_loopsStarted) return;
    _fade(_drums, active ? 0.2 + 0.5 * closeness.clamp(0, 1) : 0);
    _fade(_breath, active && running ? 0.6 : 0);
  }

  // Volume aahista badlo, aur sirf tab bhejo jab farq mehsoos ho (har frame bhejna mehnga hai)
  void _fade(AudioPlayer p, double target) {
    final cur = _vol[p] ?? 0;
    final next = cur + (target - cur) * 0.08;
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
      ..setVolume(volume * (0.85 + _r.nextDouble() * 0.3))
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
