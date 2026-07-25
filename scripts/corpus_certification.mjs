#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const assetRoot = path.join(repoRoot, "flutter_app", "assets");
const indexFile = path.join(assetRoot, "question_bank", "index.json");
const canonicalRoot = path.join(
  repoRoot,
  "data",
  "seed",
  "comprehensive",
  "nardebam",
);
const mediaRoot = path.join(assetRoot, "question_media");
const certificationRoot = path.join(repoRoot, "data", "certification", "v1");
const taxonomyFile = path.join(certificationRoot, "taxonomy.json");
const manifestFile = path.join(certificationRoot, "manifest.jsonl");
const mediaManifestFile = path.join(certificationRoot, "media-manifest.jsonl");
const runtimeAttestationFile = path.join(
  certificationRoot,
  "runtime-attestations.jsonl",
);
const repairQueueFile = path.join(certificationRoot, "repair-queue.jsonl");
const repairOverlayFile = path.join(certificationRoot, "repair-overlays.jsonl");
const screeningRoot = path.join(certificationRoot, "batches", "screening");
const mismatchReportFile = path.join(
  repoRoot,
  "data",
  "seed",
  "review",
  "nardebam",
  "agent_reports",
  "current_solution_key_mismatch_report.json",
);
const missingSolutionReportFile = path.join(
  repoRoot,
  "data",
  "seed",
  "review",
  "nardebam",
  "agent_reports",
  "missing_solutions_report.json",
);
const expectedQuestionCount = 3672;
const expectedMediaCount = 3410;
const allowedDifficulties = new Set([
  "above_average",
  "hard",
  "very_hard",
  "olympiad",
]);
const difficultyDimensionRanges = {
  prerequisite_breadth: [0, 3],
  reasoning_depth: [0, 4],
  non_routine_insight: [0, 4],
  representation_translation: [0, 3],
  computation_load: [0, 3],
  distractor_discrimination: [0, 3],
};
const knownCurrentContradictions = new Map([
  [
    "nardebam_math_1405_1346",
    "solution_conclusion_conflicts_with_the_question_direction",
  ],
  [
    "nardebam_physics_1405_1346",
    "source_key_option_2_conflicts_with_solution_option_3",
  ],
]);

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function canonicalJson(value) {
  if (Array.isArray(value)) {
    return `[${value.map(canonicalJson).join(",")}]`;
  }
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

function trustedScreeningRuntime(attestation, batchId, outputFile) {
  if (
    !attestation ||
    !(attestation.batch_ids ?? []).includes(batchId) ||
    !attestation.evidence_digest
  ) {
    return false;
  }
  const exactThreadLuna =
    attestation.observed_by === "codex_app" &&
    attestation.tool === "send_message_to_thread" &&
    attestation.model === "gpt-5.6-luna" &&
    attestation.reasoning === "medium" &&
    Boolean(attestation.thread_id);
  const expectedTaskName = `/root/${batchId.replace("-", "_")}`;
  const hashBoundParallelWorker =
    attestation.observed_by === "codex_collaboration" &&
    attestation.tool === "spawn_agent" &&
    ["gpt-5.6-terra", "gpt-5.6-sol"].includes(attestation.model) &&
    attestation.reasoning === "low" &&
    typeof attestation.task_name === "string" &&
    (attestation.task_name === expectedTaskName ||
      (attestation.task_name.startsWith(`${expectedTaskName}_`) &&
        /^(retry|resume)(?:_|$)/u.test(
          attestation.task_name.slice(expectedTaskName.length + 1),
        ))) &&
    typeof attestation.output_sha256 === "string" &&
    fs.existsSync(outputFile) &&
    attestation.output_sha256 === digestFile(outputFile);
  return exactThreadLuna || hashBoundParallelWorker;
}

function loadSource() {
  const index = readJson(indexFile);
  const rows = [];
  for (const topic of index.topics ?? []) {
    const runtimeFile = path.join(assetRoot, topic.file);
    const canonicalFile = path.join(
      canonicalRoot,
      topic.subject,
      `${topic.topic_key}.json`,
    );
    const runtimeRows = readJson(runtimeFile);
    const canonicalRows = readJson(canonicalFile);
    if (!Array.isArray(runtimeRows) || runtimeRows.length !== topic.count) {
      throw new Error(
        `${topic.file} count mismatch: index=${topic.count} runtime=${runtimeRows?.length}`,
      );
    }
    if (!Array.isArray(canonicalRows) || canonicalRows.length !== topic.count) {
      throw new Error(
        `${canonicalFile} count mismatch: index=${topic.count} canonical=${canonicalRows?.length}`,
      );
    }
    const runtimeById = new Map(runtimeRows.map((row) => [row.id, row]));
    for (const row of canonicalRows) {
      const runtimeRow = runtimeById.get(row.id);
      if (!runtimeRow) {
        throw new Error(`Runtime bank is missing canonical question ${row.id}.`);
      }
      if (digest(row) !== digest(runtimeRow)) {
        throw new Error(`Canonical/runtime semantic drift for ${row.id}.`);
      }
      rows.push({
        row,
        runtimeRow,
        topic,
        runtimeFile,
        canonicalFile,
      });
    }
  }
  if (index.total !== rows.length || rows.length !== expectedQuestionCount) {
    throw new Error(
      `Source count mismatch: index=${index.total} loaded=${rows.length} expected=${expectedQuestionCount}`,
    );
  }
  return { index, rows };
}

function walkFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs
    .readdirSync(directory, { withFileTypes: true })
    .flatMap((entry) => {
      const target = path.join(directory, entry.name);
      return entry.isDirectory() ? walkFiles(target) : [target];
    });
}

function normalizedAssetPath(file) {
  return path.relative(assetRoot, file).split(path.sep).join("/");
}

function buildMediaIndex(sourceEntries) {
  const referenced = new Set(
    sourceEntries.flatMap(({ row }) => imagesOf(allBlocks(row))),
  );
  const actual = walkFiles(mediaRoot)
    .map(normalizedAssetPath)
    .sort((left, right) => left.localeCompare(right));
  const missing = [...referenced].filter(
    (asset) => !fs.existsSync(path.join(assetRoot, asset)),
  );
  const orphaned = actual.filter((asset) => !referenced.has(asset));
  if (
    referenced.size !== expectedMediaCount ||
    actual.length !== expectedMediaCount ||
    missing.length > 0 ||
    orphaned.length > 0
  ) {
    throw new Error(
      `Media reconciliation failed: referenced=${referenced.size} actual=${actual.length} missing=${missing.length} orphaned=${orphaned.length}`,
    );
  }
  return new Map(
    actual.map((asset) => {
      const file = path.resolve(assetRoot, asset);
      if (!file.startsWith(`${path.resolve(assetRoot)}${path.sep}`)) {
        throw new Error(`Unsafe media path ${asset}.`);
      }
      const stat = fs.statSync(file);
      return [
        asset,
        {
          asset,
          sha256: digestFile(file),
          bytes: stat.size,
        },
      ];
    }),
  );
}

function loadTaxonomy() {
  const taxonomy = readJson(taxonomyFile);
  const topicToSection = new Map();
  for (const section of taxonomy.sections ?? []) {
    for (const topic of section.topics ?? []) {
      if (topicToSection.has(topic)) {
        throw new Error(`Taxonomy topic ${topic} belongs to multiple sections.`);
      }
      topicToSection.set(topic, {
        sectionId: section.id,
        subject: section.subject,
      });
    }
  }
  return { taxonomy, topicToSection };
}

function allBlocks(question) {
  return [
    ...(question.stem ?? []),
    ...(question.options ?? []).flat(),
    ...(question.solution ?? []),
    ...(question.smart_shortcut ?? []),
  ];
}

function textOf(blocks) {
  return (blocks ?? [])
    .filter((block) => block?.type === "text")
    .map((block) => String(block.text ?? ""))
    .join("\n")
    .trim();
}

function imagesOf(blocks) {
  return (blocks ?? [])
    .filter((block) => block?.type === "image")
    .map((block) => block.asset)
    .filter(Boolean);
}

function countControlCharacters(value) {
  return [...String(value ?? "")].filter((character) => {
    const code = character.charCodeAt(0);
    return (
      code <= 0x08 ||
      code === 0x0b ||
      code === 0x0c ||
      (code >= 0x0e && code <= 0x1f)
    );
  }).length;
}

function unescapedDollarCount(value) {
  let count = 0;
  for (let index = 0; index < value.length; index += 1) {
    if (value[index] !== "$") continue;
    let slashCount = 0;
    for (
      let before = index - 1;
      before >= 0 && value[before] === "\\";
      before -= 1
    ) {
      slashCount += 1;
    }
    if (slashCount % 2 === 0) count += 1;
  }
  return count;
}

function sourceLocator(subject, topicKey, questionNumber) {
  return `${subject}|${topicKey}|${questionNumber}`;
}

function expandReportRanges(groups) {
  const result = new Set();
  for (const group of groups ?? []) {
    for (const range of group.ranges ?? []) {
      for (let number = range.start; number <= range.end; number += 1) {
        result.add(sourceLocator(group.subject, group.topic_key, number));
      }
    }
  }
  return result;
}

function loadHistoricRiskSets() {
  return {
    solutionKeyMismatch: expandReportRanges(
      readJson(mismatchReportFile).grouped_mismatches,
    ),
    missingSolution: expandReportRanges(
      readJson(missingSolutionReportFile).missing_solution_groups,
    ),
  };
}

function buildCorpusSignals(sourceEntries) {
  const byContent = new Map();
  for (const { row } of sourceEntries) {
    const fingerprint = digest({
      subject: row.subject,
      stem: row.stem,
      options: row.options,
    });
    const group = byContent.get(fingerprint) ?? [];
    group.push(row);
    byContent.set(fingerprint, group);
  }
  const duplicateById = new Map();
  for (const [fingerprint, group] of byContent.entries()) {
    if (group.length < 2) continue;
    const options = new Set(group.map((row) => row.correct_option_index));
    for (const row of group) {
      duplicateById.set(row.id, {
        group_id: `duplicate-${fingerprint.slice(0, 16)}`,
        group_size: group.length,
        question_ids: group.map((item) => item.id).sort(),
        conflicting_source_keys: options.size > 1,
      });
    }
  }
  return { duplicateById };
}

function extractionSignals(
  question,
  historicRiskSets,
  corpusSignals,
  mediaIndex,
) {
  const stemText = textOf(question.stem);
  const optionTexts = (question.options ?? []).map(textOf);
  const solutionText = textOf(question.solution);
  const blocks = allBlocks(question);
  const mediaAssets = blocks
    .filter((block) => block?.type === "image")
    .map((block) => block.asset)
    .filter(Boolean);
  const placeholderStem =
    /سؤال چاپی شماره|از تصویر صفحه استخراج|صورت سؤال|باید در بازبینی نهایی با scan تطبیق داده شود|متن و گزینه‌های عددی از تصویر صفحه نیازمند بازبینی نهایی است|برای بازبینی نهایی به تصویر صفحه مراجعه شود/u.test(
      stemText,
    );
  const genericOptionPattern = /^گزینه\s*\(?[۱-۴1-4]\)?$/u;
  const genericOptions =
    optionTexts.length === 4 &&
    optionTexts.every((option) => genericOptionPattern.test(option)) &&
    (question.options ?? []).every((option) => imagesOf(option).length === 0);
  const inadequateSolution =
    /^(?:[۱-۴1-4]|و در نتیجه:|پاسخ در کلید سوالات آمده است\.)$/u.test(
      solutionText,
    );
  const emptyOptions = optionTexts
    .map((text, index) => ({ text, index }))
    .filter(({ text }) => text.length === 0)
    .map(({ index }) => index + 1);
  const controlCharacterCount = blocks
    .filter((block) => block?.type === "text")
    .reduce(
      (total, block) => total + countControlCharacters(block.text ?? ""),
      0,
    );
  const oddDollarBlockCount = blocks
    .filter((block) => block?.type === "text")
    .filter((block) => unescapedDollarCount(block.text ?? "") % 2 === 1)
    .length;
  const locator = sourceLocator(
    question.subject,
    question.topic_key,
    question.provenance?.question_number,
  );
  const duplicate = corpusSignals.duplicateById.get(question.id) ?? null;
  const referencedMedia = [...new Set(mediaAssets)]
    .sort()
    .map((asset) => mediaIndex.get(asset));
  if (referencedMedia.some((entry) => !entry)) {
    throw new Error(`Missing media evidence for ${question.id}.`);
  }
  return {
    stem_text_chars: stemText.length,
    option_count: question.options?.length ?? 0,
    option_text_chars: optionTexts.map((text) => text.length),
    empty_options: emptyOptions,
    generic_option_placeholders: genericOptions,
    solution_text_chars: solutionText.length,
    inadequate_solution: inadequateSolution,
    placeholder_stem: placeholderStem,
    image_blocks: mediaAssets.length,
    media_assets: [...new Set(mediaAssets)].sort(),
    media_bundle_sha256: digest(referencedMedia),
    control_character_count: controlCharacterCount,
    odd_dollar_block_count: oddDollarBlockCount,
    source_solution_origin: question.provenance?.solution_origin ?? null,
    source_question_page_missing:
      !Number.isFinite(question.provenance?.question_page) ||
      question.provenance.question_page <= 0,
    source_solution_page_missing:
      !Number.isFinite(question.provenance?.solution_page) ||
      question.provenance.solution_page <= 0,
    historic_solution_key_mismatch:
      historicRiskSets.solutionKeyMismatch.has(locator),
    historic_missing_solution: historicRiskSets.missingSolution.has(locator),
    known_current_contradiction:
      knownCurrentContradictions.get(question.id) ?? null,
    duplicate_content: duplicate,
  };
}

function baselineRecord(
  question,
  runtimeQuestion,
  topicToSection,
  historicRiskSets,
  corpusSignals,
  mediaIndex,
) {
  const mapping = topicToSection.get(question.topic_key);
  if (!mapping || mapping.subject !== question.subject) {
    throw new Error(
      `No valid section mapping for ${question.id}: ${question.subject}/${question.topic_key}`,
    );
  }
  const signals = extractionSignals(
    question,
    historicRiskSets,
    corpusSignals,
    mediaIndex,
  );
  const requiresImageReview =
    signals.image_blocks > 0 ||
    signals.placeholder_stem ||
    signals.generic_option_placeholders;
  const extractionIncomplete =
    signals.placeholder_stem ||
    signals.generic_option_placeholders ||
    signals.empty_options.length > 0;
  const solutionBlocked =
    signals.inadequate_solution || signals.known_current_contradiction != null;
  const sourceFidelityBlocked =
    signals.source_question_page_missing ||
    signals.source_solution_page_missing;
  const answerRisk =
    signals.historic_solution_key_mismatch ||
    signals.duplicate_content?.conflicting_source_keys === true;
  const staticReasons = [
    extractionIncomplete ? "incomplete_question_or_options" : null,
    signals.inadequate_solution ? "inadequate_solution" : null,
    signals.known_current_contradiction
      ? `known_contradiction:${signals.known_current_contradiction}`
      : null,
    signals.source_question_page_missing ? "missing_question_source_page" : null,
    signals.source_solution_page_missing ? "missing_solution_source_page" : null,
    signals.historic_solution_key_mismatch
      ? "historic_solution_key_mismatch"
      : null,
    signals.historic_missing_solution ? "historic_missing_solution" : null,
    signals.duplicate_content?.conflicting_source_keys
      ? "duplicate_content_with_conflicting_source_keys"
      : null,
  ].filter(Boolean);
  return {
    schema_version: 1,
    question_id: question.id,
    source_sha256: digest(question),
    runtime_record_sha256: digest(runtimeQuestion),
    referenced_media: signals.media_assets.map((asset) => mediaIndex.get(asset)),
    subject: question.subject,
    provenance: {
      edition: question.provenance?.edition ?? null,
      question_number: question.provenance?.question_number ?? null,
      question_pdf: question.provenance?.question_pdf ?? null,
      question_page: question.provenance?.question_page ?? null,
      solution_page: question.provenance?.solution_page ?? null,
      solution_origin: question.provenance?.solution_origin ?? null,
    },
    screening: {
      status: "pending",
      reviewer: null,
    },
    taxonomy: {
      registry_version: null,
      section_id: mapping.sectionId,
      topic_key: question.topic_key,
      subtopic_key: null,
      proposed_subtopic: null,
      proposed_concept_tags: [],
      proposed_secondary_concepts: [],
      proposed_prerequisites: [],
      concept_tags: [],
      secondary_concepts: [],
      prerequisites: [],
      status: "pending",
    },
    difficulty: {
      rubric_version: "gauss-difficulty-v1",
      source: question.difficulty,
      screened: null,
      reviewed: null,
      dimensions: null,
      confidence: null,
      anchor_evidence: [],
      status: "pending",
    },
    extraction: {
      status: extractionIncomplete ? "incomplete" : "pending",
      requires_image_review: requiresImageReview,
      signals,
      render_gate: {
        status: "pending",
        receipt_id: null,
      },
      reviews: [],
    },
    source_fidelity: {
      status: sourceFidelityBlocked ? "blocked_missing_source" : "pending",
      reviews: [],
    },
    answer: {
      source_option: question.correct_option_index,
      independent_option: null,
      effective_option: null,
      source_agreement: "unverified",
      correction: null,
      status: "source_only",
      reviews: [],
    },
    solution: {
      status: solutionBlocked
        ? signals.known_current_contradiction
          ? "mismatched"
          : "partial"
        : "pending",
      reviews: [],
    },
    adversarial_verification: {
      status: "pending",
      reviews: [],
    },
    certification: {
      status: staticReasons.length > 0 || answerRisk ? "quarantined" : "pending",
      reasons: [
        "luna_screening_pending",
        "source_fidelity_pending",
        "render_gate_pending",
        "independent_answer_pending",
        "fresh_verifier_pending",
        "adversarial_verification_pending",
        "solution_verification_pending",
        ...staticReasons,
      ],
    },
    usable: false,
  };
}

function writeJsonLines(file, rows) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(
    file,
    `${rows.map((row) => JSON.stringify(row)).join("\n")}\n`,
    "utf8",
  );
}

function writeJsonLinesAtomic(file, rows) {
  const temp = `${file}.tmp`;
  const backup = `${file}.previous`;
  writeJsonLines(temp, rows);
  if (!fs.existsSync(file)) {
    fs.renameSync(temp, file);
    return;
  }
  if (fs.existsSync(backup)) fs.unlinkSync(backup);
  fs.renameSync(file, backup);
  try {
    fs.renameSync(temp, file);
    fs.unlinkSync(backup);
  } catch (error) {
    if (fs.existsSync(file)) fs.unlinkSync(file);
    fs.renameSync(backup, file);
    if (fs.existsSync(temp)) fs.unlinkSync(temp);
    throw error;
  }
}

function readJsonLines(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`Missing certification manifest: ${file}`);
  }
  return fs
    .readFileSync(file, "utf8")
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`${file}:${index + 1}: ${error.message}`);
      }
    });
}

function countBy(rows, selector) {
  const result = {};
  for (const row of rows) {
    const key = String(selector(row));
    result[key] = (result[key] ?? 0) + 1;
  }
  return Object.fromEntries(
    Object.entries(result).sort(([left], [right]) =>
      left.localeCompare(right),
    ),
  );
}

function baseline() {
  const { rows } = loadSource();
  const { topicToSection } = loadTaxonomy();
  const mediaIndex = buildMediaIndex(rows);
  const historicRiskSets = loadHistoricRiskSets();
  const corpusSignals = buildCorpusSignals(rows);
  const records = rows
    .map(({ row, runtimeRow }) =>
      baselineRecord(
        row,
        runtimeRow,
        topicToSection,
        historicRiskSets,
        corpusSignals,
        mediaIndex,
      ),
    )
    .sort((left, right) => left.question_id.localeCompare(right.question_id));
  writeJsonLines(manifestFile, records);
  writeJsonLines(
    mediaManifestFile,
    [...mediaIndex.values()].sort((left, right) =>
      left.asset.localeCompare(right.asset),
    ),
  );
  console.log(
    JSON.stringify(
      {
        output: path.relative(repoRoot, manifestFile),
        records: records.length,
        subjects: countBy(records, (record) => record.subject),
        source_difficulty: countBy(
          records,
          (record) => record.difficulty.source,
        ),
        requires_image_review: records.filter(
          (record) => record.extraction.requires_image_review,
        ).length,
        placeholder_stem: records.filter(
          (record) => record.extraction.signals.placeholder_stem,
        ).length,
        placeholder_options: records.filter(
          (record) =>
            record.extraction.signals.generic_option_placeholders,
        ).length,
        incomplete_question_or_options: records.filter(
          (record) => record.extraction.status === "incomplete",
        ).length,
        inadequate_solution: records.filter(
          (record) => record.extraction.signals.inadequate_solution,
        ).length,
        solution_page_missing: records.filter(
          (record) =>
            record.extraction.signals.source_solution_page_missing,
        ).length,
        historic_solution_key_mismatch: records.filter(
          (record) =>
            record.extraction.signals.historic_solution_key_mismatch,
        ).length,
        historic_missing_solution: records.filter(
          (record) => record.extraction.signals.historic_missing_solution,
        ).length,
        known_current_contradiction: records.filter(
          (record) =>
            record.extraction.signals.known_current_contradiction != null,
        ).length,
        duplicate_content_rows: records.filter(
          (record) => record.extraction.signals.duplicate_content != null,
        ).length,
        duplicate_conflicting_key_rows: records.filter(
          (record) =>
            record.extraction.signals.duplicate_content
              ?.conflicting_source_keys === true,
        ).length,
        quarantined: records.filter(
          (record) => record.certification.status === "quarantined",
        ).length,
        media: {
          output: path.relative(repoRoot, mediaManifestFile),
          files: mediaIndex.size,
          bytes: [...mediaIndex.values()].reduce(
            (total, entry) => total + entry.bytes,
            0,
          ),
        },
      },
      null,
      2,
    ),
  );
}

function validateReview(review, role, option, errors, at) {
  if (!review || review.role !== role) {
    errors.push(`${at} missing ${role} review`);
    return;
  }
  if (!review.independent_context) {
    errors.push(`${at} ${role} review is not independently contextualized`);
  }
  if (review.verdict !== "holds" || review.option !== option) {
    errors.push(`${at} ${role} review does not hold option ${option}`);
  }
  if (!review.reviewer_id || !review.evidence_digest) {
    errors.push(`${at} ${role} review lacks identity/evidence digest`);
  }
}

function validate() {
  const { rows: sourceEntries } = loadSource();
  const { taxonomy, topicToSection } = loadTaxonomy();
  const mediaIndex = buildMediaIndex(sourceEntries);
  const sourceById = new Map(sourceEntries.map((entry) => [entry.row.id, entry]));
  const records = readJsonLines(manifestFile);
  const mediaManifest = readJsonLines(mediaManifestFile);
  const mediaManifestByAsset = new Map(
    mediaManifest.map((entry) => [entry.asset, entry]),
  );
  const runtimeAttestations = fs.existsSync(runtimeAttestationFile)
    ? readJsonLines(runtimeAttestationFile)
    : [];
  const runtimeAttestationById = new Map(
    runtimeAttestations.map((entry) => [entry.id, entry]),
  );
  const seen = new Set();
  const errors = [];
  const definedSubtopics = new Set(
    (taxonomy.subtopics ?? []).map((subtopic) => subtopic.key),
  );

  for (const [index, record] of records.entries()) {
    const at = `manifest:${index + 1}:${record.question_id ?? "<missing-id>"}`;
    if (record.schema_version !== 1) errors.push(`${at} invalid schema_version`);
    if (!record.question_id || seen.has(record.question_id)) {
      errors.push(`${at} missing or duplicate question_id`);
    }
    seen.add(record.question_id);
    const sourceEntry = sourceById.get(record.question_id);
    if (!sourceEntry) {
      errors.push(`${at} has no source record`);
      continue;
    }
    const source = sourceEntry.row;
    if (record.source_sha256 !== digest(source)) {
      errors.push(`${at} source SHA-256 is stale`);
    }
    if (record.runtime_record_sha256 !== digest(sourceEntry.runtimeRow)) {
      errors.push(`${at} runtime SHA-256 is stale`);
    }
    const expectedMedia = [...new Set(imagesOf(allBlocks(source)))]
      .sort()
      .map((asset) => mediaIndex.get(asset));
    if (
      canonicalJson(record.referenced_media) !== canonicalJson(expectedMedia)
    ) {
      errors.push(`${at} referenced media evidence is stale`);
    }
    for (const media of record.referenced_media ?? []) {
      if (
        canonicalJson(mediaManifestByAsset.get(media.asset)) !==
        canonicalJson(media)
      ) {
        errors.push(`${at} media manifest drift for ${media.asset}`);
      }
    }
    if (record.subject !== source.subject) errors.push(`${at} subject drift`);
    if (record.answer?.source_option !== source.correct_option_index) {
      errors.push(`${at} source option drift`);
    }
    const mapping = topicToSection.get(source.topic_key);
    if (
      !mapping ||
      record.taxonomy?.section_id !== mapping.sectionId ||
      record.taxonomy?.topic_key !== source.topic_key
    ) {
      errors.push(`${at} invalid section/topic mapping`);
    }
    if (
      record.difficulty?.source !== source.difficulty ||
      !allowedDifficulties.has(record.difficulty?.source)
    ) {
      errors.push(`${at} source difficulty drift`);
    }
    if (record.screening?.status !== "pending") {
      const reviewer = record.screening?.reviewer;
      const attestation = runtimeAttestationById.get(
        reviewer?.runtime_attestation_id,
      );
      const screeningOutputFile = path.join(
        screeningRoot,
        `${reviewer?.batch_id}.output.jsonl`,
      );
      if (
        reviewer?.model !== attestation?.model ||
        reviewer?.reasoning !== attestation?.reasoning ||
        !reviewer?.prompt_version ||
        !reviewer?.reviewer_id ||
        !trustedScreeningRuntime(
          attestation,
          reviewer?.batch_id,
          screeningOutputFile,
        )
      ) {
        errors.push(
          `${at} screening lacks trusted runtime provenance`,
        );
      }
    }
    if (record.taxonomy?.status === "reviewed") {
      if (
        record.taxonomy.registry_version !== taxonomy.version ||
        !record.taxonomy.subtopic_key ||
        !definedSubtopics.has(record.taxonomy.subtopic_key) ||
        !Array.isArray(record.taxonomy.concept_tags) ||
        record.taxonomy.concept_tags.length === 0
      ) {
        errors.push(`${at} reviewed taxonomy is incomplete or undefined`);
      }
    }
    if (record.difficulty?.status === "reviewed") {
      if (!allowedDifficulties.has(record.difficulty.reviewed)) {
        errors.push(`${at} reviewed difficulty is invalid`);
      }
      if (
        record.difficulty.rubric_version !== "gauss-difficulty-v1" ||
        typeof record.difficulty.confidence !== "number" ||
        record.difficulty.confidence < 0 ||
        record.difficulty.confidence > 1 ||
        !record.difficulty.dimensions
      ) {
        errors.push(`${at} reviewed difficulty lacks rubric evidence`);
      } else {
        for (const [dimension, [minimum, maximum]] of Object.entries(
          difficultyDimensionRanges,
        )) {
          const score = record.difficulty.dimensions[dimension];
          if (
            !Number.isInteger(score) ||
            score < minimum ||
            score > maximum
          ) {
            errors.push(`${at} invalid difficulty dimension ${dimension}`);
          }
        }
      }
    }
    if (record.usable && record.certification?.status !== "certified") {
      errors.push(`${at} usable record is not certified`);
    }
    if (record.certification?.status === "certified") {
      const option = record.answer?.effective_option;
      const answerReviews = record.answer?.reviews ?? [];
      const solver = answerReviews.find((review) => review.role === "solver");
      const verifier = answerReviews.find(
        (review) => review.role === "verifier",
      );
      const adjudicator = answerReviews.find(
        (review) => review.role === "source_key_adjudicator",
      );
      const adversary = (
        record.adversarial_verification?.reviews ?? []
      ).find((review) => review.role === "adversary");
      if (record.screening?.status !== "accepted") {
        errors.push(`${at} certified without accepted screening`);
      }
      if (
        record.extraction?.status !== "verified_complete" ||
        record.extraction?.render_gate?.status !== "passed" ||
        !record.extraction?.render_gate?.receipt_id ||
        record.source_fidelity?.status !== "verified_source" ||
        record.taxonomy?.status !== "reviewed" ||
        record.difficulty?.status !== "reviewed"
      ) {
        errors.push(
          `${at} certified before source/render/extraction/taxonomy/difficulty gates`,
        );
      }
      if (
        record.answer?.status !== "verified_correct" ||
        !Number.isInteger(option) ||
        option < 1 ||
        option > 4 ||
        record.answer?.independent_option !== option
      ) {
        errors.push(`${at} certified without a verified effective answer`);
      }
      validateReview(solver, "solver", option, errors, at);
      validateReview(verifier, "verifier", option, errors, at);
      if (
        solver?.reviewer_id &&
        verifier?.reviewer_id &&
        solver.reviewer_id === verifier.reviewer_id
      ) {
        errors.push(`${at} solver and verifier are not independent`);
      }
      if (option === record.answer?.source_option) {
        if (
          record.answer?.source_agreement !== "agrees_source" ||
          record.answer?.correction != null
        ) {
          errors.push(`${at} source agreement state is inconsistent`);
        }
      } else {
        const correction = record.answer?.correction;
        if (
          record.answer?.source_agreement !== "overrides_source" ||
          correction?.source_option !== record.answer?.source_option ||
          correction?.effective_option !== option ||
          !correction?.reason ||
          !correction?.evidence_digest
        ) {
          errors.push(`${at} source-key override lacks immutable provenance`);
        }
        validateReview(
          adjudicator,
          "source_key_adjudicator",
          option,
          errors,
          at,
        );
        const reviewerIds = new Set(
          [solver, verifier, adjudicator]
            .map((review) => review?.reviewer_id)
            .filter(Boolean),
        );
        if (reviewerIds.size !== 3) {
          errors.push(`${at} source-key override lacks three independent reviews`);
        }
      }
      if (
        record.solution?.status !== "verified_complete_correct" ||
        (record.solution?.reviews ?? []).length < 2
      ) {
        errors.push(`${at} certified without two solution reviews`);
      }
      for (const review of record.solution?.reviews ?? []) {
        if (
          review.verdict !== "holds" ||
          !review.reviewer_id ||
          !review.evidence_digest
        ) {
          errors.push(`${at} solution review lacks a holding evidence record`);
        }
      }
      if (
        record.adversarial_verification?.status !== "passed" ||
        !adversary
      ) {
        errors.push(`${at} certified without adversarial verification`);
      } else {
        validateReview(adversary, "adversary", option, errors, at);
      }
      if ((record.certification?.reasons ?? []).length !== 0) {
        errors.push(`${at} certified with unresolved reasons`);
      }
      if (!record.usable) errors.push(`${at} certified record is not usable`);
    }
  }

  for (const id of sourceById.keys()) {
    if (!seen.has(id)) errors.push(`source-only ID ${id}`);
  }
  if (
    records.length !== expectedQuestionCount ||
    seen.size !== expectedQuestionCount
  ) {
    errors.push(
      `manifest count mismatch: rows=${records.length} unique=${seen.size} expected=${expectedQuestionCount}`,
    );
  }
  if (
    mediaManifest.length !== expectedMediaCount ||
    mediaManifestByAsset.size !== expectedMediaCount
  ) {
    errors.push(
      `media manifest count mismatch: rows=${mediaManifest.length} unique=${mediaManifestByAsset.size} expected=${expectedMediaCount}`,
    );
  }
  for (const [asset, evidence] of mediaIndex.entries()) {
    if (
      canonicalJson(mediaManifestByAsset.get(asset)) !== canonicalJson(evidence)
    ) {
      errors.push(`media-only or stale evidence ${asset}`);
    }
  }
  if (errors.length > 0) {
    console.error(`Certification validation failed with ${errors.length} error(s).`);
    for (const error of errors.slice(0, 100)) console.error(`- ${error}`);
    process.exitCode = 1;
    return;
  }
  console.log(
    `Certification validation passed: ${records.length} source-bound records, ${records.filter((record) => record.usable).length} usable.`,
  );
}

function summarize() {
  const records = readJsonLines(manifestFile);
  const summary = {
    total: records.length,
    subjects: countBy(records, (record) => record.subject),
    screening: countBy(records, (record) => record.screening.status),
    extraction: countBy(records, (record) => record.extraction.status),
    taxonomy: countBy(records, (record) => record.taxonomy.status),
    difficulty: countBy(records, (record) => record.difficulty.status),
    answer: countBy(records, (record) => record.answer.status),
    solution: countBy(records, (record) => record.solution.status),
    source_fidelity: countBy(
      records,
      (record) => record.source_fidelity.status,
    ),
    adversarial_verification: countBy(
      records,
      (record) => record.adversarial_verification.status,
    ),
    certification: countBy(
      records,
      (record) => record.certification.status,
    ),
    usable: records.filter((record) => record.usable).length,
    image_review_queue: records.filter(
      (record) => record.extraction.requires_image_review,
    ).length,
    placeholder_stem: records.filter(
      (record) => record.extraction.signals.placeholder_stem,
    ).length,
    placeholder_options: records.filter(
      (record) => record.extraction.signals.generic_option_placeholders,
    ).length,
    incomplete_question_or_options: records.filter(
      (record) => record.extraction.status === "incomplete",
    ).length,
    inadequate_solution: records.filter(
      (record) => record.extraction.signals.inadequate_solution,
    ).length,
    solution_page_missing: records.filter(
      (record) => record.extraction.signals.source_solution_page_missing,
    ).length,
    historic_solution_key_mismatch: records.filter(
      (record) =>
        record.extraction.signals.historic_solution_key_mismatch,
    ).length,
    historic_missing_solution: records.filter(
      (record) => record.extraction.signals.historic_missing_solution,
    ).length,
    known_current_contradiction: records.filter(
      (record) =>
        record.extraction.signals.known_current_contradiction != null,
    ).length,
    duplicate_content_rows: records.filter(
      (record) => record.extraction.signals.duplicate_content != null,
    ).length,
    duplicate_conflicting_key_rows: records.filter(
      (record) =>
        record.extraction.signals.duplicate_content
          ?.conflicting_source_keys === true,
    ).length,
  };
  console.log(JSON.stringify(summary, null, 2));
}

function repairKind(record, issues) {
  const evidence = [
    ...issues,
    ...record.certification.reasons,
    ...record.difficulty.anchor_evidence,
  ]
    .join(" ")
    .toLowerCase();
  if (/media|image|diagram|crop|blank|asset|page fragment|mislabeled/u.test(evidence)) {
    return "media_rebind_or_reextract";
  }
  if (/formula|latex|expression|exponent/u.test(evidence)) {
    return "formula_transcription";
  }
  if (/solution|explanation|worked/u.test(evidence)) {
    return "solution_rederive";
  }
  if (/answer|key|correct_option|conclusion/u.test(evidence)) {
    return "answer_rederive";
  }
  if (/option|choice|distractor/u.test(evidence)) return "option_recovery";
  return "question_reconstruction";
}

function repairPriority(record, issues) {
  const evidence = [...issues, ...record.certification.reasons]
    .join(" ")
    .toLowerCase();
  if (
    record.extraction.status !== "screened_complete" ||
    /diagram|media|image|option|formula|missing|placeholder|crop|blank/u.test(
      evidence,
    )
  ) {
    return "p0_blocking_render_or_prompt";
  }
  if (/solution|answer|key|conclusion/u.test(evidence)) {
    return "p1_blocking_correctness";
  }
  return "p2_quality_repair";
}

function repairIssues(record) {
  const screeningIssues = record.certification.reasons
    .filter((reason) => reason.startsWith("screening_issue:"))
    .map((reason) => reason.slice("screening_issue:".length));
  const certificationIssues = record.certification.reasons.filter(
    (reason) =>
      ![
        "luna_screening_pending",
        "source_fidelity_pending",
        "render_gate_pending",
        "independent_answer_pending",
        "fresh_verifier_pending",
        "adversarial_verification_pending",
        "solution_verification_pending",
      ].includes(reason),
  );
  return [...new Set([...screeningIssues, ...certificationIssues])].sort();
}

function buildRepairQueue() {
  const records = readJsonLines(manifestFile);
  const tickets = records
    .map((record) => {
      const issues = repairIssues(record);
      const repairRequired =
        record.screening.status !== "accepted" ||
        record.extraction.status !== "screened_complete" ||
        record.solution.status === "mismatched" ||
        record.answer.status === "independently_conflicts" ||
        record.source_fidelity.status === "source_conflict" ||
        issues.length > 0;
      if (!repairRequired) return null;
      return {
        schema_version: 1,
        ticket_id: `repair:${record.question_id}:${record.source_sha256.slice(0, 12)}`,
        question_id: record.question_id,
        source_sha256: record.source_sha256,
        priority: repairPriority(record, issues),
        repair_kind: repairKind(record, issues),
        blocking_issues: issues,
        source_provenance: record.provenance,
        current_state: {
          screening: record.screening.status,
          extraction: record.extraction.status,
          source_fidelity: record.source_fidelity.status,
          answer: record.answer.status,
          solution: record.solution.status,
          certification: record.certification.status,
        },
        required_evidence: [
          "source_fidelity",
          "repair_overlay",
          "independent_solve",
          "fresh_verifier",
          "solution_review",
          "adversarial_review",
        ],
        promotion_status: "pending_evidence",
      };
    })
    .filter(Boolean)
    .sort((left, right) =>
      left.priority.localeCompare(right.priority) ||
      left.question_id.localeCompare(right.question_id),
    );
  writeJsonLinesAtomic(repairQueueFile, tickets);
  console.log(
    JSON.stringify(
      {
        output: path.relative(repoRoot, repairQueueFile),
        tickets: tickets.length,
        priorities: countBy(tickets, (ticket) => ticket.priority),
        repair_kinds: countBy(tickets, (ticket) => ticket.repair_kind),
      },
      null,
      2,
    ),
  );
}

function validateRepairOverlays() {
  if (!fs.existsSync(repairOverlayFile)) {
    console.log("Repair overlay validation passed: no overlays proposed yet.");
    return;
  }
  const records = readJsonLines(manifestFile);
  const recordById = new Map(records.map((record) => [record.question_id, record]));
  const overlays = readJsonLines(repairOverlayFile);
  const errors = [];
  const seen = new Set();
  for (const [index, overlay] of overlays.entries()) {
    const at = `repair-overlay:${index + 1}`;
    const record = recordById.get(overlay.question_id);
    if (!record) errors.push(`${at} has an unknown question_id`);
    if (!/^[a-f0-9]{64}$/u.test(overlay.source_sha256 ?? "")) {
      errors.push(`${at} source_sha256 is invalid`);
    }
    if (record && record.source_sha256 !== overlay.source_sha256) {
      errors.push(`${at} source hash is stale`);
    }
    if (seen.has(overlay.question_id)) errors.push(`${at} duplicate question_id`);
    seen.add(overlay.question_id);
    if (!new Set(["draft", "under_review", "verified", "rejected"]).has(overlay.status)) {
      errors.push(`${at} status is invalid`);
    }
    if (overlay.status === "verified") {
      const evidence = overlay.evidence ?? {};
      for (const key of [
        "source_fidelity",
        "independent_solve",
        "fresh_verifier",
        "solution_review",
        "adversarial_review",
      ]) {
        if (typeof evidence[key] !== "string" || evidence[key].length < 8) {
          errors.push(`${at} verified overlay lacks ${key} evidence`);
        }
      }
    }
  }
  if (errors.length > 0) {
    throw new Error(`Repair overlay validation failed with ${errors.length} error(s):\n${errors.map((error) => `- ${error}`).join("\n")}`);
  }
  console.log(`Repair overlay validation passed: ${overlays.length} overlay(s).`);
}

function screeningItem(question, record) {
  return {
    question_id: question.id,
    source_sha256: record.source_sha256,
    subject: question.subject,
    section_id: record.taxonomy.section_id,
    source_topic_key: question.topic_key,
    source_difficulty: question.difficulty,
    stem: question.stem,
    options: question.options,
    solution: question.solution,
    smart_shortcut: question.smart_shortcut,
    media_assets: record.extraction.signals.media_assets,
    media_evidence: record.referenced_media,
    provenance: record.provenance,
    source_answer_hidden: true,
  };
}

function screeningWeight(question) {
  const characterCount = allBlocks(question)
    .filter((block) => block?.type === "text")
    .reduce((total, block) => total + String(block.text ?? "").length, 0);
  const mediaCount = imagesOf(allBlocks(question)).length;
  return Math.max(1, Math.ceil(characterCount / 1200)) + mediaCount * 3;
}

function shard() {
  const sizeArgument =
    process.argv.find((argument) => argument.startsWith("--size="))?.slice(7) ??
    "25";
  const weightArgument =
    process.argv
      .find((argument) => argument.startsWith("--max-weight="))
      ?.slice(13) ?? "120";
  const batchSize = Number(sizeArgument);
  const maxWeight = Number(weightArgument);
  if (!Number.isInteger(batchSize) || batchSize < 1 || batchSize > 50) {
    throw new Error("--size must be an integer from 1 to 50.");
  }
  if (!Number.isInteger(maxWeight) || maxWeight < 20 || maxWeight > 500) {
    throw new Error("--max-weight must be an integer from 20 to 500.");
  }
  const records = readJsonLines(manifestFile);
  const recordById = new Map(records.map((record) => [record.question_id, record]));
  const { rows: sourceEntries } = loadSource();
  const pending = sourceEntries
    .filter(({ row }) => recordById.get(row.id)?.screening?.status === "pending")
    .sort((left, right) => {
      const topicOrder = left.topic.order - right.topic.order;
      if (left.row.subject !== right.row.subject) {
        return left.row.subject.localeCompare(right.row.subject);
      }
      return topicOrder || left.row.id.localeCompare(right.row.id);
    });
  fs.mkdirSync(screeningRoot, { recursive: true });
  for (const file of fs.readdirSync(screeningRoot)) {
    if (/^screening-\d{4}\.json$/u.test(file) || file === "index.json") {
      fs.unlinkSync(path.join(screeningRoot, file));
    }
  }
  const batches = [];
  let entries = [];
  let batchWeight = 0;
  const flush = () => {
    if (entries.length === 0) return;
    const id = `screening-${String(batches.length + 1).padStart(4, "0")}`;
    const file = `${id}.json`;
    const payload = {
      schema_version: 1,
      batch_id: id,
      screening_model: "gpt-5.6-luna",
      reasoning: "medium",
      prompt_version: "gauss-screening-v1",
      item_count: entries.length,
      subject: entries[0].row.subject,
      topic_key: entries[0].row.topic_key,
      total_weight: batchWeight,
      expected_output: `${id}.output.jsonl`,
      items: entries.map(({ row }) =>
        screeningItem(row, recordById.get(row.id)),
      ),
    };
    fs.writeFileSync(
      path.join(screeningRoot, file),
      `${JSON.stringify(payload)}\n`,
      "utf8",
    );
    batches.push({
      id,
      input: file,
      output: payload.expected_output,
      item_count: entries.length,
      total_weight: batchWeight,
      subject: payload.subject,
      topic_key: payload.topic_key,
      first_id: entries[0].row.id,
      last_id: entries.at(-1).row.id,
    });
    entries = [];
    batchWeight = 0;
  };
  for (const entry of pending) {
    const weight = screeningWeight(entry.row);
    const crossesTopic =
      entries.length > 0 &&
      (entries[0].row.subject !== entry.row.subject ||
        entries[0].row.topic_key !== entry.row.topic_key);
    if (
      entries.length > 0 &&
      (crossesTopic ||
        entries.length >= batchSize ||
        batchWeight + weight > maxWeight)
    ) {
      flush();
    }
    entries.push(entry);
    batchWeight += weight;
  }
  flush();
  const index = {
    schema_version: 1,
    prompt_version: "gauss-screening-v1",
    model: "gpt-5.6-luna",
    reasoning: "medium",
    batch_size: batchSize,
    max_weight: maxWeight,
    total_items: pending.length,
    batch_count: batches.length,
    batches,
  };
  fs.writeFileSync(
    path.join(screeningRoot, "index.json"),
    `${JSON.stringify(index, null, 2)}\n`,
    "utf8",
  );
  console.log(
    JSON.stringify(
      {
        output: path.relative(repoRoot, screeningRoot),
        items: pending.length,
        batches: batches.length,
        batch_size: batchSize,
        max_weight: maxWeight,
      },
      null,
      2,
    ),
  );
}

function commandArgument(name) {
  return process.argv
    .find((argument) => argument.startsWith(`--${name}=`))
    ?.slice(name.length + 3);
}

function validateStringArray(value, field, errors, at, { maximum = 12 } = {}) {
  if (
    !Array.isArray(value) ||
    value.length > maximum ||
    value.some(
      (entry) =>
        typeof entry !== "string" ||
        !/^[a-z0-9_]+$/u.test(entry) ||
        entry.length > 80,
    ) ||
    new Set(value).size !== value.length
  ) {
    errors.push(`${at} invalid ${field}`);
  }
}

function validateScreeningResult(result, inputItem, record, errors, at) {
  const allowedFields = new Set([
    "question_id",
    "source_sha256",
    "screening_status",
    "extraction_status",
    "subtopic",
    "concept_tags",
    "secondary_concepts",
    "prerequisites",
    "difficulty",
    "difficulty_dimensions",
    "difficulty_confidence",
    "issues",
    "review_summary",
  ]);
  for (const field of Object.keys(result)) {
    if (!allowedFields.has(field)) errors.push(`${at} unexpected field ${field}`);
  }
  if (
    result.question_id !== inputItem.question_id ||
    result.question_id !== record.question_id
  ) {
    errors.push(`${at} question ID/order mismatch`);
  }
  if (
    result.source_sha256 !== inputItem.source_sha256 ||
    result.source_sha256 !== record.source_sha256
  ) {
    errors.push(`${at} source SHA-256 mismatch`);
  }
  if (
    !new Set(["accepted", "needs_repair", "ambiguous"]).has(
      result.screening_status,
    )
  ) {
    errors.push(`${at} invalid screening_status`);
  }
  if (
    !new Set(["screened_complete", "incomplete", "ambiguous"]).has(
      result.extraction_status,
    )
  ) {
    errors.push(`${at} invalid extraction_status`);
  }
  if (
    !result.subtopic ||
    (result.subtopic.key != null &&
      !/^[a-z0-9_]+$/u.test(result.subtopic.key)) ||
    !Object.hasOwn(result.subtopic, "label_en") ||
    !Object.hasOwn(result.subtopic, "label_fa")
  ) {
    errors.push(`${at} invalid subtopic proposal`);
  }
  validateStringArray(result.concept_tags, "concept_tags", errors, at, {
    maximum: 6,
  });
  validateStringArray(
    result.secondary_concepts,
    "secondary_concepts",
    errors,
    at,
  );
  validateStringArray(result.prerequisites, "prerequisites", errors, at);
  if (!allowedDifficulties.has(result.difficulty)) {
    errors.push(`${at} invalid difficulty`);
  }
  if (!result.difficulty_dimensions) {
    errors.push(`${at} missing difficulty dimensions`);
  } else {
    for (const [dimension, [minimum, maximum]] of Object.entries(
      difficultyDimensionRanges,
    )) {
      const score = result.difficulty_dimensions[dimension];
      if (!Number.isInteger(score) || score < minimum || score > maximum) {
        errors.push(`${at} invalid difficulty dimension ${dimension}`);
      }
    }
  }
  if (
    typeof result.difficulty_confidence !== "number" ||
    result.difficulty_confidence < 0 ||
    result.difficulty_confidence > 1
  ) {
    errors.push(`${at} invalid difficulty confidence`);
  }
  if (
    !Array.isArray(result.issues) ||
    result.issues.some(
      (issue) => typeof issue !== "string" || issue.length === 0,
    ) ||
    new Set(result.issues).size !== result.issues.length
  ) {
    errors.push(`${at} invalid issues`);
  }
  if (
    typeof result.review_summary !== "string" ||
    result.review_summary.trim().length === 0 ||
    result.review_summary.length > 1200
  ) {
    errors.push(`${at} invalid review_summary`);
  }
  const staticallyIncomplete =
    record.extraction.signals.placeholder_stem ||
    record.extraction.signals.generic_option_placeholders ||
    record.extraction.signals.empty_options.length > 0;
  if (
    staticallyIncomplete &&
    (result.screening_status === "accepted" ||
      result.extraction_status === "screened_complete")
  ) {
    errors.push(`${at} model attempted to accept a static extraction blocker`);
  }
  if (
    result.screening_status === "accepted" &&
    (result.extraction_status !== "screened_complete" ||
      result.subtopic.key == null ||
      result.concept_tags.length === 0 ||
      result.issues.length > 0)
  ) {
    errors.push(`${at} accepted screening is internally inconsistent`);
  }
}

function mergeScreening() {
  const batchId = commandArgument("batch");
  const attestationId = commandArgument("attestation");
  const reattest = process.argv.includes("--reattest");
  if (!batchId || !/^screening-\d{4}$/u.test(batchId)) {
    throw new Error("--batch must be a screening-NNNN batch ID.");
  }
  if (!attestationId) {
    throw new Error("--attestation is required.");
  }
  const inputFile = path.join(screeningRoot, `${batchId}.json`);
  const input = readJson(inputFile);
  const outputFile = path.join(screeningRoot, input.expected_output);
  const output = readJsonLines(outputFile);
  const attestations = readJsonLines(runtimeAttestationFile);
  const attestation = attestations.find((entry) => entry.id === attestationId);
  if (!trustedScreeningRuntime(attestation, batchId, outputFile)) {
    throw new Error(
      `Attestation ${attestationId} does not prove a trusted screening runtime for ${batchId}.`,
    );
  }
  if (output.length !== input.items.length) {
    throw new Error(
      `${batchId} output count mismatch: expected=${input.items.length} actual=${output.length}`,
    );
  }
  const records = readJsonLines(manifestFile);
  const recordById = new Map(records.map((record) => [record.question_id, record]));
  const errors = [];
  for (const [index, result] of output.entries()) {
    const inputItem = input.items[index];
    const record = recordById.get(inputItem.question_id);
    const at = `${batchId}:${index + 1}:${inputItem.question_id}`;
    if (!record) {
      errors.push(`${at} has no certification record`);
      continue;
    }
    validateScreeningResult(result, inputItem, record, errors, at);
    if (record.screening.status !== "pending") {
      if (!reattest) {
        errors.push(`${at} screening was already merged`);
        continue;
      }
      if (
        record.screening.status !== result.screening_status ||
        record.extraction.status !== result.extraction_status ||
        canonicalJson(record.taxonomy.proposed_subtopic) !==
          canonicalJson(result.subtopic) ||
        canonicalJson(record.taxonomy.proposed_concept_tags) !==
          canonicalJson(result.concept_tags) ||
        canonicalJson(record.difficulty.screened) !==
          canonicalJson(result.difficulty) ||
        canonicalJson(record.difficulty.dimensions) !==
          canonicalJson(result.difficulty_dimensions)
      ) {
        errors.push(`${at} re-attestation would change screened findings`);
      }
    }
  }
  if (errors.length > 0) {
    throw new Error(
      `Screening merge rejected with ${errors.length} error(s):\n${errors
        .slice(0, 100)
        .map((error) => `- ${error}`)
        .join("\n")}`,
    );
  }
  for (const [index, result] of output.entries()) {
    const record = recordById.get(input.items[index].question_id);
    record.screening = {
      status: result.screening_status,
      reviewer: {
        reviewer_id: `${attestation.id}:${record.question_id}`,
        model: attestation.model,
        reasoning: attestation.reasoning,
        prompt_version: input.prompt_version,
        runtime_attestation_id: attestation.id,
        batch_id: batchId,
        evidence_digest: digest(result),
      },
    };
    record.taxonomy.proposed_subtopic = result.subtopic;
    record.taxonomy.proposed_concept_tags = result.concept_tags;
    record.taxonomy.proposed_secondary_concepts = result.secondary_concepts;
    record.taxonomy.proposed_prerequisites = result.prerequisites;
    record.taxonomy.status = "screened";
    record.difficulty.screened = result.difficulty;
    record.difficulty.dimensions = result.difficulty_dimensions;
    record.difficulty.confidence = result.difficulty_confidence;
    record.difficulty.anchor_evidence = [result.review_summary];
    record.difficulty.status = "screened";
    record.extraction.status = result.extraction_status;
    const reasons = new Set(record.certification.reasons);
    reasons.delete("luna_screening_pending");
    if (result.screening_status !== "accepted") {
      reasons.add(`screening:${result.screening_status}`);
      for (const issue of result.issues) reasons.add(`screening_issue:${issue}`);
      record.certification.status = "quarantined";
    }
    record.certification.reasons = [...reasons].sort();
  }
  writeJsonLinesAtomic(manifestFile, records);
  console.log(
    JSON.stringify(
      {
        [reattest ? "reattested_batch" : "merged_batch"]: batchId,
        records: output.length,
        attestation: attestation.id,
        screening: countBy(output, (row) => row.screening_status),
        extraction: countBy(output, (row) => row.extraction_status),
      },
      null,
      2,
    ),
  );
}

const command = process.argv[2];
try {
  switch (command) {
    case "baseline":
      baseline();
      break;
    case "validate":
      validate();
      break;
    case "summarize":
      summarize();
      break;
    case "shard":
      shard();
      break;
    case "merge-screening":
      mergeScreening();
      break;
    case "repair-queue":
      buildRepairQueue();
      break;
    case "validate-repairs":
      validateRepairOverlays();
      break;
    default:
      console.error(
        "Usage: node scripts/corpus_certification.mjs <baseline|validate|summarize|shard|merge-screening|repair-queue|validate-repairs> [--size=25] [--max-weight=120] [--batch=screening-0001] [--attestation=id] [--reattest]",
      );
      process.exitCode = 2;
  }
} catch (error) {
  console.error(error?.stack ?? String(error));
  process.exitCode = 1;
}
