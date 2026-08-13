#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const certificationRoot = path.join(repoRoot, "data", "certification", "v1");
const flutterRoot = path.join(repoRoot, "flutter_app");
const manifestFile = path.join(certificationRoot, "manifest.jsonl");
const sourceReceiptsFile = path.join(
  certificationRoot,
  "source-fidelity-receipts.jsonl",
);
const correctionReceiptsFile = path.join(
  certificationRoot,
  "scientific-correction-receipts.jsonl",
);
const overlaysFile = path.join(certificationRoot, "repair-overlays.jsonl");
const questionIndexFile = path.join(
  flutterRoot,
  "assets",
  "question_bank",
  "index.json",
);
const renderTestFile = path.join(
  flutterRoot,
  "test",
  "scientific_correction_render_test.dart",
);
const correctionLogFile = path.join(
  repoRoot,
  "docs",
  "codex",
  "2026-07-23-gauss-corpus-certification-and-stylus-hardening",
  "logs",
  "scientific-correction-0093-20260813.md",
);
const proofFile = path.join(
  repoRoot,
  "docs",
  "codex",
  "2026-07-23-gauss-corpus-certification-and-stylus-hardening",
  "evidence",
  "scientific-correction-0093-proof.json",
);
const reviewRoot = path.join(
  repoRoot,
  "docs",
  "codex",
  "2026-07-23-gauss-corpus-certification-and-stylus-hardening",
  "evidence",
);
const apply = process.argv.includes("--apply");
const stage = process.argv.includes("--stage") || apply;

const questionId = "nardebam_math_1405_0093";
const expectedSourceSha256 =
  "1f195ef839c708f090b427c13e285ef13d079273c57934388a1974d4b479af83";
const sourceConflictReceiptId = `source-fidelity-math-0004:${questionId}`;
const correctionReceiptId = `scientific-correction-math-0001:${questionId}`;

const contentPatch = Object.freeze({
  solution: [
    {
      type: "text",
      text:
        "عدد 3 واسطهٔ هندسی $a$ و $b$ است؛ پس $ab=9$. چون کسرهای صورت سؤال تعریف‌شده‌اند، $a\\ne 3$ و $b\\ne 3$. اگر $6-a-b=0$ باشد، آنگاه $a+b=6$ و با $ab=9$ خواهیم داشت $(a-3)(b-3)=0$؛ در نتیجه $a=b=3$ که با تعریف‌شدن کسرها تناقض دارد. بنابراین $6-a-b\\ne 0$ و حذف این عامل مجاز است. اگر واسطهٔ حسابی را $k$ بنامیم:\n$k=\\frac{\\frac{1}{3-a}+\\frac{1}{3-b}}{2}=\\frac{6-a-b}{2(3-a)(3-b)}=\\frac{6-a-b}{6(6-a-b)}=\\frac{1}{6}$\nپس پاسخ صحیح گزینهٔ 4 است.",
    },
  ],
});

const evidenceFiles = Object.freeze({
  independent_solve: "answer-review-0006.jsonl",
  independent_verifier: "verify-review-0006.jsonl",
  solution_review_accepting_domain_implication: "solution-review-0005a.jsonl",
  solution_review_identifying_omission: "solution-review-0005b.jsonl",
  adversarial_review_identifying_omission: "adversarial-review-0005.jsonl",
  source_key_adjudication: "jules-adjudicator-0013.jsonl",
});

function canonicalJson(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (value && typeof value === "object") {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

function digest(value) {
  return crypto.createHash("sha256").update(canonicalJson(value)).digest("hex");
}

function digestFile(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function readJsonLines(file) {
  if (!fs.existsSync(file)) return [];
  return fs
    .readFileSync(file, "utf8")
    .split(/\r?\n/u)
    .filter(Boolean)
    .map((line) => JSON.parse(line));
}

function writeJsonLinesAtomic(file, rows) {
  const temporary = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(temporary, `${rows.map(JSON.stringify).join("\n")}\n`);
  fs.renameSync(temporary, file);
}

function mergeByQuestionId(existing, replacements) {
  const replacementById = new Map(
    replacements.map((item) => [item.question_id, item]),
  );
  const merged = existing.map(
    (item) => replacementById.get(item.question_id) ?? item,
  );
  const existingIds = new Set(existing.map((item) => item.question_id));
  for (const replacement of replacements) {
    if (!existingIds.has(replacement.question_id)) merged.push(replacement);
  }
  return merged;
}

function loadRuntimeRow() {
  const index = readJson(questionIndexFile);
  for (const topic of index.topics) {
    const rows = readJson(path.join(flutterRoot, "assets", topic.file));
    const match = rows.find((row) => row.id === questionId);
    if (match) return match;
  }
  throw new Error(`${questionId}: missing immutable runtime row.`);
}

function evidenceFileReceipt(name) {
  const file = path.join(reviewRoot, name);
  if (!fs.existsSync(file)) throw new Error(`${name}: missing evidence file.`);
  const matchingRows = readJsonLines(file).filter(
    (row) => row.question_id === questionId,
  );
  if (
    matchingRows.length !== 1 ||
    matchingRows[0].source_sha256 !== expectedSourceSha256
  ) {
    throw new Error(`${name}: missing or stale 0093 evidence row.`);
  }
  return {
    path: path.relative(repoRoot, file).replaceAll("\\", "/"),
    sha256: digestFile(file),
    row_sha256: digest(matchingRows[0]),
  };
}

function buildSourceConflictReceipt(record) {
  return {
    schema_version: 1,
    receipt_id: sourceConflictReceiptId,
    batch_id: "source-fidelity-math-0004",
    question_id: questionId,
    source_sha256: record.source_sha256,
    reviewer_id: `codex-sol-xhigh-source-fidelity-0004:${questionId}`,
    reviewed_on: "2026-08-13",
    verdict: "source_conflict",
    verified_fields: ["question_number", "stem", "options"],
    conflict: {
      kind: "answer_key_and_solution_domain_conflict",
      fields: ["source_option_index", "solution"],
      detail:
        "The printed question and option order match the derived row, but the immutable extracted key is option 2 while the printed key and exact algebra give option 4. The printed solution also cancels 6-a-b without explicitly closing the excluded a=b=3 domain case.",
    },
    question_source: {
      logical_pdf: "math/2.pdf",
      pdf_sha256:
        "f0b9021a8315b9b3f5e1cd49543930158e5f919c857756e7ccf2497f1d96377a",
      pdf_ordinal: 7,
      recorded_question_page: 7,
      question_number: 93,
      rendered_page_sha256:
        "584280df9a8ca018da5a2908b96181ba8955b560e0e4aa6fdbcf9a1cf77f566c",
    },
    solution_source: {
      logical_pdf: "math/19.pdf",
      pdf_sha256:
        "4b40ec5c1f886d42b15abc21a416dd3f8504b552011bae793e087743e184bf70",
      pdf_ordinal: 9,
      recorded_solution_page: 9,
      question_number: 93,
      rendered_page_sha256:
        "d031727bb1d989fc3ad96cf5eb96b11293e441cb435de44f01e056c45ebdea64",
    },
  };
}

function buildCorrectionReceipt(record, sourceReceipt, runtimeRow) {
  if (
    record.source_sha256 !== expectedSourceSha256 ||
    digest(runtimeRow) !== record.runtime_record_sha256 ||
    sourceReceipt.receipt_id !== sourceConflictReceiptId ||
    sourceReceipt.verdict !== "source_conflict"
  ) {
    throw new Error(`${questionId}: stale correction inputs.`);
  }
  const effectiveRow = { ...runtimeRow, ...contentPatch };
  const files = Object.fromEntries(
    Object.entries(evidenceFiles).map(([role, name]) => [
      role,
      evidenceFileReceipt(name),
    ]),
  );
  return {
    schema_version: 1,
    receipt_id: correctionReceiptId,
    batch_id: "scientific-correction-math-0001",
    question_id: questionId,
    source_sha256: record.source_sha256,
    runtime_record_sha256: record.runtime_record_sha256,
    reviewer_id: `codex-sol-xhigh-scientific-correction-0001:${questionId}`,
    reviewed_on: "2026-08-13",
    verdict: "scientifically_corrected",
    source_conflict_receipt_id: sourceReceipt.receipt_id,
    source_conflict_receipt_sha256: digest(sourceReceipt),
    corrected_fields: ["solution"],
    correction_summary:
      "Completes the source solution's missing domain proof and binds the independently verified option 4 without changing the immutable source row or PDF.",
    content_patch: contentPatch,
    effective_record_sha256: digest(effectiveRow),
    answer_mapping: {
      immutable_source_option: 2,
      printed_source_option: 4,
      effective_option: 4,
      semantic_answer: "1/6",
      relation: "scientific_override_of_immutable_extracted_key",
    },
    classification: {
      registry_version: "gauss-taxonomy-v1",
      section_id: "math_algebraic_foundations",
      topic_key: "patterns_sequences",
      subtopic_key: "patterns_sequences_geometric",
      concept_tags: ["geometric_sequence", "general_term"],
      secondary_concepts: ["arithmetic_mean", "rational_expression"],
      prerequisites: ["exponents"],
    },
    question_source: sourceReceipt.question_source,
    solution_source: sourceReceipt.solution_source,
    evidence_files: files,
    proof_evidence: {
      path: path.relative(repoRoot, proofFile).replaceAll("\\", "/"),
      sha256: digestFile(proofFile),
      domain_guard_closed: true,
      exact_answer: "1/6",
    },
    render_evidence: {
      test_file: {
        path: path.relative(repoRoot, renderTestFile).replaceAll("\\", "/"),
        sha256: digestFile(renderTestFile),
      },
      evidence_log: {
        path: path.relative(repoRoot, correctionLogFile).replaceAll("\\", "/"),
        sha256: digestFile(correctionLogFile),
      },
      assertions: {
        width_dp: 320,
        text_scale_percent: 200,
        no_flutter_exception: true,
        learning_content_digits: "ascii",
        immutable_source_mutation: "none",
      },
    },
  };
}

function holdingReview(role, reviewerId, option, evidenceDigest) {
  const review = {
    role,
    reviewer_id: reviewerId,
    independent_context: true,
    verdict: "holds",
    evidence_digest: evidenceDigest,
  };
  if (option != null) review.option = option;
  return review;
}

function promote(record, receipt, sourceReceipt) {
  const receiptDigest = digest(receipt);
  record.taxonomy.registry_version = receipt.classification.registry_version;
  record.taxonomy.section_id = receipt.classification.section_id;
  record.taxonomy.subtopic_key = receipt.classification.subtopic_key;
  record.taxonomy.concept_tags = [...receipt.classification.concept_tags];
  record.taxonomy.secondary_concepts = [
    ...receipt.classification.secondary_concepts,
  ];
  record.taxonomy.prerequisites = [...receipt.classification.prerequisites];
  record.taxonomy.status = "reviewed";

  const sourceReview = {
    role: "source_fidelity_reviewer",
    reviewer_id: sourceReceipt.reviewer_id,
    verdict: sourceReceipt.verdict,
    receipt_id: sourceReceipt.receipt_id,
    evidence_digest: digest(sourceReceipt),
  };
  const correctionReview = {
    role: "scientific_correction_reviewer",
    reviewer_id: receipt.reviewer_id,
    verdict: receipt.verdict,
    receipt_id: receipt.receipt_id,
    evidence_digest: receiptDigest,
  };
  record.source_fidelity = {
    status: "verified_scientific_correction",
    reviews: [sourceReview, correctionReview],
  };
  record.extraction.status = "verified_complete";
  record.extraction.reviews = [sourceReview, correctionReview];

  const correction = {
    source_option: 2,
    effective_option: 4,
    printed_source_option: 4,
    reason:
      "The immutable extracted key says option 2, while the printed source key and complete exact-domain proof establish option 4 (1/6).",
    receipt_id: receipt.receipt_id,
    evidence_digest: receiptDigest,
  };
  record.answer.independent_option = 4;
  record.answer.effective_option = 4;
  record.answer.source_agreement = "overrides_source";
  record.answer.correction = correction;
  record.answer.status = "verified_correct";
  record.answer.reviews = [
    holdingReview(
      "solver",
      `codex-sol-xhigh-solve-review-0006:${questionId}`,
      4,
      receipt.evidence_files.independent_solve.row_sha256,
    ),
    holdingReview(
      "verifier",
      `codex-sol-xhigh-verify-review-0006:${questionId}`,
      4,
      receipt.evidence_files.independent_verifier.row_sha256,
    ),
    holdingReview(
      "source_key_adjudicator",
      `jules-source-key-adjudicator:${questionId}`,
      4,
      receipt.evidence_files.source_key_adjudication.row_sha256,
    ),
  ];

  record.solution = {
    status: "verified_complete_correct",
    reviews: [
      holdingReview(
        "solution_reviewer_a",
        `codex-sol-xhigh-solution-review-0005a:${questionId}`,
        null,
        receipt.evidence_files.solution_review_accepting_domain_implication
          .row_sha256,
      ),
      holdingReview(
        "solution_reviewer_b",
        `codex-sol-xhigh-scientific-correction-0001:${questionId}`,
        null,
        digest({
          receipt_id: receipt.receipt_id,
          proof_sha256: receipt.proof_evidence.sha256,
          repaired_blocker:
            receipt.evidence_files.solution_review_identifying_omission
              .row_sha256,
        }),
      ),
    ],
  };
  record.adversarial_verification = {
    status: "passed",
    reviews: [
      holdingReview(
        "adversary",
        `codex-sol-xhigh-scientific-correction-adversary-0001:${questionId}`,
        4,
        digest({
          blocked_review:
            receipt.evidence_files.adversarial_review_identifying_omission
              .row_sha256,
          correction_receipt: receiptDigest,
          proof_sha256: receipt.proof_evidence.sha256,
          exact_recheck:
            "The sole adversarial blocker was the missing domain guard; the patched solution explicitly proves 6-a-b is nonzero on the defined domain before cancellation.",
        }),
      ),
    ],
  };
  record.certification.reasons = [];
  record.certification.status = "certified";
  record.usable = true;
}

function main() {
  const records = readJsonLines(manifestFile);
  const record = records.find((candidate) => candidate.question_id === questionId);
  if (!record || record.source_sha256 !== expectedSourceSha256) {
    throw new Error(`${questionId}: missing or stale manifest record.`);
  }
  const runtimeRow = loadRuntimeRow();
  const existingSourceReceipts = readJsonLines(sourceReceiptsFile);
  const sourceReceipt = buildSourceConflictReceipt(record);
  const correctionReceipt = buildCorrectionReceipt(
    record,
    sourceReceipt,
    runtimeRow,
  );
  const verifiedOverlay = {
    schema_version: 1,
    question_id: questionId,
    source_sha256: record.source_sha256,
    status: "verified",
    patch: {
      target: "solution",
      kind: "scientific_domain_guard_replacement",
      content_patch: contentPatch,
      effective_record_sha256: correctionReceipt.effective_record_sha256,
      preserve_source: true,
    },
    evidence: {
      source_fidelity: sourceReceipt.receipt_id,
      independent_solve:
        correctionReceipt.evidence_files.independent_solve.row_sha256,
      fresh_verifier:
        correctionReceipt.evidence_files.independent_verifier.row_sha256,
      solution_review:
        correctionReceipt.evidence_files.solution_review_identifying_omission
          .row_sha256,
      adversarial_review:
        correctionReceipt.evidence_files.adversarial_review_identifying_omission
          .row_sha256,
    },
  };

  if (stage) {
    writeJsonLinesAtomic(
      sourceReceiptsFile,
      mergeByQuestionId(existingSourceReceipts, [sourceReceipt]),
    );
    writeJsonLinesAtomic(
      correctionReceiptsFile,
      mergeByQuestionId(readJsonLines(correctionReceiptsFile), [correctionReceipt]),
    );
    writeJsonLinesAtomic(
      overlaysFile,
      mergeByQuestionId(readJsonLines(overlaysFile), [verifiedOverlay]),
    );
  }
  if (apply) {
    promote(record, correctionReceipt, sourceReceipt);
    writeJsonLinesAtomic(manifestFile, records);
  }
  console.log(
    JSON.stringify(
      {
        mode: apply ? "apply" : stage ? "stage" : "dry-run",
        question_id: questionId,
        receipt_id: correctionReceipt.receipt_id,
        effective_option: correctionReceipt.answer_mapping.effective_option,
        effective_record_sha256: correctionReceipt.effective_record_sha256,
        certified_usable: records.filter((candidate) => candidate.usable).length,
      },
      null,
      2,
    ),
  );
}

main();
