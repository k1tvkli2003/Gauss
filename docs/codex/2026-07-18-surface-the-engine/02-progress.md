# Progress & Verification — surface-the-engine

- Status: **shipped** (all 4 tracks, same session, 2026-07-18)
- Branch: `feat/surface-the-engine`
- Owner: Claude (primary task, no subagents per AGENTS.md)

## Shipped commits (in order)

| # | Commit | Track | Analyze | Tests |
|---|---|---|---|---|
| 1 | `20157ccb` | B — Star chart + recurring traps (Observatory) | 0 issues | 36/36 |
| 2 | `d714f39a` | A — Review orbit (full SRS surfacing) + synthetic-mastery fix | 0 issues | 38/38 |
| 3 | `c3042d82` | D — Reading room over preserved archive | 0 issues | 38/38 |
| 4 | `4329e7ed` | C — Answer-first covered choices + miss tags (schema v3) | 0 issues | 39/39 |

## What each track surfaced

- **A (flagship):** `reviewDueIds()` (all `dueAt <= now`, not just lapses) →
  `/review` route, Practice mode tile, map HUD due chip, real DUE metric.
  Integrity fix: `revenge`/`review` sessions no longer mint `topic_mastered`.
- **B:** analytics `heatmap` → 12-week star-chart panel (sqrt brightness,
  Sat-first rows, today ring); `distractors` → recurring-traps register.
- **C:** `cover=1` answer-first mode (choices covered until uncovered);
  `errorTag` column (schema v3, additive migration) + tag chips on misses +
  Miss-anatomy panel. Tagging never touches scoring/SRS/XP.
- **D:** `archiveQuestions()` → read-only `/archive/:topicKey` pager with
  provenance banner and explicit unverified reveal; entry points from map
  inspector, mobile dock (dead nodes now open the room), practice launch deck.

## Verification performed

- `flutter analyze --no-pub`: clean after every track.
- `flutter test --no-pub`: full suite green after every track; 3 new tests
  (due-vs-lapse contract, synthetic-mastery exclusion, miss-tag persistence).
- Not performed: release APK build, on-device screenshots, artifact-page
  screenshot (local server blocked by permission classifier). The dossier
  artifact passed structural checks only.

## Live context

User is replacing the corpus with nardebam-only data via Codex
(`docs/codex/2026-07-18-nardebam-only-question-corpus/`). All four tracks are
count-driven/bank-agnostic; the hardcoded 7353/29/3681 contract in
`question_bank_repository.dart` belongs to that task and was intentionally
left untouched.

## Artifact

Session dossier (Persian, observatory theme, embedded Vazirmatn/Manrope):
https://claude.ai/code/artifact/cd46428b-ada5-46ab-82ae-1118264a8b2f
