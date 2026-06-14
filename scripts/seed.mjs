#!/usr/bin/env node
/**
 * Bulk-load question JSON files into Supabase.
 *
 * Reads every *.json file in data/seed/ (each an array of question objects
 * matching the gauss_questions schema) and upserts them via the service role.
 *
 * Usage:
 *   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node scripts/seed.mjs
 *   # or put them in .env (gitignored) and: npm run seed
 */
import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createClient } from "@supabase/supabase-js";
import "dotenv/config";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED_DIR = join(__dirname, "..", "data", "seed");

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !key) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars.");
  process.exit(1);
}

const supabase = createClient(url, key, { auth: { persistSession: false } });

const REQUIRED = [
  "subject",
  "category",
  "difficulty",
  "question_text",
  "option_1",
  "option_2",
  "option_3",
  "option_4",
  "correct_option_index",
  "classic_solution",
];

function validate(q, file, i) {
  for (const f of REQUIRED) {
    if (q[f] === undefined || q[f] === null || q[f] === "") {
      throw new Error(`${file}[${i}]: missing required field "${f}"`);
    }
  }
  if (!["math", "physics"].includes(q.subject))
    throw new Error(`${file}[${i}]: bad subject "${q.subject}"`);
  if (q.correct_option_index < 1 || q.correct_option_index > 4)
    throw new Error(`${file}[${i}]: correct_option_index must be 1..4`);
}

async function main() {
  const files = (await readdir(SEED_DIR)).filter((f) => f.endsWith(".json"));
  let total = 0;

  for (const file of files) {
    const raw = await readFile(join(SEED_DIR, file), "utf8");
    const rows = JSON.parse(raw);
    rows.forEach((q, i) => validate(q, file, i));

    const payload = rows.map((q) => ({
      subject: q.subject,
      category: q.category,
      sub_category: q.sub_category ?? null,
      difficulty: q.difficulty,
      question_text: q.question_text,
      image_url: q.image_url ?? null,
      option_1: q.option_1,
      option_2: q.option_2,
      option_3: q.option_3,
      option_4: q.option_4,
      correct_option_index: q.correct_option_index,
      classic_solution: q.classic_solution,
      smart_shortcut: q.smart_shortcut ?? null,
      source: q.source ?? "jules",
    }));

    const { error } = await supabase.from("gauss_questions").insert(payload);
    if (error) {
      console.error(`✗ ${file}: ${error.message}`);
      process.exitCode = 1;
    } else {
      total += payload.length;
      console.log(`✓ ${file}: inserted ${payload.length}`);
    }
  }
  console.log(`\nDone. ${total} questions inserted.`);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
