import { create } from "zustand";
import type {
  AttemptResult,
  AttemptStatus,
  ExamConfig,
  Question,
  ScratchStroke,
} from "@/types";
import { saveExam } from "@/api/history";

interface ExamState {
  config: ExamConfig | null;
  questions: Question[];
  index: number;
  // attempts keyed by question index
  attempts: Record<number, AttemptResult>;
  // scratchpad strokes keyed by question index (survives navigation)
  scratch: Record<number, ScratchStroke[]>;
  questionStartedAt: number;
  examStartedAt: number;
  finished: boolean;
  savedExamId: string | null;
  saving: boolean;

  startExam: (config: ExamConfig, questions: Question[]) => void;
  answer: (selectedOption: number) => void;
  skip: () => void;
  next: () => void;
  prev: () => void;
  goTo: (index: number) => void;
  setScratch: (index: number, strokes: ScratchStroke[]) => void;
  finishAndSave: () => Promise<void>;
  reset: () => void;

  // selectors
  current: () => Question | null;
  results: () => AttemptResult[];
  answeredCount: () => number;
}

function record(
  state: ExamState,
  status: AttemptStatus,
  selectedOption: number | null,
): Record<number, AttemptResult> {
  const q = state.questions[state.index];
  if (!q) return state.attempts;
  const timeTaken = Math.max(
    1,
    Math.round((Date.now() - state.questionStartedAt) / 1000),
  );
  return {
    ...state.attempts,
    [state.index]: { question: q, status, selectedOption, timeTakenSeconds: timeTaken },
  };
}

export const useExamStore = create<ExamState>((set, get) => ({
  config: null,
  questions: [],
  index: 0,
  attempts: {},
  scratch: {},
  questionStartedAt: 0,
  examStartedAt: 0,
  finished: false,
  savedExamId: null,
  saving: false,

  startExam: (config, questions) =>
    set({
      config,
      questions,
      index: 0,
      attempts: {},
      scratch: {},
      questionStartedAt: Date.now(),
      examStartedAt: Date.now(),
      finished: false,
      savedExamId: null,
      saving: false,
    }),

  answer: (selectedOption) => {
    const state = get();
    const q = state.questions[state.index];
    if (!q) return;
    const status: AttemptStatus =
      selectedOption === q.correct_option_index ? "correct" : "wrong";
    set({ attempts: record(state, status, selectedOption) });
  },

  skip: () => {
    const state = get();
    // Don't overwrite a real answer with a skip.
    if (state.attempts[state.index]) return;
    set({ attempts: record(state, "skipped", null) });
  },

  next: () => {
    const state = get();
    if (state.index < state.questions.length - 1) {
      set({ index: state.index + 1, questionStartedAt: Date.now() });
    }
  },

  prev: () => {
    const state = get();
    if (state.index > 0) {
      set({ index: state.index - 1, questionStartedAt: Date.now() });
    }
  },

  goTo: (index) => {
    const state = get();
    if (index >= 0 && index < state.questions.length) {
      set({ index, questionStartedAt: Date.now() });
    }
  },

  setScratch: (index, strokes) => {
    const state = get();
    set({ scratch: { ...state.scratch, [index]: strokes } });
  },

  finishAndSave: async () => {
    const state = get();
    if (state.saving || state.savedExamId) return;
    set({ saving: true });

    // Any unanswered question counts as skipped.
    const attempts = { ...state.attempts };
    state.questions.forEach((q, i) => {
      if (!attempts[i]) {
        attempts[i] = {
          question: q,
          status: "skipped",
          selectedOption: null,
          timeTakenSeconds: 0,
        };
      }
    });

    const results = Object.keys(attempts)
      .map(Number)
      .sort((a, b) => a - b)
      .map((i) => attempts[i]);

    const duration = Math.round((Date.now() - state.examStartedAt) / 1000);

    try {
      const id = await saveExam(state.config!, results, duration);
      set({ attempts, finished: true, savedExamId: id, saving: false });
    } catch (e) {
      // Still let the user see results even if the save failed.
      set({ attempts, finished: true, saving: false });
      throw e;
    }
  },

  reset: () =>
    set({
      config: null,
      questions: [],
      index: 0,
      attempts: {},
      scratch: {},
      questionStartedAt: 0,
      examStartedAt: 0,
      finished: false,
      savedExamId: null,
      saving: false,
    }),

  current: () => {
    const s = get();
    return s.questions[s.index] ?? null;
  },

  results: () => {
    const s = get();
    return Object.keys(s.attempts)
      .map(Number)
      .sort((a, b) => a - b)
      .map((i) => s.attempts[i]);
  },

  answeredCount: () => {
    const s = get();
    return Object.values(s.attempts).filter((a) => a.status !== "skipped").length;
  },
}));
