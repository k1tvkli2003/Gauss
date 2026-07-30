# Daily quest receipt: truthful study closure

## Purpose

The study room must acknowledge a meaningful daily milestone without
overstating content certainty. A reflection records the learner's own study
state; it does not certify the mathematical correctness of a quarantined source
question or answer.

## Contract

- `StudyReflectionOutcome.dailyQuestCompleted` is true only when this write
  creates the idempotent `daily_study_completed:<dayKey>` ledger event.
- Replaying the same reflection cannot create the event or show the receipt a
  second time.
- The recap opens for a daily milestone even when the study XP cap means the
  newly recorded event has zero additional XP.
- The UI explicitly distinguishes **milestone recorded** from **XP granted**;
  it never claims answer correctness or content certification.

## UI behavior

The existing study recap is reused so the interaction remains a single,
low-friction finish state rather than a competing dashboard. The headline is
`Daily observation complete`; the detail says that ten new reflections were
safely recorded. When the daily cap is already met, the receipt explains that
no extra XP was granted. Its semantic label contains the same information.

## Verification

- `dart analyze lib test` — passed.
- Targeted repository and study-surface suite — 47/47 passed, including
  idempotency and the tenth-reflection recap.
- Full `flutter test` — 98/98 passed.
- `flutter build web --release --no-wasm-dry-run` — passed.

Physical Android/Fokus Pen proof and source-PDF fidelity are intentionally
separate gates and remain open.
