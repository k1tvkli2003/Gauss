# Jules repair-harvest gate

## Purpose

Repair work may improve a quarantined question only through a source-preserving
overlay. A syntactically valid agent response is not enough: it must bind to
the exact ticket and source hash, be ordered, make a concrete non-empty repair
when labelled as a draft, and remain independently reviewable before any
promotion.

`scripts/validate_jules_repair_harvest.py` is the fail-closed gate for that
transport shape. It never reads or changes immutable source JSON/media and it
does not certify an answer or solution.

## Required contract

Each output row is exact-order and hash-bound to the original repair input and
has only these fields:

```text
ticket_id, question_id, source_sha256, status, patch,
evidence, effective_option, blockers
```

Two outcomes are allowed:

- `draft`: a non-empty, source-preserving `solution` `addendum`; it must carry
  independent-solve, solution-review, and adversarial-review summaries and no
  unresolved blockers.
- `under_review`: no patch and at least one explicit blocker. This protects
  incomplete, ambiguous, contradictory, or otherwise unproven material without
  deleting the question.

The validator rejects malformed JSONL, blank rows, duplicate IDs, order or hash
drift, unexpected fields, unsupported statuses, no-op drafts, changed-source
patches, incomplete evidence, invalid option ranges, and missing blockers.

## Initial fail-closed result

The first harvested response set from repair batches 003–008 had exact row
counts/order/source hashes, but it did **not** satisfy the overlay contract:

- some rows called themselves `draft` while omitting a patch entirely;
- some supplied an empty patch or a non-canonical replacement/update kind;
- some unresolved rows did not use an explicit under-review blocker.

Those rows remain only raw external evidence under ignored `.jules` storage;
they were not merged into `repair-overlays.jsonl`, the certification manifest,
or the runtime question bank. Batches 009–010 had no machine-extractable JSONL
at the first harvest point, so they also remain quarantined.

All eight sessions received a schema-correction follow-up that preserves the
blind lane: it prohibits source-key access, forbids discarding a question, and
requires an exact ten-row JSONL response. A new response must pass this gate,
then independent local mathematical and source-fidelity review, before it can
become even a draft overlay.

## Local verification

```text
python -m py_compile scripts/validate_jules_repair_harvest.py  # passed
synthetic valid + invalid contract assertions                  # passed
repair-003 initial harvest                                     # rejected as expected
```

This gate is intentionally narrower than certification. A passing output says
only that the repair proposal is structurally safe to review; it never makes a
question usable by itself.

## Correction harvest: batches 003–010

The schema-correction responses for all eight batches were re-extracted from
their saved Jules activity records using
`scripts/harvest_jules_repair_message.py`. The extractor emits exact UTF-8
bytes and reports the hash of those persisted bytes, so a Windows newline
conversion cannot silently break the evidence binding.

All 80 rows passed the structural gate: exact ten-row batch cardinality,
ticket order, question IDs, source hashes, allowed fields, canonical patch
shape, review evidence fields, option range, and JSONL syntax. Their outcomes
remain deliberately conservative:

- 27 rows are source-preserving `draft` solution-addendum proposals.
- 53 rows are `under_review` with an explicit blocker and remain quarantined.
- One of the 27 drafts was already present in the overlay with the same source
  hash, so it was retained rather than overwritten.
- The other 26 drafts were appended to the derived repair overlay, bringing
  `repair-overlays.jsonl` from 14 to 40 entries. Its post-write SHA-256 is
  `54a81944345427141fcf13af66b0a4d9aff02795bcab9efcd85559788b8d5d14`.

`node scripts/corpus_certification.mjs validate-repairs` passed with all 40
overlays. This is **not** answer certification, source-fidelity proof, or a
runtime promotion: draft overlays still require independent mathematical,
render/source, and adversarial review. The 53 unresolved records were not
discarded, altered, or made available to learners.

## Verification update

```text
python -m py_compile scripts/harvest_jules_repair_message.py \
  scripts/validate_jules_repair_harvest.py                    # passed
repair-003 correction extraction + strict validator            # passed
all correction batches 003–010 structural validation           # passed (80 rows)
node scripts/corpus_certification.mjs validate-repairs          # passed (40 overlays)
node scripts/corpus_certification.mjs summarize                 # passed
```

## Canonical-overlay guard

The corpus validator now also checks the canonical overlay itself, not only an
incoming Jules payload. Every overlay must have the expected version and six
top-level fields, bind to an extant source hash, use a known state, and carry a
non-empty solution patch plus independent-solve and solution-review evidence
when it is a draft. An explicit `preserve_source: false` is rejected. Older
source-preserving draft kinds remain review-only for backward compatibility;
new harvested drafts must meet the stricter addendum contract above.

A negative test temporarily injected `preserve_source: false`, confirmed that
`validate-repairs` rejected it, and restored the canonical overlay before the
final passing validation. This defends the repair plane from accidental
destructive promotions while keeping source JSON and media immutable.

## Correction harvest: batches 011–017

The seven later, source-key-blind repair sessions completed as message-only
handoffs. Their complete raw activity pages are retained under ignored
`.jules` evidence; a terminal session without a change set was not treated as
an implementation.

Each correction response was extracted from its latest exact JSONL message and
passed the transport gate against its ten-ticket input. All 70 rows preserved
ticket ID, question ID, original order, and source SHA-256. The status split
was 55 `draft` and 15 `under_review`.

`scripts/materialize_jules_repair_drafts.py` is the second fail-closed step.
It accepts only the canonical draft shape (solution target, addendum kind,
`preserve_source: true`, three non-empty review observations, and no blocker),
compares it against the overlay ledger for conflicts, and atomically writes
only new drafts. It deliberately omits a Jules `effective_option` observation:
that observation is not a source-key correction or an answer certification.

- Dry run: existing 40 overlays, 55 additions, 15 unresolved rows excluded.
- Write: 95 overlays, SHA-256
  `4c990c019cf76e9b2a9c538a01be644a7c6b3dd2b9e954e9a60676c3b503f7b8`.
- `validate-repairs`, full corpus `validate`, `summarize`, and regenerated
  `repair-queue` all passed; the queue remains 2,791 and usable remains 0.

This remains a repair proposal ledger. It does not change immutable source
JSON/media, certify the proposed option, solve source-fidelity, or admit a
question to runtime.
