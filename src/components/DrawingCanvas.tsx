import React, { useCallback, useRef, useState } from "react";
import { Pressable, Text, View } from "react-native";
import {
  Canvas,
  Path,
  Skia,
  type SkPath,
} from "@shopify/react-native-skia";
import {
  Gesture,
  GestureDetector,
  GestureHandlerRootView,
} from "react-native-gesture-handler";
import { colors } from "@/theme/colors";
import type { ScratchStroke } from "@/types";

type Stroke = ScratchStroke;

interface Props {
  /** Committed strokes (owned by the parent / store so they survive navigation). */
  strokes: Stroke[];
  onChange: (strokes: Stroke[]) => void;
}

const PEN_COLORS = [
  colors.neonBlue,
  colors.neonPurple,
  colors.neonGreen,
  colors.neonAmber,
  colors.neonRed,
  "#FFFFFF",
];

/**
 * Stylus-friendly scratchpad. Skia keeps strokes buttery even with a pen.
 * Supports color switch, stroke width, undo/redo and clear.
 */
export function DrawingCanvas({ strokes, onChange }: Props) {
  const [redoStack, setRedoStack] = useState<Stroke[]>([]);
  const [penColor, setPenColor] = useState<string>(colors.neonBlue);
  const [penWidth, setPenWidth] = useState<number>(3);

  const livePath = useRef<SkPath | null>(null);
  const [, force] = useState(0);

  const begin = useCallback((x: number, y: number) => {
    const p = Skia.Path.Make();
    p.moveTo(x, y);
    livePath.current = p;
    force((n) => n + 1);
  }, []);

  const extend = useCallback((x: number, y: number) => {
    if (livePath.current) {
      livePath.current.lineTo(x, y);
      force((n) => n + 1);
    }
  }, []);

  const end = useCallback(() => {
    if (livePath.current) {
      const snapshot = livePath.current.copy();
      onChange([...strokes, { path: snapshot, color: penColor, width: penWidth }]);
      setRedoStack([]);
      livePath.current = null;
      force((n) => n + 1);
    }
  }, [strokes, onChange, penColor, penWidth]);

  const pan = Gesture.Pan()
    .minDistance(0)
    .onBegin((e) => begin(e.x, e.y))
    .onUpdate((e) => extend(e.x, e.y))
    .onEnd(() => end())
    .runOnJS(true);

  const undo = () => {
    if (strokes.length === 0) return;
    const last = strokes[strokes.length - 1];
    setRedoStack((r) => [...r, last]);
    onChange(strokes.slice(0, -1));
  };

  const redo = () => {
    if (redoStack.length === 0) return;
    const last = redoStack[redoStack.length - 1];
    setRedoStack((r) => r.slice(0, -1));
    onChange([...strokes, last]);
  };

  const clear = () => {
    setRedoStack([]);
    livePath.current = null;
    onChange([]);
  };

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <View className="flex-1 rounded-2xl overflow-hidden border border-ink-500 bg-ink-800">
        {/* Toolbar */}
        <View className="flex-row items-center justify-between px-3 py-2 border-b border-ink-500">
          <View className="flex-row items-center gap-2">
            {PEN_COLORS.map((c) => (
              <Pressable
                key={c}
                onPress={() => setPenColor(c)}
                style={{
                  width: 22,
                  height: 22,
                  borderRadius: 11,
                  backgroundColor: c,
                  borderWidth: penColor === c ? 2 : 0,
                  borderColor: "#FFFFFF",
                }}
              />
            ))}
          </View>
          <View className="flex-row items-center gap-2">
            {[2, 3, 5, 8].map((w) => (
              <Pressable
                key={w}
                onPress={() => setPenWidth(w)}
                className={`px-2 py-1 rounded-lg ${
                  penWidth === w ? "bg-ink-500" : "bg-ink-700"
                }`}
              >
                <Text style={{ color: colors.text, fontSize: 12 }}>{w}px</Text>
              </Pressable>
            ))}
          </View>
          <View className="flex-row items-center gap-2">
            <ToolBtn label="↶" onPress={undo} disabled={strokes.length === 0} />
            <ToolBtn label="↷" onPress={redo} disabled={redoStack.length === 0} />
            <ToolBtn label="پاک" onPress={clear} disabled={strokes.length === 0} />
          </View>
        </View>

        {/* Drawing surface */}
        <GestureDetector gesture={pan}>
          <View style={{ flex: 1 }}>
            <Canvas style={{ flex: 1 }}>
              {strokes.map((s, i) => (
                <Path
                  key={i}
                  path={s.path}
                  color={s.color}
                  style="stroke"
                  strokeWidth={s.width}
                  strokeCap="round"
                  strokeJoin="round"
                />
              ))}
              {livePath.current && (
                <Path
                  path={livePath.current}
                  color={penColor}
                  style="stroke"
                  strokeWidth={penWidth}
                  strokeCap="round"
                  strokeJoin="round"
                />
              )}
            </Canvas>
          </View>
        </GestureDetector>
      </View>
    </GestureHandlerRootView>
  );
}

function ToolBtn({
  label,
  onPress,
  disabled,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      className={`px-3 py-1 rounded-lg ${disabled ? "bg-ink-800" : "bg-ink-600"}`}
    >
      <Text style={{ color: disabled ? colors.muted : colors.text, fontSize: 14 }}>
        {label}
      </Text>
    </Pressable>
  );
}
