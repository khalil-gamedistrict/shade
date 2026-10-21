# Shade

Limbo jaisa (Limbo-style) andhera 2D platformer, Flutter mein bana hua. Iski Android APK GitHub Actions se banti hai.

## Game
- Andhera silhouette jungle. Gaddhay, spikes aur ek ghoomta hua saw paar karo, aur aakhir mein roshni tak pohancho.
- Controls: neeche left mein ← → buttons, right mein jump. Keyboard pe arrow keys / WASD aur Space.
- Lamp wale checkpoints: marne pe aakhri jalay hue lamp pe wapas aate ho.

## Code
- [lib/game/world.dart](lib/game/world.dart): physics, level, takkar (collision), maut aur checkpoints
- [lib/game/painter.dart](lib/game/painter.dart): saari drawing (background, darakht, character)
- [lib/main.dart](lib/main.dart): game loop aur touch controls
- [test/world_test.dart](test/world_test.dart): tests

## Build (GitHub Actions)
[.github/workflows/android.yml](.github/workflows/android.yml) har push pe yeh steps chalata hai:
format check → analyze → test → `flutter build apk` → APK upload

- **Har push pe:** Actions → latest run → **Artifacts** → `shade-apk`
- **Release:** `git tag v1.0.0 && git push origin v1.0.0` chalao, APK **Releases** section mein aa jayegi
