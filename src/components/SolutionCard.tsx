import React from "react";
import { Text, View } from "react-native";
import { colors } from "@/theme/colors";
import { KONKUR_SECONDS_PER_QUESTION } from "@/types";
import type { AttemptResult } from "@/types";
import { toFa } from "@/lib/format";
import { DifficultyBadge } from "./DifficultyBadge";
import { MathText } from "./MathText";
import { OptionButton } from "./OptionButton";
import { GeniusKey } from "./GeniusKey";

const STATUS_META = {
  correct: { label: "درست", color: colors.neonGreen, glyph: "✓" },
  wrong: { label: "غلط", color: colors.neonRed, glyph: "✕" },
  skipped: { label: "نزده", color: colors.neonAmber, glyph: "–" },
} as const;

/** One reviewed question: verdict, options revealed, classic solution + shortcut. */
export function SolutionCard({ result, number }: { result: AttemptResult; number: number }) {
  const { question: q, status, selectedOption, timeTakenSeconds } = result;
  const meta = STATUS_META[status];
  const options = [q.option_1, q.option_2, q.option_3, q.option_4];
  const overTime = timeTakenSeconds > KONKUR_SECONDS_PER_QUESTION;

  return (
    <View className="mb-4 rounded-2xl border border-ink-500 bg-ink-800 p-4">
      {/* Verdict header */}
      <View className="mb-3 flex-row-reverse items-center justify-between">
        <View className="flex-row-reverse items-center gap-3">
          <Text style={{ color: colors.muted }} className="text-sm font-bold">
            سؤال {toFa(number)}
          </Text>
          <DifficultyBadge difficulty={q.difficulty} />
        </View>
        <View
          style={{ backgroundColor: `${meta.color}1A`, borderColor: meta.color }}
          className="flex-row items-center rounded-full border px-3 py-1"
        >
          <Text style={{ color: meta.color }} className="text-xs font-bold">
            {meta.glyph} {meta.label}
          </Text>
        </View>
      </View>

      {/* Time vs Konkur budget */}
      <View className="mb-3 flex-row-reverse items-center gap-2">
        <Text style={{ color: overTime ? colors.neonAmber : colors.neonGreen }} className="text-xs">
          ⏱ {toFa(timeTakenSeconds)}s
        </Text>
        <Text style={{ color: colors.muted }} className="text-xs">
          (استاندارد کنکور: {toFa(KONKUR_SECONDS_PER_QUESTION)}s){overTime ? " — کندتر از حد مجاز" : " — در زمان مجاز"}
        </Text>
      </View>

      {/* Question */}
      <View className="mb-4 rounded-xl border border-ink-500 bg-ink-900 p-3">
        <MathText content={q.question_text} fontSize={16} />
      </View>

      {/* Options revealed */}
      {options.map((opt, i) => (
        <OptionButton
          key={i}
          index={i + 1}
          text={opt}
          selected={selectedOption === i + 1}
          reveal
          correct={q.correct_option_index === i + 1}
        />
      ))}

      {/* Genius answer key */}
      <View className="mt-3">
        <GeniusKey classic={q.classic_solution} shortcut={q.smart_shortcut} />
      </View>
    </View>
  );
}
