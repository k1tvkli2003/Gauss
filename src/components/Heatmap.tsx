import React from "react";
import { ScrollView, Text, View } from "react-native";
import { colors } from "@/theme/colors";

/** GitHub-style "Brain Heatmap" of daily activity for the last ~17 weeks. */
export function Heatmap({ data }: { data: Record<string, number> }) {
  const today = new Date();
  const weeks = 17;
  const days: { key: string; count: number }[] = [];

  // Build a grid ending today, going back weeks*7 days.
  const start = new Date(today);
  start.setDate(start.getDate() - (weeks * 7 - 1));
  // Align to start of week (Saturday in IR, but Sunday grid is fine visually).
  for (let i = 0; i < weeks * 7; i++) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    const key = d.toISOString().slice(0, 10);
    days.push({ key, count: data[key] ?? 0 });
  }

  const max = Math.max(1, ...days.map((d) => d.count));
  const level = (c: number) => {
    if (c === 0) return colors.raised;
    const t = c / max;
    if (t > 0.66) return colors.neonGreen;
    if (t > 0.33) return "#2BB673";
    return "#1C6B47";
  };

  // Columns of 7.
  const columns: { key: string; count: number }[][] = [];
  for (let i = 0; i < days.length; i += 7) columns.push(days.slice(i, i + 7));

  return (
    <View>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View className="flex-row gap-1">
          {columns.map((col, ci) => (
            <View key={ci} className="gap-1">
              {col.map((d) => (
                <View
                  key={d.key}
                  style={{
                    width: 14,
                    height: 14,
                    borderRadius: 3,
                    backgroundColor: level(d.count),
                  }}
                />
              ))}
            </View>
          ))}
        </View>
      </ScrollView>
      <View className="mt-2 flex-row items-center justify-end gap-1">
        <Text style={{ color: colors.muted }} className="mr-1 text-xs">
          کمتر
        </Text>
        {[colors.raised, "#1C6B47", "#2BB673", colors.neonGreen].map((c) => (
          <View
            key={c}
            style={{ width: 12, height: 12, borderRadius: 3, backgroundColor: c }}
          />
        ))}
        <Text style={{ color: colors.muted }} className="ml-1 text-xs">
          بیشتر
        </Text>
      </View>
    </View>
  );
}
