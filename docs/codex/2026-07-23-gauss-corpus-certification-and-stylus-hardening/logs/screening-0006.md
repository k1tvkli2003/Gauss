# Screening 0006 evidence

- Runtime: `gpt-5.6-luna`, reasoning `medium`
- Thread: `019f4d22-b53a-74b3-a2e9-38095cbdfa36`
- Attestation: `codex-luna-medium-screening-0006-20260723`
- Input: 25 ordered `math / quadratic_equations_functions` records, weight 49
- Media: all 8 referenced WebP assets inspected from Flutter runtime assets
- Output: 25 JSONL rows with exact input IDs and SHA-256 values
- Merge: 15 accepted, 10 needs repair
- Extraction: 15 screened complete, 10 incomplete
- Corpus validation after merge: 3672 source-bound records, 150 screened, 0 usable

Several transformed-root solutions changed source-equation signs or swapped
coefficients. One root-product condition changed sign, one axis problem lost a
factor two, and the final three graph records use media crops containing
multiple questions rather than a clean bound diagram. No missing information
was reconstructed.
