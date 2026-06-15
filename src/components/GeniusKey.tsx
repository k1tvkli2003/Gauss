import React, { useState } from "react";
import { Pressable, Text, View } from "react-native";
import { colors } from "@/theme/colors";
import { MathText } from "./MathText";

/**
 * The "Genius key": the classic worked solution and the ⚡ smart shortcut as
 * switchable tabs. Shared by the in-session reveal and the results review so
 * the two never drift apart.
 */
export function GeniusKey({
  classic,
  shortcut,
  fontSize = 15,
}: {
  classic: string;
  shortcut: string | null;
  fontSize?: number;
}) {
  const [tab, setTab] = useState<"classic" | "shortcut">("classic");
  const showShortcut = tab === "shortcut" && !!shortcut;

  return (
    <View>
      <View className="flex-row gap-2">
        <TabBtn
          label="حل تشریحی"
          active={tab === "classic"}
          color={colors.neonBlue}
          onPress={() => setTab("classic")}
        />
        {shortcut ? (
          <TabBtn
            label="⚡ راه تستی"
            active={tab === "shortcut"}
            color={colors.neonPurple}
            onPress={() => setTab("shortcut")}
          />
        ) : null}
      </View>

      <View
        style={{ borderColor: showShortcut ? colors.neonPurple : colors.neonBlue }}
        className="mt-3 rounded-xl border bg-ink-900 p-4"
      >
        <MathText content={showShortcut ? shortcut! : classic} fontSize={fontSize} />
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
