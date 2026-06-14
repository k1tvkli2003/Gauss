import React, { useCallback, useState } from "react";
import { Pressable, ScrollView, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useFocusEffect, useRouter } from "expo-router";
import { colors } from "@/theme/colors";
import { categoryLabel } from "@/data/categories";
import { Heatmap } from "@/components/Heatmap";
import { fetchAnalytics, type Analytics } from "@/api/history";
import { KONKUR_SECONDS_PER_QUESTION, type Subject } from "@/types";

export default function AnalyticsScreen() {
  const router = useRouter();
  const [data, setData] = useState<Analytics | null>(null);

  useFocusEffect(
    useCallback(() => {
      fetchAnalytics().then(setData).catch(() => setData(null));
    }, []),
  );

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.bg }}>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <View className="mb-6 flex-row-reverse items-center justify-between">
          <Text style={{ color: colors.text }} className="text-2xl font-bold">
            تحلیل عملکرد
          </Text>
          <Pressable onPress={() => router.back()} className="rounded-lg bg-ink-700 px-4 py-2">
            <Text style={{ color: colors.text }}>بازگشت ›</Text>
          </Pressable>
        </View>

        {!data || data.totalAnswered === 0 ? (
          <View className="mt-20 items-center">
            <Text style={{ color: colors.muted }}>هنوز داده‌ای ثبت نشده. یه آزمون بزن!</Text>
          </View>
        ) : (
          <>
            {/* KPI row */}
            <View className="mb-6 flex-row gap-3">
              <Kpi label="کل پاسخ‌ها" value={String(data.totalAnswered)} color={colors.neonBlue} />
              <Kpi label="دقت کلی" value={`${Math.round(data.accuracy)}%`} color={colors.neonGreen} />
              <Kpi
                label="میانگین زمان"
                value={`${Math.round(data.avgTime)}s`}
                color={data.avgTime > KONKUR_SECONDS_PER_QUESTION ? colors.neonAmber : colors.neonGreen}
              />
            </View>

            {/* Brain heatmap */}
            <Card title="نقشهٔ حرارتی مغز">
              <Heatmap data={data.heatmap} />
            </Card>

            {/* Weak topics */}
            <Card title="نقاط ضعف (به ترتیب اولویت تمرین)">
              {data.weakTopics.map((t) => {
                const subject: Subject = t.category.match(
                  /mechanics|electro|thermo|waves/,
                )
                  ? "physics"
                  : "math";
                return (
                  <View key={t.category} className="mb-3">
                    <View className="mb-1 flex-row-reverse items-center justify-between">
                      <Text style={{ color: colors.text }} className="text-sm">
                        {categoryLabel(subject, t.category)}
                      </Text>
                      <Text
                        style={{ color: barColor(t.accuracy) }}
                        className="text-sm font-bold"
                      >
                        {Math.round(t.accuracy)}% · {t.correct}/{t.total}
                      </Text>
                    </View>
                    <View className="h-2 w-full overflow-hidden rounded-full bg-ink-600">
                      <View
                        style={{
                          width: `${Math.max(4, t.accuracy)}%`,
                          backgroundColor: barColor(t.accuracy),
                          height: "100%",
                        }}
                      />
                    </View>
                  </View>
                );
              })}
            </Card>
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function Kpi({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <View className="flex-1 items-center rounded-2xl border border-ink-500 bg-ink-700 py-4">
      <Text style={{ color }} className="text-2xl font-bold">
        {value}
      </Text>
      <Text style={{ color: colors.muted }} className="mt-1 text-center text-xs">
        {label}
      </Text>
    </View>
  );
}

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View className="mb-5 rounded-2xl border border-ink-500 bg-ink-800 p-4">
      <Text style={{ color: colors.muted }} className="mb-4 text-right text-sm font-semibold">
        {title}
      </Text>
      {children}
    </View>
  );
}

function barColor(acc: number): string {
  if (acc >= 70) return colors.neonGreen;
  if (acc >= 40) return colors.neonAmber;
  return colors.neonRed;
}
