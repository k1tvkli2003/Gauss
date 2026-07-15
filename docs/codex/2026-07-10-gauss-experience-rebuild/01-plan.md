# Plan

## Completed Approach

The Flutter replacement was built additively beside the current Android project. Preservation contracts and baselines were frozen first, `Orrery of Proofs` was selected autonomously because the owner delegated product decisions, and implementation proceeded through vertical slices over one typed repository/domain boundary. Source assets were never rewritten; every production copy was reconciled by path, length, and hash.

## Steps

| Step | Status | Result |
|---|---|---|
| 1. Audit Kotlin behavior, data, routes, persistence, tests, and visuals | done | Frozen six-finding audit and rollback evidence recorded. |
| 2. Freeze preservation evidence and rollback | done | See `preservation-contract.md`. |
| 3. Define Flutter IA, route map, domain contracts, and visual directions | done | `Orrery of Proofs` selected from three generated directions. |
| 4. Establish the product decision | done | Autonomous selection followed the explicit no-questions instruction. |
| 5. Scaffold Flutter Android/web app additively | done | `flutter_app/` owns the active Android/web implementation. |
| 6. Implement domain/data/persistence vertical slice | done | Drift schema v2, exact resume, SRS, immutable event ledger, quests, analytics, and injected clock. |
| 7. Implement Map -> Practice -> Mission -> Recap -> Insights | done | Complete map-first journeys with empty/error/recovery states. |
| 8. Audit dataset trust and quarantine unsafe scoring content | done | 3,681 mission-ready; 3,672 preserved archive; no source deletion. |
| 9. Verify tests, release builds, browser layouts, accessibility, and artifacts | done | All available gates passed; physical Android device was unavailable. |
| 10. Close documentation and handoff | done | Durable contracts and artifact evidence recorded in this task folder. |

## Implemented Interfaces

- Protected source: `app/src/main/assets/question_bank/**`, `app/src/main/assets/question_media/**`, and `data/seed/comprehensive/**`.
- Active app: `flutter_app/`.
- Canonical routes: `/map`, `/practice`, `/insights`, `/mission/:topicKey`, `/revenge`, and `/resume`.
- Persistence: a new Flutter/Drift database on Android and web; the Kotlin `gauss.db` contract was not mutated.
- Adaptive shell: compact immersive map with bottom navigation; expanded atlas canvas with contextual mission inspector.
- Trust model: `QuestionTrust.missionReady` and `QuestionTrust.preservedArchive`; only mission-ready rows can score, earn XP, affect SRS, or enter analytics.

## Closed Risks

- The source answer key is normalized through a typed 1-based-to-0-based boundary and contract-tested.
- All 66.45 MB of media are preserved and loaded on demand; the unused legacy map background is retained on disk but excluded from the Flutter asset bundle.
- Web persistence, deep links, compact/expanded layouts, keyboard-visible semantics, and runtime logs were exercised in the built release app.
- Fake preview state cannot enter persistence; rewards are event-ledger based and idempotent.
- Nardebam duplicate/conflicting rows cannot enter scored missions, while their exact source bytes remain preserved.

## Acceptance

All in-scope acceptance gates are complete. Remaining release-environment actions are optional: install on a physical Android device and provide a private production keystore if distribution beyond personal sideloading is desired.

