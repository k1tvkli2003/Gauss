import React, { useMemo } from "react";
import { Pressable, ScrollView, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useRouter } from "expo-router";
import { colors } from "@/theme/colors";
import { KONKUR_SECONDS_PER_QUESTION } from "@/types";
import { SolutionCard } from "@/components/SolutionCard";
import { useExamStore } from "@/store/examStore";

export default function Results() {
  const router = useRouter();
  const results = useExamStore((s) => s.results());
  const reset = useExamStore((s) => s.reset);

  const summary = useMemo(() => {
    const correct = results.filter((r) => r.status === "correct").length;
    const wrong = results.filter((r) => r.status === "wrong").length;
    const skipped = results.filter((r) => r.status === "skipped").length;
    const total = results.length;
    const timeSum = results.reduce((s, r) => s + r.timeTakenSeconds, 0);
    const avg = total > 0 ? Math.round(timeSum / total) : 0;
    return {
      correct,
      wrong,
      skipped,
      total,
      score: total > 0 ? Math.round((correct / total) * 100) : 0,
      avg,
    };
  }, [results]);

  const home = () => {
    reset();
    router.replace("/");
  };

  if (results.length === 0) {
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: colors.bg }}>
        <View className="flex-1 items-center justify-center">
          <Text style={{ color: colors.muted }}>نتیجه‌ای برای نمایش نیست.</Text>
          <Pressable onPress={home} className="mt-4 rounded-lg bg-ink-700 px-5 py-3">
            <Text style={{ color: colors.text }}>خانه</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    );
  }

  const scoreColor =
    summary.score >= 70 ? colors.neonGreen : summary.score >= 40 ? colors.neonAmber : colors.neonRed;

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.bg }}>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <Text style={{ color: colors.text }} className="mb-1 text-right text-2xl font-bold">
          کارنامه
        </Text>
        <Text style={{ color: colors.muted }} className="mb-5 text-right text-sm">
          {summary.avg > KONKUR_SECONDS_PER_QUESTION
            ? "سرعتت رو ببر بالا رفیق — از زمان کنکور عقبی."
            : "ایول، سرعتت توی استاندارد کنکوره. 🔥"}
        </Text>

        {/* Score ring + breakdown */}
        <View className="mb-6 flex-row items-center gap-5 rounded-2xl border border-ink-500 bg-ink-800 p-5">
          <View
            style={{ borderColor: scoreColor }}
            className="h-24 w-24 items-center justify-center rounded-full border-4"
          >
            <Text style={{ color: scoreColor }} className="text-3xl font-bold">
              {summary.score}%
            </Text>
          </View>
          <View className="flex-1 gap-2">
            <Row label="درست" value={summary.correct} color={colors.neonGreen} />
            <Row label="غلط" value={summary.wrong} color={colors.neonRed} />
            <Row label="نزده" value={summary.skipped} color={colors.neonAmber} />
            <Row label="میانگین زمان" value={`${summary.avg}s`} color={colors.neonBlue} />
          </View>
        </View>

        <View className="mb-4 flex-row gap-3">
          <Pressable
            onPress={() => router.replace("/exam/setup")}
            style={{ backgroundColor: colors.neonBlue }}
            className="flex-1 items-center rounded-xl py-3"
          >
            <Text style={{ color: colors.bg }} className="font-bold">
              آزمون دوباره
            </Text>
          </Pressable>
          <Pressable onPress={home} className="flex-1 items-center rounded-xl bg-ink-700 py-3">
            <Text style={{ color: colors.text }} className="font-bold">
              خانه
            </Text>
          </Pressable>
        </View>

        <Text style={{ color: colors.text }} className="mb-3 mt-2 text-right text-lg font-bold">
          پاسخنامهٔ تشریحی
        </Text>
        {results.map((r, i) => (
          <SolutionCard key={r.question.id} result={r} number={i + 1} />
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

function Row({ label, value, color }: { label: string; value: string | number; color: string }) {
  return (
    <View className="flex-row-reverse items-center justify-between">
      <Text style={{ color: colors.muted }} className="text-sm">
        {label}
      </Text>
      <Text style={{ color }} className="text-base font-bold">
        {value}
      </Text>
    </View>
  );
}
