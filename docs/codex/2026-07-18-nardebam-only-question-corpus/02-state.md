# State

- Current status: `active`
- Last updated: 2026-07-18T23:50:00+03:30
- Owner: Codex

## Current State

The Flutter product is the active Android/web implementation. It ships 3,672
preserved questions across 29 topics, projects them into 9 sections and stable
sets of at most 20, and records only private clear/revisit reflections. The
question corpus, media, Room position, and study reflections are local-first.

The installed Android package was updated in place from v89 to
`1.0.90 (90)` using the existing Gauss signing identity. The original
`firstInstallTime` remained unchanged, proving package and data continuity.

## Decisions

| Decision | Rationale |
|---|---|
| Retain only explicit internal source provenance | Prevents generated or prior Gauss questions from silently surviving |
| Remove the provider name only from product copy, not internal provenance | Keeps the UI neutral while preserving auditability |
| Treat all source mappings as unverified | Deletion/migration is not answer validation |
| Use private clear/revisit reflection instead of correctness/XP | Avoids false scoring while retaining useful metacognition |
| Keep all sections and sets open | Locks would imply mastery evidence the corpus does not provide |
| Use Subject → Section → Unit/topic → set ≤20 | Makes 3,672 items navigable without flattening or radial clutter |
| Keep the path continuous and sinuous | Provides clear forward orientation and preserves the accepted adventure direction |
| Keep router mounted during bootstrap | Preserves refreshed/bookmarked web deep links |
| Keep ink session-local | Direct annotation must never mutate source data or stored progress |
| Reuse the protected Gauss release key and code 90 | Preserves Android update compatibility and installed data |

## Verified Facts

- Questions: 3,672 total; 2,042 mathematics; 1,630 physics.
- Topics: 29; curriculum sections: 5 mathematics and 4 physics.
- Question-bank artifact: 30 files, 6,007,444 bytes.
- Media: 3,410 files, 66,450,076 bytes.
- Static/test gate: analyzer clean; 49 tests passed.
- Web release deep links: Map, Study, and Insights verified directly.
- Android: cold launch 6,316 ms; hot foreground 1,217 ms on Android 15
  emulator; no fatal/Flutter errors after navigation and drawing.

## Known Boundary

The source answer and solution mappings remain intentionally unverified.
Accordingly, Study Room reveals them as preserved source material but does not
score them. This is a trust boundary, not an incomplete migration.

## Done

- Source-only migration, curriculum, persistence, UI, routes, and drawing.
- Analyzer, 49 tests, web release, byte-parity verifier, signed APK, Android
  update/launch/navigation/drawing/clear proof.
- Runtime, research, opinion, motion, precision, and identity ledgers.

## Remaining

- Validate task docs and the modernize skill change.
- Final secret/ignored-file/diff audit.
- Commit and push the complete work to `main`, then remove other branches.
