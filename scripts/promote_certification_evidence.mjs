#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const certificationRoot = path.join(repoRoot, "data", "certification", "v1");
const manifestFile = path.join(certificationRoot, "manifest.jsonl");
const renderReceiptsFile = path.join(certificationRoot, "render-receipts.jsonl");
const sourceReceiptsFile = path.join(
  certificationRoot,
  "source-fidelity-receipts.jsonl",
);
const sourceRepairReceiptsFile = path.join(
  certificationRoot,
  "source-repair-receipts.jsonl",
);
const renderLog = path.join(
  repoRoot,
  "docs",
  "codex",
  "2026-07-23-gauss-corpus-certification-and-stylus-hardening",
  "logs",
  "render-gate-20260810.md",
);

const apply = process.argv.includes("--apply");
const renderReceiptId = "flutter-render-v1-20260810";
const sourceBatchId = "source-fidelity-math-0001";

const explicitTaxonomyAdjudications = new Map([
  [
    "nardebam_math_1405_0088",
    {
      expectedSourceSha256:
        "d9bebd267034a860316c54071610b7e3dae122bd9f88079a66779b1f458d0ed7",
      expectedProposalKey: "geometric_mean_pair",
      registryVersion: "gauss-taxonomy-v1",
      sectionId: "math_algebraic_foundations",
      topicKey: "patterns_sequences",
      subtopicKey: "patterns_sequences_geometric",
      conceptTags: ["geometric_sequence", "general_term"],
      secondaryConcepts: [],
      prerequisites: ["exponents"],
      rationale:
        "The two unknown numbers and their geometric mean form a three-term geometric sequence; the sum/product reduction then yields one quadratic with a unique absolute difference.",
    },
  ],
]);

const sourceRechecks = new Map([
  [
    "nardebam_math_1405_0088",
    {
      expectedSourceSha256:
        "d9bebd267034a860316c54071610b7e3dae122bd9f88079a66779b1f458d0ed7",
      batchId: "source-fidelity-math-0003",
      reviewerId:
        "codex-sol-xhigh-source-fidelity-0003:nardebam_math_1405_0088",
      reviewedOn: "2026-08-13",
      recheckReason:
        "Re-audited after a historical cohort omission; exact question and solution renders were inspected again and all derived fields match the printed source.",
    },
  ],
]);

const sourcePdfHashes = Object.freeze({
  "math/1.pdf": "35313e7fcffcb4d0ea9c11f5f63b35255740396d534ac4841465f357fdee21af",
  "math/2.pdf": "f0b9021a8315b9b3f5e1cd49543930158e5f919c857756e7ccf2497f1d96377a",
  "math/3.pdf": "351a5e3e62346eb14ff43e89fbff5ea97e890bf33ff864bc4f1727ff1681bf0f",
  "math/19.pdf": "4b40ec5c1f886d42b15abc21a416dd3f8504b552011bae793e087743e184bf70",
});

const pageRenderHashes = Object.freeze({
  "math/1.pdf#12": "09ce8b705f78cbf6d03fdd65d4d7d61e3bb05e311f3a2ccd794f41701436b04e",
  "math/2.pdf#5": "f9a470e3f6b1753133ffac6dd8f1f4af4d41883df44b905dc83283043b41e659",
  "math/2.pdf#6": "031a576c1d9801f768c9bd97f41eed2b349523e2c7169a2d036d143eca4ba7d1",
  "math/2.pdf#7": "584280df9a8ca018da5a2908b96181ba8955b560e0e4aa6fdbcf9a1cf77f566c",
  "math/3.pdf#7": "41ac6a3cc7a02fb00979c7652231a4e74130358af408f67bdf526ae100e3a50c",
  "math/3.pdf#8": "e33158a21486afaaa1b1d602486c350be749bacef68b871cf0e913b4c354e2d7",
  "math/19.pdf#1": "138a6a3537f971d4bdd2d9d34eeb91126c0b5da1847542caf4049dcf961cbe64",
  "math/19.pdf#6": "e5e406b2f2dd61158250275f774123b87cfaf1866a21c2d20b9bf95d4f45d6f5",
  "math/19.pdf#7": "e4385d0139a119a7e80f948edfd43a68224510ef8e662d5d477af3b7402c8712",
  "math/19.pdf#8": "6da8c259978258e47c58de1713841da31f038dc4b64d1ebddf132dbb50fbaf93",
  "math/19.pdf#9": "d031727bb1d989fc3ad96cf5eb96b11293e441cb435de44f01e056c45ebdea64",
  "math/19.pdf#10": "c19033fc16bb26aabb47dafd9b8d474aafa69d0412eaeef9d5025a7ab031cbf2",
  "math/19.pdf#11": "6ae8f10ed5bb75439231da9f6ae95dc545242f9eaf956cf429445ef2a0fc1baa",
});

const auditedIds = Object.freeze([
  "nardebam_math_1405_0004",
  "nardebam_math_1405_0008",
  "nardebam_math_1405_0009",
  "nardebam_math_1405_0010",
  "nardebam_math_1405_0011",
  "nardebam_math_1405_0013",
  "nardebam_math_1405_0061",
  "nardebam_math_1405_0063",
  "nardebam_math_1405_0064",
  "nardebam_math_1405_0065",
  "nardebam_math_1405_0066",
  "nardebam_math_1405_0070",
  "nardebam_math_1405_0071",
  "nardebam_math_1405_0072",
  "nardebam_math_1405_0073",
  "nardebam_math_1405_0074",
  "nardebam_math_1405_0075",
  "nardebam_math_1405_0078",
  "nardebam_math_1405_0079",
  "nardebam_math_1405_0082",
  "nardebam_math_1405_0085",
  "nardebam_math_1405_0086",
  "nardebam_math_1405_0087",
  "nardebam_math_1405_0088",
  "nardebam_math_1405_0089",
  "nardebam_math_1405_0090",
  "nardebam_math_1405_0091",
  "nardebam_math_1405_0092",
  "nardebam_math_1405_0095",
  "nardebam_math_1405_0096",
  "nardebam_math_1405_0097",
  "nardebam_math_1405_0098",
  "nardebam_math_1405_0099",
  "nardebam_math_1405_0101",
  "nardebam_math_1405_0102",
  "nardebam_math_1405_0103",
  "nardebam_math_1405_0104",
  "nardebam_math_1405_0107",
  "nardebam_math_1405_0108",
  "nardebam_math_1405_0109",
  "nardebam_math_1405_0110",
  "nardebam_math_1405_0112",
  "nardebam_math_1405_0113",
  "nardebam_math_1405_0114",
  "nardebam_math_1405_0115",
  "nardebam_math_1405_0116",
  "nardebam_math_1405_0118",
  "nardebam_math_1405_0120",
]);

const conflicts = new Map([
  [
    "nardebam_math_1405_0070",
    {
      kind: "solution_transcription_mismatch",
      fields: ["solution"],
      detail:
        "The derived solution duplicates the t7=t1+6d=0 line; the source page contains it once.",
    },
  ],
  [
    "nardebam_math_1405_0085",
    {
      kind: "option_order_sign_mismatch",
      fields: ["options"],
      detail:
        "The source options are +9/16, -9/16, +27/64, -27/64; the derived record reverses each sign pair.",
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

function readJsonLines(file) {
  if (!fs.existsSync(file)) return [];
  return fs
    .readFileSync(file, "utf8")
    .split(/\r?\n/u)
    .filter(Boolean)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`${file}:${index + 1}: ${error.message}`);
      }
    });
}

function writeJsonLinesAtomic(file, rows) {
  const temporary = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(temporary, `${rows.map(JSON.stringify).join("\n")}\n`);
  fs.renameSync(temporary, file);
}

function mergeByQuestionId(existing, replacements) {
  const replacementById = new Map(
    replacements.map((receipt) => [receipt.question_id, receipt]),
  );
  const merged = existing.map(
    (receipt) => replacementById.get(receipt.question_id) ?? receipt,
  );
  const existingIds = new Set(existing.map((receipt) => receipt.question_id));
  for (const replacement of replacements) {
    if (!existingIds.has(replacement.question_id)) merged.push(replacement);
  }
  return merged;
}

function questionSource(record) {
  const questionNumber = record.provenance.question_number;
  const logicalPdf = `math/${record.provenance.question_pdf}`;
  const pdfOrdinal = logicalPdf === "math/1.pdf" ? 12 : record.provenance.question_page;
  const renderKey = `${logicalPdf}#${pdfOrdinal}`;
  if (!sourcePdfHashes[logicalPdf] || !pageRenderHashes[renderKey]) {
    throw new Error(`${record.question_id}: missing question-page evidence for ${renderKey}`);
  }
  return {
    logical_pdf: logicalPdf,
    pdf_sha256: sourcePdfHashes[logicalPdf],
    pdf_ordinal: pdfOrdinal,
    recorded_question_page: record.provenance.question_page,
    question_number: questionNumber,
    rendered_page_sha256: pageRenderHashes[renderKey],
  };
}

function solutionSource(record) {
  const logicalPdf = "math/19.pdf";
  const pdfOrdinal = record.provenance.solution_page;
  const renderKey = `${logicalPdf}#${pdfOrdinal}`;
  if (!pageRenderHashes[renderKey]) {
    throw new Error(`${record.question_id}: missing solution-page evidence for ${renderKey}`);
  }
  return {
    logical_pdf: logicalPdf,
    pdf_sha256: sourcePdfHashes[logicalPdf],
    pdf_ordinal: pdfOrdinal,
    recorded_solution_page: record.provenance.solution_page,
    question_number: record.provenance.question_number,
    rendered_page_sha256: pageRenderHashes[renderKey],
  };
}

function buildRenderReceipt(records) {
  const sourceSet = records.map((record) => ({
    question_id: record.question_id,
    source_sha256: record.source_sha256,
    runtime_record_sha256: record.runtime_record_sha256,
    referenced_media: record.referenced_media,
  }));
  return {
    schema_version: 1,
    receipt_id: renderReceiptId,
    observed_on: "2026-08-10",
    status: "passed",
    runtime: {
      flutter: "3.44.0",
      flutter_revision: "559ffa3f75",
      dart: "3.12.0",
      host: "windows",
    },
    source_set_sha256: digest(sourceSet),
    assertions: {
      question_count: 3672,
      text_block_count: 22032,
      formula_count_minimum: 37001,
      media_asset_count: 3410,
      persian_math_200_percent_widget: "passed",
      english_chrome_under_persian_device_locale: "passed",
      learning_text_ascii_numerals: "passed",
      learning_text_ascii_numerals_question_count: 3672,
      learning_text_ascii_numerals_block_count_minimum: 22000,
      certified_embedded_media_count: 0,
      source_mutation: "none",
    },
    test_files: [
      {
        path: "flutter_app/test/content_rendering_test.dart",
        sha256: digestFile(path.join(repoRoot, "flutter_app", "test", "content_rendering_test.dart")),
      },
      {
        path: "flutter_app/test/corpus_media_asset_test.dart",
        sha256: digestFile(path.join(repoRoot, "flutter_app", "test", "corpus_media_asset_test.dart")),
      },
      {
        path: "flutter_app/test/english_chrome_contract_test.dart",
        sha256: digestFile(path.join(repoRoot, "flutter_app", "test", "english_chrome_contract_test.dart")),
      },
    ],
    asset_index: {
      path: "flutter_app/assets/question_bank/index.json",
      sha256: digestFile(path.join(repoRoot, "flutter_app", "assets", "question_bank", "index.json")),
    },
    evidence_log: {
      path: path.relative(repoRoot, renderLog).replaceAll("\\", "/"),
      sha256: digestFile(renderLog),
    },
    commands: [
      "flutter test test/content_rendering_test.dart test/corpus_media_asset_test.dart",
      "flutter test test/english_chrome_contract_test.dart",
    ],
  };
}

function buildSourceReceipt(record) {
  const conflict = conflicts.get(record.question_id);
  const recheck = sourceRechecks.get(record.question_id);
  if (recheck && record.source_sha256 !== recheck.expectedSourceSha256) {
    throw new Error(`${record.question_id}: recheck source hash drift`);
  }
  const verifiedFields = conflict
    ? ["question_number", "source_option_index", "stem", "solution"].filter(
        (field) => !conflict.fields.includes(field),
      )
    : ["question_number", "source_option_index", "stem", "options", "solution"];
  return {
    schema_version: 1,
    receipt_id: `${recheck?.batchId ?? sourceBatchId}:${record.question_id}`,
    batch_id: recheck?.batchId ?? sourceBatchId,
    question_id: record.question_id,
    source_sha256: record.source_sha256,
    reviewer_id:
      recheck?.reviewerId ??
      `codex-sol-xhigh-source-fidelity-0001:${record.question_id}`,
    reviewed_on: recheck?.reviewedOn ?? "2026-08-10",
    verdict: conflict ? "source_conflict" : "matches_source",
    verified_fields: verifiedFields,
    conflict: conflict ?? null,
    ...(recheck ? { recheck_reason: recheck.recheckReason } : {}),
    question_source: questionSource(record),
    solution_source: solutionSource(record),
  };
}

function applyExplicitTaxonomyAdjudication(record) {
  const adjudication = explicitTaxonomyAdjudications.get(record.question_id);
  if (!adjudication) return;
  if (
    record.source_sha256 !== adjudication.expectedSourceSha256 ||
    record.taxonomy.topic_key !== adjudication.topicKey ||
    record.taxonomy.proposed_subtopic?.key !== adjudication.expectedProposalKey
  ) {
    throw new Error(`${record.question_id}: taxonomy adjudication input drift`);
  }
  record.taxonomy.registry_version = adjudication.registryVersion;
  record.taxonomy.section_id = adjudication.sectionId;
  record.taxonomy.subtopic_key = adjudication.subtopicKey;
  record.taxonomy.concept_tags = [...adjudication.conceptTags];
  record.taxonomy.secondary_concepts = [...adjudication.secondaryConcepts];
  record.taxonomy.prerequisites = [...adjudication.prerequisites];
  record.taxonomy.status = "reviewed";
}

function assertCertificationReady(record) {
  const checks = [
    [record.screening.status === "accepted", "screening"],
    [record.taxonomy.status === "reviewed", "taxonomy"],
    [record.difficulty.status === "reviewed", "difficulty"],
    [record.answer.status === "verified_correct", "answer"],
    [record.answer.independent_option === record.answer.effective_option, "answer option"],
    [record.solution.status === "verified_complete_correct", "solution"],
    [(record.solution.reviews ?? []).length >= 2, "solution reviews"],
    [record.adversarial_verification.status === "passed", "adversarial review"],
  ];
  const failed = checks.filter(([holds]) => !holds).map(([, label]) => label);
  if (failed.length > 0) {
    throw new Error(`${record.question_id}: source audit candidate lacks ${failed.join(", ")}`);
  }
}

function main() {
  const records = readJsonLines(manifestFile);
  if (records.length !== 3672) throw new Error(`expected 3672 records, found ${records.length}`);
  const byId = new Map(records.map((record) => [record.question_id, record]));
  if (byId.size !== records.length) throw new Error("manifest has duplicate question IDs");

  const audited = auditedIds.map((id) => {
    const record = byId.get(id);
    if (!record) throw new Error(`missing audited record ${id}`);
    applyExplicitTaxonomyAdjudication(record);
    assertCertificationReady(record);
    return record;
  });
  if (
    audited.length !== 48 ||
    conflicts.size !== 2 ||
    explicitTaxonomyAdjudications.size !== 1 ||
    sourceRechecks.size !== 1
  ) {
    throw new Error("source-fidelity cohort cardinality drift");
  }

  const renderReceipt = buildRenderReceipt(records);
  const auditedSourceReceipts = audited.map(buildSourceReceipt);
  const sourceReceipts = mergeByQuestionId(
    readJsonLines(sourceReceiptsFile),
    auditedSourceReceipts,
  );
  const sourceReceiptById = new Map(
    sourceReceipts.map((receipt) => [receipt.question_id, receipt]),
  );
  const repairedQuestionIds = new Set(
    readJsonLines(sourceRepairReceiptsFile).map(
      (receipt) => receipt.question_id,
    ),
  );

  const resolvedReasons = new Set([
    "source_fidelity_pending",
    "render_gate_pending",
    "historic_missing_solution",
    "independent_answer_pending",
    "fresh_verifier_pending",
    "solution_verification_pending",
    "adversarial_verification_pending",
    "duplicate_content_with_conflicting_source_keys",
  ]);

  for (const record of records) {
    record.extraction.render_gate = {
      status: "passed",
      receipt_id: renderReceiptId,
    };
    record.certification.reasons = (record.certification.reasons ?? []).filter(
      (reason) => reason !== "render_gate_pending",
    );

    const receipt = sourceReceiptById.get(record.question_id);
    if (!receipt) continue;
    // A source-repair receipt is newer, stricter evidence than the conflict
    // observation that motivated it. This generic render/source promotion
    // must never demote an already repaired record back into quarantine; the
    // dedicated source-repair promoter owns that state transition.
    if (repairedQuestionIds.has(record.question_id)) continue;
    const evidenceDigest = digest(receipt);
    const review = {
      role: "source_fidelity_reviewer",
      reviewer_id: receipt.reviewer_id,
      verdict: receipt.verdict,
      receipt_id: receipt.receipt_id,
      evidence_digest: evidenceDigest,
    };
    record.source_fidelity = {
      status: receipt.verdict === "matches_source" ? "verified_source" : "source_conflict",
      reviews: [review],
    };
    record.extraction.reviews = [review];
    record.certification.reasons = record.certification.reasons.filter(
      (reason) => reason !== "source_fidelity_pending",
    );

    if (receipt.verdict === "source_conflict") {
      record.extraction.status = "ambiguous";
      record.certification.status = "quarantined";
      record.certification.reasons = [
        ...new Set([
          ...record.certification.reasons,
          `source_conflict:${receipt.conflict.kind}`,
        ]),
      ].sort();
      record.usable = false;
      continue;
    }

    record.extraction.status = "verified_complete";
    record.certification.reasons = record.certification.reasons.filter(
      (reason) => !resolvedReasons.has(reason),
    );
    if (record.certification.reasons.length > 0) {
      throw new Error(
        `${record.question_id}: unresolved reasons after evidence merge: ${record.certification.reasons.join(", ")}`,
      );
    }
    record.certification.status = "certified";
    record.usable = true;
  }

  const matched = auditedSourceReceipts.filter(
    (receipt) => receipt.verdict === "matches_source",
  );
  const conflicted = auditedSourceReceipts.filter(
    (receipt) => receipt.verdict === "source_conflict",
  );
  if (matched.length !== 46 || conflicted.length !== 2) {
    throw new Error("source-fidelity verdict cardinality drift");
  }

  const summary = {
    mode: apply ? "apply" : "dry-run",
    render_receipt_id: renderReceiptId,
    render_records: records.length,
    source_audited: auditedSourceReceipts.length,
    source_receipt_ledger: sourceReceipts.length,
    source_matched: matched.length,
    source_conflicts: conflicted.map((receipt) => ({
      question_id: receipt.question_id,
      kind: receipt.conflict.kind,
    })),
    certified_usable: records.filter((record) => record.usable).length,
    source_set_sha256: renderReceipt.source_set_sha256,
  };

  if (apply) {
    writeJsonLinesAtomic(renderReceiptsFile, [renderReceipt]);
    writeJsonLinesAtomic(sourceReceiptsFile, sourceReceipts);
    writeJsonLinesAtomic(manifestFile, records);
  }
  console.log(JSON.stringify(summary, null, 2));
}

main();
