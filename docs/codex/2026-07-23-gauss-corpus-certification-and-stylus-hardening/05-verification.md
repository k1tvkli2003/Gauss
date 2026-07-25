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
| Luna screening 0015 | inspected blind batch + 9 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 25 needs repair |
| Luna screening 0016 | inspected blind batch + 9 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 25 needs repair |
| Luna screening 0017 | inspected blind batch + 3 original media; `merge-screening` | passed | 25 ordered/hash-bound rows; 25 needs repair |
| Parallel screening 0018 | isolated subagent + 5 original media; output-SHA attestation; `merge-screening` | passed | 25 ordered/hash-bound rows; 25 needs repair |
| Parallel screening 0019 | isolated subagent + 4 original media; output-SHA attestation; `merge-screening` | passed | 7 ordered/hash-bound rows; 7 needs repair |
| Parallel screening 0020 | isolated subagent + 4 original media; output-SHA attestation; `merge-screening` | passed | 25 ordered/hash-bound rows; 8 accepted, 14 needs repair, 3 ambiguous |
| Parallel screening 0021 | isolated subagent + 5 original media; output-SHA attestation; `merge-screening` | passed | 25 ordered/hash-bound rows; 13 accepted, 11 needs repair, 1 ambiguous |
| Parallel screening 0022 | isolated subagent + 16 original media; output-SHA attestation; `merge-screening` | passed | 25 ordered/hash-bound rows; 6 accepted, 18 needs repair, 1 ambiguous |
| Parallel screening 0023 | fresh blind subagent + 22 original media; output-SHA attestation; `merge-screening` | passed after rejecting first run | 25 ordered/hash-bound rows; 2 accepted, 12 needs repair, 11 ambiguous |
| Parallel screening 0024 | isolated subagent; output-SHA attestation; `merge-screening` | passed | 25 ordered/hash-bound rows; 7 accepted, 8 needs repair, 10 ambiguous |
| Parallel screening 0025 | isolated subagent + 11 original media; output-SHA attestation; `merge-screening` | passed | 25 ordered/hash-bound rows; 3 accepted, 22 needs repair |
| Parallel screening 0026 | isolated subagent + 5 original media; output-SHA attestation; `merge-screening` | passed | 25 ordered/hash-bound rows; 9 accepted, 16 needs repair |
| Parallel screening 0027 | isolated subagent + 2 original media; coordinator rejection, worker correction, output-SHA attestation; `merge-screening` | passed | 25 rows; 19 needs repair, 6 ambiguous |
| Parallel screening 0028 | isolated subagent + 32 original media; output-SHA attestation; `merge-screening` | passed | 23 rows; 1 accepted, 22 needs repair |
| Parallel screening 0029 | isolated subagent + 22 original media; coordinator rejection, worker correction, output-SHA attestation; `merge-screening` | passed | 25 rows; 8 accepted, 17 needs repair |
| Parallel screening 0030 | isolated subagent + 28 original media; coordinator rejection, worker correction, output-SHA attestation; `merge-screening` | passed | 16 rows; 11 accepted, 5 needs repair |
| Parallel screening 0031 | isolated subagent + 17 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 17 needs repair, 8 ambiguous |
| Parallel screening 0032 | isolated subagent + 28 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 4 accepted, 8 needs repair, 13 ambiguous |
| Parallel screening 0033 | isolated subagent + 26 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 3 accepted, 13 needs repair, 9 ambiguous |
| Parallel screening 0034 | isolated subagent + 4 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 4 accepted, 21 needs repair |
| Parallel screening 0035 | isolated subagent + 13 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 2 accepted, 23 needs repair |
| Parallel screening 0036 | isolated subagent + 22 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 24 needs repair, 1 ambiguous |
| Parallel screening 0037 | isolated subagent + 30 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 24 needs repair, 1 ambiguous |
| Parallel screening 0038 | isolated subagent + 28 original media; coordinator blocker rejection, worker correction, output-SHA attestation; `merge-screening` | passed | 25 rows; 25 needs repair |
| Parallel screening 0039 | isolated subagent + 26 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 23 needs repair, 2 ambiguous |
| Parallel screening 0040 | isolated subagent + 12 original media; output-SHA attestation; `merge-screening` | passed | 11 rows; 11 ambiguous |
| Parallel screening 0041 | isolated subagent + 11 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 8 accepted, 14 needs repair, 3 ambiguous |
| Parallel screening 0042 | isolated subagent + 14 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 24 needs repair, 1 ambiguous |
| Parallel screening 0043 | isolated subagent + 3 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 10 needs repair, 15 ambiguous |
| Parallel screening 0044 | isolated subagent + 12 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 25 needs repair |
| Parallel screening 0045 | isolated subagent + 3 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 12 accepted, 11 needs repair, 2 ambiguous |
| Parallel screening 0046 | isolated subagent + 2 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 17 accepted, 8 needs repair |
| Parallel screening 0047 | isolated subagent + 28 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 16 accepted, 3 needs repair, 6 ambiguous |
| Parallel screening 0048 | isolated subagent + 3 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 19 accepted, 6 needs repair |
| Parallel screening 0049 | isolated subagent + 1 original media; output-SHA attestation; `merge-screening` | passed | 15 rows; 10 accepted, 4 needs repair, 1 ambiguous |
| Parallel screening 0050 | isolated subagent + 15 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 15 accepted, 3 needs repair, 7 ambiguous |
| Parallel screening 0051 | isolated Sol subagent + 2 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 20 accepted, 4 needs repair, 1 ambiguous |
| Parallel screening 0052 | isolated Sol subagent + 2 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 15 accepted, 8 needs repair, 2 ambiguous |
| Parallel screening 0053 | isolated Sol subagent + 1 original media; output-SHA attestation; `merge-screening` | passed | 17 rows; 11 accepted, 5 needs repair, 1 ambiguous |
| Parallel screening 0054 | isolated Sol subagent + 33 original media; output-SHA attestation; `merge-screening` | passed | 19 rows; 18 needs repair, 1 ambiguous |
| Parallel screening 0055 | isolated Sol subagent + 13 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 21 needs repair, 4 ambiguous |
| Parallel screening 0056 | isolated Sol subagent + 5 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 25 needs repair |
| Parallel screening 0057 | isolated Sol subagent + 12 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 21 needs repair, 4 ambiguous |
| Parallel screening 0058 | isolated Sol subagent + 8 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 7 accepted, 12 needs repair, 6 ambiguous |
| Parallel screening 0059 | isolated Sol subagent + 8 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 7 accepted, 18 needs repair |
| Parallel screening 0060 | isolated Sol subagent + 30 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 10 accepted, 15 needs repair |
| Parallel screening 0061 | isolated Sol subagent + 4 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 16 accepted, 9 needs repair |
| Parallel screening 0062 | isolated Sol subagent + 30 original media; output-SHA attestation; `merge-screening` | passed | 22 rows; 10 accepted, 11 needs repair, 1 ambiguous |
| Parallel screening 0063 | isolated Sol subagent + 7 original media; output-SHA attestation; `merge-screening` | passed | 3 rows; 3 accepted |
| Parallel screening 0065 | isolated Sol subagent + 2 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 5 accepted, 15 needs repair, 5 ambiguous |
| Parallel screening 0064 | isolated Sol subagent + 24 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 2 accepted, 17 needs repair, 6 ambiguous |
| Parallel screening 0066 | isolated Sol subagent + 13 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 6 accepted, 14 needs repair, 5 ambiguous |
| Parallel screening 0068 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 2 rows; 2 needs repair |
| Post-merge corpus reconciliation | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 1543 screened; 0 usable |
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
- پس از 67 خروجی screening معتبر، 957 مورد needs repair و 155 مورد ambiguous هستند؛ هیچ‌کدام usable نشده‌اند.
