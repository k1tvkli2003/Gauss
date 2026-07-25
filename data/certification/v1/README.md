# Gauss question certification v1

## Purpose

This layer certifies the complete retained source corpus without rewriting it.
The 3,672 source records and 3,410 media files remain immutable. Canonical
records under `data/seed/comprehensive` must be semantically identical to the
Flutter runtime shards, and every referenced media byte is SHA-256 bound. A question is
usable or scorable only when its derived certification record proves that:

1. the stem and all four options are complete and legible;
2. every formula and Persian text run renders;
3. section, topic, subtopic, concepts, and difficulty were reviewed;
4. an independent solver selected an option without seeing the source key;
5. a fresh-context verifier agreed with that option;
6. the solution is complete, correct, and explains the same question; and
7. all evidence is tied to the current source-record SHA-256.

Source-key agreement is evidence, not proof. Model agreement is also not proof
unless it is independent, adversarially verified, and internally consistent.

## Dataset contract

- Classification: user-provided real source corpus plus derived review metadata.
- Source authority: `flutter_app/assets/question_bank/index.json` and its 29
  topic shards.
- Identity: every source ID appears exactly once in `manifest.jsonl`.
- Reconciliation: no manifest-only or source-only IDs; canonical, runtime, and
  media hashes must match.
- Mutation boundary: source shards and media are read-only. Repairs are proposed
  separately and never overwrite the preservation source silently.
- Screening runtime: default quality profile `gpt-5.6-luna` / `medium` with an
  externally observed Codex-app receipt. The user-authorized throughput profile
  is an isolated `gpt-5.6-terra` or `gpt-5.6-sol` / `low` subagent whose task
  identity and exact output-file SHA-256 are recorded in a collaboration
  attestation. Prompt version and result evidence remain recorded per item. A
  model-name string inside model output is never accepted as attestation.
- Correctness: a screening model cannot certify an answer. Independent solve
  and fresh-context verification are separate gates.

## Baseline risk queues

The deterministic baseline deliberately fails closed:

- 409 questions have demonstrably incomplete prompt/option extraction.
- 5 solutions are demonstrably inadequate; one overlaps the extraction queue.
- 481 solution records have no positive source page.
- 353 current questions map to historical solution/key mismatch reports.
- 322 current questions map to historical missing-solution reports.
- 2 current records have a known key/solution or prompt/solution contradiction.
- 24 rows form 12 exact duplicate-content groups; 18 rows have conflicting
  source keys inside their duplicate group.

These are review signals, not automatic answer corrections. Baseline status is
1,470 quarantined, 2,202 pending, and 0 usable.

## Evidence lanes

The following lanes stay separate:

1. `source_fidelity`: transcription, option, diagram, printed key, and solution
   mapping to the original source.
2. `screening`: an attested screening runtime checks extraction, taxonomy
   discovery, concepts, and difficulty only; it never sees or certifies the
   source answer.
3. `answer`: blind solve and fresh-context verification derive the effective
   answer.
4. `solution`: two evidence-bearing reviewers check completeness and logic.
5. `adversarial_verification`: a fresh reviewer attacks interpretation,
   distractors, arithmetic, units, counterexamples, and alternative answers.

An incorrect source key is corrected only in an immutable overlay. The original
`source_option` is retained; `effective_option` may differ only with three
independent answer reviews, explicit correction provenance, and an adversarial
pass.

## Taxonomy workflow

The screening lane first proposes subtopics and concepts. Proposals are
clustered and reconciled, then a versioned registry is frozen. Only a second
classification pass using registered IDs can mark taxonomy `reviewed`;
free-form proposals never enter runtime directly.

## Difficulty rubric

- `above_average`: direct curriculum application; one or two concepts and a
  short, mostly linear derivation.
- `hard`: multi-step use of two or three concepts, a meaningful transformation,
  or careful interpretation.
- `very_hard`: non-obvious strategy, several linked concepts, case analysis, or
  substantial algebraic/physical modeling.
- `olympiad`: proof-like or novel insight beyond routine curriculum technique.

Difficulty describes reasoning burden after extraction is complete. Illegible
or incomplete questions are not “hard”; they are quarantined.

## Status model

`pending -> screened -> solved -> verified -> certified`

Any extraction gap, answer conflict, solution mismatch, insufficient evidence,
or stale hash moves the item to `quarantined`. Only `certified` records may set
`usable=true`.

## Commands

```powershell
node scripts/corpus_certification.mjs baseline
node scripts/corpus_certification.mjs validate
node scripts/corpus_certification.mjs summarize
node scripts/corpus_certification.mjs shard --size=25 --max-weight=120
node scripts/corpus_certification.mjs merge-screening --batch=screening-0001 --attestation=<receipt-id>
```

`baseline` and `shard` are deterministic and never edit source data. Screening
batches are topic-confined and weighted by text/media load. `merge-screening`
rejects missing/reordered/stale IDs, static-blocker acceptance, extra fields,
invalid rubric scores, unattested model identity, and duplicate merges before
atomically replacing the derived manifest.
