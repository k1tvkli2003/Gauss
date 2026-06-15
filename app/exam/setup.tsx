import React, { useEffect, useMemo, useState } from "react";
import { ActivityIndicator, Pressable, ScrollView, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useLocalSearchParams, useRouter } from "expo-router";
import { colors, difficultyMeta, subjectMeta } from "@/theme/colors";
import { CATEGORIES } from "@/data/categories";
import { toFa } from "@/lib/format";
import { pressScale } from "@/lib/press";
import { fetchAvailability, fetchExamQuestions } from "@/api/questions";
import { useExamStore } from "@/store/examStore";
import type { Difficulty, Subject } from "@/types";

const DIFFICULTIES: Difficulty[] = ["above_average", "hard", "very_hard", "olympiad"];
const COUNTS = [5, 10, 15, 20];

export default function ExamSetup() {
  const router = useRouter();
  const params = useLocalSearchParams<{ subject?: string; category?: string }>();
  const startExam = useExamStore((s) => s.startExam);

  const [subject, setSubject] = useState<Subject>(
    params.subject === "physics" ? "physics" : "math",
  );
  const [categories, setCategories] = useState<string[]>([]);
  const [subCategories, setSubCategories] = useState<string[]>([]);
  const [difficulties, setDifficulties] = useState<Difficulty[]>(["hard", "very_hard"]);
  const [count, setCount] = useState(10);
  const [availability, setAvailability] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setCategories([]);
    setSubCategories([]);
    fetchAvailability(subject).then(setAvailability).catch(() => setAvailability({}));
  }, [subject]);

  // One-time pre-selection from a Home deep-link (e.g. weakness strip).
  useEffect(() => {
    if (typeof params.category === "string" && params.category.length > 0) {
      setCategories([params.category]);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const available = useMemo(
    () => Object.values(availability).reduce((a, b) => a + b, 0),
    [availability],
  );

  // Sub-categories belonging to the currently-selected top-level categories.
  const subCatOptions = useMemo(
    () =>
      CATEGORIES[subject]
        .filter((c) => categories.includes(c.key))
        .flatMap((c) => c.subCategories),
    [subject, categories],
  );

  // Drop any selected sub-categories that are no longer valid.
  useEffect(() => {
    setSubCategories((prev) => prev.filter((k) => subCatOptions.some((o) => o.key === k)));
  }, [subCatOptions]);

  const toggle = <T,>(list: T[], v: T, set: (x: T[]) => void) =>
    set(list.includes(v) ? list.filter((x) => x !== v) : [...list, v]);

  const start = async () => {
    setError(null);
    setLoading(true);
    try {
      const questions = await fetchExamQuestions({
        subject,
        categories,
        subCategories,
        difficulties,
        count,
      });
      if (questions.length === 0) {
        setError("هیچ سؤالی با این فیلترها پیدا نشد. فیلترها رو بازتر کن رفیق.");
        setLoading(false);
        return;
      }
      startExam({ subject, categories, subCategories, difficulties, count }, questions);
      router.replace("/exam/session");
    } catch (e: any) {
      setError(e?.message ?? "خطا در بارگذاری سؤالات.");
      setLoading(false);
    }
  };

  const startDisabled = loading || difficulties.length === 0;

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.bg }}>
      <View className="flex-1 px-6 pt-6">
        <Header onBack={() => router.back()} />

        {/* Two-column landscape layout */}
        <View className="flex-1 flex-row gap-6">
          {/* Left — quick toggles */}
          <ScrollView className="flex-1" showsVerticalScrollIndicator={false}>
            <Section title="درس">
              <View className="flex-row gap-3">
                {(["math", "physics"] as Subject[]).map((s) => (
                  <Chip
                    key={s}
                    label={subjectMeta[s].faLabel}
                    active={subject === s}
                    color={subjectMeta[s].color}
                    onPress={() => setSubject(s)}
                    wide
                  />
                ))}
              </View>
            </Section>

            <Section title="سطح دشواری">
              <View className="flex-row flex-wrap justify-end gap-2">
                {DIFFICULTIES.map((d) => (
                  <Chip
                    key={d}
                    label={difficultyMeta[d].faLabel}
                    active={difficulties.includes(d)}
                    color={difficultyMeta[d].color}
                    onPress={() => toggle(difficulties, d, setDifficulties)}
                  />
                ))}
              </View>
            </Section>

            <Section title="تعداد سؤال">
              <View className="flex-row gap-3">
                {COUNTS.map((n) => (
                  <Chip
                    key={n}
                    label={toFa(n)}
                    active={count === n}
                    color={colors.neonPurple}
                    onPress={() => setCount(n)}
                    wide
                  />
                ))}
              </View>
            </Section>
          </ScrollView>

          {/* Right — topic & sub-topic grid */}
          <ScrollView className="flex-1" showsVerticalScrollIndicator={false}>
            <Section title="مبحث (خالی = همه)">
              <View className="flex-row flex-wrap justify-end gap-2">
                {CATEGORIES[subject].map((c) => {
                  const n = availability[c.key] ?? 0;
                  return (
                    <Chip
                      key={c.key}
                      label={`${c.faLabel} (${toFa(n)})`}
                      active={categories.includes(c.key)}
                      color={colors.neonBlue}
                      disabled={n === 0}
                      onPress={() => toggle(categories, c.key, setCategories)}
                    />
                  );
                })}
              </View>
            </Section>

            {subCatOptions.length > 0 && (
              <Section title="زیرمبحث (خالی = همهٔ مبحث)">
                <View className="flex-row flex-wrap justify-end gap-2">
                  {subCatOptions.map((sc) => (
                    <Chip
                      key={sc.key}
                      label={sc.faLabel}
                      active={subCategories.includes(sc.key)}
                      color={colors.neonGreen}
                      onPress={() => toggle(subCategories, sc.key, setSubCategories)}
                    />
                  ))}
                </View>
              </Section>
            )}
          </ScrollView>
        </View>
      </View>

      {/* Sticky Start CTA — always visible, thumb-reachable */}
      <View className="border-t border-ink-500 px-6 py-3">
        {error && (
          <Text style={{ color: colors.neonRed }} className="mb-2 text-right text-sm">
            {error}
          </Text>
        )}
        <Pressable
          onPress={start}
          disabled={startDisabled}
          style={({ pressed }) => [
            { backgroundColor: startDisabled ? colors.card : colors.neonBlue },
            pressScale(pressed && !startDisabled),
          ]}
          className="items-center rounded-2xl py-4"
        >
          {loading ? (
            <ActivityIndicator color={colors.neonBlue} />
          ) : (
            <Text
              style={{ color: difficulties.length === 0 ? colors.muted : colors.bg }}
              className="text-lg font-bold"
            >
              شروع آزمون · {toFa(available)} سؤال آماده
            </Text>
          )}
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

function Header({ onBack }: { onBack: () => void }) {
  return (
    <View className="mb-6 flex-row-reverse items-center justify-between">
      <Text style={{ color: colors.text }} className="text-2xl font-bold">
        آزمون سفارشی
      </Text>
      <Pressable onPress={onBack} className="rounded-lg bg-ink-700 px-4 py-2">
        <Text style={{ color: colors.text }}>بازگشت ›</Text>
      </Pressable>
    </View>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View className="mb-6">
      <Text style={{ color: colors.muted }} className="mb-3 text-right text-sm font-semibold">
        {title}
      </Text>
      {children}
    </View>
  );
}

function Chip({
  label,
  active,
  color,
  onPress,
  disabled,
  wide,
}: {
  label: string;
  active: boolean;
  color: string;
  onPress: () => void;
  disabled?: boolean;
  wide?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={{
        borderColor: active ? color : colors.border,
        backgroundColor: active ? `${color}1A` : colors.card,
        opacity: disabled ? 0.4 : 1,
        flex: wide ? 1 : undefined,
      }}
      className="items-center rounded-xl border px-4 py-3"
    >
      <Text style={{ color: active ? color : colors.text }} className="text-sm font-semibold">
        {label}
      </Text>
    </Pressable>
  );
}
