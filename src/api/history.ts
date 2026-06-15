import { supabase } from "@/lib/supabase";
import { getProfileId } from "@/lib/profile";
import type {
  AttemptResult,
  ExamConfig,
  ExamHistoryRow,
  Subject,
  UserHistoryRow,
} from "@/types";

/** Persist a finished exam + every attempt. Returns the exam id. */
export async function saveExam(
  config: ExamConfig,
  results: AttemptResult[],
  durationSeconds: number,
): Promise<string> {
  const profileId = await getProfileId();

  const correct = results.filter((r) => r.status === "correct").length;
  const wrong = results.filter((r) => r.status === "wrong").length;
  const skipped = results.filter((r) => r.status === "skipped").length;
  const total = results.length;
  const score = total > 0 ? (correct / total) * 100 : 0;

  const { data: exam, error: examErr } = await supabase
    .from("gauss_exams_history")
    .insert({
      profile_id: profileId,
      config,
      total_questions: total,
      correct_count: correct,
      wrong_count: wrong,
      skipped_count: skipped,
      score_percentage: Number(score.toFixed(2)),
      duration_seconds: durationSeconds,
    })
    .select("id")
    .single();
  if (examErr) throw examErr;

  const examId = (exam as { id: string }).id;

  const rows = results.map((r) => ({
    profile_id: profileId,
    exam_id: examId,
    question_id: r.question.id,
    status: r.status,
    selected_option: r.selectedOption,
    time_taken_seconds: r.timeTakenSeconds,
  }));

  const { error: histErr } = await supabase.from("gauss_user_history").insert(rows);
  if (histErr) throw histErr;

  return examId;
}

export async function fetchExamHistory(limit = 30): Promise<ExamHistoryRow[]> {
  const profileId = await getProfileId();
  const { data, error } = await supabase
    .from("gauss_exams_history")
    .select("*")
    .eq("profile_id", profileId)
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data as ExamHistoryRow[];
}

/** Distinct question ids the user got wrong or skipped (for Revenge Mode). */
export async function fetchRevengeQuestionIds(): Promise<string[]> {
  const profileId = await getProfileId();
  const { data, error } = await supabase
    .from("gauss_user_history")
    .select("question_id, status, solved_at")
    .eq("profile_id", profileId)
    .in("status", ["wrong", "skipped"])
    .order("solved_at", { ascending: false });
  if (error) throw error;

  // A question is "redeemed" once its most recent attempt is correct, so we
  // also pull recent correct attempts and exclude those.
  const { data: correctData, error: cErr } = await supabase
    .from("gauss_user_history")
    .select("question_id, solved_at")
    .eq("profile_id", profileId)
    .eq("status", "correct");
  if (cErr) throw cErr;

  const latestCorrect = new Map<string, string>();
  for (const r of correctData as { question_id: string; solved_at: string }[]) {
    const prev = latestCorrect.get(r.question_id);
    if (!prev || r.solved_at > prev) latestCorrect.set(r.question_id, r.solved_at);
  }

  const result: string[] = [];
  const seen = new Set<string>();
  for (const r of data as { question_id: string; solved_at: string }[]) {
    if (seen.has(r.question_id)) continue;
    seen.add(r.question_id);
    const redeemedAt = latestCorrect.get(r.question_id);
    if (redeemedAt && redeemedAt > r.solved_at) continue;
    result.push(r.question_id);
  }
  return result;
}

export interface TopicStat {
  category: string;
  subject: Subject;
  total: number;
  correct: number;
  accuracy: number;
  avgTime: number;
}

/** A wrong-answer trap the user repeatedly falls for. */
export interface DistractorStat {
  category: string;
  subject: Subject;
  option: number; // 1..4
  count: number;
}

export interface Analytics {
  totalAnswered: number;
  totalCorrect: number;
  accuracy: number;
  avgTime: number;
  weakTopics: TopicStat[];
  distractors: DistractorStat[];
  heatmap: Record<string, number>; // 'YYYY-MM-DD' -> attempts
}

/** Aggregate everything the analytics screen + heatmap need. */
export async function fetchAnalytics(): Promise<Analytics> {
  const profileId = await getProfileId();

  const { data: history, error } = await supabase
    .from("gauss_user_history")
    .select("status, time_taken_seconds, solved_at, question_id, selected_option")
    .eq("profile_id", profileId);
  if (error) throw error;
  const rows = history as Pick<
    UserHistoryRow,
    "status" | "time_taken_seconds" | "solved_at" | "question_id" | "selected_option"
  >[];

  // Join subject + category for weak-topic and distractor analysis.
  const qIds = [...new Set(rows.map((r) => r.question_id))];
  const catByQ = new Map<string, string>();
  const subjByQ = new Map<string, Subject>();
  if (qIds.length > 0) {
    const { data: qs } = await supabase
      .from("gauss_questions")
      .select("id, category, subject")
      .in("id", qIds);
    for (const q of (qs ?? []) as { id: string; category: string; subject: Subject }[]) {
      catByQ.set(q.id, q.category);
      subjByQ.set(q.id, q.subject);
    }
  }

  const totalAnswered = rows.length;
  const totalCorrect = rows.filter((r) => r.status === "correct").length;
  const timed = rows.filter((r) => (r.time_taken_seconds ?? 0) > 0);
  const avgTime =
    timed.length > 0
      ? timed.reduce((s, r) => s + (r.time_taken_seconds ?? 0), 0) / timed.length
      : 0;

  const byCat = new Map<
    string,
    { subject: Subject; total: number; correct: number; time: number }
  >();
  for (const r of rows) {
    const cat = catByQ.get(r.question_id) ?? "unknown";
    const subject = subjByQ.get(r.question_id) ?? "math";
    const e = byCat.get(cat) ?? { subject, total: 0, correct: 0, time: 0 };
    e.total += 1;
    if (r.status === "correct") e.correct += 1;
    e.time += r.time_taken_seconds ?? 0;
    byCat.set(cat, e);
  }
  const weakTopics: TopicStat[] = [...byCat.entries()]
    .map(([category, e]) => ({
      category,
      subject: e.subject,
      total: e.total,
      correct: e.correct,
      accuracy: e.total > 0 ? (e.correct / e.total) * 100 : 0,
      avgTime: e.total > 0 ? e.time / e.total : 0,
    }))
    .sort((a, b) => a.accuracy - b.accuracy);

  // Distractor traps: which wrong option you repeatedly pick, by topic.
  const byTrap = new Map<string, DistractorStat>();
  for (const r of rows) {
    if (r.status !== "wrong" || r.selected_option == null) continue;
    const category = catByQ.get(r.question_id) ?? "unknown";
    const subject = subjByQ.get(r.question_id) ?? "math";
    const key = `${category}|${r.selected_option}`;
    const e = byTrap.get(key) ?? { category, subject, option: r.selected_option, count: 0 };
    e.count += 1;
    byTrap.set(key, e);
  }
  const distractors: DistractorStat[] = [...byTrap.values()]
    .filter((d) => d.count >= 2)
    .sort((a, b) => b.count - a.count)
    .slice(0, 6);

  const heatmap: Record<string, number> = {};
  for (const r of rows) {
    const day = r.solved_at.slice(0, 10);
    heatmap[day] = (heatmap[day] ?? 0) + 1;
  }

  return {
    totalAnswered,
    totalCorrect,
    accuracy: totalAnswered > 0 ? (totalCorrect / totalAnswered) * 100 : 0,
    avgTime,
    weakTopics,
    distractors,
    heatmap,
  };
}
