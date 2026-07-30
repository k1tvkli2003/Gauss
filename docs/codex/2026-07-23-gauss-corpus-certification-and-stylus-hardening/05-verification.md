# Verification

## Summary
- Result: partial
- Last verified: 2026-07-30T15:17:00+03:30

## Checks
| Check | Command/Method | Result | Evidence |
|---|---|---|---|
| Study Observatory copy contract | `flutter test test/study_experience_test.dart` | passed | 22/22; asserts the truthful `question cards reflected` progress reading alongside subject switching, responsive layout, study-room, and pen checks |
| Study Observatory static analysis | `dart analyze lib test` | passed | no issues found |
| Study Observatory release build | `flutter build web --release --no-wasm-dry-run` | passed | Flutter produced `build/web` after the copy correction |
| Map/Study visual browser QA | release web bundle rendered with local Chromium | passed | Map at 411x890 and 900x1180 plus Study at 411x890 inspected; the unscored dock now says `CURRENT STUDY`, with focused visible-copy and semantics tests |
| Map study-state terminology | focused map-dock tests, `dart analyze lib test`, `flutter test`, release web build, Chromium phone render | passed | `CURRENT MISSION` is now `CURRENT STUDY` in visible and semantic copy; 98/98 Flutter tests and a fresh 411x890 release render pass while the user-owned header work stays unstaged |
| Full Flutter regression after UI polish | `flutter test` | passed | 98/98, including question TeX, media decode, responsive study surfaces, Focus Pen contracts, navigation, and benchmark guards |
| Jules repair wave 018/020/024 partial harvest | exact message extraction, transport validator, canonical materializer | passed with quarantine | 30/30 rows bind to original ticket/order/source hash; 24 drafts added, 6 under-review rows excluded; overlay SHA-256 `37ca00cad5f8ab5796272063ee608e5c865b0b4f48c692737aad120cd557e295` |
| Jules repair wave 025–031 dispatch readiness | allocator, blind-input assertion, `jules_batch.py validate` | passed locally; remote dispatch deferred | 70 unique text-only rows; all inputs exclude answer keys; live `doctor` and scheduler `--dry-run` each exceeded the bounded 64-second network window, so no session was created |
| Post-partial-harvest corpus gates | `validate-repairs`, `validate`, `summarize`, `repair-queue` | passed | 119 overlays; 3672 source-bound; 2791 repair tickets; 0 usable |
| Certification syntax | `node --check scripts/corpus_certification.mjs` | passed | valid Node module |
| Canonical/runtime/media baseline | `node scripts/corpus_certification.mjs baseline` | passed | 3672 records; 3410 files; 66,450,076 bytes |
| Certification reconciliation | `node scripts/corpus_certification.mjs validate` | passed | 3672 source-bound; 0 usable |
| Jules repair wave 011–017 transport | exact JSONL extraction + `validate_jules_repair_harvest.py` | passed with quarantine | 70/70 rows bind to original ticket/order/source hash; 55 drafts and 15 explicit under-review blockers |
| Jules draft materialization 011–017 | `materialize_jules_repair_drafts.py` dry-run + write | passed with quarantine | canonical addendum-only guard added 55 source-preserving drafts; 15 unresolved rows were not materialized; overlay SHA-256 `4c990c019cf76e9b2a9c538a01be644a7c6b3dd2b9e954e9a60676c3b503f7b8` |
| Post-materialization corpus gates | `validate-repairs`, `validate`, `summarize`, `repair-queue` | passed | 95 overlays; 3672 source-bound; repair queue 2791; 0 usable |
| Deterministic Jules wave 018–024 allocation | `prepare_jules_repair_wave.py` dry-run + write | passed | 294 eligible text-only screened-complete candidates; seven independent 10-row batches selected without prior ticket/overlay overlap |
| Wave 018–024 blind-input invariant | local Python assertion | passed | 70 unique rows; every prompt/input excludes `correct_option_index` and states that the source answer key is not supplied |
| Wave 018–024 Jules manifest | `jules_batch.py validate` + quota-aware `run --dry-run` | passed | seven repoless, no-PR tasks; complete Pro snapshot: 93 rolling slots and 15 concurrent slots available |
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
| Independent adversarial-review evidence slice 0002 | `evidence/adversarial-review-0002.jsonl` | passed | 5/5 adversarial attacks passed with no blockers; evidence SHA-256 `178144cd5d1abd39a34abf6d771e9ac0a78bf4f6ec5426d565481fab0fd0c5f4`; source-fidelity and render gates remain open |
| Blind solve/verifier evidence slice 0004 | `evidence/answer-review-0004.jsonl` + `evidence/verify-review-0004.jsonl` | passed | 5/5 independent options agreed (`4,4,4,2,2`); evidence hashes `f1d38998a5fc4aba03b55e43205ed4eccd7f12cf0c3a094d3087796229dd716d`, `a59c5fabe2eb1d4c4016d81f90b298403d947b2a30446417ce908da1cebc5230`; no source key was exposed |
| Independent solution-review evidence slice 0003 | `evidence/solution-review-0003a.jsonl` + `evidence/solution-review-0003b.jsonl` | passed | 5/5 `holds`, complete, correct from two independent reviewers; evidence hashes `2e2a2c6e2009d2a8775df1a84d4dde4132d32e95c8f6a87afb127628f3089e99`, `c0adf619bee593eb6479320a5dbc1215a6b69f263ac5a3f778c9bf875cb4e3e3`; adversarial slice pending |
| Independent adversarial-review evidence slice 0003 | `evidence/adversarial-review-0003.jsonl` | passed | 5/5 adversarial attacks passed with no blockers; evidence SHA-256 `4c845932bf0ffe9d2c9b4b35939117e10e33ae0e1de73de85dc1efd1f6d78b2c`; source-fidelity and render gates remain open |
| Blind solve/verifier evidence slice 0005 | `evidence/answer-review-0005.jsonl` + `evidence/verify-review-0005.jsonl` | passed | 5/5 independent options agreed (`3,2,3,1,4`); evidence hashes `920d25151678c2eabbf7d65320a5aba937ea78ee8c8772737a91761f1a396b08`, `d705f0c982487540b50f6f9c9c4d56ff58e46bd30e1412cb1579f44e4b390c07`; no source key was exposed |
| Source-key correction 0085 | manifest answer correction + third adjudicator evidence | passed | Preserved source option 4; effective option 3; explicit correction evidence digest `c238ec50ac564720ea6afa0a1874a96f5e745ef090a41c24dddd121c99f3c813`; original source remains immutable |
| Independent adversarial-review evidence slice 0004 | `evidence/adversarial-review-0004.jsonl` | passed | 5/5 adversarial attacks passed; evidence SHA-256 `cb44d0288fe50c25d5401fd1c6aa1a2242a07fef0596c300959dcb2abe7e816e`; source-fidelity and render gates remain open |
| Blind solve/verifier evidence slice 0006 | `evidence/answer-review-0006.jsonl` + `evidence/verify-review-0006.jsonl` | passed | 5/5 independent options agreed (`1,4,1,4,1`); evidence hashes `c3cf97b36099dfc1723c991a5e23f3eb44e811fd1e2abde0e54daa3d87f932fc`, `1da2ae49215ab5c9310dc2246bc6453c3c2950b813d3b49ce370f37aad84d056`; no source key was exposed |
| Independent solution-review evidence slice 0005 | `evidence/solution-review-0005a.jsonl` + `evidence/solution-review-0005b.jsonl` | mixed | 4/5 complete/correct; `0093` is correct but partial due omitted cancellation-domain proof; evidence hashes `8fd72bd604b2874d05ae8d98f4249ae9e5ee311716559415a8e8f61482017651`, `43e1a5cdabea06a5517fc92f48709e4b81273f32cd67da6409c1e32e26fad76a` |
| Draft repair overlay 0093 | `data/certification/v1/repair-overlays.jsonl` | draft | Adds a domain-guard addendum without changing immutable source; `validate-repairs` passed |
| Independent adversarial-review evidence slice 0005 | `evidence/adversarial-review-0005.jsonl` | mixed | 4/5 passed; `0093` blocked on source-solution domain omission while independently confirming option 4; evidence SHA-256 `4df3ec8aa6c8c2b42d1148342b59fc5773c2347d8b21a02dfe780628abc5d7f9` |
| Blind solve/verifier evidence slice 0007 | `evidence/answer-review-0007.jsonl` + `evidence/verify-review-0007.jsonl` | passed | 5/5 independent options agreed (`2,2,3,2,1`); evidence hashes `d90f8db0f1622e56e85e9d69d3fca412dcaf1a3ae51f65ab57851250bc13a0de`, `c4fe8633598c539ea6bd37d194ce02a31d8581922b21b929d8567277a8700d2b`; clean verifier rerun avoided manifest/answer-key access |
| Independent solution-review evidence slice 0006 | `evidence/solution-review-0006a.jsonl` + `evidence/solution-review-0006b.jsonl` | mixed | 4/5 complete/correct; `0100` is correct but partial because the source solution omits the `q=0` domain branch; evidence hashes `ef7366ec72dc76c08dfb6420221249951df9d3558543df21722eaac0012f0a0f`, `7177e19d6bfe5976209806f70e1dded4d830c4f56779721a5ea6fe5db9b1af33` |
| Independent adversarial-review evidence slice 0006 | `evidence/adversarial-review-0006.jsonl` | mixed | 4/5 passed; `0100` blocked on the valid q=0 branch omission while independently confirming option 1; evidence SHA-256 `4d25d2207ae9ad026d223f2cd990a5b1f7e6c0e4ed927d236695e22628f756d8` |
| Blind solve/verifier evidence slice 0008 | `evidence/answer-review-0008.jsonl` + `evidence/verify-review-0008.jsonl` | passed | 5/5 independent options agreed (`4,3,3,3,1`); evidence hashes `93f9d7532e4d62449ccd8502fa12b257462ac5b84318ad6ee0e5cda71259a873`, `f540cca1b3a59260370a7414ccdb6a00155822e580aa2f616edb6f6012d205b4`; verifier clean rerun stayed outside manifest/answer keys |
| Independent solution-review evidence slice 0007 | `evidence/solution-review-0007a.jsonl` + `evidence/solution-review-0007b.jsonl` | passed | 5/5 `holds`, complete, correct from two independent reviewers; evidence hashes `17fd3671983840dadbadcec5661945e2b054d4956fb3ae7eb9fe194fe0360d0e`, `0ca1b01b76e5e0c6a56706822be5d9ed37af7cd5b15c18cbe8fc71d1f4473354`; adversarial slice pending |
| Independent adversarial-review evidence slice 0007 | `evidence/adversarial-review-0007.jsonl` | passed | 5/5 adversarial attacks passed; evidence SHA-256 `96e9ae1c1fa46c8a97f6371f0652473784d2e78f4db7b0fa135aef136486e8ba`; source-fidelity and render gates remain open |
| Blind solve/verifier evidence slice 0009 | `evidence/answer-review-0009.jsonl` + `evidence/verify-review-0009.jsonl` | passed | 5/5 independent options agreed (`4,4,3,4,4`); evidence hashes `0dc58f78232206f9f187db68b21b7c2a92b5dc384ab8472a5cf29cd511108fe5`, `5bf4541ee270aa251885d6cb927452e6d78dcfa4048c6aa7852dcfe5656b3873`; no source key was exposed |
| Independent solution-review evidence slice 0008 | `evidence/solution-review-0008a.jsonl` + `evidence/solution-review-0008b.jsonl` | passed | 5/5 `holds`, complete, correct from two independent reviewers; evidence hashes `fbc520e251353f98e2e1fa6476f8548d1a304a5d6a58b2e332a19df0153bd2ff`, `ae77745b00fc6969afe6036d4b4b009f39007b1886bec0a972c969774ad18583`; adversarial slice pending |
| Independent adversarial-review evidence slice 0008 | `evidence/adversarial-review-0008.jsonl` | passed | 5/5 adversarial attacks passed; evidence SHA-256 `7ab98b24c62f1b7d484cf86e701d2e9cc4c80c46d5a427bb950641f96094f5d5`; source-fidelity and render gates remain open |
| Independent solution-review evidence slice 0004 | `evidence/solution-review-0004a.jsonl` + `evidence/solution-review-0004b.jsonl` | passed | 5/5 `holds`, complete, correct from two independent reviewers; evidence hashes `d282abfa81e1b4c228798ca4a815cc46a842386fd31e500c05357f8ec83a83ed`, `79458ab5f62cbb08d1f1b862edffbd1b3323919000238c9b38b0d2f362775f1c`; adversarial slice pending |
| Blind solve/verifier evidence slice 0010 | `evidence/answer-review-0010.jsonl` + `evidence/verify-review-0010.jsonl` | passed | 5/5 independent options agreed (`1,4,4,3,2`); evidence hashes `d24f0b400c72c29b5f4001d3101476714dec2a3163fcbc8b7ed2e619136b8d07`, `ea498cef2a5f122e553c0a0a9a8d16c5ab050f164de9a26b54c49ff1f746c148`; clean rerun kept source answer keys hidden |
| Independent solution-review evidence slice 0010 | `evidence/solution-review-0010a.jsonl` + `evidence/solution-review-0010b.jsonl` | passed | 5/5 `holds`, complete, correct from two independent reviewers; evidence hashes `6d067aa4d644d2e67604ba19646b0e8a7c520cc7470f83019ec8c1d62602af18`, `364380cedcc93b67314ce86f52c448c561869fb2f9871eb22c73a841512af441`; adversarial slice pending |
| Independent adversarial-review evidence slice 0010 | `evidence/adversarial-review-0010.jsonl` | passed | 5/5 adversarial attacks passed (`1,4,4,3,2`); evidence SHA-256 `90984a9d9c99aebb0f67357b4664bd5feab23c2472126bf7746823251e641491`; source-fidelity and render gates remain open |
| Flutter static and test proof | `flutter_app/lib`, `flutter_app/test` | passed | `dart analyze lib` clean; `flutter test` 94/94 passed, covering rendering, responsive layouts, scratchpad/stylus contracts, offline startup, navigation, and deep links |
| Flutter release artifact proof | `flutter_app/build/web`, `flutter_app/build/app/outputs/flutter-apk/app-debug.apk` | passed | `flutter build web --release` completed with Wasm dry-run success; `flutter build apk --debug` completed; device/runtime and physical Focus Pen proof remain separate |
| Coordinator fail-closed repair (0154) | output reclassification + SHA/attestation update | passed | One accepted row with nonempty visual issue moved to needs_repair/incomplete; source untouched |
| Jules repoless solver/verifier/solution/adversarial batches 0011–0013 | `.jules/gauss-corpus-2026-07-27` raw sessions and hash-bound JSONL artifacts | passed with quarantine | 30/30 rows matched IDs/order/source hashes in every lane; 29 adversarial passes and one blocked repair (`0093` domain guard); no source JSON/media changed |
| Jules source-key adjudication 0013 | session `958553139132015389`; adjudicator JSONL | passed with quarantine | `0085` effective option 3 and `0093` effective option 4; 0093 correction is recorded but remains blocked on solution/adversarial completeness |
| Jules manifest evidence advancement | `data/certification/v1/manifest.jsonl` | passed | Five rows advanced to `verified_complete_correct` solution and `passed` adversarial; `node scripts/corpus_certification.mjs validate` passes; usable remains 0 by design |
| Jules repair overlay batch 001 | `evidence/jules-repair-001.jsonl`, `data/certification/v1/repair-overlays.jsonl` | passed with quarantine | 10/10 ticket/hash rows validated; 6 draft overlays added source-preservingly, 4 inconsistent tickets remain under review; `validate-repairs` and corpus `validate` pass |
| Jules repair overlay batch 002 | `evidence/jules-repair-002.jsonl`, `data/certification/v1/repair-overlays.jsonl` | passed with quarantine | 10/10 ticket/hash rows validated; 6 additional source-preserving draft solution replacements added (14 overlays total); four internally inconsistent tickets remain under review; `validate-repairs` and corpus `validate` pass with 3672 source-bound records and 0 usable |
| Repair queue refresh after Jules batch 002 | `node scripts/corpus_certification.mjs repair-queue` | passed | 2,791 source-bound quarantine tickets regenerated: 2,488 render/prompt P0 and 303 correctness P1; current manifest answer/solution states are reflected without bypassing certification gates |

## Not Run
- Daily quest receipt visual/device check: the widget and web release build
  passed, but no physical Android device is connected for a live capture.
- اجرای physical Xiaomi Focus Pen؛ دستگاه متصل نیست.
- Android runtime launch/screenshot این slice؛ `adb devices` هیچ target نشان نداد.
- source-PDF fidelity؛ مسیر اصل PDFها در environment حاضر نیست.
- mathematical certification؛ 5/3672 records now have independent solve + verifier, two-reviewer solution confirmation, and adversarial pass; source-fidelity/render gates remain open, and screening itself never certified answers.

## Known Issues
- 409 extraction blockers و سایر risk queues در `02-state.md`.
- هیچ سؤال هنوز certification علمی کامل ندارد و نباید certified ادعا شود.
- Jules source برای Gauss متصل نیست.
- پس از 95 خروجی screening معتبر، 1313 مورد needs repair و 187 مورد ambiguous هستند؛ هیچ‌کدام usable نشده‌اند.
