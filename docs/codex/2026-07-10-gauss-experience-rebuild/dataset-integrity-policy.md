# Dataset Integrity Policy

Version: 2
Effective: 2026-07-18

## Purpose

Keep the complete retained source corpus and its media while preventing source answer/solution mappings from silently becoming scored learning truth. Provenance, preservation, and mission eligibility are separate properties.

## Current Corpus Classification

| Classification | Rows | Scored missions | XP/quests/SRS/analytics | Product label |
|---|---:|---|---|---|
| `QuestionTrust.preservedArchive` | 3,672 | blocked | blocked | Source archive / reading room |
| `QuestionTrust.missionReady` | 0 | n/a | n/a | Not available |
| Total bundled | 3,672 | n/a | n/a | 3,672 preserved source questions |

The technical `source_bank` value remains in JSON solely as provenance. The provider name is not product branding and must not appear in user-facing app copy.

## Evidence

- The retained source contains 2,042 math rows and 1,630 physics rows across 29 topic shards.
- All 3,672 bundled records declare the same preserved source bank and keep `provenance.kind=source` plus `solution_origin=source`.
- All 3,410 referenced media files resolve; their combined size remains 66,450,076 bytes.
- The source contains 12 duplicate question groups covering 24 rows; nine groups covering 18 rows conflict on the answer key.
- Source explanations are not independently proven to map reliably to their questions, so schema-valid rows remain non-scoring.
- The former 3,681 Gauss rows and every generated/legacy non-source dataset were removed from the current tree on the owner's explicit instruction. Git history remains the recovery boundary.

## Runtime Rules

1. Every bundled question must be a retained source item; any other source bank is a dataset-integrity error.
2. No retained source row may enter a scored mission queue.
3. Archived rows never award XP, advance quests, alter SRS, or affect scored analytics.
4. An old resumable mission containing an archived row is not resumed; its local database rows are retained.
5. Topic surfaces expose reading-room access and use `Reading only` or equivalent honest copy when no scored set exists.
6. Product chrome uses generic source/archive wording and never exposes the provider provenance name.
7. A solution is not presented as verified guidance until a separate validation overlay proves its mapping.

## Change Control

Archive status may be relaxed only when a new independent, versioned validation source establishes question-to-answer and question-to-solution mapping. Corrections belong in a separate overlay with provenance, tests, and rollback evidence; source JSON/media remain immutable.

## Required Regression Gates

- Total rows = 3,672.
- Math rows = 2,042; physics rows = 1,630.
- Mission-ready rows = 0; preserved archive rows = 3,672.
- Every bundled `source_bank` equals the retained technical source identifier.
- Referenced media = 3,410 files / 66,450,076 bytes; orphan media = 0.
- Default mission query result = empty.
- Provider provenance name is absent from user-facing Flutter copy.
- Source, Flutter, web, and APK question/media trees reconcile by path, length, and SHA-256.

## Historical Baseline

Version 1 (2026-07-15) described a 7,353-row mixed corpus: 3,681 mission-ready Gauss rows plus 3,672 preserved source rows. It is retained in Git history for auditability and is no longer the active product contract.
