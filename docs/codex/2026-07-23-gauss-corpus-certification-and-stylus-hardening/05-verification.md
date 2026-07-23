# Verification

## Summary
- Result: partial
- Last verified: 2026-07-23T16:41:06+03:30

## Checks
| Check | Command/Method | Result | Evidence |
|---|---|---|---|
| Certification syntax | `node --check scripts/corpus_certification.mjs` | passed | valid Node module |
| Canonical/runtime/media baseline | `node scripts/corpus_certification.mjs baseline` | passed | 3672 records; 3410 files; 66,450,076 bytes |
| Certification reconciliation | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound; 0 usable |
| Weighted sharding | `... shard --size=25 --max-weight=120` | passed | 179 batches; 0 cross-topic; max 120 |
| Luna screening 0001 | inspected blind batch + 19 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 6 accepted, 17 needs repair, 2 ambiguous |
| Luna screening 0002 | inspected blind batch + 6 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 25 needs repair |
| Luna screening 0003 | inspected blind batch + 3 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 11 accepted, 13 needs repair, 1 ambiguous |
| Luna screening 0004 | inspected blind batch; `merge-screening` | passed | 25 ordered/hash-bound rows; 18 accepted, 6 needs repair, 1 ambiguous |
| Luna screening 0005 | inspected blind batch + 1 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 16 accepted, 9 needs repair |
| Luna screening 0006 | inspected blind batch + 8 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 15 accepted, 10 needs repair |
| Luna screening 0007 | inspected blind batch + 17 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 21 accepted, 3 needs repair, 1 ambiguous |
| Luna screening 0008 | inspected blind batch; `merge-screening` | passed | 25 ordered/hash-bound rows; 21 accepted, 4 needs repair |
| Luna screening 0009 | inspected blind batch + 2 original media; `merge-screening` | passed | 15 ordered/hash-bound rows; 6 accepted, 9 needs repair |
| Luna screening 0010 | inspected blind batch + 14 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 5 accepted, 19 needs repair, 1 ambiguous |
| Luna screening 0011 | inspected blind batch + 6 original media; `merge-screening` | passed | 21 ordered/hash-bound rows; 13 accepted, 7 needs repair, 1 ambiguous |
| Luna screening 0012 | inspected blind batch + 24 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 9 accepted, 16 needs repair |
| Luna screening 0013 | inspected blind batch + 32 original media; `merge-screening` | passed | 22 ordered/hash-bound rows; 22 needs repair |
| Luna screening 0014 | inspected blind batch + 19 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 25 needs repair |
| Post-merge corpus reconciliation | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 333 screened; 0 usable |
| Static analysis | `flutter analyze --fatal-infos` | passed | No issues found |
| Full Flutter suite | `flutter test --no-pub --reporter compact` | passed | 94/94 |
| Corpus TeX gate | full corpus parser test | passed | 3672 questions; 22032 text blocks; >37000 formulas |
| Display math layout | phone / 200% widget test | passed | display row below inline row, no exception |
| Stylus behavior | focused widget tests | passed | pressure, cancel, palm identity, multitouch, controller swap |
| Web release 1.0.107 | `flutter build web --release ...` | passed | Wasm dry run passed |
| Signed APK 1.0.107 | protected Credential Manager build | passed | 141,818,161 bytes; SHA-256 `13469590CE2A8A109A1295606DB9E90220217968B8C2F56AAD4ECEC293AC1EB4` |
| Signing continuity | `apksigner` + exact SHA-256 | passed | v2; Gauss fingerprint `F50C...B76844`; non-debug |
| Zip alignment | `zipalign -c -P 16 -v 4` | passed | verification successful |
| Release data parity | `tool/verify_release_artifacts.ps1` | passed | 30 bank files and 3410 media identical in source/Flutter/Web/APK |

## Not Run
- اجرای physical Xiaomi Focus Pen؛ دستگاه متصل نیست.
- Android runtime launch/screenshot این slice؛ `adb devices` هیچ target نشان نداد.
- source-PDF fidelity؛ مسیر اصل PDFها در environment حاضر نیست.
- mathematical certification؛ 0/3672 تا این checkpoint؛ screening فقط taxonomy/extraction/difficulty است و پاسخ را تأیید نمی‌کند.

## Known Issues
- 409 extraction blockers و سایر risk queues در `02-state.md`.
- هیچ سؤال هنوز certification علمی کامل ندارد و نباید certified ادعا شود.
- Jules source برای Gauss متصل نیست.
- در یازده batch نخست، 122 مورد needs repair و 7 مورد ambiguous هستند؛ هیچ‌کدام usable نشده‌اند.
