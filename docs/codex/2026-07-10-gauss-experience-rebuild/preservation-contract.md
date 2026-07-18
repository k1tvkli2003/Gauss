# Preservation Contract

Frozen: 2026-07-10T22:28:00+03:30  
Reconciled for source-only corpus: 2026-07-18

| Asset or contract | Source of truth | Class | Current evidence | Allowed change | Acceptance proof |
|---|---|---|---|---|---|
| Bundled question bank | `app/src/main/assets/question_bank/**` | immutable retained source | 30 JSON files; 6,007,444 bytes; 3,672 IDs | Copy/bundle only; no non-source rows | Exact path/length/SHA equality in Flutter assets, web release, and APK |
| Question media | `app/src/main/assets/question_media/**` | immutable | 3,410 files; 66,450,076 bytes | Copy/bundle and lazy-load only | Exact path/length/SHA equality across every built target and all references resolve |
| Comprehensive source corpus | `data/seed/comprehensive/nardebam/**` | immutable retained source | 29 JSON files; 8,703,652 bytes; math=2,042; physics=1,630 | No content edits | Strict source counts and source/bundle identity reconciliation pass |
| Stable question identity and answer contract | `Question.id`, `correct_option_index`, typed adapter | immutable semantics | All 3,672 rows parse; answer index is range checked | Domain exposes a 0-based selected choice only through explicit conversion | Full-bank contract and four-choice boundary tests pass |
| Dataset trust | `QuestionTrust` and `solutionVerified` | compatible derived policy | 0 mission-ready; 3,672 preserved archive | Relaxation requires independent versioned evidence | No archive row enters missions, XP, SRS, quests, or scored analytics |
| Provider provenance | `source_bank` and `provenance` JSON | internal metadata | Retained on all source rows | Never rendered as product branding | User-facing copy scan excludes the provider name |
| Flutter progress | Drift schema v4 + immutable events/study records | derived live state | Study reflections and per-shelf positions persist; archived source rows never award XP or scored events | Versioned forward migrations only | Repository idempotency, resume, aggregation, and no-XP reflection tests pass |
| User history | Owner statement and local store | empty initial baseline | Owner confirmed sole use and no prior usage | Initialize new Flutter store; no backfill | First-launch/empty-state invariants pass |
| Routes/deep links | Flutter router | active compatible interface | `/map`, `/study`, `/insights`, `/study/chapter/:topicKey`, `/study/revisit`; old practice/archive paths redirect | Add compatible routes; do not bypass trust guards | Fresh web direct URLs, bootstrap regression test, and native semantic navigation pass |
| Signing configuration | `android/app/build.gradle.kts` and `docs/release/android-signing.md` | immutable release identity | Package `com.gauss.app`; v1.0.90 (90) signed by the protected Gauss certificate | Future builds must use `GAUSS_KEYSTORE_*`, a monotonic code, and the same key | Strict verifier passes and Android v89→v90 update preserves first-install time |
| Fonts | Flutter asset declaration and original font files | compatible copy | Manrope with Vazirmatn fallback | Preserve files/license and fallback behavior | Mixed-direction text, semantics, and layout tests pass |
| Visual direction | Flutter Study Observatory implementation | derived/rebuildable | Continuous Math/Physics path, astronomical Map/Study/Insights/Room, floating glass navigation | Refinement may not obscure reading actions or data truth | Phone/desktop web captures, Android native captures, overflow/large-text/reduced-motion tests pass |

## Trust-Preserving Interpretation

Preservation now means retaining every row and media asset from the selected source corpus, stable identities, and provenance. It does not mean retaining unrelated generated or legacy question banks, and it never turns an unverified mapping into a scored answer.

## Deletion and Recovery Boundary

- On 2026-07-18 the owner explicitly authorized removal of every non-source question dataset from the current tree.
- Removed material is recoverable from Git history before this migration; it is intentionally absent from current source, bundles, and future builds.
- No production/staging system or user database was mutated. The owner confirmed the app had not been used.
- The legacy Android question-bank mirror is source-only so old build tooling cannot silently reintroduce deleted questions.

## Rollback Trigger

Stop a future cutover if any retained source count, path, media reference, SHA manifest, UI provenance-copy gate, release build, or trust-policy test fails; or if an archive row becomes scorable without independent versioned validation evidence.
