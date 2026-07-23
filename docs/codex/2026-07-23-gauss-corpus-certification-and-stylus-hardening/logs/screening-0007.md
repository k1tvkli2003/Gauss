# Screening 0007 evidence

- Runtime: `gpt-5.6-luna`, reasoning `medium`
- Thread: `019f4d22-b53a-74b3-a2e9-38095cbdfa36`
- Attestation: `codex-luna-medium-screening-0007-20260723`
- Input: 25 ordered `math / quadratic_equations_functions` records, weight 76
- Media: all 17 referenced WebP assets inspected from the Flutter runtime asset tree
- Output: 25 JSONL rows with exact input IDs and SHA-256 values
- Merge: 21 accepted, 3 needs repair, 1 ambiguous
- Extraction: 21 screened complete, 3 incomplete, 1 ambiguous
- Corpus validation after merge: 3672 source-bound records, 175 screened, 0 usable

The ambiguous record has an essential graph asset replaced by a cropped,
unrelated multi-question options page. One record asks for `m` while every
equation and option uses `a`; another solution changes the sign of the linear
term; and one stem says `y=x+8` while its graph and solution use `4y+x=8`.
Those source-fidelity defects remain quarantined. No answer or solution was
certified and no missing text was reconstructed.
