import React, { useCallback, useState } from "react";
import { ActivityIndicator, Pressable, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useFocusEffect, useRouter } from "expo-router";
import { colors } from "@/theme/colors";
import { fetchRevengeQuestionIds } from "@/api/history";
import { fetchQuestionsByIds } from "@/api/questions";
import { useExamStore } from "@/store/examStore";

export default function Revenge() {
  const router = useRouter();
  const startExam = useExamStore((s) => s.startExam);
  const [count, setCount] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);

  useFocusEffect(
    useCallback(() => {
      fetchRevengeQuestionIds()
        .then((ids) => setCount(ids.length))
        .catch(() => setCount(0));
    }, []),
  );

  const start = async (limit: number) => {
    setBusy(true);
    try {
      const ids = await fetchRevengeQuestionIds();
      const chosen = ids.slice(0, limit);
      const questions = await fetchQuestionsByIds(chosen);
      if (questions.length === 0) return;
      startExam(
        {
          subject: questions[0].subject,
          categories: [],
          subCategories: [],
          difficulties: [],
          count: questions.length,
        },
        questions,
      );
      router.replace("/exam/session");
    } finally {
      setBusy(false);
    }
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.bg }}>
      <View className="flex-1 p-6">
        <View className="mb-8 flex-row-reverse items-center justify-between">
          <Text style={{ color: colors.neonRed }} className="text-2xl font-bold">
            حالت انتقام 🔁
          </Text>
          <Pressable onPress={() => router.back()} className="rounded-lg bg-ink-700 px-4 py-2">
            <Text style={{ color: colors.text }}>بازگشت ›</Text>
          </Pressable>
        </View>

        <View className="items-center justify-center rounded-2xl border border-ink-500 bg-ink-800 p-8">
          <Text style={{ color: colors.text }} className="mb-2 text-center text-lg">
            ببین رفیق، اینجا همهٔ سؤال‌هایی که{" "}
            <Text style={{ color: colors.neonRed }}>غلط</Text> زدی یا{" "}
            <Text style={{ color: colors.neonAmber }}>رد</Text> کردی جمع شده.
          </Text>
          <Text style={{ color: colors.muted }} className="mb-6 text-center text-sm">
            تا وقتی یه سؤال رو درست نزنی، از این لیست بیرون نمی‌ره.
          </Text>

          <Text style={{ color: colors.neonRed }} className="mb-6 text-5xl font-bold">
            {count === null ? "…" : count}
          </Text>

          {count !== null && count > 0 ? (
            <View className="w-full gap-3">
              {[10, 20].map((n) =>
                count >= n || n === 10 ? (
                  <Pressable
                    key={n}
                    onPress={() => start(n)}
                    disabled={busy}
                    style={{ backgroundColor: colors.neonRed }}
                    className="items-center rounded-xl py-3"
                  >
                    {busy ? (
                      <ActivityIndicator color={colors.bg} />
                    ) : (
                      <Text style={{ color: colors.bg }} className="font-bold">
                        تمرین {Math.min(n, count)} سؤال
                      </Text>
                    )}
                  </Pressable>
                ) : null,
              )}
              <Pressable
                onPress={() => start(count)}
                disabled={busy}
                className="items-center rounded-xl border border-ink-500 py-3"
              >
                <Text style={{ color: colors.text }} className="font-bold">
                  همهٔ {count} سؤال
                </Text>
              </Pressable>
            </View>
          ) : (
            <Text style={{ color: colors.muted }} className="text-center">
              فعلاً چیزی برای انتقام نیست. برو یه آزمون بزن!
            </Text>
          )}
        </View>
      </View>
    </SafeAreaView>
  );
}
