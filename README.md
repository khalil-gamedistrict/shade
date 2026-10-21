# Snake — Flutter + GitHub Actions

Flutter mein bana Snake game. Iski Android APK GitHub Actions se automatically banti hai.

## Build kaise hoti hai
[.github/workflows/android.yml](.github/workflows/android.yml) har push pe yeh steps chalata hai:
format check → analyze → test → `flutter build apk` → APK upload

- **Har push pe:** GitHub repo → Actions → latest run → **Artifacts** → `snake-apk` download karo
- **Release:** `git tag v1.0.0 && git push origin v1.0.0` chalao, APK **Releases** section mein aa jayegi

## Local pe
```bash
flutter test           # tests
flutter run            # phone/emulator pe chalao
```
