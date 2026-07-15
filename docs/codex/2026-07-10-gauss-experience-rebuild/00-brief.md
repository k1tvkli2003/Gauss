# Gauss Flutter rebuild

- Task ID: `2026-07-10-gauss-experience-rebuild`
- Status: `complete`
- Created: 2026-07-10T21:18:38+03:30
- Completed: 2026-07-15T15:10:59+03:30
- Language: English

## Request

Rewrite the whole Gauss product in Flutter/Dart as one offline-first application for native Android and web. Preserve the entire learning dataset and media. The owner is the only intended user and confirmed that the previous app had not been used, so no live user-history migration was required.

## Success Criteria

- One Flutter codebase must produce native Android and web releases.
- Every source question, stable ID, question-bank shard, and media file must remain byte-preserved and reconciled in built artifacts.
- Only contract-safe content may affect scoring, XP, SRS, quests, achievements, or analytics.
- Map, practice/review, mission, solution/recap, recovery, and insights journeys must work from persisted local state.
- Compact and expanded layouts must retain map-first identity, truthful counts, RTL learning content, and accessible semantics.
- Analyzer, tests, release builds, artifact parity, and built-web runtime QA must pass within the available host capabilities.

## Delivered Outcome

- One additive Flutter codebase now builds release artifacts for Android and web.
- The source corpus remains byte-for-byte preserved: 7,353 questions, 30 bundled question-bank files, and 3,410 media files.
- A typed trust boundary exposes 3,681 contract-checked questions to scored missions while retaining 3,672 Nardebam rows as a non-scoring preserved archive.
- Core journeys work end to end: choose a topic or review queue, solve with scratchpad and media zoom, resume an interrupted mission, inspect supported solutions, receive idempotent XP/quest rewards, revisit mistakes, and inspect private analytics.
- The primary experience is the selected `Orrery of Proofs` map, with compact bottom navigation and an expanded web inspector built from the same route/state identity.
- App chrome is English. Persian learning blocks remain RTL and use the bundled Vazirmatn family.
- The Kotlin/Compose worktree remains intact as rollback evidence; the Flutter replacement is additive under `flutter_app/`.

## Acceptance Results

- `flutter analyze --no-pub`: passed with zero issues.
- `flutter test --no-pub`: 27 tests passed.
- Android universal and split release APK builds: passed and cryptographically valid.
- Flutter web release build: passed, including the WebAssembly dry run.
- Browser QA: compact and expanded layouts, deep links, archive quarantine, question/solution flow, semantics, and runtime logs passed; final warning/error count was zero.
- Source -> Flutter assets -> web build -> every APK asset copy passed exact path, length, and SHA-256 reconciliation.

## Scope Boundaries

- Intentionally absent: cloud backend, accounts, auth, sync, telemetry, ads, payments, subscriptions, shops, public leagues, social features, and multiplayer.
- Store publication and production signing were not requested. Release APKs use the valid Android debug fallback certificate until a private release keystore is supplied through the supported `GAUSS_KEYSTORE_*` environment variables.
- A physical Android runtime was unavailable; native verification therefore covers analyzer/tests, release assembly, package metadata, archive contents, and signature validity rather than an on-device launch.
- Deleting the Kotlin project or rewriting Git history remains out of scope.
