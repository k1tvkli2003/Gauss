# Phase 6 — performance measurements

Measured with `flutter test test/shard_decode_benchmark_test.dart` on the
development host (Windows, debug VM). Device numbers will be slower, but the
*relative* costs are what drove the decisions.

## Shard decode (study room first open)

| Shard | Questions | Cold decode | Warm (cached) |
|---|---|---|---|
| oscillation_waves | 283 | 46 ms | 0 ms |
| functions | 264 | 15 ms | 0 ms |
| one_dimensional_motion | 248 | 8 ms | 0 ms |
| trigonometry | 236 | 12 ms | 0 ms |

**Decision: no isolate.** The plan allowed moving JSON decode to a `compute`
isolate *if* the measurement showed jank. It does not: the worst shard costs
46 ms once, then 0 ms from cache. An isolate would add
`BackgroundIsolateBinaryMessenger` setup and bundle-access complexity for a
cost that is already below a dropped-frame budget on this host and paid once
per topic. Re-measure on a low-end device before revisiting.

## Curated shelf lookup (revisit / gem orbits) — real defect found

`questionsByIds` scanned every shard until it found the wanted ids. Opening a
revisit shelf whose question lived in a late shard decoded almost the entire
library:

| Path | Cost |
|---|---|
| Full scan (before) | **134 ms** |
| Topic-hinted (after) | **1 ms** |

**Fix:** study records already store each question's `topicKey`, so the
curated shelves now pass a `topicByQuestionId` hint map and only the shards
that actually hold marked questions are decoded. Stale hints fall through to
the old scan, so correctness never depends on the hint being right.

Locked by `question_contract_test.dart`: hinted lookups leave every other
shard undecoded (`isTopicLoaded` is false), order still follows the requested
ids, and a stale hint still resolves.

## Question media

No change needed. `ContentBlocksView` already sizes `cacheWidth` from the real
viewport width times device pixel ratio, clamped to 600–1800, with a separate
2400 budget for the fullscreen viewer. Audited, left alone.

## Startup

Phase 1 already removed the attempts/analytics/revenge/review/active-mission
queries that no live surface consumed; boot now loads only the study summary,
the spaced-due queue, and the gamification summary.
