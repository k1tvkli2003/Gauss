# Screening 0008 evidence

- Runtime: `gpt-5.6-luna`, reasoning `medium`
- Thread: `019f4d22-b53a-74b3-a2e9-38095cbdfa36`
- Attestation: `codex-luna-medium-screening-0008-20260723`
- Input: 25 ordered `math / quadratic_equations_functions` records, weight 26
- Media: none referenced; no media inspection was required
- Output: 25 JSONL rows with exact input IDs and SHA-256 values
- Merge: 21 accepted, 4 needs repair
- Extraction: 21 screened complete, 4 incomplete
- Corpus validation after merge: 3672 source-bound records, 200 screened, 0 usable

Four records remain quarantined. One rational-equation solution changes an
intermediate expression, one radical solution changes the radicand, one
parameterized radical solution changes both sides of the equation, and one
nested-radical solution solves a different equation. No answer or solution
was certified and no missing text was reconstructed.
