# Screening 0010 evidence

- Runtime: `gpt-5.6-luna`, reasoning `medium`
- Thread: `019f4d22-b53a-74b3-a2e9-38095cbdfa36`
- Attestation: `codex-luna-medium-screening-0010-20260723`
- Input: 25 ordered `math / rational_inequalities_sign` records, weight 67
- Media: all 14 referenced WebP assets inspected from the Flutter runtime asset tree
- Output: 25 JSONL rows with exact input IDs and SHA-256 values
- Merge: 5 accepted, 19 needs repair, 1 ambiguous
- Extraction: 5 screened complete, 19 incomplete, 1 ambiguous
- Corpus validation after merge: 3672 source-bound records, 240 screened, 0 usable

Most attached solution crops were unrelated to their current rows. Several
rows also contained changed polynomials, placeholder zero glyphs, or solutions
for entirely different rational/absolute-value questions. The graph options
for 0230 were not inspectable in the supplied multi-question crop, so that row
remains ambiguous. No answer or solution was certified and no missing text was
reconstructed.
