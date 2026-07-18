# Plan / living tracker — Surface the Engine

Execution order chosen by dependency + risk (schema migration last).
Verification gate per track: `flutter analyze --no-pub` + `flutter test --no-pub`.

## Track B — Cheap visual wins (no schema change) — FIRST
- [ ] `_StarChartCalendar` widget in `insights_screen.dart` consuming
      `analytics.heatmap` (day-cells brighten by count; observatory sky theme).
- [ ] `_TrapsRegister` consuming `analytics.distractors` (resolve topic labels;
      "Choice N in {topic} — {count}×").
- [ ] Wire both into `InsightsScreen` slivers.
- [ ] analyze + test + commit.

## Track A — Review orbit / SRS (no schema change)
- [ ] `ProgressRepository.reviewDueIds({now, limit})` = `dueAt <= now` ordered.
- [ ] `GaussController.reviewDueCount` + `createReviewMission({count})`.
- [ ] `_refreshProgress` populates review count.
- [ ] `MissionScreen(review: true)` + `/review` route.
- [ ] Surface: Map HUD "Review N" chip + Practice "Review due" mode tile.
- [ ] recentExams label mapping for `review`.
- [ ] analyze + test + commit.

## Track D — Reading Room / archive unlock (no schema change)
- [ ] `QuestionBankRepository.archiveQuestions(topicKey)` = `!missionReady`.
- [ ] `GaussController` passthrough + archive counts.
- [ ] `ArchiveScreen` (read-only browse: stem, options, source solution with
      explicit "unverified source" banner; ephemeral reveal, no persistence).
- [ ] `/archive` route + Practice "Reading room" tile.
- [ ] Revive dead node: `referenceOnly` topic inspector → "Open reading room".
- [ ] analyze + test + commit.

## Track C — Skill depth (C2 = schema migration) — LAST
- [ ] C1 answer-first "cover choices" toggle in `MissionScreen` (no schema).
- [ ] C2 add `errorTag` nullable column to `Attempts`; `schemaVersion 2→3` +
      `addColumn` migration; regenerate `gauss_database.g.dart` (build_runner).
- [ ] `AttemptRecord.errorTag`; `ProgressRepository.tagAttempt(...)`;
      `AnalyticsSnapshot.errorBreakdown`.
- [ ] Mission: quick error-tag chips after a wrong check.
- [ ] Insights: "why you miss" breakdown.
- [ ] analyze + test + commit.

## Final
- [ ] Full `flutter analyze` + `flutter test` green.
- [ ] Update `04-progress.md` + `_index.md`.
- [ ] Note any verification not runnable in this environment.
