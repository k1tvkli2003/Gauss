#!/usr/bin/env node
// Convert the current official-course bank to the 29-topic v2 comprehensive taxonomy.

import fs from "node:fs";
import path from "node:path";
import { isValidTopic } from "./comprehensive_taxonomy.mjs";

const SOURCE = "data/seed/official";
const OUT = "data/seed/comprehensive/gauss";
const REVIEW = "data/seed/review/comprehensive_classification.json";

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const target = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(target) : entry.name.endsWith(".json") ? [target] : [];
  });
}

const direct = new Map(Object.entries({
  trigonometry: "trigonometry",
  trigonometry_advanced: "trigonometry",
  trigonometry_period_equations: "trigonometry",
  rational_powers_algebraic_expressions: "radicals_algebraic_expressions",
  functions_domain_range: "functions",
  functions_inverse_operations: "functions",
  functions_monotonic_composition: "functions",
  counting_without_counting: "combinatorics",
  geometry: "geometry",
  exponential_logarithmic: "exponential_logarithmic",
  limits_continuity: "limits_continuity",
  infinite_limits: "limits_continuity",
  derivatives: "derivatives",
  derivative_applications: "derivative_applications",
  geometry_conics_circle: "visual_thinking_conics",
  total_probability: "probability",
  physics_measurement: "physics_measurement",
  physical_properties_matter: "physical_properties_matter",
  work_energy_power: "work_energy_power",
  temperature_heat: "temperature_heat",
  electrostatics: "electrostatics",
  current_electricity: "current_electricity",
  magnetism_induction: "magnetism_induction",
  kinematics: "one_dimensional_motion",
  dynamics_circular_motion: "dynamics",
  oscillation_waves: "oscillation_waves",
  atomic_nuclear: "atomic_nuclear",
}));

const has = (text, pattern) => pattern.test(text);

function classify(q) {
  const old = q.sub_category;
  const text = [q.question_text, q.classic_solution, q.smart_shortcut].join(" ").replaceAll("ي", "ی");
  if (direct.has(old)) return { topic: direct.get(old), confidence: "direct" };
  if (old === "sets_patterns_sequences") {
    const setLike = has(text, /مجموعه|اشتراک|اجتماع|عضو|زیرمجموعه|\bA\\|\\cup|\\cap/);
    return { topic: setLike ? "sets" : "patterns_sequences", confidence: setLike ? "heuristic" : "review" };
  }
  if (old === "statistics_probability") {
    const probability = has(text, /احتمال|پیشامد|فضای نمونه|تاس|سکه|کارت|مهره/);
    return { topic: probability ? "probability" : "statistics", confidence: "heuristic" };
  }
  if (old === "analytic_geometry_algebra") {
    if (has(text, /مختصات|شیب|معادله خط|فاصله.*نقطه|محورهای مختصات/)) return { topic: "analytic_geometry", confidence: "heuristic" };
    if (has(text, /درجه دوم|دلتا|سهمی|ریشه.*معادله|مميز/)) return { topic: "quadratic_equations_functions", confidence: "heuristic" };
    return { topic: "rational_inequalities_sign", confidence: "review" };
  }
  if (old === "equations_inequalities") {
    if (has(text, /قدر مطلق|جزء صحیح|کف|\\lfloor|\[x\]/)) return { topic: "absolute_value_floor", confidence: "heuristic" };
    if (has(text, /درجه دوم|دلتا|سهمی|ریشه.*معادله|مميز/)) return { topic: "quadratic_equations_functions", confidence: "heuristic" };
    return { topic: "rational_inequalities_sign", confidence: "review" };
  }
  return { topic: q.subject === "math" ? "functions" : "physics_measurement", confidence: "review" };
}

function textBlock(text) {
  return [{ type: "text", text: String(text ?? "").trim() }];
}

const buckets = new Map();
const review = [];
for (const file of walk(SOURCE).sort()) {
  const rows = JSON.parse(fs.readFileSync(file, "utf8"));
  for (const q of rows) {
    const result = classify(q);
    if (!isValidTopic(q.subject, result.topic)) throw new Error(`Invalid mapping ${q.id} -> ${q.subject}/${result.topic}`);
    const stem = textBlock(q.question_text);
    if (q.image_url) stem.push({ type: "image", asset: q.image_url, alt: "شکل سؤال" });
    const converted = {
      id: q.id,
      subject: q.subject,
      topic_key: result.topic,
      difficulty: q.difficulty,
      stem,
      options: [q.option_1, q.option_2, q.option_3, q.option_4].map(textBlock),
      correct_option_index: q.correct_option_index,
      solution: textBlock(q.classic_solution),
      smart_shortcut: q.smart_shortcut ? textBlock(q.smart_shortcut) : null,
      source_bank: "gauss",
      provenance: {
        kind: q.source?.startsWith("reclassified:") ? "existing" : "generated",
        edition: "gauss_pre_nardebam_v2",
        question_number: null,
        question_pdf: null,
        question_page: null,
        solution_page: null,
        solution_origin: "existing"
      }
    };
    const key = `${q.subject}/${result.topic}`;
    if (!buckets.has(key)) buckets.set(key, []);
    buckets.get(key).push(converted);
    if (result.confidence === "review") review.push({ id: q.id, subject: q.subject, old_course: q.category, old_chapter: q.sub_category, proposed_topic: result.topic, question_text: q.question_text });
  }
}

fs.rmSync(OUT, { recursive: true, force: true });
for (const [key, rows] of [...buckets.entries()].sort()) {
  const file = path.join(OUT, `${key}.json`);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(rows, null, 2)}\n`, "utf8");
}
fs.mkdirSync(path.dirname(REVIEW), { recursive: true });
fs.writeFileSync(REVIEW, `${JSON.stringify(review, null, 2)}\n`, "utf8");
console.log(`Converted ${[...buckets.values()].reduce((sum, rows) => sum + rows.length, 0)} Gauss questions into ${buckets.size} topic shards.`);
console.log(`${review.length} classification(s) require Jules adjudication -> ${REVIEW}`);
