# Screening 0001 evidence

- Runtime: `gpt-5.6-luna`, reasoning `medium`
- Thread: `019f4d22-b53a-74b3-a2e9-38095cbdfa36`
- Attestation: `codex-luna-medium-screening-0001-20260723`
- Input: 25 ordered `math / sets` records, total weight 82
- Media: all 19 referenced WebP assets inspected from Flutter runtime assets
- Output: 25 JSONL rows with exact input IDs and SHA-256 values
- Merge: accepted 6, needs repair 17, ambiguous 2
- Extraction: screened complete 8, incomplete 15, ambiguous 2
- Corpus validation after merge: 3672 source-bound records, 0 usable

The dominant evidence was not a subtle answer disagreement. It was visible
record corruption: solution text mapped to a different stem, option imagery
cropped from unrelated material, changed interval endpoints, or mismatched set
expressions. No source answer key was read or inferred in this screening lane.
All accepted rows remain non-usable until source-fidelity, blind-answer,
fresh-verifier, complete-solution, render, and adversarial gates pass.
