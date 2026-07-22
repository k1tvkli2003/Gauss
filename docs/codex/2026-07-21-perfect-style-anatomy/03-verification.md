# Verification record

This file is updated only with observed results.

## Completed evidence

- Baseline phone/tablet/desktop release-web screenshot matrix captured.
- Existing installed Android package certificate recorded.
- Existing release APK certificate recorded and mismatch reproduced with
  `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- Release task without protected signing inputs rejected by the new
  fail-closed Gradle contract.

## Flutter quality gates

- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **75/75 passed**.
- `flutter test --no-pub test/question_contract_test.dart --reporter expanded`:
  **11/11 passed**, including all 3,672 questions and all 3,410 media files.
- Compact accessibility gate: map passes at 411x820 logical pixels with 200%
  text and reduced motion.
- Insights layout gate: passes at 320x700, 360x820, 411x820, 800x600, and
  1180x900.

## Web release and runtime

- `flutter build web --release --no-pub`: passed; Wasm dry run also passed.
- Release bundle exercised at 390x844, 768x1024, and 1440x900 on Map, Study,
  and Insights, plus the direct Vault route.
- Captured runtime result: `runtimeErrors: []` (no console error, page error, or
  `MissingPluginException`).
- Browser Vault reports its Android-only native backup boundary without calling
  an unsupported plugin.

## Android v105 artifact

- APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- Package: `com.gauss.app`
- Version: `1.0.105 (105)`
- Size: `141,817,909` bytes
- SHA-256: `C958FA27D8889394F410BE08F83B17731B8EE633AB0426BB77E9DB217AF80FE6`
- Native ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`
- APK Signature Scheme v2: verified
- Signer: `CN=Gauss, OU=Personal, O=Gauss, L=Tehran, ST=Tehran, C=IR`
- Certificate SHA-256:
  `F50C3338BF6C1CFBE058F6ECE579E224B2D537D12548A949C35F79B573B76844`
- `zipalign -c -v 4`: verification successful
- Permissions: no Internet permission; only the package-scoped dynamic receiver
  permission is declared.

## In-place update proof

| Field | Before | After |
| --- | --- | --- |
| Version | 1.0.90 (90) | 1.0.105 (105) |
| First install | 2026-07-18 13:02:33 | 2026-07-18 13:02:33 |
| Last update | 2026-07-18 23:42:12 | 2026-07-22 12:15:17 |
| Signer SHA-256 | F50C…6844 | F50C…6844 |

`adb install -r` returned `Success`, cold launch returned `Status: ok`, the
foreground activity was `com.gauss.app/.MainActivity`, and the post-launch log
audit found no fatal, AndroidRuntime, Flutter, or missing-plugin error.

## Artifact parity

`tool/verify_release_artifacts.ps1` passed every strict comparison:

- 30 question shards / 6,007,444 bytes match from source to Flutter assets,
  release web, and APK.
- 3,410 media files / 66,450,076 bytes match from source to Flutter assets,
  release web, and APK.
- APK signature is cryptographically valid and non-debug.

## Visual evidence

- Baseline matrix: `assets/baseline/`
- Final web matrix: `assets/final/{phone,tablet,desktop}-{map,study,insights}.png`
- Modal proof: `assets/final/phone-tour.png`
- Browser capability proof: `assets/final/desktop-web-vault.png`
- Native runtime proof: `assets/final/android-phone-map.png` and
  `assets/final/android-tablet-map.png`
