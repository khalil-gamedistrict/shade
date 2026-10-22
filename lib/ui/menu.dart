// Title screen, chapter ka naam (har chapter se pehle), aur "jald aa raha hai"
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/chapters.dart';

/// Kaun se chapter khatam ho chuke — phone/browser pe save rehta hai
class Progress {
  final done = <int>{};

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      done.addAll((p.getStringList('done') ?? []).map(int.parse));
    } catch (_) {
      // Tests/private browsing mein storage na mile to bas khaali progress
    }
  }

  /// Pehla chapter hamesha khula; baaqi tab khulte hain jab pichhla paar ho jaye
  bool unlocked(int chapter) => chapter == 1 || done.contains(chapter - 1);

  Future<void> markDone(int chapter) async {
    done.add(chapter);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList('done', done.map((e) => '$e').toList());
    } catch (_) {}
  }
}

const _white = Color(0xFFE8E8E8);
const _dim = Color(0x66E8E8E8);

/// Space/Enter ya tap — dono se aage
class _Advance extends StatelessWidget {
  final VoidCallback onAdvance;
  final Widget child;
  const _Advance({required this.onAdvance, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): onAdvance,
        const SingleActivator(LogicalKeyboardKey.enter): onAdvance,
      },
      child: Focus(
        autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAdvance,
          child: child,
        ),
      ),
    );
  }
}

class TitleScreen extends StatelessWidget {
  final Progress progress;
  final void Function(Chapter) onPlay;
  const TitleScreen({super.key, required this.progress, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    // "Khelo" = pehla bana hua chapter jo abhi khatam nahi hua
    final next = chapters.lastWhere((c) => progress.unlocked(c.number));
    return Scaffold(
      backgroundColor: Colors.black,
      body: _Advance(
        onAdvance: () => onPlay(next),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF3A3C3D), Colors.black],
              radius: 1.1,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SHADE',
                  style: TextStyle(
                    fontSize: 64,
                    letterSpacing: 18,
                    color: _white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'run home',
                  style: TextStyle(fontSize: 14, letterSpacing: 4, color: _dim),
                ),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final c in chapters)
                      _ChapterTile(
                        c,
                        done: progress.done.contains(c.number),
                        locked: !progress.unlocked(c.number),
                        onTap: () => onPlay(c),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Tap / Space — play Chapter ${next.number}',
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: _dim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final bool done;
  final bool locked;
  final VoidCallback onTap;
  const _ChapterTile(
    this.chapter, {
    required this.done,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final open = chapter.ready && !locked;
    final color = open ? _white : _dim;
    return InkWell(
      // Band chapter: tap yahin ruk jaye (neeche "kahin bhi tap = khelo" tak na pahunche), aur wajah batao
      onTap: open
          ? onTap
          : () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Finish Chapter ${chapter.number - 1} to unlock.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      letterSpacing: 1.5,
                      color: Color(0xFFDADADA),
                    ),
                  ),
                  backgroundColor: const Color(0xFF1C1D1E),
                  duration: const Duration(seconds: 2),
                ),
              ),

      child: Container(
        width: 112,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: open ? Colors.white24 : Colors.white10),
        ),
        child: Column(
          children: [
            Text(
              '${chapter.number}',
              style: TextStyle(
                fontSize: 22,
                color: color,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chapter.title,
              style: TextStyle(fontSize: 13, letterSpacing: 1.5, color: color),
            ),
            const SizedBox(height: 4),
            if (locked)
              const Icon(Icons.lock_outline, size: 13, color: _dim)
            else
              Text(
                done ? '✓' : (chapter.ready ? ' ' : 'soon'),
                style: const TextStyle(fontSize: 11, color: _dim),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chapter shuru hone se pehle: kaale parde pe aahista ubharta naam
class ChapterCard extends StatefulWidget {
  final Chapter chapter;
  final VoidCallback onDone;
  const ChapterCard({super.key, required this.chapter, required this.onDone});

  @override
  State<ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<ChapterCard> {
  bool visible = false;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 100),
      () => mounted ? setState(() => visible = true) : null,
    );
    Future.delayed(
      const Duration(milliseconds: 2600),
      () => mounted ? setState(() => visible = false) : null,
    );
    Future.delayed(const Duration(milliseconds: 3600), _finish);
  }

  void _finish() {
    if (finished || !mounted) return;
    finished = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _Advance(
        onAdvance: _finish,
        child: Center(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 900),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CHAPTER ${widget.chapter.number}',
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 6,
                    color: _dim,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.chapter.title,
                  style: const TextStyle(
                    fontSize: 44,
                    letterSpacing: 8,
                    color: _white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Jo chapter abhi bana nahi
class ComingSoon extends StatelessWidget {
  final Chapter chapter;
  final VoidCallback onBack;
  const ComingSoon({super.key, required this.chapter, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _Advance(
        onAdvance: onBack,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CHAPTER ${chapter.number}',
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 6,
                  color: _dim,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                chapter.title,
                style: const TextStyle(
                  fontSize: 44,
                  letterSpacing: 8,
                  color: _white,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'coming soon',
                style: TextStyle(fontSize: 14, letterSpacing: 3, color: _dim),
              ),
              const SizedBox(height: 28),
              const Text(
                'Tap — menu',
                style: TextStyle(fontSize: 12, letterSpacing: 2, color: _dim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kahani ka ikhtitaam — aakhri chapter ke baad
class EndingCard extends StatelessWidget {
  final VoidCallback onDone;
  const EndingCard({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _Advance(
        onAdvance: onDone,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'He made it home.',
                style: TextStyle(
                  fontSize: 26,
                  letterSpacing: 4,
                  color: _white,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'THE END',
                style: TextStyle(fontSize: 13, letterSpacing: 8, color: _dim),
              ),
              SizedBox(height: 36),
              Text(
                'Tap — menu',
                style: TextStyle(fontSize: 12, letterSpacing: 2, color: _dim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
