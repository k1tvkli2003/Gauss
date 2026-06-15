import React from "react";
import { Pressable, Text, View } from "react-native";
import { colors } from "@/theme/colors";
import { pressScale } from "@/lib/press";
import { MathText } from "./MathText";

interface Props {
  index: number; // 1..4
  text: string;
  selected: boolean;
  // review mode
  reveal?: boolean;
  correct?: boolean;
  onPress?: () => void;
}

const LABELS = ["", "۱", "۲", "۳", "۴"];

export function OptionButton({
  index,
  text,
  selected,
  reveal,
  correct,
  onPress,
}: Props) {
  let borderColor: string = colors.border;
  let bg: string = colors.card;

  if (reveal) {
    if (correct) {
      borderColor = colors.neonGreen;
      bg = `${colors.neonGreen}14`;
    } else if (selected) {
      borderColor = colors.neonRed;
      bg = `${colors.neonRed}14`;
    }
  } else if (selected) {
    borderColor = colors.neonBlue;
    bg = `${colors.neonBlue}14`;
  }

  return (
    <Pressable
      onPress={onPress}
      disabled={reveal}
      style={({ pressed }) => [{ borderColor, backgroundColor: bg }, pressScale(pressed && !reveal)]}
      className="mb-3 flex-row-reverse items-center rounded-xl border px-4 py-3"
    >
      <View
        style={{
          borderColor,
          backgroundColor: selected || (reveal && correct) ? borderColor : "transparent",
        }}
        className="ml-3 h-7 w-7 items-center justify-center rounded-full border"
      >
        <Text
          style={{
            color: selected || (reveal && correct) ? colors.bg : colors.muted,
          }}
          className="text-sm font-bold"
        >
          {LABELS[index]}
        </Text>
      </View>
      <View className="flex-1">
        <MathText content={text} fontSize={16} />
      </View>
    </Pressable>
  );
}
