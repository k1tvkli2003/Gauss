import type { ViewStyle } from "react-native";

/**
 * Tactile press feedback usable inside a Pressable `style` callback:
 *   style={({ pressed }) => [base, pressScale(pressed)]}
 * Pure React Native (no reanimated) so it's safe everywhere.
 */
export function pressScale(pressed: boolean, to = 0.97): ViewStyle {
  return { transform: [{ scale: pressed ? to : 1 }] };
}
