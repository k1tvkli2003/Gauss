# Source-only corpus and Study Observatory rebuild

- Task ID: `2026-07-18-nardebam-only-question-corpus`
- Status: `done — implementation, release verification, and main publication complete`
- Created: 2026-07-18T17:43:31
- Last verified: 2026-07-18T23:50:00+03:30
- Language: en

## Request

Retain only the 3,672 explicitly sourced questions and every referenced media
asset, remove the provider name from product copy, and rebuild the private
Flutter Android/web learning experience around a continuous Math/Physics study
path. The experience must include direct ink on the question, a full
scratchpad, calm private reflection, astronomical presentation, responsive
navigation, and real release/runtime proof.

## Success Criteria

- Exactly 3,672 shipped records remain: 2,042 mathematics and 1,630 physics.
- Every shipped record has the internal provenance value
  `source_bank: nardebam`; the provenance name never appears in user-facing
  Flutter/web copy.
- All 3,410 referenced media files remain byte-identical in source, Flutter,
  web, and APK artifacts; non-source corpora and orphan media are absent.
- Curriculum hierarchy is Subject → Section → Unit/topic → stable sets of at
  most 20 questions, with a continuous sinuous path and no artificial locks.
- Study Room supports private hypothesis, source reveal, clear/revisit
  reflection, resume position, direct question ink, instant clear, and a
  separate full-sheet scratchpad without scoring unverified answer mappings.
- Map, Study, Insights, and Study Room are responsive, astronomical,
  map/product-first surfaces with floating glass navigation and the selected
  Gauss identity.
- Analyzer, full tests, web release, deep links, signed APK, artifact hashes,
  update-in-place, Android launch, semantic interaction, drawing, and clearing
  are all verified.

## Product Boundary

Gauss is a private, single-user, local-first product. Authentication,
monetization, public leagues, social pressure, and punitive streak mechanics
are intentionally excluded. Source-provided answer and solution mappings are
preserved but are not represented as independently verified correctness.

## Out of Scope

- Independently re-solving and validating all 3,672 answer mappings.
- Cloud sync, public profiles, social or competitive systems.
- Store publication. The APK is production-key signed and update-compatible,
  but no store upload was requested.

## Preservation Contract

Git history remains intact. The migration changes the current release corpus
without rewriting source questions or referenced media. Existing Android app
data is preserved through package/signing/version continuity.
