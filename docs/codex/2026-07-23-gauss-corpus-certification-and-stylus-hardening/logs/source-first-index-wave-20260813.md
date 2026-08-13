# Source-first corpus index wave — 2026-08-13

## Outcome required

Every one of the `3672` runtime records must be rebuilt from the printed
question, explanatory-solution, and answer-key pages before it can become
usable. The printed books are authoritative; the current runtime corpus is only
an identity/locator input and may not supply recovery content.

## Root cause frozen

- Historical `provenance.question_page` values mixed printed page labels with
  one-based PDF ordinals.
- Math questions `1..16`, for example, are on PDF ordinal `12` of `1.pdf`, not
  ordinal `10`.
- The actual first topic boundary is sets `1..32`, then patterns/sequences
  `33..100`. The historical corpus had records `33..50` bound to the sets
  pages, while the printed `2.pdf` pages contain the real pattern questions.
- The first source-rewrite Jules wave therefore remains untrusted and is not a
  promotion input.

## Independent page inventories

- Question books: `29` immutable PDFs, `482` rendered pages, exactly `15`
  source-inventory lanes.
- Answer books: `530` explanatory-solution pages plus `18` answer-key pages,
  exactly `15` answer-inventory lanes.
- Every ticket binds subject, source PDF, one-based PDF ordinal, source PDF
  SHA-256, rendered page SHA-256, and exact attachment filename.
- The merge gate requires exact, duplicate-free global coverage of math
  `1..2042` and physics `1..1630` independently for question starts,
  explanatory solutions, and key cells.
- Any crop, ambiguity, unreadable number, incomplete continuation, or nonempty
  note fails the global index merge.

## Rewrite v2 gate

`prepare_jules_source_rewrite_wave.py` now accepts only independently merged
question/answer indexes with matching receipts and hashes. Historical recorded
page values are retained as untrusted evidence but cannot choose an
attachment. Each rewrite ticket receives ordered question-page and
solution-page arrays plus exactly one indexed key page. The validator binds
those arrays, prompt hash, attachment hashes/bytes, four options, answer
agreement, rewrite invariants, media coordinates, and ASCII numerals.

## Verification

- `21/21` focused Python tests passed across question inventory, answer
  inventory, index merge, and source-rewrite v2.
- Python bytecode compilation passed for the new/changed pipeline files.
- `git diff --check` passed for the source-rewrite v2 slice.
- Necessary media now requires a tight, non-null pixel crop; whole-page crops
  are rejected before any recovery row can advance.

## Jules dispatch status at this checkpoint

- Source-inventory lanes `1..15` have real Jules web session IDs recorded in
  ignored operational state at `.jules/source-inventory/wave-0001/sessions.json`.
- This dispatch covers all `482/482` immutable question-book pages. Capacity
  was released only after superseded terminal sessions were verified, so no
  lane was counted from a reordered sidebar link or a failed start toast.
- Lane `2` was harvested as an untrusted draft and correctly failed the local
  schema gate because Jules encoded empty notes as strings/sentinel strings.
  It remains unmerged pending deterministic transport normalization and full
  source-numbering review.
- No Jules row from this wave has been merged yet. Runtime usability remains
  fail-closed until every lane is harvested, validated, merged, and followed by
  the answer inventory and source-rewrite/scientific review waves.
