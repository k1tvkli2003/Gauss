import React, { useCallback, useState } from "react";
import { Pressable, ScrollView, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useFocusEffect, useRouter } from "expo-router";
import { colors } from "@/theme/colors";
import { categoryLabel } from "@/data/categories";
import { toFa } from "@/lib/format";
import { fetchAnalytics, fetchExamHistory, fetchRevengeQuestionIds, type TopicStat } from "@/api/history";
import type { ExamHistoryRow } from "@/types";

export default function Home() {
  const router = useRouter();
  const [stats, setStats] = useState({ answered: 0, accuracy: 0, streak: 0 });
  const [revengeCount, setRevengeCount] = useState(0);
  const [recent, setRecent] = useState<ExamHistoryRow[]>([]);
  const [weak, setWeak] = useState<TopicStat[]>([]);

  const load = useCallback(() => {
    let active = true;
    (async () => {
      try {
        const [a, ids, exams] = await Promise.all([
          fetchAnalytics(),
          fetchRevengeQuestionIds(),
          fetchExamHistory(5),
        ]);
        if (!active) return;
        setStats({
          answered: a.totalAnswered,
          accuracy: Math.round(a.accuracy),
          streak: computeStreak(a.heatmap),
        });
        setRevengeCount(ids.length);
        setRecent(exams);
        // Weakest topics with enough signal, worst-first.
        setWeak(a.weakTopics.filter((t) => t.total >= 3).slice(0, 3));
      } catch {
        /* offline / empty — keep zeros */
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  useFocusEffect(load);

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.bg }}>
      <ScrollView contentContainerStyle={{ padding: 24 }}>
        {/* Header */}
        <View className="mb-8 flex-row-reverse items-center justify-between">
          <View className="items-end">
            <Text style={{ color: colors.text }} className="text-3xl font-bold">
              گائوس
            </Text>
            <Text style={{ color: colors.muted }} className="mt-1 text-sm">
              ذهن رو تیز نگه دار، رفیق.
            </Text>
          </View>
          <View
            style={{ borderColor: colors.neonPurple }}
            className="h-14 w-14 items-center justify-center rounded-2xl border"
          >
            <Text style={{ color: colors.neonPurple }} className="text-2xl font-bold">
              ∑
            </Text>
          </View>
        </View>

        {/* Stat strip */}
        <View className="mb-6 flex-row gap-3">
          <StatCard label="پاسخ‌داده" value={String(stats.answered)} color={colors.neonBlue} />
          <StatCard label="دقت" value={`${stats.accuracy}%`} color={colors.neonGreen} />
          <StatCard label="روزهای پیاپی" value={String(stats.streak)} color={colors.neonAmber} />
        </View>

        {/* Primary actions */}
        <BigButton
          title="آزمون جدید"
          subtitle="ساخت آزمون سفارشی — ریاضی یا فیزیک"
          glyph="⚡"
          color={colors.neonBlue}
          onPress={() => router.push("/exam/setup")}
        />
        <View className="mt-3 flex-row gap-3">
          <SmallButton
            title="حالت انتقام"
            subtitle={`${revengeCount} سؤال`}
            glyph="🔁"
            color={colors.neonRed}
            disabled={revengeCount === 0}
            onPress={() => router.push("/revenge")}
          />
          <SmallButton
            title="تحلیل و آمار"
            subtitle="نقشه حرارتی مغز"
            glyph="📊"
            color={colors.neonPurple}
            onPress={() => router.push("/analytics")}
          />
        </View>

        {/* Weakness strip — drill your worst topics in one tap */}
        {weak.length > 0 && (
          <View className="mt-8">
            <Text style={{ color: colors.text }} className="mb-3 text-right text-lg font-semibold">
              ضعف امروز — بزن تو هدف 🎯
            </Text>
            {weak.map((t) => (
              <Pressable
                key={`${t.subject}-${t.category}`}
                onPress={() =>
                  router.push({
                    pathname: "/exam/setup",
                    params: { subject: t.subject, category: t.category },
                  })
                }
                className="mb-2 flex-row-reverse items-center justify-between rounded-xl border border-ink-500 bg-ink-700 px-4 py-3"
              >
                <View className="flex-row-reverse items-center gap-2">
                  <Text style={{ color: colors.text }} className="text-sm font-semibold">
                    {categoryLabel(t.subject, t.category)}
                  </Text>
                  <Text style={{ color: colors.muted }} className="text-xs">
                    ({t.subject === "math" ? "ریاضی" : "فیزیک"})
                  </Text>
                </View>
                <View className="flex-row items-center gap-3">
                  <Text style={{ color: weakColor(t.accuracy) }} className="text-sm font-bold">
                    {toFa(Math.round(t.accuracy))}٪
                  </Text>
                  <Text style={{ color: colors.neonBlue }} className="text-xs">
                    تمرین ›
                  </Text>
                </View>
              </Pressable>
            ))}
          </View>
        )}

        {/* Recent exams */}
        {recent.length > 0 && (
          <View className="mt-8">
            <Text style={{ color: colors.text }} className="mb-3 text-right text-lg font-semibold">
              آزمون‌های اخیر
            </Text>
            {recent.map((e) => (
              <View
                key={e.id}
                className="mb-2 flex-row-reverse items-center justify-between rounded-xl border border-ink-500 bg-ink-700 px-4 py-3"
              >
                <Text style={{ color: colors.muted }} className="text-xs">
                  {new Date(e.created_at).toLocaleDateString("fa-IR")}
                </Text>
                <View className="flex-row items-center gap-4">
                  <Text style={{ color: colors.muted }} className="text-xs">
                    {e.correct_count}/{e.total_questions}
                  </Text>
                  <Text
                    style={{ color: scoreColor(e.score_percentage) }}
                    className="text-base font-bold"
                  >
                    {Math.round(e.score_percentage)}%
                  </Text>
                </View>
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function StatCard({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <View className="flex-1 items-center rounded-2xl border border-ink-500 bg-ink-700 py-4">
      <Text style={{ color }} className="text-2xl font-bold">
        {value}
      </Text>
      <Text style={{ color: colors.muted }} className="mt-1 text-xs">
        {label}
      </Text>
    </View>
  );
}

function BigButton({
  title,
  subtitle,
  glyph,
  color,
  onPress,
}: {
  title: string;
  subtitle: string;
  glyph: string;
  color: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={{ borderColor: color, backgroundColor: `${color}10` }}
      className="flex-row-reverse items-center justify-between rounded-2xl border p-5"
    >
      <View className="items-end">
        <Text style={{ color: colors.text }} className="text-xl font-bold">
          {title}
        </Text>
        <Text style={{ color: colors.muted }} className="mt-1 text-sm">
          {subtitle}
        </Text>
      </View>
      <Text style={{ fontSize: 30 }}>{glyph}</Text>
    </Pressable>
  );
}

function SmallButton({
  title,
  subtitle,
  glyph,
  color,
  onPress,
  disabled,
}: {
  title: string;
  subtitle: string;
  glyph: string;
  color: string;
  onPress: () => void;
  disabled?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={{
        borderColor: disabled ? colors.border : color,
        backgroundColor: disabled ? colors.card : `${color}10`,
        opacity: disabled ? 0.5 : 1,
      }}
      className="flex-1 flex-row-reverse items-center justify-between rounded-2xl border p-4"
    >
      <View className="items-end">
        <Text style={{ color: colors.text }} className="text-base font-bold">
          {title}
        </Text>
        <Text style={{ color: colors.muted }} className="mt-1 text-xs">
          {subtitle}
        </Text>
      </View>
      <Text style={{ fontSize: 22 }}>{glyph}</Text>
    </Pressable>
  );
}

function scoreColor(p: number): string {
  if (p >= 70) return colors.neonGreen;
  if (p >= 40) return colors.neonAmber;
  return colors.neonRed;
}

function weakColor(acc: number): string {
  if (acc >= 70) return colors.neonGreen;
  if (acc >= 40) return colors.neonAmber;
  return colors.neonRed;
}

function computeStreak(heatmap: Record<string, number>): number {
  let streak = 0;
  const d = new Date();
  // Allow today to be empty (streak from yesterday).
  if (!heatmap[d.toISOString().slice(0, 10)]) d.setDate(d.getDate() - 1);
  for (;;) {
    const key = d.toISOString().slice(0, 10);
    if (heatmap[key]) {
      streak += 1;
      d.setDate(d.getDate() - 1);
    } else break;
  }
  return streak;
}
