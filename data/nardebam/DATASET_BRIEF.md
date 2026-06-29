# Nardebam 1405 ingestion brief

- Purpose: offline personal Math/Physics practice in Gauss.
- Canonical taxonomy: `topic_manifest.json` (18 Math + 11 Physics topics).
- Exact source target: 2042 keyed Math tests and 1630 keyed Physics tests.
- Source type: user-provided scans; original PDFs remain local and are never committed.
- Record format: `question_v2.schema.json` with stable IDs, structured content blocks, four options, answer, solution, and page-level provenance.
- Promotion path: `raw -> reviewed -> promoted -> sharded app assets`.
- Core validation: no missing/duplicate source number, valid topic, four non-empty options, authoritative key match, non-empty solution, and every referenced media asset present.
- AI policy: page segmentation may be deterministic, but transcription and formula understanding must be performed by Jules. Raw OCR is never promoted directly.
- Quota policy: at most 15 active Jules sessions, 100 creations per rolling day, one automatic retry, resumable state on disk.
