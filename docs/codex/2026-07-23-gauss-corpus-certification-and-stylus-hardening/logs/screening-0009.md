# Screening 0009 evidence

- Runtime: `gpt-5.6-luna`, reasoning `medium`
- Thread: `019f4d22-b53a-74b3-a2e9-38095cbdfa36`
- Attestation: `codex-luna-medium-screening-0009-20260723`
- Input: 15 ordered `math / quadratic_equations_functions` records, weight 21
- Media: both referenced WebP assets inspected from the Flutter runtime asset tree
- Output: 15 JSONL rows with exact input IDs and SHA-256 values
- Merge: 6 accepted, 9 needs repair
- Extraction: 6 screened complete, 9 incomplete
- Corpus validation after merge: 3672 source-bound records, 215 screened, 0 usable

The two inspected assets included one blank white solution image and one
matching route diagram. Nine records remain quarantined for changed radical
equations, incomplete solution text, an option/solution mismatch, or multiple
values emitted for a single-choice question. No answer or solution was
certified and no missing text was reconstructed.
