# Brief — Surface the Engine (critique + opportunity)

- **Task ID:** `2026-07-18-surface-the-engine`
- **Date:** 2026-07-18
- **Branch:** `feat/surface-the-engine`
- **Mode:** `/ideas` (critique + differentiated, testable opportunities)
- **Scope guardrails (from `AGENTS.md`):** private single-user product; map-first;
  English chrome / Persian learning content; **no** auth, monetization, public
  leagues, or social/streak pressure; humane progression; Duolingo path clarity +
  Clash Royale reward feel as interaction references only.

## Central thesis

> **Gauss's engine is far smarter than its surface.** The single biggest source of
> untapped value is not "build new capability" — it is **surfacing signal the
> engine already computes and then discards.** Most of the roadmap is ~80% present
> in the codebase.

## Grounded findings (evidence)

| # | Finding | Evidence |
|---|---------|----------|
| 1 | **Spaced-repetition engine is built but 90% hidden.** `_updateSrs` writes `ease/interval/reps/dueAt` for *every* finalized question, but the only consumer is `revengeIds` which filters `lapses > 0`. Correctly-answered questions get review dates that never resurface. | `progress_repository.dart:556` vs `:355` |
| 2 | **Half the library is locked.** 7,353 total questions, only **3,681 mission-ready**; **3,672** `nardebam` items are quarantined and unreachable. `absolute_value_floor` (132 q, 0 ready) is a dead map node. | `question_bank_repository.dart:8`, `index.json total:7353` |
| 3 | **Computed-but-unrendered signal.** `AnalyticsSnapshot.heatmap` (daily activity) and `.distractors` (recurring traps, top 6) are produced in `analytics()` and rendered nowhere in the UI. | `progress_repository.dart:434,416`; absent from `insights_screen.dart` |
| 4 | **MCQ-only loop enables backsolving.** Choices are visible immediately; for a bank skewed hard/olympiad (5,200 hard + 1,043 very_hard + 850 olympiad), this shortcuts real derivation. | `mission_screen.dart` |
| 5 | **Insights is readable but not actionable.** Weak topics ("useful friction") shown, but no path to practice them. | `insights_screen.dart:1156` |
| 6 | Mira companion has only 2 states (thinking, correct). | `assets/visual/mascot/` |

## Approved tracks (user selected all four + all three outputs)

- **A — Review orbit (flagship):** surface the hidden SRS as a real "Due for
  review" queue (all `dueAt <= now`, not just lapses).
- **B — Cheap visual wins:** render the already-computed activity heatmap as a
  "star chart" + the distractor "recurring traps", both in the Observatory.
- **C — Skill depth:** answer-first ("cover choices") mode + error-type tagging
  (mistake autopsy / غلط‌نامه).
- **D — Unlock the archive:** read-only "Reading Room" over the 3,672 quarantined
  questions (clearly labelled unverified), reviving the dead `absolute_value_floor`
  node.

## Explicitly rejected (scope integrity)

- Social leagues / leaderboards / sharing — private app.
- Streak punishment — forbidden by `AGENTS.md`.
- Online LLM tutor — fights offline-first / local-first truth.
- Adaptive-difficulty ML — premature; SRS + weak-topic targeting already adapt.
