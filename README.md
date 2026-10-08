# Gauss

Offline-first Android app for mathematics and physics practice, built as a
map-first adventure ("Orrery of Proofs"). Single-user, private, local-first:
no auth, no leagues, no monetization. Bundled question bank and media ship
with the app so it works fully offline.

## What's inside

- `flutter_app/` — the active release target. Flutter/Dart, version
  `1.0.90+90`, package ID `com.gauss.app`. Map-first island progression UI,
  five-question micro-lessons grouped by taxonomy and difficulty, day-bound
  quests/streaks on an injectable domain clock, responsive-composition gates
  (320dp phones through tablets, RTL/LTR, 200% text).
- `app/` — legacy Kotlin/Compose module (`com.gauss.legacy`, "Gauss Legacy
  Archive"). Retained for source reference only; not a release target and not
  update-compatible with the Flutter app.
- `docs/release/android-signing.md` — signing continuity record. Release
  builds fail closed without the external `GAUSS_KEYSTORE_*` identity; they
  never fall back to the debug certificate.
- `supabase/`, `data/`, `scripts/`, `flutter_app/tool/` — backend
  migrations, dataset material, and release helpers (`verify_release_artifacts.ps1`,
  media-manifest updater, Android perf harnesses).
- `.github/workflows/release-apk.yml` — main-only pipeline: tests the Flutter
  app, builds the universal APK, verifies package/version/alignment/signing,
  publishes APK plus `SHA256SUMS` to a GitHub Release.

## Tech stack

Flutter (go_router, drift, supabase_flutter, flutter_math_fork), legacy
Kotlin/Compose/Gradle 8.7.3 archive, Supabase backend, GitHub Actions
releases. App-chrome strings in English; numerals in rendered Q/A normalized
to ASCII 0-9 at the rendering boundary.

## Getting started

Only the Flutter app is installable:

```powershell
cd flutter_app
flutter pub get
flutter build apk --debug
```

Signed release needs the external keystore environment from
`docs/release/android-signing.md`. Install on a connected device with
`adb install -r build/app/outputs/flutter-apk/app-release.apk`.
Release checks from `flutter_app/`: `flutter analyze --no-pub`,
`flutter test --no-pub`, `.\tool\verify_release_artifacts.ps1`.

## Status

In active development. The Flutter app is the delivery path; release signing,
physical-device verification, and remaining backend gates are tracked in
`docs/`. The Kotlin tree is frozen history.
