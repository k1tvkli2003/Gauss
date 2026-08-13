#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const certificationRoot = path.join(repoRoot, "data", "certification", "v1");
const flutterRoot = path.join(repoRoot, "flutter_app");
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
const scientificCorrectionReceiptsFile = path.join(
  certificationRoot,
  "scientific-correction-receipts.jsonl",
);
const embeddedMediaNumeralReceiptsFile = path.join(
  certificationRoot,
  "embedded-media-numeral-receipts.jsonl",
);
const questionIndexFile = path.join(
  flutterRoot,
  "assets",
  "question_bank",
  "index.json",
);
const outputFile = path.join(
  flutterRoot,
  "assets",
  "curriculum",
  "certified_question_runtime_v1.json",
);

const expectedQuestionCount = 3672;
const apply = process.argv.includes("--apply");
const check = process.argv.includes("--check");

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

function allBlocks(question) {
  return [
    ...(question.stem ?? []),
    ...(question.options ?? []).flat(),
    ...(question.solution ?? []),
    ...(question.smart_shortcut ?? []),
  ];
}

function imagesOf(question) {
  return allBlocks(question)
    .filter((block) => block?.type === "image")
    .map((block) => block.asset)
    .filter(Boolean);
}

function writeJsonAtomic(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporary = `${file}.tmp-${process.pid}`;
  fs.writeFileSync(temporary, `${JSON.stringify(value)}\n`);
  fs.renameSync(temporary, file);
}

function loadRuntimeRows(index) {
  const rows = [];
  const topics = new Map();
  for (const topic of index.topics ?? []) {
    const file = path.join(flutterRoot, "assets", topic.file);
    const shard = readJson(file);
    if (!Array.isArray(shard) || shard.length !== topic.count) {
      throw new Error(
        `${topic.topic_key}: expected ${topic.count} runtime rows, found ${shard?.length}`,
      );
    }
    topics.set(topic.topic_key, topic);
    for (const row of shard) {
      rows.push(row);
    }
  }
  if (rows.length !== index.total || rows.length !== expectedQuestionCount) {
    throw new Error(
      `Runtime corpus count drift: index=${index.total} loaded=${rows.length}.`,
    );
  }
  const byId = new Map(rows.map((row) => [row.id, row]));
  if (byId.size !== rows.length) throw new Error("Runtime corpus has duplicate IDs.");
  return { rows, byId, topics };
}

function assertCertified(
  record,
  runtimeRow,
  sourceReceiptById,
  repairReceiptById,
  scientificCorrectionReceiptById,
  embeddedMediaNumeralReceiptByAsset,
) {
  const at = record.question_id;
  const failures = [];
  if (!record.usable) failures.push("usable");
  if (record.certification?.status !== "certified") failures.push("certification");
  if ((record.certification?.reasons ?? []).length !== 0) failures.push("reasons");
  if (record.screening?.status !== "accepted") failures.push("screening");
  if (record.extraction?.status !== "verified_complete") failures.push("extraction");
  if (record.extraction?.render_gate?.status !== "passed") failures.push("render");
  if (
    ![
      "verified_source",
      "verified_repaired_source",
      "verified_scientific_correction",
    ].includes(
      record.source_fidelity?.status,
    )
  ) {
    failures.push("source_fidelity");
  }
  if (record.taxonomy?.status !== "reviewed") failures.push("taxonomy");
  if (record.difficulty?.status !== "reviewed" || !record.difficulty?.reviewed) {
    failures.push("difficulty");
  }
  if (record.answer?.status !== "verified_correct") failures.push("answer");
  if (
    !Number.isInteger(record.answer?.effective_option) ||
    record.answer.effective_option < 1 ||
    record.answer.effective_option > 4
  ) {
    failures.push("effective_option");
  }
  if (record.solution?.status !== "verified_complete_correct") failures.push("solution");
  if (record.adversarial_verification?.status !== "passed") failures.push("adversarial");
  if (!runtimeRow) failures.push("runtime_row");
  if (runtimeRow && digest(runtimeRow) !== record.runtime_record_sha256) {
    failures.push("runtime_hash");
  }
  if (runtimeRow?.topic_key !== record.taxonomy?.topic_key) failures.push("topic");
  if (runtimeRow?.subject !== record.subject) failures.push("subject");
  if (runtimeRow?.correct_option_index !== record.answer?.source_option) {
    failures.push("source_option");
  }
  const correctionReceipt = scientificCorrectionReceiptById.get(at);
  const derivedReceipt = correctionReceipt ?? repairReceiptById.get(at);
  const effectiveRow = derivedReceipt?.content_patch
    ? { ...runtimeRow, ...derivedReceipt.content_patch }
    : runtimeRow;
  for (const asset of [...new Set(imagesOf(effectiveRow ?? {}))]) {
    const mediaReceipt = embeddedMediaNumeralReceiptByAsset.get(asset);
    if (
      !mediaReceipt ||
      !["no_digits", "ascii_only"].includes(mediaReceipt.verdict)
    ) {
      failures.push(`embedded_media_numerals:${asset}`);
    }
  }
  if (record.source_fidelity?.status === "verified_source") {
    const sourceReceipt = sourceReceiptById.get(at);
    const sourceReview = (record.source_fidelity?.reviews ?? []).find(
      (review) => review.role === "source_fidelity_reviewer",
    );
    if (
      !sourceReceipt ||
      sourceReceipt.verdict !== "matches_source" ||
      sourceReceipt.receipt_id !== sourceReview?.receipt_id ||
      sourceReceipt.source_sha256 !== record.source_sha256
    ) {
      failures.push("source_receipt");
    }
  } else if (record.source_fidelity?.status === "verified_repaired_source") {
    const repairReceipt = repairReceiptById.get(at);
    const repairReview = (record.source_fidelity?.reviews ?? []).find(
      (review) => review.role === "source_repair_reviewer",
    );
    if (
      !repairReceipt ||
      repairReceipt.verdict !== "repaired_matches_source" ||
      repairReceipt.receipt_id !== repairReview?.receipt_id ||
      repairReceipt.source_sha256 !== record.source_sha256 ||
      repairReceipt.runtime_record_sha256 !== record.runtime_record_sha256 ||
      digest(repairReceipt) !== repairReview?.evidence_digest
    ) {
      failures.push("repair_receipt");
    }
  } else {
    const correctionReview = (record.source_fidelity?.reviews ?? []).find(
      (review) => review.role === "scientific_correction_reviewer",
    );
    if (
      !correctionReceipt ||
      correctionReceipt.verdict !== "scientifically_corrected" ||
      correctionReceipt.receipt_id !== correctionReview?.receipt_id ||
      correctionReceipt.source_sha256 !== record.source_sha256 ||
      correctionReceipt.runtime_record_sha256 !== record.runtime_record_sha256 ||
      digest(correctionReceipt) !== correctionReview?.evidence_digest
    ) {
      failures.push("scientific_correction_receipt");
    }
  }
  if (failures.length > 0) {
    throw new Error(`${at}: certified runtime admission failed: ${failures.join(", ")}`);
  }
}

function buildContract() {
  const manifest = readJsonLines(manifestFile);
  const index = readJson(questionIndexFile);
  const renderReceipts = readJsonLines(renderReceiptsFile);
  const sourceReceipts = readJsonLines(sourceReceiptsFile);
  const repairReceipts = fs.existsSync(sourceRepairReceiptsFile)
    ? readJsonLines(sourceRepairReceiptsFile)
    : [];
  const scientificCorrectionReceipts = fs.existsSync(
    scientificCorrectionReceiptsFile,
  )
    ? readJsonLines(scientificCorrectionReceiptsFile)
    : [];
  const embeddedMediaNumeralReceipts = fs.existsSync(
    embeddedMediaNumeralReceiptsFile,
  )
    ? readJsonLines(embeddedMediaNumeralReceiptsFile)
    : [];
  const { byId, topics } = loadRuntimeRows(index);
  if (manifest.length !== expectedQuestionCount) {
    throw new Error(`Manifest count drift: ${manifest.length}.`);
  }
  const usable = manifest.filter((record) => record.usable);
  const sourceReceiptById = new Map(
    sourceReceipts.map((receipt) => [receipt.question_id, receipt]),
  );
  const repairReceiptById = new Map(
    repairReceipts.map((receipt) => [receipt.question_id, receipt]),
  );
  const scientificCorrectionReceiptById = new Map(
    scientificCorrectionReceipts.map((receipt) => [
      receipt.question_id,
      receipt,
    ]),
  );
  const embeddedMediaNumeralReceiptByAsset = new Map(
    embeddedMediaNumeralReceipts.map((receipt) => [receipt.asset, receipt]),
  );
  const entries = usable.map((record) => {
    const runtimeRow = byId.get(record.question_id);
    assertCertified(
      record,
      runtimeRow,
      sourceReceiptById,
      repairReceiptById,
      scientificCorrectionReceiptById,
      embeddedMediaNumeralReceiptByAsset,
    );
    const renderReceiptId = record.extraction.render_gate.receipt_id;
    if (!renderReceipts.some((receipt) => receipt.receipt_id === renderReceiptId)) {
      throw new Error(`${record.question_id}: missing render receipt ${renderReceiptId}.`);
    }
    const repairReceipt = repairReceiptById.get(record.question_id);
    const scientificCorrectionReceipt =
      scientificCorrectionReceiptById.get(record.question_id);
    const repaired = record.source_fidelity.status === "verified_repaired_source";
    const scientificallyCorrected =
      record.source_fidelity.status === "verified_scientific_correction";
    const derivedReceipt = scientificCorrectionReceipt ?? repairReceipt;
    return {
      question_id: record.question_id,
      subject: record.subject,
      topic_key: record.taxonomy.topic_key,
      section_id: record.taxonomy.section_id,
      subtopic_key: record.taxonomy.subtopic_key,
      concept_tags: record.taxonomy.concept_tags,
      prerequisites: record.taxonomy.prerequisites,
      reviewed_difficulty: record.difficulty.reviewed,
      source_sha256: record.source_sha256,
      runtime_record_sha256: record.runtime_record_sha256,
      effective_record_sha256: repaired || scientificallyCorrected
        ? derivedReceipt.effective_record_sha256
        : record.runtime_record_sha256,
      source_option_index: record.answer.source_option,
      effective_option_index: record.answer.effective_option,
      solution_verified: true,
      render_receipt_id: renderReceiptId,
      source_fidelity_receipt_id: repaired || scientificallyCorrected
        ? derivedReceipt.receipt_id
        : record.source_fidelity.reviews.find(
            (review) => review.role === "source_fidelity_reviewer",
          ).receipt_id,
      content_patch:
        repaired || scientificallyCorrected
          ? derivedReceipt.content_patch
          : null,
    };
  });
  const topicCounts = Object.fromEntries(
    [...topics.keys()].map((topicKey) => [
      topicKey,
      entries.filter((entry) => entry.topic_key === topicKey).length,
    ]),
  );
  const renderSourceSets = new Set(renderReceipts.map((receipt) => receipt.source_set_sha256));
  if (renderSourceSets.size !== 1) {
    throw new Error("Render receipts do not bind one exact source set.");
  }
  const payload = {
    schema_version: 1,
    source_question_count: expectedQuestionCount,
    mission_ready_count: entries.length,
    source_set_sha256: [...renderSourceSets][0],
    manifest_file_sha256: digestFile(manifestFile),
    render_receipts_file_sha256: digestFile(renderReceiptsFile),
    source_fidelity_receipts_file_sha256: digestFile(sourceReceiptsFile),
    source_repair_receipts_file_sha256: fs.existsSync(sourceRepairReceiptsFile)
      ? digestFile(sourceRepairReceiptsFile)
      : null,
    scientific_correction_receipts_file_sha256: fs.existsSync(
      scientificCorrectionReceiptsFile,
    )
      ? digestFile(scientificCorrectionReceiptsFile)
      : null,
    embedded_media_numeral_receipts_file_sha256: fs.existsSync(
      embeddedMediaNumeralReceiptsFile,
    )
      ? digestFile(embeddedMediaNumeralReceiptsFile)
      : null,
    topic_mission_ready_counts: topicCounts,
    questions: entries,
  };
  return { ...payload, contract_sha256: digest(payload) };
}

function main() {
  if (apply && check) throw new Error("Choose either --apply or --check.");
  const contract = buildContract();
  if (check) {
    if (!fs.existsSync(outputFile)) throw new Error("Certified runtime asset is missing.");
    const current = readJson(outputFile);
    if (canonicalJson(current) !== canonicalJson(contract)) {
      throw new Error("Certified runtime asset is stale; regenerate with --apply.");
    }
  }
  if (apply) writeJsonAtomic(outputFile, contract);
  console.log(
    JSON.stringify(
      {
        mode: apply ? "apply" : check ? "check" : "dry-run",
        output: path.relative(repoRoot, outputFile).replaceAll("\\", "/"),
        mission_ready_count: contract.mission_ready_count,
        topic_mission_ready_counts: contract.topic_mission_ready_counts,
        contract_sha256: contract.contract_sha256,
      },
      null,
      2,
    ),
  );
}

main();
