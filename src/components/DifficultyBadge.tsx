import React from "react";
import { Text, View } from "react-native";
import type { Difficulty } from "@/types";
import { difficultyMeta } from "@/theme/colors";

export function DifficultyBadge({ difficulty }: { difficulty: Difficulty }) {
  const meta = difficultyMeta[difficulty];
  return (
    <View
      style={{
        borderColor: meta.color,
        backgroundColor: `${meta.color}1A`,
      }}
      className="flex-row items-center self-start rounded-full border px-3 py-1"
    >
      <View
        style={{ backgroundColor: meta.color }}
        className="mr-2 h-2 w-2 rounded-full"
      />
      <Text style={{ color: meta.color }} className="text-xs font-semibold">
        {meta.faLabel}
      </Text>
    </View>
  );
}
