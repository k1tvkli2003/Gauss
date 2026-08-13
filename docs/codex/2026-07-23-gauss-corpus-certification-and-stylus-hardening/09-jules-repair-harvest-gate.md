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

## Deterministic next-wave allocator

`scripts/prepare_jules_repair_wave.py` converts the derived repair queue into
exclusive, ignored Jules task inputs without accepting a source answer key. It
filters for unassigned, text-only math `solution_rederive` tickets whose
extraction state is `screened_complete`, excludes every prior task input and
canonical overlay ID, and orders by stable question ID. It exports only:

```text
ticket_id, question_id, source_sha256, blocking_issues, stem, options, solution
```

For wave 018–024, 294 eligible tickets yielded seven independent ten-row
batches. A local blind-input assertion proved all 70 question IDs are unique
and no prompt or input contains `correct_option_index`. The scheduler manifest
is repoless and has no automatic PR mode. Session completion remains only a
harvest trigger; the existing strict extractor and materializer still decide
whether any draft reaches the derived overlay ledger.

## Partial correction harvest: wave 018–024

The wave scheduler was still legitimately active for `repair-021` and
`repair-022`, so its state lock was retained. Five terminal activity records
were read without changing the scheduler state. Three contained a complete,
latest JSONL message that exactly matched their own blind ten-ticket input:

| Task | Exact rows | Draft | Under review | Outcome |
| --- | ---: | ---: | ---: | --- |
| `repair-018` | 10 | 9 | 1 | transport gate passed |
| `repair-020` | 10 | 6 | 4 | transport gate passed |
| `repair-024` | 10 | 9 | 1 | transport gate passed |
| `repair-019` | 0 | — | — | no complete exact-order hash-bound JSONL block; unresolved |
| `repair-023` | 0 | — | — | no complete exact-order hash-bound JSONL block; unresolved |

The three accepted messages were first materialized with `--dry-run`: 24 new
drafts, six explicit under-review records excluded, 119 resulting overlays.
The write produced overlay SHA-256
`37ca00cad5f8ab5796272063ee608e5c865b0b4f48c692737aad120cd557e295`.
The repeated dry run was idempotent (24 existing drafts skipped, zero added).

`validate-repairs`, full-corpus `validate`, `summarize`, and regenerated
`repair-queue` passed after the write. The corpus remains 3672 source-bound
records, 2791 repair tickets, and **0 usable** questions. These overlays are
source-preserving proposed solution addenda only: they do not certify an
answer, repair a media/extraction blocker, establish source fidelity, or move
any record into the scored runtime.

## Terminal reconciliation: wave 018–024

After the active scheduler exited and its state lock cleared naturally, one
final `jules_batch.py harvest` recorded the terminal state without altering
source data: five sessions are `completed` and `repair-021`/`repair-022` are
`failed` with the provider error. The harvest reported zero repository
artifacts for all seven sessions. That does not supersede the persisted
message evidence: only 018, 020, and 024 had complete exact-order,
source-hash-bound JSONL and were already structurally validated/materialized.
019 and 023 lack a complete block; 021 and 022 failed. These four batches
remain quarantined as unresolved repair tickets, not silently retried,
dropped, or promoted.

## Prepared wave 025–031

After excluding every prior repair input and all current overlay IDs, the
deterministic allocator found 224 further eligible text-only math tickets. It
selected the first 70 into seven ten-row batches (`repair-025` through
`repair-031`). A local blind-input assertion proved that all question IDs are
unique and that every payload has precisely
`ticket_id`, `question_id`, `source_sha256`, `blocking_issues`, `stem`,
`options`, and `solution`; `correct_option_index` is absent from both input
and prompt. The repoless manifest validates locally.

Remote dispatch is intentionally pending, not failed-open. A fresh Jules
quota `doctor` and a scheduler `--dry-run` each exceeded their bounded
64-second network window. No remote repair session was created without a
current quota response, and the prepared local inputs remain ignored until
that attestation is available.

## Terminal repair harvest: 044–045

On 2026-08-09 the two previously active, repoless, source-key-blind sessions
were reconciled directly against the Jules API and both were terminal
`COMPLETED`:

| Task | Session | Transport artifact | Rows | Draft | Under review |
| --- | --- | --- | ---: | ---: | ---: |
| `repair-044` | `sessions/16949113585755100113` | harvested unified diff, `output.jsonl` extracted with `git apply --include` | 10 | 9 | 1 |
| `repair-045` | `sessions/5362413856214294398` | exact fenced JSONL from the sole `agentMessaged` activity | 10 | 9 | 1 |

Both outputs passed the existing strict transport gate: exact row count,
original order, ticket ID, question ID, source SHA-256, allowed fields,
draft/under-review shape, and JSONL syntax. The persisted output hashes are
`42dccddc534cb941ac5276997b0572bf378f32a0961daab6b7dc26312f6ff9e0`
for 044 and
`cdfb2d8dc3576fc7d3d6cab70236d8920aba29da2fc89c5c72a4638bda62c2bf`
for 045.

The independent blind audit in `content-audit-044-045.json` re-derived all
twenty questions from stem and options and accepted eighteen addenda. The
versioned row-level audit is preserved in
[`logs/repair-044-045.md`](logs/repair-044-045.md). The
accepted IDs are `1797`, `1798`, `1799`, `1800`, `1801`, `1802`, `1803`,
`1804`, `1805`, `1807`, `1808`, `1809`, `1810`, `1812`, `1813`, `1814`,
`1816`, and `1817` in the `nardebam_math_1405_*` namespace. Two rows remain
fail-closed:

- `nardebam_math_1405_1806`: the literal decimal-digit count is 23,100, but
  none of the four immutable options matches; no missing digit-domain
  restriction can be invented.
- `nardebam_math_1405_1811`: the capped distribution count is 10, but the
  immutable options are 6–9; option 7 would require an unstated nonempty-box
  condition.

The audited materializer advanced the derived overlay ledger from 248 to 266
entries with SHA-256
`a23f4c054181fe748d4ed2adb9235f866a062de26e66ca38a0a29f868561407e`.
`validate-repairs`, full-corpus `validate`, `summarize`, and regenerated
`repair-queue` all passed: 3,672 source-bound rows, 2,791 quarantined tickets
(2,488 P0 render/prompt and 303 P1 correctness), and **0 usable**. These are
source-preserving draft solution addenda only; no source JSON/media or source
answer key changed, and no row bypassed source-fidelity, render, solution,
answer, or adversarial certification gates.

## Terminal reconciliation: repair 043/046 and priority 0037

On 2026-08-10 bounded direct API reads proved the two tasks still marked
`active` in the old local batch state were terminal:

| Task | Session | Live state | Rows | Output SHA-256 |
| --- | --- | --- | ---: | --- |
| `repair-043` | `sessions/14343518125421771215` | `COMPLETED` | 10 | `cc79a58cbb286df39ad5cd43249c107c194c0909df210b5defddbb29e9562209` |
| `repair-046` | `sessions/15703792575445043007` | `COMPLETED` | 10 | `521f3d68e942ba0bfeb1ceb23d5b61022b4b01927ffe4fc8b03dbdaf001fcc66` |

Each session had one exact fenced JSONL activity and no repository artifact or
pull request. The existing extractor/transport reports passed with ten rows,
original order, ticket/question identity, source hash, schema, and draft shape.
The independent mathematical audit accepted all twenty addenda. Eighteen were
already byte-identical in the overlay ledger; only `nardebam_math_1405_1883`
and `nardebam_math_1405_1937` were new, advancing 266 → 268.

The materializer no longer trusts the audit's `sourceKeyHidden` boolean alone.
For every audited remote batch it now requires the original input to contain
exactly `ticket_id`, `question_id`, `source_sha256`, `blocking_issues`, `stem`,
`options`, and `solution`; validates text-block shape; binds input order and
hashes to the harvested rows; proves the prompt ends with that exact serialized
input; and proves the saved remote session prompt equals the local blind prompt.
This strengthened gate revalidated repair-043/044/045/046. No source answer-key
field was present in any of those remote payloads.

The priority `nardebam_math_1405_0037` row is fifth in the locally validated,
repoless repair-061 input and has source hash
`510c99cc94bf379b1c7fec112cedf582ee228eb8f72e9b753c1df831ca9a5689`.
Its input has only the seven allowed blind fields and no source-answer field.
Independent re-derivation proves option 2 is the only pair that is always
disjoint because `(A-B) ∩ B = ∅`; however, `A-B` is not guaranteed nonempty
(for example when `A ⊆ B`). A source-preserving addendum now replaces the
unrelated arithmetic-sequence explanation and records that caveat, advancing
268 → 269, but the record remains quarantined and uncertified.

The repair-061–078 manifest validates locally (18 independent tasks; manifest
SHA-256 `89b0823649f959c838dc349995995398dbf7d9962ac365b03a2809f906a8f36c`).
No new session was dispatched: both a bounded Jules doctor and a quota-only
pagination call timed out without a complete account-wide capacity snapshot.
Per the fail-closed quota rule, partial evidence cannot authorize creation.

Final gates passed: 269 unique overlays with current source hashes and SHA-256
`18663b9241c6faae15a6dd6d052f9ac04c19caea94cc9922da503baada7a8556`;
3,672 source-bound records; 2,791 quarantined tickets (2,488 P0, 303 P1); and
**0 usable**. Source question JSON, media, source keys, and runtime admission
state were unchanged.
