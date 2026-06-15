import type React from "react";
import { Text, StyleSheet, type TextStyle } from "react-native";

/**
 * Vazirmatn font pipeline.
 *
 * `useFonts(fontAssets)` in the root layout registers each weight under a
 * distinct family name. We then patch `Text.render` once so that every piece
 * of text in the app resolves to the Vazirmatn weight that matches its
 * `fontWeight` — without having to touch the existing `font-bold` /
 * `font-semibold` Tailwind classes scattered across the screens.
 */
export const fontAssets = {
  "Vazirmatn-Regular": require("../../assets/fonts/Vazirmatn-Regular.ttf"),
  "Vazirmatn-SemiBold": require("../../assets/fonts/Vazirmatn-SemiBold.ttf"),
  "Vazirmatn-Bold": require("../../assets/fonts/Vazirmatn-Bold.ttf"),
  "Vazirmatn-ExtraBold": require("../../assets/fonts/Vazirmatn-ExtraBold.ttf"),
  "Vazirmatn-Black": require("../../assets/fonts/Vazirmatn-Black.ttf"),
} as const;

/** Map a resolved fontWeight to the matching Vazirmatn family. */
function familyForWeight(weight: TextStyle["fontWeight"]): string {
  switch (String(weight)) {
    case "900":
    case "black":
      return "Vazirmatn-Black";
    case "800":
    case "extrabold":
      return "Vazirmatn-ExtraBold";
    case "700":
    case "bold":
      return "Vazirmatn-Bold";
    case "600":
    case "semibold":
      return "Vazirmatn-SemiBold";
    default:
      return "Vazirmatn-Regular";
  }
}

let patched = false;

/**
 * Inject the correct Vazirmatn family into every <Text>. Idempotent — safe to
 * call on each render of the root layout. We honour an explicit `fontFamily`
 * (e.g. monospace) and neutralise `fontWeight` afterwards so Android doesn't
 * synthesise a faux-bold on top of the already-bold TTF.
 */
export function installVazirmatn(): void {
  if (patched) return;
  patched = true;

  const TextAny = Text as unknown as {
    render: (...args: unknown[]) => React.ReactElement;
  };
  const originalRender = TextAny.render;

  TextAny.render = function patchedRender(...args: unknown[]) {
    const element = originalRender.apply(this, args);
    const flat = (StyleSheet.flatten(element.props.style) || {}) as TextStyle;

    // Respect an explicitly chosen font (don't clobber monospace etc.).
    if (flat.fontFamily) return element;

    const fontFamily = familyForWeight(flat.fontWeight);
    return {
      ...element,
      props: {
        ...element.props,
        style: [element.props.style, { fontFamily, fontWeight: "normal" }],
      },
    };
  };
}
