# Screening 0003 evidence

- Runtime: `gpt-5.6-luna`, reasoning `medium`
- Thread: `019f4d22-b53a-74b3-a2e9-38095cbdfa36`
- Attestation: `codex-luna-medium-screening-0003-20260723`
- Input: 25 ordered `math / patterns_sequences` records, total weight 34
- Media: all 3 referenced WebP assets inspected from Flutter runtime assets
- Output: 25 JSONL rows with exact input IDs and SHA-256 values
- Merge: 11 accepted, 13 needs repair, 1 ambiguous
- Extraction: 11 screened complete, 13 incomplete, 1 ambiguous
- Corpus validation after merge: 3672 source-bound records, 75 screened, 0 usable

The primary defects were digit-2 substitutions rendered as `r`, cropped or
unrelated images, recurrence sign changes, and different requested indices
between stem and solution. Accepted rows have internally aligned sequence
statements and complete solution text, but remain non-usable pending the
independent answer, solution, source-fidelity, render, and adversarial lanes.
