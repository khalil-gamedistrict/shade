import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shade/game/figures.dart';
import 'package:shade/game/grass.dart';

// App icon banata hai (hero ki shakal, dhundla jungle). Aam test run mein nahi chalta:
//   MAKE_ICON=1 flutter test test/make_icon_test.dart
// Android mipmap aur web icons likhta hai; bara 1024px wala build/icon.png mein.
const out = 'build';

void main() {
  testWidgets('app icon', skip: !Platform.environment.containsKey('MAKE_ICON'), (
    tester,
  ) async {
    await tester.runAsync(() async {
      Directory(out).createSync(recursive: true);
      const n = 1024.0;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final full = const Rect.fromLTWH(0, 0, n, n);
      // Dhundla aasmaan: beech mein roshni (hero ke peeche), kinaron pe andhera
      c.drawRect(full, Paint()..color = const Color(0xFF2A2C2E));
      c.drawRect(
        full,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0.05, -0.05),
            radius: 0.75,
            colors: [Color(0xFFE4E6E8), Color(0xFF9A9DA0), Color(0xFF3A3C3E)],
            stops: [0, 0.45, 1],
          ).createShader(full),
      );
      // Door ke dhundle darakht
      final far = Paint()..color = const Color(0x40202224);
      for (final (x, w) in [
        (90.0, 26.0),
        (250.0, 18.0),
        (770.0, 22.0),
        (930.0, 30.0),
        (640.0, 14.0),
      ]) {
        c.drawRect(Rect.fromLTWH(x, 0, w, n), far);
      }
      // Qareeb ke kaale tane kinaron pe
      final ink = Paint()..color = const Color(0xFF070707);
      c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(70, 0)
          ..quadraticBezierTo(48, 500, 62, n)
          ..lineTo(0, n)
          ..close(),
        ink,
      );
      c.drawPath(
        Path()
          ..moveTo(n, 0)
          ..lineTo(n - 52, 0)
          ..quadraticBezierTo(n - 40, 520, n - 58, n)
          ..lineTo(n, n)
          ..close(),
        ink,
      );
      // Latakti bailen patton ke saath
      final vine = Paint()
        ..color = const Color(0xFF070707)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      for (final (x, len) in [
        (170.0, 300.0),
        (330.0, 180.0),
        (720.0, 240.0),
        (860.0, 360.0),
      ]) {
        c.drawPath(
          Path()
            ..moveTo(x, 0)
            ..quadraticBezierTo(x + 18, len * 0.5, x - 6, len),
          vine,
        );
        for (var k = 1; k < 8; k++) {
          final y = len * k / 8, side = k.isEven ? 1.0 : -1.0;
          c.save();
          c.translate(x + 6 * sin(k.toDouble()), y);
          c.rotate(side * 0.9);
          c.drawPath(
            Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(9, 12, 0, 26)
              ..quadraticBezierTo(-9, 12, 0, 0),
            ink,
          );
          c.restore();
        }
      }
      // Zameen: halka teela, ghaas
      const groundY = 770.0;
      double top(double x) => groundY - 26 * sin(x / n * pi);
      final g = Path()..moveTo(0, n);
      for (var x = 0.0; x <= n; x += 8) {
        g.lineTo(x, top(x));
      }
      g
        ..lineTo(n, n)
        ..close();
      c.drawPath(g, ink);
      c.save();
      c.scale(4);
      final grass = Path();
      Grass.addTo(
        grass,
        0,
        0,
        n / 4,
        0,
        n / 4,
        (_) => 0.35,
        1.3,
        topAt: (x) => top(x * 4) / 4,
      );
      c.drawPath(grass, ink);
      c.restore();
      // Hero: daurta hua, baal hawa mein, aankhen chamakti
      drawFigure(
        c,
        look: Look.hero,
        foot: Offset(n * 0.5, top(n * 0.5) + 36),
        dir: 1,
        phase: 1.57,
        moving: true,
        inAir: false,
        time: 0.4,
        wind: 0.6,
        scale: 9.2,
      );
      final pic = rec.endRecording();
      const res = 'android/app/src/main/res';
      final targets = {
        '$out/icon.png': 1024,
        '$res/mipmap-mdpi/ic_launcher.png': 48,
        '$res/mipmap-hdpi/ic_launcher.png': 72,
        '$res/mipmap-xhdpi/ic_launcher.png': 96,
        '$res/mipmap-xxhdpi/ic_launcher.png': 144,
        '$res/mipmap-xxxhdpi/ic_launcher.png': 192,
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
        'web/favicon.png': 16,
      };
      for (final MapEntry(key: path, value: size) in targets.entries) {
        final r = ui.PictureRecorder();
        final cv = Canvas(r);
        cv.scale(size / n);
        cv.drawPicture(pic);
        final img = await r.endRecording().toImage(size, size);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
      }
    });
  });
}
