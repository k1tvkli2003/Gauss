import React, { useState } from "react";
import { Pressable, Text, View } from "react-native";
import { colors } from "@/theme/colors";
import { KONKUR_SECONDS_PER_QUESTION } from "@/types";
import type { AttemptResult } from "@/types";
import { DifficultyBadge } from "./DifficultyBadge";
import { MathText } from "./MathText";
import { OptionButton } from "./OptionButton";

const STATUS_META = {
  correct: { label: "درست", color: colors.neonGreen, glyph: "✓" },
  wrong: { label: "غلط", color: colors.neonRed, glyph: "✕" },
  skipped: { label: "نزده", color: colors.neonAmber, glyph: "–" },
} as const;

/** One reviewed question: verdict, options revealed, classic solution + shortcut. */
export function SolutionCard({ result, number }: { result: AttemptResult; number: number }) {
  const { question: q, status, selectedOption, timeTakenSeconds } = result;
  const [tab, setTab] = useState<"classic" | "shortcut">("classic");
  const meta = STATUS_META[status];
  const options = [q.option_1, q.option_2, q.option_3, q.option_4];
  const overTime = timeTakenSeconds > KONKUR_SECONDS_PER_QUESTION;

  return (
    <View className="mb-4 rounded-2xl border border-ink-500 bg-ink-800 p-4">
      {/* Verdict header */}
      <View className="mb-3 flex-row-reverse items-center justify-between">
        <View className="flex-row-reverse items-center gap-3">
          <Text style={{ color: colors.muted }} className="text-sm font-bold">
            سؤال {number}
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
          ⏱ {timeTakenSeconds}s
        </Text>
        <Text style={{ color: colors.muted }} className="text-xs">
          (استاندارد کنکور: {KONKUR_SECONDS_PER_QUESTION}s){overTime ? " — کندتر از حد مجاز" : " — در زمان مجاز"}
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
      <View className="mt-3 flex-row gap-2">
        <TabBtn
          label="حل تشریحی"
          active={tab === "classic"}
          color={colors.neonBlue}
          onPress={() => setTab("classic")}
        />
        {q.smart_shortcut ? (
          <TabBtn
            label="⚡ راه تستی"
            active={tab === "shortcut"}
            color={colors.neonPurple}
            onPress={() => setTab("shortcut")}
          />
        ) : null}
      </View>

      <View
        style={{
          borderColor: tab === "classic" ? colors.neonBlue : colors.neonPurple,
        }}
        className="mt-3 rounded-xl border bg-ink-900 p-4"
      >
        <MathText
          content={tab === "classic" ? q.classic_solution : q.smart_shortcut ?? ""}
          fontSize={15}
        />
      </View>
    </View>
  );
}

function TabBtn({
  label,
  active,
  color,
  onPress,
}: {
  label: string;
  active: boolean;
  color: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={{
        borderColor: active ? color : colors.border,
        backgroundColor: active ? `${color}1A` : colors.card,
      }}
      className="flex-1 items-center rounded-lg border py-2"
    >
      <Text style={{ color: active ? color : colors.muted }} className="text-sm font-semibold">
        {label}
      </Text>
    </Pressable>
  );
}
