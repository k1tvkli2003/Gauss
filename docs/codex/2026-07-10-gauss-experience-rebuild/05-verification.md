# Verification

## Summary

- Result: passed
- Scope note: every in-scope gate available on this host passed.
- Last verified: 2026-07-15T15:10:59+03:30
- Flutter: 3.44.0 stable
- Dart: 3.12.0
- Android package: `com.gauss.app`
- App version: `1.0.0+1`

## Code and Contract Checks

| Check | Command/Method | Result | Evidence |
|---|---|---|---|
| Static analysis | `flutter analyze --no-pub` | passed | Zero issues |
| Flutter tests | `flutter test --no-pub` | passed | 27 tests |
| Dataset/source baseline | `node scripts/validate_comprehensive_dataset.mjs --asset --strict-source-counts` | passed | 7,353 questions; 3,410 media files |
| Typed question contract | `question_contract_test.dart` | passed | 3,681 mission-ready; 3,672 preserved archive; 3,610 displayed solutions; 71 withheld conflicts |
| Mission safety | Contract tests + direct route QA | passed | Nardebam source requests return no mission-ready questions |
| Duplicate safety | Full-bank contract test | passed | Zero duplicate mission-ready content |
| Progress/reward behavior | Repository and catalog tests | passed | Resume, SRS, idempotent events, daily quest, achievements, and local midnight |

## Dataset and Media Parity

| Protected tree | Files | Bytes | Baseline digest/result |
|---|---:|---:|---|
| Bundled question bank | 30 | 12,654,640 | `94d0153f94863ec9ee66e41e28b3c2021144a42350a133e9926b39f1ba8d0713` |
| Question media | 3,410 | 66,450,076 | `00e4eb33f1215ce8b8cf104baebb7c0b0a858137032f535c1e7b4c3b6ca3c320` |
| Comprehensive source tree | 57 | 17,114,082 | `0b3c252159923c98b11e748c826b3137d00f5386df6275d0f623b1c691b10db5` |

`tool/verify_release_artifacts.ps1` passed exact relative-path, byte-length, and SHA-256 equality from protected source to Flutter assets, release web output, the universal APK, and all three ABI-split APKs.

## Release Builds

| Target | Command | Result |
|---|---|---|
| Web | `flutter build web --release --no-pub` | passed; WebAssembly dry run succeeded |
| Universal Android | `flutter build apk --release --no-pub` | passed |
| ABI-split Android | `flutter build apk --release --split-per-abi --no-pub` | passed |

### Android artifacts

| Artifact | Bytes | Version code | SHA-256 |
|---|---:|---:|---|
| `app-release.apk` | 131,979,493 | 1 | `0702103BCF65B4C856DD0388E5C15FA9A0F8DC6CAE1489153C9923A5BBF79364` |
| `app-arm64-v8a-release.apk` | 92,072,593 | 2001 | `E884EF4113B943780ADFC165D1B8EBA9AB2E6F08E7981493BD72E98C306126B9` |
| `app-armeabi-v7a-release.apk` | 89,580,445 | 1001 | `C7E5681613FFDCA687A4CDE756112EBF214596640774FF056D346BF173D37563` |
| `app-x86_64-release.apk` | 93,509,285 | 4001 | `C507246D518A3CFC7C294580B9FF260FF45C4197D27FD2F48398F5CA74435964` |

All APKs report compile/target SDK 36, valid package metadata, and a valid APK v2 signature. The current certificate is the debug fallback (`C=US, O=Android, CN=Android Debug`, SHA-256 `33c955a5b237ce4d1b8ee44f7873f091ed60c14de1acaf99c772329bd5e37c85`).

### Web output

| File | Bytes |
|---|---:|
| `main.dart.js` | 3,606,732 |
| `sqlite3.wasm` | 733,662 |
| `drift_worker.dart.js` | 349,350 |

## Browser Runtime QA

- Release bundle served locally and exercised at compact 391x844 CSS and expanded 1440x900 CSS layouts.
- Map, Practice, Insights, normal mission, correct-answer solution reveal, direct archive route, and disabled zero-ready topic state passed.
- No horizontal overflow occurred in the tested compact or expanded surfaces.
- All seven badge semantics reported clear progress descriptions.
- `absolute_value_floor` truthfully reports `0 ready / 132 preserved` and cannot start a scored mission.
- A direct Nardebam route returns the safe no-mission-ready state.
- Final browser log contained zero warnings and zero errors.

## Performance and Bundle Check

- Question media remain lazy-loaded.
- The unused legacy map background remains preserved in the workspace but is no longer declared as a Flutter runtime asset.
- The final universal APK is approximately 1.51 MB smaller than the original release measurement (131,979,493 vs 133,494,254 bytes).

## Limitations

- No Android emulator or physical device was connected. An actual device launch was therefore not available.
- Production/store signing was not possible without a user-owned keystore. Environment-driven release signing is already supported by `android/app/build.gradle.kts` through `GAUSS_KEYSTORE_*` variables.
- Visual Studio is missing for Windows desktop, which is outside the requested Android/web scope.
