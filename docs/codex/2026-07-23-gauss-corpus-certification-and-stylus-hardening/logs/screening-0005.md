# Screening 0005 evidence

- Runtime: `gpt-5.6-luna`, reasoning `medium`
- Thread: `019f4d22-b53a-74b3-a2e9-38095cbdfa36`
- Attestation: `codex-luna-medium-screening-0005-20260723`
- Input: 25 ordered `math / quadratic_equations_functions` records, weight 28
- Media: the one referenced WebP asset inspected from Flutter runtime assets
- Output: 25 JSONL rows with exact input IDs and SHA-256 values
- Merge: 16 accepted, 9 needs repair
- Extraction: 16 screened complete, 9 incomplete
- Corpus validation after merge: 3672 source-bound records, 125 screened, 0 usable

Detected defects include a solution split across adjacent records, dropped
terms, changed constant signs, incorrect coefficient signs, square-to-cube
changes, a reversed rational-equation sign, and solving the negation of the
requested expression. None were repaired by inference.
