import React, { useState } from "react";
import { Alert, Pressable, ScrollView, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useRouter } from "expo-router";
import { colors, subjectMeta } from "@/theme/colors";
import { categoryLabel } from "@/data/categories";
import { toFa } from "@/lib/format";
import { DifficultyBadge } from "@/components/DifficultyBadge";
import { MathText } from "@/components/MathText";
import { OptionButton } from "@/components/OptionButton";
import { GeniusKey } from "@/components/GeniusKey";
import { DrawingCanvas } from "@/components/DrawingCanvas";
import { Timer } from "@/components/Timer";
import { useExamStore } from "@/store/examStore";

export default function ExamSession() {
  const router = useRouter();
  const {
    questions,
    index,
    attempts,
    scratch,
    config,
    answer,
    skip,
    next,
    prev,
    goTo,
    setScratch,
    finishAndSave,
  } = useExamStore();

  const [submitting, setSubmitting] = useState(false);
  // Which question indices the user has revealed the solution for (study aid).
  const [revealed, setRevealed] = useState<Record<number, boolean>>({});
  const q = questions[index];
  const current = attempts[index];
  const selected = current?.selectedOption ?? null;
  const isRevealed = !!revealed[index];

  if (!q || !config) {
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: colors.bg }}>
        <View className="flex-1 items-center justify-center">
          <Text style={{ color: colors.muted }}>آزمونی فعال نیست.</Text>
          <Pressable onPress={() => router.replace("/")} className="mt-4 rounded-lg bg-ink-700 px-5 py-3">
            <Text style={{ color: colors.text }}>خانه</Text>
          </Pressable>
        </View>
      </SafeAreaView>
    );
  }

  const isLast = index === questions.length - 1;
  const options = [q.option_1, q.option_2, q.option_3, q.option_4];

  const confirmFinish = () => {
    const answered = Object.keys(attempts).length;
    Alert.alert(
      "پایان آزمون",
      `${toFa(answered)} از ${toFa(questions.length)} سؤال ثبت شده. مطمئنی؟`,
      [
        { text: "ادامه می‌دم", style: "cancel" },
        { text: "تمام", style: "destructive", onPress: doFinish },
      ],
    );
  };

  const toggleReveal = () => setRevealed((r) => ({ ...r, [index]: !r[index] }));

  const doFinish = async () => {
    setSubmitting(true);
    try {
      await finishAndSave();
    } catch {
      // saved-state still advances; results screen handles it
    }
    router.replace("/exam/results");
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.bg }}>
      {/* Top bar */}
      <View className="flex-row-reverse items-center justify-between border-b border-ink-500 px-5 py-3">
        <View className="flex-row-reverse items-center gap-3">
          <Text style={{ color: subjectMeta[config.subject].color }} className="text-base font-bold">
            {subjectMeta[config.subject].faLabel}
          </Text>
          <Text style={{ color: colors.muted }} className="text-sm">
            سؤال {toFa(index + 1)} / {toFa(questions.length)}
          </Text>
        </View>
        <View className="flex-row items-center gap-3">
          <Timer resetKey={index} />
          <Pressable
            onPress={confirmFinish}
            disabled={submitting}
            style={{ backgroundColor: colors.neonGreen }}
            className="rounded-lg px-4 py-2"
          >
            <Text style={{ color: colors.bg }} className="font-bold">
              پایان
            </Text>
          </Pressable>
        </View>
      </View>

      {/* Split screen */}
      <View className="flex-1 flex-row">
        {/* LEFT — question */}
        <View className="flex-1 border-l border-ink-500">
          <ScrollView contentContainerStyle={{ padding: 20 }}>
            <View className="mb-3 flex-row-reverse items-center justify-between">
              <DifficultyBadge difficulty={q.difficulty} />
              <Text style={{ color: colors.muted }} className="text-xs">
                {categoryLabel(config.subject, q.category)}
                {q.sub_category ? ` · ${q.sub_category}` : ""}
              </Text>
            </View>

            <View className="mb-5 rounded-2xl border border-ink-500 bg-ink-800 p-4">
              <MathText content={q.question_text} fontSize={18} />
            </View>

            {options.map((opt, i) => (
              <OptionButton
                key={i}
                index={i + 1}
                text={opt}
                selected={selected === i + 1}
                reveal={isRevealed}
                correct={q.correct_option_index === i + 1}
                onPress={() => answer(i + 1)}
              />
            ))}

            {/* In-session Genius reveal — deliberate-practice loop */}
            {isRevealed && (
              <View className="mt-2">
                <GeniusKey classic={q.classic_solution} shortcut={q.smart_shortcut} />
              </View>
            )}
          </ScrollView>

          {/* Reveal bar — show the Genius key once an answer is committed */}
          <View className="flex-row-reverse items-center justify-between px-5 pt-2">
            <Pressable
              onPress={toggleReveal}
              disabled={!current}
              style={{
                borderColor: isRevealed ? colors.neonPurple : colors.neonGreen,
                backgroundColor: !current
                  ? colors.card
                  : isRevealed
                    ? `${colors.neonPurple}1A`
                    : `${colors.neonGreen}1A`,
                opacity: current ? 1 : 0.45,
              }}
              className="flex-1 items-center rounded-xl border py-2"
            >
              <Text
                style={{ color: !current ? colors.muted : isRevealed ? colors.neonPurple : colors.neonGreen }}
                className="text-sm font-bold"
              >
                {isRevealed ? "بستن حل" : current ? "نمایش حل ✨" : "اول جواب بده، بعد حل ✍️"}
              </Text>
            </Pressable>
          </View>

          {/* Nav footer */}
          <View className="flex-row-reverse items-center justify-between border-t border-ink-500 px-5 py-3">
            <NavBtn label="بعدی ›" onPress={next} disabled={isLast} primary />
            <View className="flex-row items-center gap-2">
              <Pressable
                onPress={() => {
                  skip();
                  if (!isLast) next();
                }}
                className="rounded-lg bg-ink-700 px-4 py-2"
              >
                <Text style={{ color: colors.muted }}>رد کردن</Text>
              </Pressable>
            </View>
            <NavBtn label="‹ قبلی" onPress={prev} disabled={index === 0} />
          </View>

          {/* Question dots */}
          <View className="flex-row flex-wrap justify-center gap-2 px-5 pb-3">
            {questions.map((_, i) => {
              const a = attempts[i];
              let bg = colors.raised;
              if (i === index) bg = colors.neonBlue;
              else if (a?.status === "skipped") bg = colors.neonAmber;
              else if (a) bg = colors.neonPurple;
              return (
                <Pressable
                  key={i}
                  onPress={() => goTo(i)}
                  style={{ width: 26, height: 26, borderRadius: 8, backgroundColor: bg }}
                  className="items-center justify-center"
                >
                  <Text
                    style={{ color: i === index ? colors.bg : colors.text, fontSize: 11 }}
                    className="font-bold"
                  >
                    {toFa(i + 1)}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </View>

        {/* RIGHT — scratchpad */}
        <View className="flex-1 p-3">
          <View className="mb-2 flex-row-reverse items-center justify-between px-1">
            <Text style={{ color: colors.muted }} className="text-xs">
              دفتر طراحی · با قلم بنویس ✍️
            </Text>
          </View>
          <DrawingCanvas
            key={index}
            strokes={scratch[index] ?? []}
            onChange={(s) => setScratch(index, s)}
          />
        </View>
      </View>
    </SafeAreaView>
  );
}

function NavBtn({
  label,
  onPress,
  disabled,
  primary,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  primary?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={{
        backgroundColor: disabled ? colors.card : primary ? colors.neonBlue : colors.raised,
        opacity: disabled ? 0.4 : 1,
      }}
      className="rounded-lg px-5 py-2"
    >
      <Text style={{ color: primary && !disabled ? colors.bg : colors.text }} className="font-semibold">
        {label}
      </Text>
    </Pressable>
  );
}
