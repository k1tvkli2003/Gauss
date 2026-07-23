# Screening 0023 evidence

- Runtime: fresh blind parallel subagent `gpt-5.6-terra`, reasoning `low`
- Task: `/root/screening_0023_retry`
- Attestation: `codex-subagent-terra-low-screening-0023-retry-20260723`
- Output binding: SHA-256 `24a121af775b2ef29e1dc1617715709e5291037955a297fbc8ad1f2a1bf35ff8`
- Input: 25 ordered `math / functions` records
- Media: all 22 referenced Flutter assets inspected and hash checked
- Merge: 2 accepted, 12 needs repair, 11 ambiguous
- Extraction: 14 screened complete, 11 ambiguous
- Corpus validation after merge: 3672 source-bound records, 615 screened, 0 usable

The first worker output was rejected after reported answer-field exposure. This
receipt binds only the independent rerun, which did not inspect prior output or
answer-bearing files. Graph/table-dependent rows with cropped or unrelated
assets remained fail-closed. No answer or solution was certified.
