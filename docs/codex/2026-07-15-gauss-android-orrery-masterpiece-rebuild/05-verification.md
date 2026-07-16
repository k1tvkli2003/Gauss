# Verification

## Summary

- Result: `PASS`
- Last verified: 2026-07-16T23:38:58+03:30
- Scope: Android phone + tablet, release artifact, code quality, behavior, accessibility, data/media preservation.

## Automated checks

| Check | Command / method | Result | Evidence |
|---|---|---|---|
| Static analysis | `flutter analyze --no-pub` | PASS | No issues found. |
| Flutter tests | `flutter test --no-pub` | PASS | 35 tests passed. |
| Android entry contract | `android_experience_test.dart` | PASS | namespace/applicationId/activity/adaptive icon aligned to `com.gauss.app`. |
| Theme/font contract | widget/source tests | PASS | Manrope primary, Vazirmatn Persian fallback, OFL bundled. |
| Startup contract | widget test | PASS | Branded startup appears before controller initialization finishes. |
| Accessibility | widget tests | PASS | semantic wordmark, text scale 1.5, reduced motion and long mixed RTL/LTR math. |
| Adaptive layout | widget tests | PASS | phone path and tablet radial map render without overflow. |
| Dataset invariants | `question_contract_test.dart` | PASS | 7,353 total; 29 shards; 3,681 mission-ready; 3,672 reference-only; 3,610 verified explanations. |
| Media invariants | `question_contract_test.dart` | PASS | 3,410 files; 66,450,076 bytes. |

## Release artifact

| Check | Result |
|---|---|
| Path | `flutter_app/build/app/outputs/flutter-apk/app-release.apk` |
| Size | 143,048,138 bytes |
| SHA-256 | `D89C90814482AD7340377A71BB69F2CBB6D5CC7F2461438A887B7ACA243A9ABA` |
| Package | `com.gauss.app` |
| Version | `1.0.0` (`versionCode=1`) |
| SDK | `minSdk=26`, `targetSdk=36` |
| Activity | `com.gauss.app.MainActivity` |
| ABI | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| Signing | APK Signature Scheme v2 verified; one signer. |
| Debuggable | absent from release manifest. |
| Network permission | absent; offline-first package. |
| Screens | small/normal/large/xlarge; all densities. |

## Runtime acceptance

| Scenario | Result | Evidence |
|---|---|---|
| Phone cold launch, API 35, 1080×2400 | PASS | `Status: ok`, `LaunchState: COLD`, `TotalTime: 1893ms` on software renderer. |
| Tablet cold launch, API 35, 2560×1600 @ density 320 | PASS | `Status: ok`, `LaunchState: COLD`, `TotalTime: 3240ms`; [screenshot](assets/release-tablet-map.png). |
| Tablet portrait cold launch, API 35, 1600×2560 @ density 320 | PASS | `Status: ok`, `LaunchState: COLD`, `TotalTime: 3056ms`; [screenshot](assets/release-tablet-portrait-map.png). |
| Phone font scale 1.5 | PASS | Runtime setting confirmed `1.5`; [screenshot](assets/release-phone-font150.png). |
| Mission question | PASS | Real Persian stem and math; [screenshot](assets/release-phone-mission.png). |
| Mission completion | PASS | 10 skips, 0%, Mira thinking, reward ledger; [screenshot](assets/release-phone-complete.png). |
| Main surfaces | PASS | [Map](assets/release-phone-map.png), [Practice](assets/release-phone-practice.png), [Insights](assets/release-phone-insights.png). |

## Honest limitations

- امضای فعلی certificate پیش‌فرض Android Debug دارد، چون متغیرهای keystore شخصی در محیط تعریف نشده‌اند. امضا cryptographically معتبر و برای sideload شخصی مناسب است؛ release عمومی به keystore نگهداری‌شده توسط کاربر نیاز دارد.
- API 37 16KB-page emulator در مسیر screenshot یک assertion مربوط به renderer داشت. package روی همان image نصب و resolve شد، اما مدرک بصری نهایی روی API 35 software renderer پایدار گرفته شد.
