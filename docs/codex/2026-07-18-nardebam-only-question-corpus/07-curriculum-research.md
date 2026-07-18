# Curriculum Research and Adaptation

## Research Goal

Understand why Duolingo-style paths remain legible at large content volume, then
adapt the structural ideas to a private mathematics/physics archive without
copying branded visuals, language-learning mechanics, locks, or social pressure.

## Primary Sources Consulted

- [Duolingo home-screen redesign](https://blog.duolingo.com/new-duolingo-home-screen-design/?lang=en)
- [Duolingo product highlights](https://blog.duolingo.com/product-highlights/)
- [Intermediate mini-units](https://blog.duolingo.com/intermediate-mini-units/)
- [Reviewing lessons](https://blog.duolingo.com/how-to-review-lessons-on-duolingo/)
- [Duolingo 101](https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo/)

Research was used for information architecture and progression clarity, not
visual imitation.

## Transferable Principles

1. A single primary path reduces choice paralysis.
2. Large curricula need visible intermediate groupings rather than one node per
   chapter or a flat topic list.
3. Short, stable lesson units make progress understandable and resumable.
4. Review should be available near the primary path, not hidden in settings.
5. Progress needs a clear current position and a fast return action.

## Gauss Adaptation

| Reference principle | Gauss implementation |
|---|---|
| One clear route | One continuous sinuous path per selected subject |
| Intermediate grouping | Subject → Section → Unit/topic → set |
| Short lesson units | Deterministic, non-overlapping sets of at most 20 questions |
| Current position | Continue Orbit, current node emphasis, jump-to-current |
| Review access | Revisit Orbit plus per-topic clear/revisit counts |
| Navigation context | Persistent Math/Physics switch and section chips |

## Curriculum Projection

- Mathematics: 5 sections, 18 topics, 2,042 questions.
- Physics: 4 sections, 11 topics, 1,630 questions.
- Total: 9 sections, 29 topics, 3,672 questions.
- Each source question appears exactly once in the generated study shelves.
- Shelf keys are stable, enabling persisted resume position and reflection
  aggregation without rewriting the corpus.

## Intentional Differences

- No locked path: source mappings are not independently validated, so Gauss
  cannot honestly gate progress on correctness.
- No hearts, leagues, public streaks, or forced daily pressure: the product is
  private and single-user.
- No synthetic XP for opening preserved material: the reflection model records
  `clear` or `revisit` without pretending that an answer was scored.
- Math and Physics are separate subject modes sharing one consistent path
  grammar, not radial planets mixed into one canvas.

## Acceptance Evidence

`study_curriculum_test.dart` proves topic uniqueness, full 3,672-question
coverage, non-overlapping shelves, and the maximum set size. Phone/desktop
release captures prove that the same hierarchy survives responsive layouts.
