# Gauss Perfectionize Program — comprehensive, post-study-rebuild

- Task ID: `2026-07-19-perfectionize-program`
- Status: `proposed` (awaiting user "go"; each phase ships independently)
- Baseline: `main @ 3bcf7d43` — source-only study world (3,672 nardebam items,
  0 mission-ready), 50/50 tests green.
- Owner: Claude (primary task, no subagents per AGENTS.md)

## Thesis

The source-only rebuild saved the product's honesty but silenced its game
layer. Evidence:

- No screen consumes `GamificationSummary` — XP, level, quest, streak, and the
  565-line achievement catalog render nowhere; Insights shows 6 hardcoded
  inline "study seals" instead.
- `/mission`, `/revenge`, `/review`, `/resume` have zero UI entry points; the
  1,880-line mission screen (answer-first mode, miss tags, Mira deck) is
  unreachable except by stale deep link.
- The SRS engine writes nothing new (no scored attempts) and the "Revisit
  orbit" is an unspaced static bucket — the forgetting curve is unmanaged.
- Mira appears only on map + mission; the study room — now the core loop —
  has no companion.
- `_refreshProgress` still runs analytics/gamification/revenge/review queries
  on every boot for surfaces that no longer exist.

The program: rebind every dormant engine to study-native events, fix the
defects the rebuild left behind, and widen the product with additions that
fit the calm, private, offline identity.

## Permanently excluded (user decision — do not re-propose)

- Timed exam simulator (کنکور countdown scoring).
- Persistent per-question scratchpad/drawing (session-ephemeral ink stays).
- Social/leagues/leaderboards, streak penalties, online AI tutor, ML adaptive
  difficulty (AGENTS.md scope).

## Pillar 1 — Defect & risk removal (function/integrity)

| ID | Defect | Fix |
|---|---|---|
| D1 | Dead routes `/mission`, `/revenge`, `/review`, `/resume` reachable by deep link into empty/error states | Redirect to `/map` (web deep-link test exists as harness); keep mission code for future verified corpus |
| D2 | Reward engine has no producer; ledger tables frozen | Pillar 2 rebinds (not deletion — history preserved) |
| D3 | Revisit bucket has no spacing/due concept | Pillar 3 |
| D4 | Startup runs analytics/gamification/revenge/review queries no surface consumes | Trim `_refreshProgress` to study+ledger needs; re-add per pillar as surfaces return |
| D5 | Old exam/attempt history (gauss era) invisible everywhere | Acceptable (preserved in DB); optional later: tiny "legacy record" note in Insights |
| D6 | `errorTag`/MissReason orphaned with mission screen | Re-express as study reflection detail (Pillar 4, U3) or leave dormant until missions return — decision at implementation |
| D7 | Hypothesis vs source key never compared or surfaced | Pillar 4 (I1) with explicit "unverified source key" labeling |

## Pillar 2 — Study-native gamification revival (flagship)

Reuse the existing idempotent event ledger + XP tables; add rule version 2.
No schema change expected (event ids are strings; quest table generic).

- G1 **Event producers**: `question_reflected` (+4 XP, daily cap 120),
  `revisit_cleared` (revisit→clear on a later day; the new "orbital
  correction", +12), `set_completed` (all questions in a study set
  reflected, +20), `unit_completed` (topic fully reflected, +60),
  `new_unit_touched` (+8). All keyed `type:questionId|setKey` — idempotent
  by construction; first-reflection uniqueness already enforced by PK.
- G2 **Catalog rebind**: map `AchievementMetric` sources to study events
  (correctAnswers→reflections, correctedMistakes→revisit_cleared,
  masteredTopics→units completed, practicedSubjects→subjects touched,
  studyRhythm→study heatmap days, completedMissions→sets completed,
  goldChallenges→sections completed). Families, rarities, art tokens, and
  the crafted `_AchievementPlate` UI survive unchanged; the 6 inline seals
  retire.
- G3 **HUD return**: XP + level medallion on map header and Observatory;
  calm daily quest "Chart 10 reflections" via existing quest table; streak
  stays no-penalty rhythm.
- G4 **Set-complete recap**: when the last question of a set is reflected,
  a reward recap moment (Mira, reward lines, next-set CTA) — the mission
  complete screen reborn for study.

## Pillar 3 — Spaced revisit (SRS reborn)

- S1 Reflection writes `srsStates` (ids now stable nardebam):
  revisit → due tomorrow (lapse-style), clear → long interval.
  Revisit shelf orders by `dueAt`; "N due" chip on map/practice replaces the
  static count; overdue stars dim on the star chart legend.

## Pillar 4 — UX / anatomy

- U1 = D1 route hygiene.
- U2 Study-room reveal upgrade: after reveal, per-choice states show the
  source-claimed key distinctly (already) plus the user's hypothesis chip
  ("my call" vs "source key") — one glance comparison.
- U3 Reflection vocabulary +1: `clear / revisit / gem` (ستاره‌دار) — gems get
  a shelf of their own in Practice modes.
- U4 Question finder: jump by number within topic, random-pick within
  section, difficulty filter chips over shelf slices.
- U5 First-run tour: 3-step coach marks for path → study room → revisit
  (one-time, dismissible, reduced-motion aware).

## Pillar 5 — UI / style

- V1 Mira in the study room: thinking pose beside hypothesis, correct pose
  on reveal when hypothesis matches source key (labeled "source key"),
  gentle copy variants; completion recap pose per G4.
- V2 Node/path states for gem + due (brass gem tick, amber due ring) within
  the existing painter language.
- V3 Responsive + font-scale 1.5 + reduced-motion audit for archive/study
  screens (map already tested); add widget tests mirroring existing ones.

## Pillar 6 — Performance

- P1 Measure first-open of biggest shard (`functions`, 495 items) in study
  room; if jank, move JSON decode to `compute` isolate; keep repository
  cache.
- P2 = D4 startup trim; re-add queries only with their surfaces.
- P3 Question-media images in study room: explicit `cacheWidth` audit in
  `ContentBlocksView` image path.

## Pillar 7 — Broad additions (fit-checked options)

- I1 Hypothesis ledger: private Insights row — "hypotheses matched the
  source key N of M times (source unverified)". Zero pressure, honest label.
- I2 Progress backup/export: one-tap local export of the drift DB (and
  import) — resilience for a private offline product.
- I3 Android home-screen widget: today's charted count + due count, calm
  monochrome (no streak pressure).
- I4 Study-set shuffle seed option: deterministic reshuffle of a set's order
  for a second pass (no scoring change).
- I5 Insights subject balance dial: math vs physics reflection share.

## Phasing (each phase = verify + commit + push)

| Phase | Scope | Effort | Risk |
|---|---|---|---|
| 1 | D1+D4 hygiene, S1 spaced revisit | S | Low |
| 2 | G1+G2 engine v2 + catalog rebind (tests on ledger idempotency) | M | Med |
| 3 | G3 HUD + G4 recap + V1 Mira study presence | M | Low |
| 4 | U2+U3+I1 reveal/hypothesis/gem | M | Low |
| 5 | U4 finder + I4 shuffle + I5 dial | M | Low |
| 6 | P1+P3 perf pass with measurements | S | Low |
| 7 | I2 backup + I3 widget + U5 tour | M/L | Med |

Kill signals: any mechanic that starts feeling like pressure (timers,
penalties, red badges) violates AGENTS.md calm-progression scope and gets
cut; any ledger rule that can double-award on retry fails review.
