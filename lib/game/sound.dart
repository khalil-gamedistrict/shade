// Game ki awaazen. Files: assets/sounds/*.ogg (tools/prepare_sounds.py se bani, sab CC0)
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'world.dart';

class Sound {
  final _r = Random();
  final _effects = <GameEvent, AudioPlayer>{};
  final _steps =
      <AudioPlayer>[]; // 6 alag qadam — har dafa random, taake mashini na lage
  int _lastStep = -1;

  // Lagataar chalti awaazen: jungle, hawa, baarish
  final _forest = AudioPlayer();
  final _wind = AudioPlayer();
  final _rain = AudioPlayer();
  final _thunderNear = AudioPlayer();
  final _thunderFar = AudioPlayer();
  bool _loopsStarted = false;
  final _vol = <AudioPlayer, double>{};

  static const _volumes = {
    GameEvent.jump: 0.5,
    GameEvent.land: 0.55,
    GameEvent.death: 0.9,
    GameEvent.checkpoint: 0.45,
    GameEvent.win: 0.7,
  };

  Future<void> load() async {
    for (final e in _volumes.keys) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource('sounds/${e.name}.ogg'));
      _effects[e] = p;
    }
    for (var i = 1; i <= 6; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource('sounds/step$i.ogg'));
      _steps.add(p);
    }
    for (final (p, name) in [
      (_forest, 'forest'),
      (_wind, 'wind'),
      (_rain, 'rain'),
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
    for (final p in [_forest, _wind, _rain]) {
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
    final AudioPlayer? player;
    var volume = 0.0;
    if (e == GameEvent.step) {
      if (_steps.isEmpty) return;
      var i = _r.nextInt(_steps.length);
      if (i == _lastStep) i = (i + 1) % _steps.length;
      _lastStep = i;
      player = _steps[i];
      volume = 0.3 + _r.nextDouble() * 0.15;
    } else {
      player = _effects[e];
      volume = _volumes[e] ?? 0.5;
    }
    if (player == null) return;
    player
      ..stop()
      ..setVolume(volume)
      ..resume();
  }

  void dispose() {
    for (final p in [
      ..._effects.values,
      ..._steps,
      _forest,
      _wind,
      _rain,
      _thunderNear,
      _thunderFar,
    ]) {
      p.dispose();
    }
  }
}
