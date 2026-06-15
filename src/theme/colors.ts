import type { Difficulty, Subject } from "@/types";

export const colors = {
  bg: "#0B0F14",
  surface: "#11161D",
  card: "#171E27",
  raised: "#1F2832",
  border: "#2A3744",
  text: "#E6EDF3",
  // Lifted from #7B8794 to pass WCAG AA (~5.3:1) on card surfaces.
  muted: "#9AA6B2",
  neonBlue: "#3DD3FF",
  neonPurple: "#A06BFF",
  neonGreen: "#3DFF99",
  neonAmber: "#FFC23D",
  neonRed: "#FF5C72",
} as const;

export const difficultyMeta: Record<
  Difficulty,
  { label: string; faLabel: string; color: string }
> = {
  above_average: { label: "Above Avg", faLabel: "بالاتر از متوسط", color: colors.neonGreen },
  hard: { label: "Hard", faLabel: "سخت", color: colors.neonBlue },
  very_hard: { label: "Very Hard", faLabel: "خیلی سخت", color: colors.neonAmber },
  olympiad: { label: "Olympiad", faLabel: "المپیادی", color: colors.neonRed },
};

export const subjectMeta: Record<Subject, { label: string; faLabel: string; color: string }> = {
  math: { label: "Math", faLabel: "ریاضی", color: colors.neonPurple },
  physics: { label: "Physics", faLabel: "فیزیک", color: colors.neonBlue },
};
