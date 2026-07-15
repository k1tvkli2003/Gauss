# Dataset Integrity Policy

Version: 1  
Effective: 2026-07-15

## Purpose

Keep every source question and media file while preventing known-conflicting material from silently becoming scored learning truth. Preservation and mission eligibility are separate properties.

## Corpus Classification

| Classification | Rows | Scored missions | XP/quests/SRS/analytics | Solution display |
|---|---:|---|---|---|
| `QuestionTrust.missionReady` (Gauss) | 3,681 | allowed | allowed after persisted non-skipped attempts | 3,610 shown; 71 withheld |
| `QuestionTrust.preservedArchive` (Nardebam) | 3,672 | blocked | blocked | blocked in scored flow |
| Total preserved | 7,353 | n/a | n/a | Source solution blocks remain byte-preserved |

## Evidence

- Nardebam contains 3,672 source rows.
- It contains 12 duplicate question groups covering 24 rows.
- Nine of those groups, covering 18 rows, conflict on the answer key.
- Nardebam explanations are not reliably mapped to their questions, so schema-valid rows are not treated as answer-validated learning material.
- The 3,681 Gauss mission-ready rows contain no duplicate content groups under the production contract test.
- Seventy-one Gauss explanations explicitly name an option number that conflicts with the answer contract. Their questions remain scorable, but `solutionVerified=false` prevents the conflicting explanation from being shown.

## Runtime Rules

1. Only `missionReady` rows may enter a mission queue.
2. A source filter requesting Nardebam returns no mission-ready questions.
3. Archived rows never award XP, advance quests, alter SRS, or affect analytics.
4. An old resumable mission containing non-mission-ready rows is not resumed; its database rows are retained for preservation.
5. Topics expose both ready and preserved counts. A topic with zero ready rows has a disabled `Archive` action.
6. The UI uses `contract-checked` wording and does not claim independent mathematical proof.
7. A solution is displayed only when `solutionVerified` is true.

## Change Control

Archive status may be relaxed only when a new independent, versioned validation source establishes question-to-answer and question-to-solution mapping. The original JSON/media must still remain byte-identical; any corrections belong in a separate overlay with provenance, tests, and rollback evidence.

## Required Regression Gates

- Total rows = 7,353.
- Mission-ready rows = 3,681.
- Preserved archive rows = 3,672.
- Displayable solutions = 3,610.
- Withheld conflicting Gauss explanations = 71.
- Mission-ready duplicate content groups = 0.
- Nardebam mission query result = empty.
- Source, web, and APK question/media trees reconcile by path, length, and SHA-256.

