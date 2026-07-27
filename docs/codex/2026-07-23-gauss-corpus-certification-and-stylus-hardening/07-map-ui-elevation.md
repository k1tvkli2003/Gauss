# Map UI elevation — evidence record

- Status: implemented and visual-QA verified on 2026-07-28
- Modernization mode: **Elevate**
- Approved visual direction: full-screen astronomical expedition; a single,
  winding learning route with live HUD and a floating mission action. This is
  the already accepted Gauss map direction, not a new concept proposal.

## Why this slice

The corpus-repair workflow is intentionally slow and fail-closed. UI work can
move in parallel, but must not fabricate question truth or hide certification
state. The map therefore continues to use only live local curriculum and
progress state while its visual hierarchy becomes clearer.

The before/after visual inspection showed two concrete phone-scale problems:

1. labels placed directly over the astronomical texture could lose their
   attachment and contrast;
2. the floating bottom action named a topic but did not clearly say whether it
   was the current mission, a selected set, or a completed/revisit set.

## Whole-experience ledger

| Surface | Keep | Refine in this slice | Deliberately not changed |
| --- | --- | --- | --- |
| Brand/header | live Gauss wordmark, selected theorem mark, Math/Physics switch, compact readable progress | retain the existing compact-header fix as the single progress cue | launcher/splash identity |
| Map stage | real atmospheric art, theorem landmark, continuous path, live Persian topic labels, tap targets | label plaques now create a light node-facing anchor and recover contrast without flattening the path into cards | curriculum topology and progress rules |
| Mission action | floating glass panel and 48dp action | live `CURRENT MISSION` / `SELECTED SET` / `SET COMPLETE` state, topic identity, charted/revisit reading, dedicated emblem | scoring or answer-certification claims |
| Tablet/web | rail, widened stage, persistent inspector | label readability stays consistent across widths | inspector information architecture |

## Asset and live-content split

- Raster atmosphere/landmarks remain intentional visual assets:
  `assets/visual/map/orrery_atmosphere_portrait.png`,
  `assets/visual/map/theorem_engine.png`, and node/mascot art.
- The wordmark stays the approved raster typography asset via `GaussWordmark`.
- The theorem-star and topic glyphs remain live custom vector rendering so the
  mark stays crisp in HUD, navigation, and topic-specific action controls.
- Topic names, set names, reflected counts, revisit counts, selected/current
  state, labels, and accessibility descriptions are all live local state. No
  data text was baked into an image.

## Responsive and accessibility checks

| Viewport | Confirmed result |
| --- | --- |
| 390 × 844 phone | readable header, connected route, node plaques, 92dp mission dock above floating bottom navigation |
| 768 × 1024 tablet | rail and dock coexist; labels stay connected to their node without eclipsing the route |
| 1440 × 960 web | full stage retains negative space; persistent Study Inspector remains independent of map action |
| 411 × 820 at 200% text and reduced motion | Flutter widget test passes with no exception; detail line yields before the title/action are compromised |

The status change uses short opacity/container transitions with the shared
motion token and respects `MediaQuery.disableAnimations`. Touch actions retain
a minimum 48dp height. Persian topic labels are explicitly RTL with no Persian
letter spacing; English app chrome stays English.

## Evidence

Local rendered screenshots from the release Web build:

- `.codex-tmp/map-preview-mission-dock/map-phone.png`
- `.codex-tmp/map-preview-mission-dock/map-tablet.png`
- `.codex-tmp/map-preview-mission-dock/map-wide.png`

Validation completed after this visual pass:

```text
dart analyze lib                                      # no issues
flutter test                                          # 96 tests passed
flutter build web --release --no-wasm-dry-run         # succeeded
```

## Honest remaining proof

This is browser-rendered visual evidence, not a physical Android screen
recording. The implementation keeps the same responsive/semantic route and is
covered by Flutter widget tests; real device capture remains part of final
release proof, alongside the separate Xiaomi Focus Pen verification work.
