# Verification

## Summary

- Result: passed
- Last verified: 2026-07-18T23:50:00+03:30
- Flutter: 3.44.0 stable
- Android target: emulator-5554, Android 15/API 35

## Data and Source Contracts

| Check | Command | Result |
|---|---|---|
| Migration idempotence | `node scripts/migrate_to_nardebam_only.mjs` | PASS: 3,672→3,672, zero removals/orphans/targets |
| Strict corpus validation | `node scripts/validate_comprehensive_dataset.mjs --strict-source-counts --asset` | PASS |
| Counts | validator | 3,672 total; Math 2,042; Physics 1,630; 29 topics |
| Media references | validator | 3,410 blocks/files resolve |
| Curriculum coverage | Flutter test | Every topic/question appears exactly once; sets ≤20 |
| Public copy boundary | Flutter test | Provider name absent from app/web copy |

## Flutter Quality

| Check | Result |
|---|---|
| `flutter analyze --no-pub` | PASS, no issues |
| `flutter test --reporter expanded` | PASS, 49 tests |
| Web release | PASS; Wasm dry run succeeded |
| Direct `/#/study` and `/#/insights` | PASS from fresh Chrome/CDP profiles |
| Phone and desktop screenshot inspection | PASS |

## Cross-Artifact Preservation

`tool/verify_release_artifacts.ps1` passed in strict mode:

| Artifact relation | Files | Bytes | Result |
|---|---:|---:|---|
| Source → Flutter question bank | 30 | 6,007,444 | PASS |
| Source → Web question bank | 30 | 6,007,444 | PASS |
| Source → APK question bank | 30 | 6,007,444 | PASS |
| Source → Flutter media | 3,410 | 66,450,076 | PASS |
| Source → Web media | 3,410 | 66,450,076 | PASS |
| Source → APK media | 3,410 | 66,450,076 | PASS |

## Release Artifact

- APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- Version: `1.0.90 (90)`
- Package: `com.gauss.app`
- Size: 141,323,633 bytes
- SHA-256:
  `959CBAF38D63439845129926B1FC5EB55667BEACD023C01304704D75CC3878AB`
- Signature: APK Signature Scheme v2, non-debug Gauss certificate.
- Certificate SHA-256:
  `F5:0C:33:38:BF:6C:1C:FB:E0:58:F6:EC:E5:79:E2:24:B2:D5:37:D1:25:48:A9:49:C3:5F:79:B5:73:B7:68:44`

## Android Runtime

| Proof | Result |
|---|---|
| `adb install -r` over v89 | PASS |
| First install time retained | PASS: 2026-07-18 13:02:33 |
| Cold launch | PASS: 6,316 ms |
| Hot foreground | PASS: 1,217 ms |
| Map → Study via semantic tab | PASS |
| Study → Study Room via semantic action | PASS |
| Native pen activation and DOWN/MOVE/UP stroke | PASS |
| Clear enabled after stroke, disabled after tap | PASS |
| Fatal/Flutter error scan after interactions | PASS: none |

## Expected Non-Blocking Environment Warnings

The Android 15 x86 emulator logged CPU-variant, JDWP, SELinux
`max_map_count`, and HWUI format warnings. There was no application crash,
ANR, Dart exception, or Flutter error.

## Trust Limitation

Source-provided answers and explanations are preserved but not independently
validated. The product deliberately labels them unverified and does not score
them.
