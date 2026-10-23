import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/chapters.dart';
import 'game/jungle.dart';
import 'game/palette.dart';
import 'game/world.dart';
import 'game/sound.dart';
import 'services/ads.dart';
import 'ui/game_screen.dart';
import 'ui/menu.dart';
import 'ui/trailer.dart';

// Testing ke liye sound band karna ho: --dart-define=SOUND=false
const soundEnabled = bool.fromEnvironment('SOUND', defaultValue: true);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ShadeApp(sound: soundEnabled));
}

class ShadeApp extends StatelessWidget {
  final bool sound;
  const ShadeApp({super.key, this.sound = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: ShadeHome(sound: sound),
    );
  }
}

enum _Phase { trailer, title, card, play, soon, ending }

/// Game ka safar: title → chapter ka naam → khelna → agla chapter (ya "jald aa raha hai")
class ShadeHome extends StatefulWidget {
  final bool sound;
  const ShadeHome({super.key, required this.sound});

  @override
  State<ShadeHome> createState() => _ShadeHomeState();
}

class _ShadeHomeState extends State<ShadeHome> {
  final progress = Progress();
  Sound? sound; // saare chapters ke liye ek hi — loops beech mein nahi tootte
  _Phase phase =
      _Phase.trailer; // har dafa khulne pe pehle trailer (skip ho sakta hai)
  final jungle = Jungle(); // darakhton ki tasveerein ek dafa — trailer aur saare chapters mein
  // Rangeen subah wale chapter ki apni tasveerein (pehli dafa khulne pe banti hain)
  late final dawnJungle = Jungle(colors: Palette.dawn);
  Chapter chapter = chapters.first;
  final AdService ads = PlaceholderAds(); // asli ads aane pe yahan badalna

  @override
  void initState() {
    super.initState();
    if (widget.sound) sound = Sound()..load();
    progress.load().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    sound?.dispose();
    super.dispose();
  }

  void _open(Chapter c) => setState(() {
    if (!progress.unlocked(c.number)) return; // band chapter
    chapter = c;
    phase = c.ready ? _Phase.card : _Phase.soon;
  });

  void _completed() {
    progress.markDone(chapter.number);
    final i = chapters.indexOf(chapter);
    if (i + 1 < chapters.length) {
      _open(chapters[i + 1]);
    } else {
      setState(() => phase = _Phase.ending); // kahani khatam
    }
  }

  void _toTitle() => setState(() => phase = _Phase.title);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: switch (phase) {
        _Phase.trailer => TrailerScreen(
          key: const ValueKey('trailer'),
          jungle: jungle,
          sound: sound,
          onDone: _toTitle,
        ),
        _Phase.title => TitleScreen(
          key: const ValueKey('title'),
          progress: progress,
          onPlay: _open,
        ),
        _Phase.card => ChapterCard(
          key: ValueKey('card${chapter.number}'),
          chapter: chapter,
          onDone: () => setState(() => phase = _Phase.play),
        ),
        _Phase.play => GameScreen(
          key: ValueKey('play${chapter.number}'),
          level: chapter.level!(),
          jungle: chapter.level!().mood == Mood.dawn ? dawnJungle : jungle,
          sound: sound,
          onComplete: _completed,
          onExit: _toTitle,
          ads: ads,
        ),
        _Phase.soon => ComingSoon(
          key: ValueKey('soon${chapter.number}'),
          chapter: chapter,
          onBack: _toTitle,
        ),
        _Phase.ending => EndingCard(
          key: const ValueKey('ending'),
          onDone: _toTitle,
        ),
      },
    );
  }
}
