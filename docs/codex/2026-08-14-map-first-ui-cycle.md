# Map-first UI cycle — 2026-08-14

## Frozen finding

The accepted mobile Map reference makes the astronomical route the primary
surface. The Android build at checkpoint `f04a4fb` instead spent roughly the
first third of the viewport on repeated Course, Orbit, and Chapter hierarchy.
The live Chapter threshold also read as an opaque dashboard bar over the sky,
and restoring a lesson centered it inside the part of the viewport already
claimed by the mission dock.

## Repair

- reduced the compact masthead from 108dp to 92dp while retaining the exact
  centered wordmark, equal flank tracks, 48dp controls, and full semantics;
- folded Chapter identity and progress into one adaptive Orbit constellation
  line, with a deliberate two-line reflow at 320dp/200% text;
- replaced the compact Chapter card with a translucent two-rail celestial
  annotation so the route remains visibly continuous behind it;
- aligned route geometry with the measured 100dp normal-text annotation and
  reserved the node radius plus a 12dp optical gap;
- moved restored/current lessons to the upper reading third so the chapter,
  current node, and following route remain visible above the floating dock.

## Evidence

- focused Flutter tests: 29/29 passed across
  `map_geometry_test.dart`, `android_experience_test.dart`, and
  `map_mission_dock_test.dart`;
- focused `flutter analyze`: no issues;
- `git diff --check`: clean;
- Android debug APK `versionCode 124` built and installed as
  `com.gauss.app.debug` on API 35 without replacing the signed
  `com.gauss.app` (`versionCode 106`);
- Android screenshot inspected at 1080x2400:
  `.codex-tmp/gauss-map-124.png` (local, intentionally ignored);
- post-launch logcat contained no `FATAL EXCEPTION`, `E/flutter`, or
  `RenderFlex` evidence.

## Result

The route now begins directly below the single Orbit selector, five compact
lesson instruments fit in the first Android frame, and neither the selected
lesson instrument nor the floating navigation collides with Android system
navigation. The current multi-user/Supabase expansion remains a separate
additive checkpoint so UI work cannot accidentally mutate persistence.
