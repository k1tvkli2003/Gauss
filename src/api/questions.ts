import { supabase } from "@/lib/supabase";
import { requestTimeout } from "@/lib/net";
import type { Difficulty, ExamConfig, Question, Subject } from "@/types";

/** Fetch a randomized set of questions matching an exam config. */
export async function fetchExamQuestions(config: ExamConfig): Promise<Question[]> {
  let query = supabase
    .from("gauss_questions")
    .select("*")
    .eq("subject", config.subject);

  if (config.categories.length > 0) {
    query = query.in("category", config.categories);
  }
  if (config.subCategories.length > 0) {
    query = query.in("sub_category", config.subCategories);
  }
  if (config.difficulties.length > 0) {
    query = query.in("difficulty", config.difficulties);
  }

  // Over-fetch then shuffle client-side for variety (dataset is small).
  const { signal, clear } = requestTimeout();
  try {
    const { data, error } = await query.limit(200).abortSignal(signal);
    if (error) throw error;
    const shuffled = shuffle(data as Question[]);
    return shuffled.slice(0, config.count);
  } finally {
    clear();
  }
}

export async function fetchQuestionsByIds(ids: string[]): Promise<Question[]> {
  if (ids.length === 0) return [];
  const { signal, clear } = requestTimeout();
  try {
    const { data, error } = await supabase
      .from("gauss_questions")
      .select("*")
      .in("id", ids)
      .abortSignal(signal);
    if (error) throw error;
    return data as Question[];
  } finally {
    clear();
  }
}

/** How many questions exist per category — used to validate exam setup. */
export async function fetchAvailability(
  subject: Subject,
): Promise<Record<string, number>> {
  const { data, error } = await supabase
    .from("gauss_questions")
    .select("category")
    .eq("subject", subject);
  if (error) throw error;
  const counts: Record<string, number> = {};
  for (const row of data as { category: string }[]) {
    counts[row.category] = (counts[row.category] ?? 0) + 1;
  }
  return counts;
}

export function difficultyList(): Difficulty[] {
  return ["above_average", "hard", "very_hard", "olympiad"];
}

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
