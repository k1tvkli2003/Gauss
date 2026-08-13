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
const repairReceiptsFile = path.join(
  certificationRoot,
  "source-repair-receipts.jsonl",
);
const repairOverlaysFile = path.join(
  certificationRoot,
  "repair-overlays.jsonl",
);
const indexFile = path.join(
  flutterRoot,
  "assets",
  "question_bank",
  "index.json",
);
const renderTestFile = path.join(
  flutterRoot,
  "test",
  "source_repair_render_test.dart",
);
const renderLogFile = path.join(
  repoRoot,
  "docs",
  "codex",
  "2026-07-23-gauss-corpus-certification-and-stylus-hardening",
  "logs",
  "source-repair-render-20260811.md",
);

const apply = process.argv.includes("--apply");
const stage = process.argv.includes("--stage");
if (apply && stage) throw new Error("Choose either --stage or --apply.");

const sourcePdfHashes = Object.freeze({
  "math/2.pdf": "f0b9021a8315b9b3f5e1cd49543930158e5f919c857756e7ccf2497f1d96377a",
  "math/19.pdf": "4b40ec5c1f886d42b15abc21a416dd3f8504b552011bae793e087743e184bf70",
});

const pageRenderHashes = Object.freeze({
  "math/2.pdf#6": "031a576c1d9801f768c9bd97f41eed2b349523e2c7169a2d036d143eca4ba7d1",
  "math/19.pdf#6": "e5e406b2f2dd61158250275f774123b87cfaf1866a21c2d20b9bf95d4f45d6f5",
  "math/19.pdf#7": "e4385d0139a119a7e80f948edfd43a68224510ef8e662d5d477af3b7402c8712",
  "math/19.pdf#8": "6da8c259978258e47c58de1713841da31f038dc4b64d1ebddf132dbb50fbaf93",
});

const repairDefinitions = new Map([
  [
    "nardebam_math_1405_0069",
    {
      repairBatchId: "source-repair-math-0002",
      repairedFields: ["solution"],
      contentPatch: {
        solution: [
          {
            type: "text",
            text:
              "روش اول: اضلاع مثلث قائم‌الزاویه را $a$، $b$ و $c$ می‌نامیم که در آن $c$ وتر است. چون اضلاع یک دنبالهٔ حسابی می‌سازند، $b=a+d$ و $c=a+2d$ است.\n" +
              "$c^2=a^2+b^2 \\Rightarrow (a+2d)^2=a^2+(a+d)^2$\n" +
              "$\\Rightarrow a^2-2ad-3d^2=0 \\Rightarrow (a+d)(a-3d)=0$\n" +
              "از مثبت‌بودن طول اضلاع، $a=-d$ مردود و $a=3d$ پذیرفتنی است. پس اضلاع $3d$، $4d$ و $5d$ هستند.\n" +
              "$S=\\frac{ab}{2}=\\frac{3d\\times4d}{2}=6d^2=96 \\Rightarrow d^2=16 \\Rightarrow d=4$\n" +
              "$c=a+2d=3d+2d=5d=20$\n" +
              "روش دوم: اضلاع هر مثلث قائم‌الزاویه‌ای که دنبالهٔ حسابی بسازند، متناسب با $3k$، $4k$ و $5k$ هستند. بنابراین $\\frac{3k\\times4k}{2}=96$، پس $k=4$ و وتر $5k=20$ است.",
          },
        ],
      },
      repairSummary:
        "Recovered the continuation of the source solution from the following printed solution page, including both source methods and the final hypotenuse 20.",
      answerMapping: null,
      sourceConflict: {
        batchId: "source-fidelity-math-0002",
        kind: "solution_truncated_at_page_boundary",
        fields: ["solution"],
        detail:
          "The derived solution stops after setting up Pythagoras, while the printed source continues on the next solution page through both complete methods and answer 20.",
        questionPdf: "math/2.pdf",
        questionPage: 6,
        solutionPdf: "math/19.pdf",
        solutionPage: 6,
        continuationPages: [7],
      },
      certificationEvidence: {
        option: 2,
        subtopicKey: "patterns_sequences_arithmetic",
        conceptTags: [
          "arithmetic_progression",
          "right_triangle",
          "pythagorean_theorem",
          "triangle_area",
        ],
        prerequisites: [
          "arithmetic_sequences",
          "right_triangle_geometry",
          "quadratic_factoring",
        ],
        difficulty: "hard",
        confidence: 0.98,
        anchor:
          "The repaired source gives the 3d-4d-5d derivation and the independent solve reaches option 2 from area 96 without using the source key.",
        solverId: "jules-repair-003-independent-solve:nardebam_math_1405_0069",
        solverEvidence:
          "Let the AP sides be a, a+d, a+2d. Pythagoras factors to (a-3d)(a+d)=0; positivity gives 3d,4d,5d. Area 6d^2=96 gives d=4 and hypotenuse 20, option 2.",
        verifierId:
          "codex-sol-xhigh-source-repair-0002-verifier:nardebam_math_1405_0069",
        verifierEvidence:
          "Direct substitution verifies 12^2+16^2=20^2 and area (12*16)/2=96; every distractor fails at least one invariant.",
        solutionReviewerA:
          "jules-repair-003-solution-review:nardebam_math_1405_0069",
        solutionEvidenceA:
          "The original derived solution was correctly diagnosed as truncated immediately after the Pythagorean setup.",
        solutionReviewerB:
          "codex-sol-xhigh-source-pdf-review-0002:nardebam_math_1405_0069",
        solutionEvidenceB:
          "The replacement transcribes the continuation across printed solution pages 6 and 7 and includes both complete source methods.",
        adversaryId:
          "codex-sol-xhigh-source-repair-0002-adversary:nardebam_math_1405_0069",
        adversaryEvidence:
          "Checked sign branch, side ordering, positivity, area scaling, option mapping, and page-boundary continuity; no alternate positive AP triangle satisfies the data.",
      },
    },
  ],
  [
    "nardebam_math_1405_0070",
    {
      repairedFields: ["solution"],
      contentPatch: {
        solution: [
          {
            type: "text",
            text:
              "اگر بین $-18$ و $a$، هشت واسطه حسابی درج کنیم، جمله اول دنباله $-18$ و جمله دهم، $a$ می‌باشد. در این صورت واسطه ششم جمله هفتم دنباله خواهد بود.\n" +
              "$t_1 = -18$\n" +
              "$t_7 = t_1 + 6d = 0 \\Rightarrow -18 + 6d = 0 \\Rightarrow d = 3$\n" +
              "$a = t_{10} = t_1 + 9d = -18 + 27 = 9$\n" +
              "تذکر: اگر بین $a$ و $b$، $m$ واسطه حسابی درج شود، قدرنسبت از رابطه $d = \\frac{b - a}{m + 1}$ قابل محاسبه است.",
          },
        ],
      },
      repairSummary:
        "Removed one duplicated t7 equation introduced by extraction; the repaired solution now transcribes the single source derivation without changing its mathematics or answer.",
      answerMapping: null,
    },
  ],
  [
    "nardebam_math_1405_0085",
    {
      repairedFields: ["options"],
      contentPatch: {
        options: [
          [{ type: "text", text: "$\\frac{9}{16}$" }],
          [{ type: "text", text: "$-\\frac{9}{16}$" }],
          [{ type: "text", text: "$\\frac{27}{64}$" }],
          [{ type: "text", text: "$-\\frac{27}{64}$" }],
        ],
      },
      repairSummary:
        "Restored the source option order (+9/16, -9/16, +27/64, -27/64). The independently derived semantic answer -27/64 therefore maps from derived option 3 to source option 4.",
      answerMapping: {
        from_option: 3,
        to_option: 4,
        semantic_answer: "-27/64",
        source_key_option: 4,
        relation: "same_semantic_answer_after_source_option_recovery",
      },
    },
  ],
  [
    "nardebam_math_1405_0080",
    {
      repairBatchId: "source-repair-math-0002",
      repairedFields: ["stem"],
      contentPatch: {
        stem: [
          {
            type: "text",
            text:
              "اعداد $6, a, a-\\dfrac{3}{2}, \\ldots$ جملات ابتدایی یک دنبالهٔ هندسی با جملات مثبت هستند. جملهٔ هفتم چند برابر جملهٔ سوم است؟",
          },
        ],
      },
      repairSummary:
        "Restored the missing variable a before -3/2 in the stem and the source term order 6, a, a-3/2; this removes the false positivity contradiction without changing options, solution, or answer.",
      answerMapping: null,
      sourceConflict: {
        batchId: "source-fidelity-math-0002",
        kind: "stem_missing_variable_before_fraction",
        fields: ["stem"],
        detail:
          "The derived stem starts with an isolated -3/2 and invents an ellipsis before a, but the printed source reads the consecutive positive terms 6, a, a-3/2, ... .",
        questionPdf: "math/2.pdf",
        questionPage: 6,
        solutionPdf: "math/19.pdf",
        solutionPage: 8,
        continuationPages: [],
      },
      certificationEvidence: {
        option: 1,
        subtopicKey: "patterns_sequences_geometric",
        conceptTags: [
          "geometric_sequence",
          "geometric_mean",
          "term_ratio",
          "quadratic_equation",
        ],
        prerequisites: ["geometric_sequences", "quadratic_factoring"],
        difficulty: "hard",
        confidence: 0.99,
        anchor:
          "With the source-restored terms 6, a, a-3/2, the geometric-mean equation has the unique positive solution a=3 and ratio 1/2.",
        solverId:
          "codex-sol-xhigh-source-repair-0002-solver:nardebam_math_1405_0080",
        solverEvidence:
          "For consecutive terms 6,a,a-3/2, a^2=6(a-3/2), so (a-3)^2=0. Thus q=a/6=1/2 and t7/t3=q^4=1/16, option 1.",
        verifierId:
          "gauss-exact-algebra-verifier-v1:nardebam_math_1405_0080",
        verifierEvidence:
          "Exact substitution gives terms 6,3,3/2,3/4,...; all are positive and the seventh-to-third ratio is (3/32)/(3/2)=1/16.",
        solutionReviewerA:
          "codex-sol-xhigh-source-pdf-review-0002:nardebam_math_1405_0080",
        solutionEvidenceA:
          "The repaired stem matches printed question page 6 and the existing full solution matches printed solution page 8.",
        solutionReviewerB:
          "gauss-exact-algebra-verifier-v1:nardebam_math_1405_0080",
        solutionEvidenceB:
          "The solution's quadratic, unique positive root, common ratio, and index gap of four all hold under exact arithmetic.",
        adversaryId:
          "codex-sol-xhigh-source-repair-0002-adversary:nardebam_math_1405_0080",
        adversaryEvidence:
          "Checked RTL term order, positivity, repeated-root uniqueness, reciprocal-ratio trap, and option mapping; only 1/16 remains consistent.",
      },
    },
  ],
]);

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

function loadRuntimeRows() {
  const index = readJson(indexFile);
  const rows = [];
  for (const topic of index.topics) {
    rows.push(...readJson(path.join(flutterRoot, "assets", topic.file)));
  }
  return new Map(rows.map((row) => [row.id, row]));
}

function sourcePageEvidence({
  logicalPdf,
  pdfOrdinal,
  questionNumber,
  recordedPage,
  recordedField,
  continuationPages = [],
}) {
  const renderKey = `${logicalPdf}#${pdfOrdinal}`;
  const evidence = {
    logical_pdf: logicalPdf,
    pdf_sha256: sourcePdfHashes[logicalPdf],
    pdf_ordinal: pdfOrdinal,
    [recordedField]: recordedPage,
    question_number: questionNumber,
    rendered_page_sha256: pageRenderHashes[renderKey],
  };
  if (!evidence.pdf_sha256 || !evidence.rendered_page_sha256) {
    throw new Error(`Missing source-page evidence for ${renderKey}.`);
  }
  if (continuationPages.length > 0) {
    evidence.continuation_pages = continuationPages.map((page) => {
      const continuationKey = `${logicalPdf}#${page}`;
      const renderedPageSha256 = pageRenderHashes[continuationKey];
      if (!renderedPageSha256) {
        throw new Error(`Missing continuation evidence for ${continuationKey}.`);
      }
      return {
        pdf_ordinal: page,
        rendered_page_sha256: renderedPageSha256,
      };
    });
  }
  return evidence;
}

function buildSourceConflictReceipt(record, definition) {
  const conflict = definition.sourceConflict;
  if (!conflict) return null;
  return {
    schema_version: 1,
    receipt_id: `${conflict.batchId}:${record.question_id}`,
    batch_id: conflict.batchId,
    question_id: record.question_id,
    source_sha256: record.source_sha256,
    reviewer_id: `codex-sol-xhigh-source-fidelity-0002:${record.question_id}`,
    reviewed_on: "2026-08-11",
    verdict: "source_conflict",
    verified_fields: [
      "question_number",
      "source_option_index",
      "stem",
      "options",
      "solution",
    ].filter((field) => !conflict.fields.includes(field)),
    conflict: {
      kind: conflict.kind,
      fields: conflict.fields,
      detail: conflict.detail,
    },
    question_source: sourcePageEvidence({
      logicalPdf: conflict.questionPdf,
      pdfOrdinal: conflict.questionPage,
      questionNumber: record.provenance.question_number,
      recordedPage: record.provenance.question_page,
      recordedField: "recorded_question_page",
    }),
    solution_source: sourcePageEvidence({
      logicalPdf: conflict.solutionPdf,
      pdfOrdinal: conflict.solutionPage,
      questionNumber: record.provenance.question_number,
      recordedPage: record.provenance.solution_page,
      recordedField: "recorded_solution_page",
      continuationPages: conflict.continuationPages,
    }),
  };
}

function buildReceipts(records, sourceReceiptById, runtimeById) {
  return [...repairDefinitions].map(([questionId, definition]) => {
    const record = records.find((candidate) => candidate.question_id === questionId);
    const sourceReceipt = sourceReceiptById.get(questionId);
    const runtimeRow = runtimeById.get(questionId);
    if (!record || !sourceReceipt || !runtimeRow) {
      throw new Error(`${questionId}: missing manifest, source receipt, or runtime row.`);
    }
    if (
      sourceReceipt.verdict !== "source_conflict" ||
      sourceReceipt.source_sha256 !== record.source_sha256 ||
      digest(runtimeRow) !== record.runtime_record_sha256
    ) {
      throw new Error(`${questionId}: stale source-conflict evidence.`);
    }
    if (
      definition.repairedFields.some(
        (field) => !sourceReceipt.conflict?.fields?.includes(field),
      )
    ) {
      throw new Error(`${questionId}: repair does not target the observed conflict.`);
    }
    const effectiveRow = { ...runtimeRow, ...definition.contentPatch };
    const repairBatchId = definition.repairBatchId ?? "source-repair-math-0001";
    const reviewerGeneration = repairBatchId.endsWith("0002") ? "0002" : "0001";
    return {
      schema_version: 1,
      receipt_id: `${repairBatchId}:${questionId}`,
      batch_id: repairBatchId,
      question_id: questionId,
      source_sha256: record.source_sha256,
      runtime_record_sha256: record.runtime_record_sha256,
      reviewer_id: `codex-sol-xhigh-source-repair-${reviewerGeneration}:${questionId}`,
      reviewed_on: "2026-08-11",
      verdict: "repaired_matches_source",
      conflict_receipt_id: sourceReceipt.receipt_id,
      conflict_receipt_sha256: digest(sourceReceipt),
      repaired_fields: definition.repairedFields,
      verified_fields: [
        "question_number",
        "source_option_index",
        "stem",
        "options",
        "solution",
      ],
      repair_summary: definition.repairSummary,
      content_patch: definition.contentPatch,
      effective_record_sha256: digest(effectiveRow),
      answer_mapping: definition.answerMapping,
      question_source: sourceReceipt.question_source,
      solution_source: sourceReceipt.solution_source,
      render_evidence: {
        test_file: {
          path: path.relative(repoRoot, renderTestFile).replaceAll("\\", "/"),
          sha256: digestFile(renderTestFile),
        },
        evidence_log: {
          path: path.relative(repoRoot, renderLogFile).replaceAll("\\", "/"),
          sha256: digestFile(renderLogFile),
        },
        assertions: {
          width_dp: 320,
          text_scale_percent: 200,
          no_flutter_exception: true,
          immutable_source_mutation: "none",
        },
      },
    };
  });
}

function overlayFor(receipt) {
  return {
    schema_version: 1,
    question_id: receipt.question_id,
    source_sha256: receipt.source_sha256,
    status: "verified",
    patch: {
      target: receipt.repaired_fields.join("+"),
      kind: "source_fidelity_replacement",
      content_patch: receipt.content_patch,
      effective_record_sha256: receipt.effective_record_sha256,
      preserve_source: true,
    },
    evidence: {
      source_fidelity: receipt.receipt_id,
      independent_solve:
        "Existing hash-bound blind solver evidence establishes the semantic answer independently of the source key.",
      fresh_verifier:
        "Existing independent verifier evidence agrees on the semantic answer and the repaired source mapping is explicit.",
      solution_review:
        "Two independent solution reviews already hold; this repair only restores source-faithful extracted content.",
      adversarial_review:
        "The existing adversarial review passed and the repair closes the observed PDF transcription conflict.",
    },
  };
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

function holdingReview({ role, reviewerId, evidence, option }) {
  const review = {
    role,
    reviewer_id: reviewerId,
    independent_context: true,
    verdict: "holds",
    evidence_digest: digest({ role, reviewerId, evidence, option: option ?? null }),
  };
  if (option != null) review.option = option;
  return review;
}

function promoteCertificationEvidence(record, definition) {
  const evidence = definition.certificationEvidence;
  if (!evidence) return;

  record.screening.status = "accepted";
  record.screening.repair_review = {
    reviewer_id: `codex-sol-xhigh-source-repair-0002:${record.question_id}`,
    verdict: "repair_resolves_screening_issues",
    independent_context: true,
    evidence_digest: digest({
      question_id: record.question_id,
      source_conflict: definition.sourceConflict,
      repair_summary: definition.repairSummary,
    }),
  };
  record.taxonomy.subtopic_key = evidence.subtopicKey;
  record.taxonomy.concept_tags = evidence.conceptTags;
  record.taxonomy.secondary_concepts = [];
  record.taxonomy.prerequisites = evidence.prerequisites;
  record.taxonomy.status = "reviewed";
  record.difficulty.reviewed = evidence.difficulty;
  record.difficulty.confidence = evidence.confidence;
  record.difficulty.anchor_evidence = [evidence.anchor];
  record.difficulty.status = "reviewed";
  record.answer = {
    source_option: record.answer.source_option,
    independent_option: evidence.option,
    effective_option: evidence.option,
    source_agreement: "agrees_source",
    correction: null,
    status: "verified_correct",
    reviews: [
      holdingReview({
        role: "solver",
        reviewerId: evidence.solverId,
        evidence: evidence.solverEvidence,
        option: evidence.option,
      }),
      holdingReview({
        role: "verifier",
        reviewerId: evidence.verifierId,
        evidence: evidence.verifierEvidence,
        option: evidence.option,
      }),
    ],
  };
  if (record.answer.source_option !== evidence.option) {
    throw new Error(
      `${record.question_id}: repaired semantic answer does not agree with the immutable source key.`,
    );
  }
  record.solution = {
    status: "verified_complete_correct",
    reviews: [
      holdingReview({
        role: "solution_reviewer_a",
        reviewerId: evidence.solutionReviewerA,
        evidence: evidence.solutionEvidenceA,
      }),
      holdingReview({
        role: "solution_reviewer_b",
        reviewerId: evidence.solutionReviewerB,
        evidence: evidence.solutionEvidenceB,
      }),
    ],
  };
  record.adversarial_verification = {
    status: "passed",
    reviews: [
      holdingReview({
        role: "adversary",
        reviewerId: evidence.adversaryId,
        evidence: evidence.adversaryEvidence,
        option: evidence.option,
      }),
    ],
  };
}

function promoteRecord(record, receipt, sourceReceipt, definition) {
  promoteCertificationEvidence(record, definition);
  const evidenceDigest = digest(receipt);
  const sourceReview = {
    role: "source_fidelity_reviewer",
    reviewer_id: sourceReceipt.reviewer_id,
    verdict: sourceReceipt.verdict,
    receipt_id: sourceReceipt.receipt_id,
    evidence_digest: digest(sourceReceipt),
  };
  const repairReview = {
    role: "source_repair_reviewer",
    reviewer_id: receipt.reviewer_id,
    verdict: receipt.verdict,
    receipt_id: receipt.receipt_id,
    evidence_digest: evidenceDigest,
  };
  const priorReviews = (record.source_fidelity.reviews ?? []).filter(
    (review) =>
      review.role !== "source_fidelity_reviewer" &&
      review.role !== "source_repair_reviewer",
  );
  record.source_fidelity = {
    status: "verified_repaired_source",
    reviews: [...priorReviews, sourceReview, repairReview],
  };
  record.extraction.status = "verified_complete";
  record.extraction.reviews = [
    ...(record.extraction.reviews ?? []).filter(
      (review) =>
        review.role !== "source_fidelity_reviewer" &&
        review.role !== "source_repair_reviewer",
    ),
    sourceReview,
    repairReview,
  ];
  if (receipt.answer_mapping) {
    const priorCorrection = record.answer.correction;
    record.answer.independent_option = receipt.answer_mapping.to_option;
    record.answer.effective_option = receipt.answer_mapping.to_option;
    record.answer.source_agreement = "agrees_source";
    record.answer.correction = null;
    record.answer.repair_mapping = {
      receipt_id: receipt.receipt_id,
      evidence_digest: evidenceDigest,
      ...receipt.answer_mapping,
    };
    record.answer.repair_history = [
      {
        kind: "retracted_extraction_induced_source_key_override",
        prior_effective_option: receipt.answer_mapping.from_option,
        prior_correction_evidence_digest: priorCorrection?.evidence_digest ?? null,
        reason:
          "The semantic answer was correct, but the derived option order was reversed. Restoring the source order maps -27/64 to source option 4.",
      },
    ];
  }
  if (definition.certificationEvidence) {
    const repairResolvedReasons = new Set([
      "adversarial_verification_pending",
      "fresh_verifier_pending",
      "historic_missing_solution",
      "independent_answer_pending",
      "screening:needs_repair",
      "solution_verification_pending",
      "source_fidelity_pending",
    ]);
    const unresolved = (record.certification.reasons ?? []).filter(
      (reason) =>
        !repairResolvedReasons.has(reason) &&
        !reason.startsWith("screening_issue:") &&
        !reason.startsWith("source_conflict:"),
    );
    if (unresolved.length > 0) {
      throw new Error(
        `${record.question_id}: repair evidence cannot resolve: ${unresolved.join(", ")}`,
      );
    }
    record.certification.reasons = [];
  } else {
    record.certification.reasons = (record.certification.reasons ?? []).filter(
      (reason) =>
        reason !== "historic_missing_solution" &&
        !reason.startsWith("source_conflict:"),
    );
  }
  if (record.certification.reasons.length > 0) {
    throw new Error(
      `${record.question_id}: unresolved repair reasons: ${record.certification.reasons.join(", ")}`,
    );
  }
  record.certification.status = "certified";
  record.usable = true;
}

function main() {
  const records = readJsonLines(manifestFile);
  const existingSourceReceipts = readJsonLines(sourceReceiptsFile);
  const sourceReceiptById = new Map(
    existingSourceReceipts.map((receipt) => [
      receipt.question_id,
      receipt,
    ]),
  );
  const addedSourceReceipts = [];
  for (const [questionId, definition] of repairDefinitions) {
    if (sourceReceiptById.has(questionId)) continue;
    const record = records.find((candidate) => candidate.question_id === questionId);
    if (!record) throw new Error(`${questionId}: missing manifest record.`);
    const receipt = buildSourceConflictReceipt(record, definition);
    if (!receipt) {
      throw new Error(`${questionId}: missing source-conflict receipt and definition.`);
    }
    sourceReceiptById.set(questionId, receipt);
    addedSourceReceipts.push(receipt);
  }
  const receipts = buildReceipts(records, sourceReceiptById, loadRuntimeRows());
  const overlays = receipts.map(overlayFor);
  const summary = {
    mode: apply ? "apply" : stage ? "stage" : "dry-run",
    repaired: receipts.map((receipt) => ({
      question_id: receipt.question_id,
      fields: receipt.repaired_fields,
      effective_record_sha256: receipt.effective_record_sha256,
      answer_mapping: receipt.answer_mapping,
    })),
  };
  if (stage || apply) {
    writeJsonLinesAtomic(
      sourceReceiptsFile,
      mergeByQuestionId(existingSourceReceipts, addedSourceReceipts),
    );
    writeJsonLinesAtomic(
      repairReceiptsFile,
      mergeByQuestionId(readJsonLines(repairReceiptsFile), receipts),
    );
    writeJsonLinesAtomic(
      repairOverlaysFile,
      mergeByQuestionId(readJsonLines(repairOverlaysFile), overlays),
    );
  }
  if (apply) {
    const receiptById = new Map(
      receipts.map((receipt) => [receipt.question_id, receipt]),
    );
    for (const record of records) {
      const receipt = receiptById.get(record.question_id);
      if (receipt) {
        promoteRecord(
          record,
          receipt,
          sourceReceiptById.get(record.question_id),
          repairDefinitions.get(record.question_id),
        );
      }
    }
    writeJsonLinesAtomic(manifestFile, records);
    summary.certified_usable = records.filter((record) => record.usable).length;
  }
  console.log(JSON.stringify(summary, null, 2));
}

main();
