# Preservation Contract

Frozen: 2026-07-10T22:28:00+03:30  
Final reconciliation: 2026-07-15T15:10:59+03:30

| Asset or contract | Source of truth | Class | Final evidence | Allowed change | Acceptance proof |
|---|---|---|---|---|---|
| Bundled question bank | `app/src/main/assets/question_bank/**` | immutable | 30 JSON files; 12,654,640 bytes; 7,353 IDs; digest `94d0153f94863ec9ee66e41e28b3c2021144a42350a133e9926b39f1ba8d0713` | Copy/bundle only; typed parsing adapters may classify trust and normalize answer indexes | Exact path/length/SHA equality in Flutter assets, web release, universal APK, and split APKs |
| Question media | `app/src/main/assets/question_media/**` | immutable | 3,410 files; 66,450,076 bytes; digest `00e4eb33f1215ce8b8cf104baebb7c0b0a858137032f535c1e7b4c3b6ca3c320` | Copy/bundle and lazy-load only | Exact path/length/SHA equality across every built target and all references resolve |
| Comprehensive source corpus | `data/seed/comprehensive/**` | immutable | 57 JSON files; 17,114,082 bytes; digest `0b3c252159923c98b11e748c826b3137d00f5386df6275d0f623b1c691b10db5` | No content edits | Strict source counts and source/bundle identity reconciliation pass |
| Stable question identity and answer contract | `Question.id`, `correct_option_index`, typed adapter | immutable semantics | All 7,353 rows parse; answer contract is range checked | Domain exposes a 0-based selected choice only through explicit source conversion | Full-bank contract tests and four-choice boundary tests pass |
| Dataset trust | `QuestionTrust` and `solutionVerified` | compatible derived policy | 3,681 mission-ready; 3,672 preserved archive; 3,610 displayed solutions; 71 withheld conflicts | Policy may become stricter; relaxation requires an independently verified source and new versioned evidence | No archive row enters missions, XP, SRS, quests, or analytics |
| Kotlin/Compose product and dirty changes | Existing repository worktree | immutable rollback evidence | Initial unstaged patch hash `01eebba3d1c362cca4b9f988f742874d775fc6b0`; legacy dirty paths remain user-owned | Add Flutter files beside it; no cleanup/reset/revert | Flutter replacement remains under `flutter_app/`; legacy build remains available |
| Room schema/history | Existing Kotlin database sources | immutable reference | Schema v4 and migrations retained | Flutter uses a different Drift store/schema | Flutter repository tests cover equivalent product contracts without mutating `gauss.db` |
| Flutter progress | Drift schema v2 + immutable events | derived live state | Resume, attempts, SRS, XP, quest claims, achievements, and analytics tested | Versioned forward migrations only | Idempotency and local-midnight tests pass |
| User history | Owner statement and new local store | empty initial baseline | Owner confirmed sole use and no prior usage | Initialize new Flutter store; no backfill | First-launch/empty-state invariants pass |
| Routes/deep links | Flutter router | active compatible interface | `/map`, `/practice`, `/insights`, `/mission/:topicKey`, `/revenge`, `/resume` | Add compatible routes; do not bypass trust guards | Direct URL, missing/archive session, normal mission, and navigation QA pass |
| Signing configuration | `android/app/build.gradle.kts` | compatible configuration | Package `com.gauss.app`; valid debug-fallback v2 signature | Supply `GAUSS_KEYSTORE_*` for private production signing | APK metadata/signature verification passes; certificate policy reported separately |
| Fonts | Flutter asset declaration and original Vazirmatn files | compatible copy | Mixed English/Persian UI rendered in browser QA | Preserve files/license and fallback behavior | RTL blocks, joining, semantics, and layout inspection pass |
| Visual direction | `03-previews.md` and Flutter Orrery implementation | derived/rebuildable | Selected map-first composition implemented on compact and expanded web | Refinement may not obscure learning actions or data truth | No tested overflow; archive/readiness and inspector states remain semantic |

## Trust-Preserving Interpretation

Preservation means source bytes, stable identities, provenance, and media remain available. It does not require known-conflicting content to be scored or shown as authoritative. The non-destructive trust policy is specified in `dataset-integrity-policy.md`.

## Backup and Rollback

- No production/staging system was mutated.
- No live database backup was needed because the owner confirmed the app had never been used.
- Git/worktree plus the immutable digests above protect source restoration.
- Kotlin remains available; Flutter is additive.
- The obsolete map background file remains in the workspace even though it is excluded from the Flutter runtime bundle.

## Rollback Trigger

Stop a future cutover if any source count/hash/path/media check fails, a core journey loses behavior, a release build fails, persisted rewards/SRS/analytics diverge from contract tests, or an archive row becomes scorable without a versioned independent validation record.

