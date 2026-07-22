# Verification

## Summary
- Result: passed
- Last verified: 2026-07-23T01:45:00+03:30

## Checks
| Check | Command/Method | Result | Evidence |
|---|---|---|---|
| Git baseline | `git status --short --branch` | passed | clean `main...origin/main` قبل از docs |
| Static analysis | `dart analyze --fatal-infos` | passed | No issues found |
| Test baseline | `flutter test --no-pub --reporter compact` | passed | 75/75؛ data/media/route/ink/persistence included |
| Critics PDF | renderer + `pdftoppm -png -r 120` + visual inspection | passed | 16/16 pages legible; no clipped/orphan page |
| Runtime baseline visuals | inspect existing phone/tablet/desktop screenshots | passed | Map، Study، Insights، Vault، tour |
| Post-change static analysis | `dart analyze --fatal-infos` | passed | No issues found after adaptive/state slices |
| Android experience | full test file | passed | 11/11 incl. 599/600/1440 live shell، 200% Map/tour |
| Study experience | full test file | passed | 17/17 incl. 1×4/2×2/4×1، 840 split، ink lock، scratch bounds، Insights row، 200% matrix |
| Mission regression | full test file | passed | 6/6 |
| Web release build | `flutter build web --release --no-pub` | passed | Wasm dry run passed؛ `main.dart.js` 3,786,439 bytes |
| Final static analysis | `dart analyze --fatal-infos` | passed | No issues found |
| Final Flutter suite | `flutter test --no-pub --reporter compact` | passed | 86/86 |
| Final web release | `flutter build web --release --no-pub --no-wasm-dry-run` | passed | 3,521 files / 131,092,669 bytes / `main.dart.js` 3,768,732 bytes |
| Final signed APK | artifact verifier + `aapt` + `apksigner` | passed | `com.gauss.app` 1.0.106 (106), v2 valid, SHA-256 `BD42A22CA047CC04699A4B9133251A15795F14FECE8C4141788D8F0F2E34CD1F` |
| Exact content preservation | `verify_release_artifacts.ps1` | passed | question bank 30 / 6,007,444 bytes; media 3,410 / 66,450,076 bytes in source/Flutter/Web/APK |
| In-place Android upgrade | `adb install -r` on existing signed v105 | passed | version 105→106; `firstInstallTime=2026-07-18 13:02:33` unchanged |
| Final runtime Map visuals | CDP + Android release screenshots + visual inspection | passed | [web phone](assets/runtime/phone-map-copy-reference-final-v2.png), [web tablet](assets/runtime/tablet-map-copy-reference-final.png), [Android phone](assets/runtime/android-phone-map-copy-reference-v106.png), [Android tablet](assets/runtime/android-tablet-map-copy-reference-v106.png) |

## Not Run
- physical-device profile؛ دستگاه فیزیکی در دسترس نیست.

## Known Issues
- physical-device battery/thermal/jank claims remain intentionally unmade.
