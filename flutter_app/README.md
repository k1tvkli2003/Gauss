# Gauss Flutter Android

This directory is the active, released Gauss Android application.

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release
```

Install only:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The app package is `com.gauss.app`. Its map-first Android UI, question corpus,
media, offline progress and release tests all live here. The root-level Kotlin
module is a separate legacy archive and must not be used for releases.
