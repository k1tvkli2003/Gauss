#!/usr/bin/env node
// Reclassify the legacy topic-oriented seed bank into the official
// experimental-sciences course/chapter taxonomy. Legacy files are left intact;
// generated official files become the only merge source.

import fs from "node:fs";
import crypto from "node:crypto";
import path from "node:path";
import { isValidTopic } from "./curriculum.mjs";

const LEGACY_ROOT = "data/seed";
const OFFICIAL_ROOT = "data/seed/official";
const QUARANTINE_ROOT = "data/seed/quarantine";

function walk(dir) {
  let out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (["official", "quarantine"].includes(entry.name)) continue;
      out = out.concat(walk(p));
    } else if (entry.name.endsWith(".json")) {
      out.push(p);
    }
  }
  return out;
}

function stableId(q) {
  if (q.id) return q.id;
  const basis = [
    q.subject, q.category, q.sub_category ?? "", q.question_text,
    q.option_1, q.option_2, q.option_3, q.option_4,
  ].join("");
  return crypto.createHash("sha1").update(basis).digest("hex").slice(0, 24);
}

function textOf(q) {
  return [
    q.question_text,
    q.classic_solution,
    q.smart_shortcut,
    q.option_1,
    q.option_2,
    q.option_3,
    q.option_4,
  ].filter(Boolean).join(" ");
}

function hasAny(text, needles) {
  return needles.some((needle) => text.includes(needle));
}

function classify(q) {
  const subject = q.subject;
  const category = q.category;
  const sub = q.sub_category;
  const text = textOf(q);

  if (subject === "math") {
    if (category === "hesaban") {
      if (sub === "limits") {
        if (hasAny(text, ["\\infty", "∞", "بی‌نهایت", "بینهایت"])) return ["math_12", "infinite_limits"];
        return ["math_11", "limits_continuity"];
      }
      if (sub === "derivatives") {
        if (hasAny(text, ["اکسترمم", "بیشینه", "کمینه", "ماکسیمم", "مینیمم", "بهینه"])) {
          return ["math_12", "derivative_applications"];
        }
        return ["math_12", "derivatives"];
      }
      if (sub === "functions") {
        if (hasAny(text, ["لگاریتم", "\\log", "نمایی", "exponential"])) return ["math_11", "exponential_logarithmic"];
        if (hasAny(text, ["وارون", "معکوس", "اعمال جبری"])) return ["math_11", "functions_inverse_operations"];
        if (hasAny(text, ["صعودی", "نزولی", "ترکیب"])) return ["math_12", "functions_monotonic_composition"];
        return ["math_10", "functions_domain_range"];
      }
      if (sub === "trigonometry") {
        if (hasAny(text, ["تناوب", "دوره", "معادله"])) return ["math_12", "trigonometry_period_equations"];
        if (hasAny(text, ["توابع مثلثاتی", "رابطه", "تکمیلی"])) return ["math_11", "trigonometry_advanced"];
        return ["math_10", "trigonometry"];
      }
      if (sub === "integrals") return null;
    }

    if (category === "hendeseh") {
      if (["analytical", "analytical_geometry"].includes(sub)) return ["math_11", "analytic_geometry_algebra"];
      if (sub === "circle" || sub === "conics") return ["math_12", "geometry_conics_circle"];
      if (["spatial", "spatial_geometry"].includes(sub)) return null;
    }

    if (category === "gosasteh_amar") {
      if (sub === "combinatorics") return ["math_10", "counting_without_counting"];
      if (sub === "statistics") return ["math_10", "statistics_probability"];
      if (sub === "probability") {
        if (hasAny(text, ["احتمال کل", "کل"])) return ["math_12", "total_probability"];
        return ["math_10", "statistics_probability"];
      }
      if (["discrete", "number_theory"].includes(sub)) return null;
    }
  }

  if (subject === "physics") {
    if (category === "mechanics") {
      if (sub === "kinematics") return ["physics_12", "kinematics"];
      if (sub === "dynamics") return ["physics_12", "dynamics_circular_motion"];
      if (sub === "work_energy") return ["physics_10", "work_energy_power"];
      if (sub === "momentum") return null;
    }

    if (category === "electromagnetism") {
      if (sub === "electrostatics") return ["physics_11", "electrostatics"];
      if (sub === "circuits") return ["physics_11", "current_electricity"];
      if (sub === "magnetism" || sub === "induction") return ["physics_11", "magnetism_induction"];
    }

    if (category === "thermodynamics") {
      if (sub === "fluids") return ["physics_10", "physical_properties_matter"];
      if (sub === "heat" || sub === "gas_laws") return ["physics_10", "temperature_heat"];
    }

    if (category === "waves_modern") {
      if (sub === "oscillations" || sub === "waves") return ["physics_12", "oscillation_waves"];
      if (sub === "modern") return ["physics_12", "atomic_nuclear"];
      if (sub === "optics") return null;
    }
  }

  return null;
}

function normalizedQuestion(q, file) {
  const mapped = classify(q);
  if (!mapped) return null;
  const [course, chapter] = mapped;
  if (!isValidTopic(q.subject, course, chapter)) return null;

  const correctOption = Number(q.correct_option_index);
  const correctText = q[`option_${correctOption}`] ?? "";
  const classic = q.classic_solution?.trim() || (
    `راه‌حل منبع برای این سؤال ناقص بود؛ برای حفظ سلامت دیتاست، پاسخ درست از کلید اولیه بازسازی شد. ` +
    `گزینهٔ ${correctOption} یعنی ${correctText} پاسخ ثبت‌شدهٔ این تست است.`
  );

  return {
    id: stableId(q),
    subject: q.subject,
    category: course,
    sub_category: chapter,
    difficulty: q.difficulty,
    question_text: q.question_text,
    image_url: q.image_url ?? null,
    option_1: q.option_1,
    option_2: q.option_2,
    option_3: q.option_3,
    option_4: q.option_4,
    correct_option_index: correctOption,
    classic_solution: classic,
    smart_shortcut: q.smart_shortcut ?? null,
    source: q.source ?? `reclassified:${file.replaceAll("\\", "/")}`,
  };
}

function resetGeneratedDir(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
}

resetGeneratedDir(OFFICIAL_ROOT);
resetGeneratedDir(QUARANTINE_ROOT);

const grouped = new Map();
const quarantined = [];
const files = walk(LEGACY_ROOT).sort();

for (const file of files) {
  const arr = JSON.parse(fs.readFileSync(file, "utf8"));
  arr.forEach((q, index) => {
    const item = normalizedQuestion(q, file);
    if (item) {
      const groupKey = `${item.category}_${item.sub_category}`;
      if (!grouped.has(groupKey)) grouped.set(groupKey, []);
      grouped.get(groupKey).push(item);
    } else {
      quarantined.push({
        id: stableId(q),
        source_file: file.replaceAll("\\", "/"),
        source_index: index,
        reason: "outside_experimental_curriculum_or_unmapped",
        ...q,
      });
    }
  });
}

for (const [groupKey, rows] of [...grouped.entries()].sort(([a], [b]) => a.localeCompare(b))) {
  rows.sort((a, b) => a.id.localeCompare(b.id));
  fs.writeFileSync(
    path.join(OFFICIAL_ROOT, `${groupKey}.json`),
    JSON.stringify(rows, null, 2),
  );
}

fs.writeFileSync(
  path.join(QUARANTINE_ROOT, "legacy_unmapped.json"),
  JSON.stringify(quarantined, null, 2),
);

const officialCount = [...grouped.values()].reduce((sum, rows) => sum + rows.length, 0);
console.log(`Reclassified ${officialCount} official questions into ${grouped.size} files.`);
console.log(`Quarantined ${quarantined.length} legacy questions in ${QUARANTINE_ROOT}/legacy_unmapped.json.`);
