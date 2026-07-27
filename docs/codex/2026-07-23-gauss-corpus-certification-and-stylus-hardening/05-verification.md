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
| Parallel screening 0067 | isolated Sol subagent + 2 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 5 accepted, 18 needs repair, 2 ambiguous |
| Parallel screening 0069 | isolated Sol subagent + 9 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 9 accepted, 13 needs repair, 3 ambiguous |
| Parallel screening 0071 | isolated Sol subagent + 2 original media; output-SHA attestation; `merge-screening` | passed | 19 rows; 10 accepted, 9 needs repair |
| Parallel screening 0070 | isolated Sol subagent + 16 original media; output-SHA attestation; coordinator rejection, fail-closed correction, `merge-screening` | passed | 25 rows; 13 accepted, 12 needs repair |
| Parallel screening 0072 | isolated Sol subagent + 14 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 13 needs repair, 12 ambiguous |
| Parallel screening 0073 | isolated Sol subagent + 8 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 21 needs repair, 4 ambiguous |
| Parallel screening 0074 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 25 rows; 25 needs repair |
| Parallel screening 0075 | isolated Sol subagent + 4 original media; output-SHA attestation; `merge-screening` | passed | 22 rows; 3 accepted, 19 needs repair |
| Parallel screening 0076 | isolated Sol subagent + 1 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 23 needs repair, 2 ambiguous |
| Parallel screening 0077 | isolated Sol subagent + 1 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 24 needs repair, 1 ambiguous |
| Parallel screening 0078 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 25 rows; 25 needs repair |
| Parallel screening 0079 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 13 rows; 13 needs repair |
| Parallel screening 0080 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 6 rows; 6 needs repair |
| Parallel screening 0082 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 7 rows; 7 needs repair |
| Parallel screening 0083 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 7 rows; 7 needs repair |
| Parallel screening 0081 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 6 rows; 6 needs repair |
| Parallel screening 0084 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 7 rows; 7 needs repair |
| Parallel screening 0085 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 7 rows; 7 needs repair |
| Parallel screening 0086 | isolated Sol subagent + 37 original media; output-SHA attestation; `merge-screening` | passed | 9 rows; 9 needs repair |
| Parallel screening 0087 | isolated Sol subagent + 33 original media; output-SHA attestation; `merge-screening` | passed | 17 rows; 1 accepted, 16 needs repair |
| Parallel screening 0088 | isolated Sol subagent + 19 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 4 accepted, 21 needs repair |
| Parallel screening 0089 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 9 rows; 9 needs repair |
| Parallel screening 0090 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 7 rows; 7 needs repair |
| Parallel screening 0091 | isolated Sol subagent + 30 original media; output-SHA attestation; `merge-screening` | passed | 6 rows; 6 needs repair |
| Parallel screening 0092 | isolated Sol subagent + 19 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 21 accepted, 4 needs repair |
| Parallel screening 0093 | isolated Sol subagent + 29 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 8 accepted, 9 needs repair, 8 ambiguous |
| Parallel screening 0094 | isolated Sol subagent + 23 original media; output-SHA attestation; `merge-screening` | passed | 13 rows; 2 accepted, 11 needs repair |
| Parallel screening 0095 | isolated Sol subagent + 36 original media; output-SHA attestation; `merge-screening` | passed | 9 rows; 9 needs repair |
| Parallel screening 0096 | isolated Sol subagent + 34 original media; output-SHA attestation; `merge-screening` | passed | 6 rows; 6 needs repair |
| Parallel screening 0097 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 6 rows; 6 needs repair |
| Parallel screening 0098 | isolated Sol subagent + 34 original media; output-SHA attestation; `merge-screening` | passed | 6 rows; 6 needs repair; one extraction incomplete |
| Parallel screening 0099 | isolated Sol subagent + 35 original media; output-SHA attestation; `merge-screening` | passed | 6 rows; 6 needs repair |
| Parallel screening 0101 | isolated Sol subagent + 33 original media; output-SHA attestation; `merge-screening` | passed | 5 rows; 4 needs repair, 1 ambiguous |
| Parallel screening 0100 | isolated Sol subagent + 36 original media; output-SHA attestation; `merge-screening` | passed | 6 rows; 6 needs repair; one extraction incomplete |
| Parallel screening 0102 | isolated Sol subagent + 6 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 15 accepted, 9 needs repair, 1 ambiguous |
| Parallel screening 0103 | isolated Sol subagent + 14 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 23 accepted, 2 needs repair |
| Parallel screening 0104 | isolated Sol subagent + 29 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 11 accepted, 2 needs repair, 12 ambiguous |
| Parallel screening 0105 | isolated Sol subagent + 32 original media; output-SHA attestation; `merge-screening` | passed | 23 rows; 10 accepted, 5 needs repair, 8 ambiguous |
| Parallel screening 0106 | isolated Sol subagent; output-SHA attestation; coordinator fail-closed correction; `merge-screening` | passed | 15 rows; 2 accepted, 2 needs repair, 11 ambiguous |
| Parallel screening 0107 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 18 rows; 5 accepted, 13 ambiguous |
| Parallel screening 0108 | isolated Sol subagent + 34 original media; output-SHA attestation; `merge-screening` | passed | 17 rows; 1 accepted, 13 needs repair, 3 ambiguous |
| Parallel screening 0109 | isolated Sol subagent + 34 original media; output-SHA attestation; `merge-screening` | passed | 18 rows; 18 accepted |
| Parallel screening 0110 | isolated Sol subagent + 9 original media; output-SHA attestation; `merge-screening` | passed | 5 rows; 2 accepted, 3 needs repair |
| Parallel screening 0114 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 25 rows; 9 accepted, 16 needs repair |
| Parallel screening 0113 | isolated Sol subagent; coordinator fail-closed correction; output-SHA attestation; `merge-screening` | passed | 25 rows; 6 accepted, 17 needs repair, 2 ambiguous |
| Parallel screening 0115 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 2 rows; 1 accepted, 1 needs repair |
| Parallel screening 0116 | isolated Sol subagent + 12 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 16 accepted, 5 needs repair, 4 ambiguous |
| Parallel screening 0117 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 25 rows; 11 accepted, 14 needs repair |
| Parallel screening 0118 | isolated Sol subagent + 19 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 25 needs repair |
| Parallel screening 0119 | isolated Sol subagent + 20 original media; output-SHA attestation; `merge-screening` | passed | 25 rows; 25 needs repair |
| Parallel screening 0120 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 23 rows; 20 needs repair, 3 ambiguous |
| Parallel screening 0121 | isolated Sol subagent; output-SHA attestation; `merge-screening` | passed | 25 rows; 23 needs repair, 2 ambiguous |
| Flutter baseline suite | `flutter test --no-pub --reporter compact` | passed | 94/94 tests; map/study/scratch responsive and native interaction contracts green |
| Flutter static analysis | `flutter analyze --fatal-infos` | passed | No issues found |
| Post-merge corpus reconciliation | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2265 screened; 0 usable |
| Post-merge corpus reconciliation (0116) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2290 screened; 0 usable |
| Post-merge corpus reconciliation (0118) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2340 screened; 0 usable |
| Post-merge corpus reconciliation (0121) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2413 screened; 0 usable |
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
| Post-merge corpus reconciliation (0124) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2483 screened (67.62%); 0 usable; 3337 repair tickets |
| Repair queue regeneration (0124) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3337 hash-bound tickets; 3069 P0 render/prompt, 268 P1 correctness |
| Repair overlay gate (0124) | `node scripts/corpus_certification.mjs validate-repairs` | passed | No overlays proposed; source-preserving repair queue remains fail-closed |
| Flutter Web release (current) | `flutter build web --release --no-wasm-dry-run` | passed | `build/web` generated successfully |
| Post-merge corpus reconciliation (0127) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2510 screened (68.36%); 0 usable; 3324 repair tickets |
| Repair queue regeneration (0127) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3324 hash-bound tickets; 3056 P0 render/prompt, 268 P1 correctness |
| Post-merge corpus reconciliation (0126) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2535 screened (69.04%); 0 usable; 3311 repair tickets |
| Repair queue regeneration (0126) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3311 hash-bound tickets; 3043 P0 render/prompt, 268 P1 correctness |
| Post-merge corpus reconciliation (0130) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2556 screened (69.61%); 0 usable; 3300 repair tickets |
| Repair queue regeneration (0130) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3300 hash-bound tickets; 3032 P0 render/prompt, 268 P1 correctness |
| Post-merge corpus reconciliation (0133) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2657 screened (72.36%); 0 usable; 3227 repair tickets |
| Repair queue regeneration (0133) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3227 hash-bound tickets; 2956 P0 render/prompt, 271 P1 correctness |
| Coordinator fail-closed repair (0128) | output reclassification + SHA/attestation update | passed | One contradictory accepted row moved to needs_repair; no source JSON/media deleted or overwritten |
| Post-merge corpus reconciliation (0137) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2715 screened (73.94%); 0 usable; 3184 repair tickets |
| Repair queue regeneration (0137) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3184 hash-bound tickets; 2911 P0 render/prompt, 273 P1 correctness |
| Post-merge corpus reconciliation (0142) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2830 screened (77.07%); 0 usable; 3164 repair tickets |
| Repair queue regeneration (0142) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3164 hash-bound tickets; 2891 P0 render/prompt, 273 P1 correctness |
| Trusted retry (0139) | replacement output + retry attestation | passed | Original worker stalled; trusted retry produced 25/25 needs_repair and revalidated all 30 media assets |
| Post-merge corpus reconciliation (0145) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2897 screened (78.89%); 0 usable; 3130 repair tickets |
| Repair queue regeneration (0145) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3130 hash-bound tickets; 2854 P0 render/prompt, 276 P1 correctness |
| Post-merge corpus reconciliation (0147) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2947 screened (80.26%); 0 usable; 3108 repair tickets |
| Repair queue regeneration (0147) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3108 hash-bound tickets; 2828 P0 render/prompt, 280 P1 correctness |
| Post-merge corpus reconciliation (0149) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 2997 screened (81.62%); 0 usable; 3080 repair tickets |
| Repair queue regeneration (0149) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3080 hash-bound tickets; 2796 P0 render/prompt, 284 P1 correctness |
| Post-merge corpus reconciliation (0151) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3042 screened (82.84%); 0 usable; 3050 repair tickets |
| Repair queue regeneration (0151) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3050 hash-bound tickets; 2765 P0 render/prompt, 285 P1 correctness |
| Post-merge corpus reconciliation (0152) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3053 screened (83.14%); 0 usable; 3050 repair tickets |
| Repair queue regeneration (0152) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3050 hash-bound tickets; 2765 P0 render/prompt, 285 P1 correctness |
| Post-merge corpus reconciliation (0155) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3124 screened (85.08%); 0 usable; 3011 repair tickets |
| Repair queue regeneration (0155) | `node scripts/corpus_certification.mjs repair-queue` | passed | 3011 hash-bound tickets; 2725 P0 render/prompt, 286 P1 correctness |
| Post-merge corpus reconciliation (0158) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3159 screened (86.03%); 0 usable; 2981 repair tickets |
| Repair queue regeneration (0158) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2981 hash-bound tickets; 2695 P0 render/prompt, 286 P1 correctness |
| Post-merge corpus reconciliation (0157) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3175 screened (86.47%); 0 usable; 2967 repair tickets |
| Repair queue regeneration (0157) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2967 hash-bound tickets; 2681 P0 render/prompt, 286 P1 correctness |
| Post-merge corpus reconciliation (0160) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3208 screened (87.36%); 0 usable; 2946 repair tickets |
| Repair queue regeneration (0160) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2946 hash-bound tickets; 2659 P0 render/prompt, 287 P1 correctness |
| Post-merge corpus reconciliation (0162) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3258 screened (88.73%); 0 usable; 2935 repair tickets |
| Repair queue regeneration (0162) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2935 hash-bound tickets; 2646 P0 render/prompt, 289 P1 correctness |
| Post-merge corpus reconciliation (0165) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3333 screened (90.77%); 0 usable; 2935 repair tickets |
| Repair queue regeneration (0165) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2935 hash-bound tickets; 2646 P0 render/prompt, 289 P1 correctness |
| Post-merge corpus reconciliation (0167) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3383 screened (92.13%); 0 usable; 2935 repair tickets |
| Repair queue regeneration (0167) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2935 hash-bound tickets; 2646 P0 render/prompt, 289 P1 correctness |
| Post-merge corpus reconciliation (0168) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3403 screened (92.67%); 0 usable; 2930 repair tickets |
| Repair queue regeneration (0168) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2930 hash-bound tickets; 2640 P0 render/prompt, 290 P1 correctness |
| Post-merge corpus reconciliation (0171) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3463 screened (94.31%); 0 usable; 2916 repair tickets |
| Repair queue regeneration (0171) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2916 hash-bound tickets; 2626 P0 render/prompt, 290 P1 correctness |
| Post-merge corpus reconciliation (0174) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3516 screened (95.75%); 0 usable; 2891 repair tickets |
| Repair queue regeneration (0174) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2891 hash-bound tickets; 2601 P0 render/prompt, 290 P1 correctness |
| Post-merge corpus reconciliation (0177) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3591 screened (97.79%); 0 usable; 2836 repair tickets |
| Repair queue regeneration (0177) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2836 hash-bound tickets; 2544 P0 render/prompt, 292 P1 correctness |
| Post-merge corpus reconciliation (0179) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3630 screened (98.86%); 0 usable; 2814 repair tickets |
| Repair queue regeneration (0179) | `node scripts/corpus_certification.mjs repair-queue` | passed | 2814 hash-bound tickets; 2520 P0 render/prompt, 294 P1 correctness |
| Full corpus reconciliation (0111/0112 retries) | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound records; 3672 screened (100%); 0 usable; 2791 repair tickets |
| Final screening repair queue regeneration | `node scripts/corpus_certification.mjs repair-queue` | passed | 2791 hash-bound tickets; 2488 P0 render/prompt, 303 P1 correctness |
| Repair overlay gate after full screening | `node scripts/corpus_certification.mjs validate-repairs` | passed | No overlays proposed; source-preserving repair queue remains fail-closed |
| Blind solve/verifier evidence slice 0001 | `.codex-tmp/answer-review-0001.jsonl` + `.codex-tmp/verify-review-0001.jsonl` | passed | 5/5 independent options agreed; evidence hashes `355781638a469f3a8088e4a79b4ce3ba8f7ff3cd6c3778683ed9e730e5a1a04b`, `531d48eccf9fbf24d3ca566282306a0df4701797705246b5f486f555d63621f8`; no source key was exposed to workers |
| Blind solve/verifier evidence slice 0002 | `evidence/answer-review-0002.jsonl` + `evidence/verify-review-0002.jsonl` | passed | 5/5 independent options agreed; evidence hashes `517ba0224ccde5238ef86c16d8689c8b939e68957f55e8609d1aece8bf1ef4ed`, `e9d4d265a93ba59e30d5303d80a282df35b5700da9a5193a9fa8e754164f2cf8`; no source key was exposed to workers |
| Independent solution-review evidence slice 0001 | `evidence/solution-review-0001a.jsonl` + `evidence/solution-review-0001b.jsonl` | passed | 5/5 `holds`, complete, correct from two independent reviewers; evidence hashes `11ad9038d8b319a54e123209bb4452dd2d315aaf100d6ce476a27e2137e40a04`, `22ed67eae6dfa28d570c37ff2ab1f181460019306db33d5ad580b10036c36b1d` |
| Independent adversarial-review evidence slice 0001 | `evidence/adversarial-review-0001.jsonl` | passed | 5/5 adversarial attacks passed with no blockers; evidence SHA-256 `f8cab2cea3d317ae0d7c5dc5c67ef38e7479830468beda7887eb6d12d6b71997`; source-fidelity and render gates remain open |
| Blind solve/verifier evidence slice 0003 | `evidence/answer-review-0003.jsonl` + `evidence/verify-review-0003.jsonl` | passed | 5/5 independent options agreed (`1,1,2,2,2`); evidence hashes `84d063abf765e55e107c88235fc05ae2f931155b0ac23c941d7edce45c1f2637`, `03a49f7150d67732f3b0ba52bc8247dfb831df8e810223538d922ca08fc4e038`; no source key was exposed |
| Independent solution-review evidence slice 0002 | `evidence/solution-review-0002a.jsonl` + `evidence/solution-review-0002b.jsonl` | passed | 5/5 `holds`, complete, correct from two independent reviewers; evidence hashes `32de0bcebee67f412a4c65ee2454bdc977c08f6f11c0e7062d4ecf7fb9e602ad`, `601e9c5d96f46079bcca5adaa3de50790051d22d842b4caa71a8769a1bb54601`; adversarial slice pending |
| Coordinator fail-closed repair (0154) | output reclassification + SHA/attestation update | passed | One accepted row with nonempty visual issue moved to needs_repair/incomplete; source untouched |

## Not Run
- اجرای physical Xiaomi Focus Pen؛ دستگاه متصل نیست.
- Android runtime launch/screenshot این slice؛ `adb devices` هیچ target نشان نداد.
- source-PDF fidelity؛ مسیر اصل PDFها در environment حاضر نیست.
- mathematical certification؛ 5/3672 records now have independent solve + verifier, two-reviewer solution confirmation, and adversarial pass; source-fidelity/render gates remain open, and screening itself never certified answers.

## Known Issues
- 409 extraction blockers و سایر risk queues در `02-state.md`.
- هیچ سؤال هنوز certification علمی کامل ندارد و نباید certified ادعا شود.
- Jules source برای Gauss متصل نیست.
- پس از 95 خروجی screening معتبر، 1313 مورد needs repair و 187 مورد ambiguous هستند؛ هیچ‌کدام usable نشده‌اند.
