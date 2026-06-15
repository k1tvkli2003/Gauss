import type { SkPath } from "@shopify/react-native-skia";

export type Subject = "math" | "physics";

export type Difficulty = "above_average" | "hard" | "very_hard" | "olympiad";

export type AttemptStatus = "correct" | "wrong" | "skipped";

export interface Question {
  id: string;
  subject: Subject;
  category: string;
  sub_category: string | null;
  difficulty: Difficulty;
  question_text: string;
  image_url: string | null;
  option_1: string;
  option_2: string;
  option_3: string;
  option_4: string;
  correct_option_index: number; // 1..4
  classic_solution: string;
  smart_shortcut: string | null;
  source: string;
  created_at: string;
}

export interface ExamConfig {
  subject: Subject;
  categories: string[];
  subCategories: string[];
  difficulties: Difficulty[];
  count: number;
}

/** A single committed stroke on the scratchpad canvas. */
export interface ScratchStroke {
  path: SkPath;
  color: string;
  width: number;
}

export interface AttemptResult {
  question: Question;
  status: AttemptStatus;
  selectedOption: number | null; // 1..4
  timeTakenSeconds: number;
}

export interface ExamHistoryRow {
  id: string;
  profile_id: string;
  config: ExamConfig | null;
  total_questions: number;
  correct_count: number;
  wrong_count: number;
  skipped_count: number;
  score_percentage: number;
  duration_seconds: number | null;
  created_at: string;
}

export interface UserHistoryRow {
  id: string;
  profile_id: string;
  exam_id: string | null;
  question_id: string;
  status: AttemptStatus;
  selected_option: number | null;
  time_taken_seconds: number | null;
  solved_at: string;
}

// Konkur standard time budget per question (seconds).
export const KONKUR_SECONDS_PER_QUESTION = 70;
