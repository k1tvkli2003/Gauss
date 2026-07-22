# Gauss Flutter Android

This directory is the active, released Gauss Android application.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug
```

Release builds require all four external `GAUSS_KEYSTORE_*` values and fail
closed when the protected Gauss signing identity is unavailable. See
[`../docs/release/android-signing.md`](../docs/release/android-signing.md).

Install only:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The app package is `com.gauss.app`. Its map-first Android UI, question corpus,
media, offline progress and release tests all live here. The root-level Kotlin
module is a separate legacy archive and must not be used for releases.
