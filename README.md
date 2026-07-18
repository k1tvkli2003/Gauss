# Gauss

Gauss is a private, offline-first Flutter Android app for mathematics and
physics practice. The released product is the map-first **Orrery of Proofs**
experience in [`flutter_app/`](flutter_app/), with the complete bundled
question bank and media preserved locally.

## Active Android app

The only Gauss APK to install or publish is built from `flutter_app/`:

```powershell
cd flutter_app
flutter pub get
flutter build apk --release
```

The output is:

```text
flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

It has package ID `com.gauss.app`. On a connected Android device:

```powershell
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## GitHub releases

`.github/workflows/release-apk.yml` runs only on `main`, tests the Flutter app,
builds the universal APK from `flutter_app/`, verifies its package, version,
alignment and non-debug signing, then publishes the APK plus `SHA256SUMS` to a
GitHub Release.

The release signing identity is intentionally external to Git:

- alias: `gauss-release`
- package ID: `com.gauss.app`
- GitHub secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`

See [Android signing continuity](docs/release/android-signing.md) for the
non-secret recovery and verification record.

## Legacy Kotlin project

The root-level `app/` Kotlin/Compose module is retained for historical source
reference only. It has the distinct package ID `com.gauss.legacy` and the
display name **Gauss Legacy Archive**. It is not a release target and cannot
replace the Flutter Gauss app.

## Data contract

The active Flutter app bundles the complete protected corpus and media locally.
Run its release checks from `flutter_app/`:

```powershell
flutter analyze --no-pub
flutter test --no-pub
.\tool\verify_release_artifacts.ps1
```
