import React, { useEffect, useRef, useState } from "react";
import { Text, View } from "react-native";
import { colors } from "@/theme/colors";
import { KONKUR_SECONDS_PER_QUESTION } from "@/types";

/** Per-question stopwatch. Goes amber past the Konkur 70s budget, red at 2x. */
export function Timer({ resetKey }: { resetKey: string | number }) {
  const [seconds, setSeconds] = useState(0);
  const start = useRef(Date.now());

  useEffect(() => {
    start.current = Date.now();
    setSeconds(0);
    const id = setInterval(() => {
      setSeconds(Math.floor((Date.now() - start.current) / 1000));
    }, 1000);
    return () => clearInterval(id);
  }, [resetKey]);

  let color = colors.neonGreen;
  if (seconds > KONKUR_SECONDS_PER_QUESTION * 2) color = colors.neonRed;
  else if (seconds > KONKUR_SECONDS_PER_QUESTION) color = colors.neonAmber;

  const mm = String(Math.floor(seconds / 60)).padStart(2, "0");
  const ss = String(seconds % 60).padStart(2, "0");

  return (
    <View className="flex-row items-center rounded-lg bg-ink-700 px-3 py-1">
      <View style={{ backgroundColor: color }} className="mr-2 h-2 w-2 rounded-full" />
      <Text style={{ color, fontVariant: ["tabular-nums"] }} className="font-mono text-sm">
        {mm}:{ss}
      </Text>
      <Text style={{ color: colors.muted }} className="ml-2 text-xs">
        / {KONKUR_SECONDS_PER_QUESTION}s
      </Text>
    </View>
  );
}
