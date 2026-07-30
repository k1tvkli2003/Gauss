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
