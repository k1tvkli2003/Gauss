# Gauss design direction

Source of truth for visual and interaction direction. Derived from the accepted
references (`docs/adventure-reference-crops/`), the binding UI manifest
(`docs/codex/2026-08-21-gauss-android-ui-ux-perfection-and-performance/07-ui-system-and-production-manifest.md`)
and `AGENTS.md`. Code tokens live in `flutter_app/lib/ui/tokens/`.
`antislop` filters against this file; `ui-ux-pro-max` supplies Flutter and UX
checks. Neither replaces it.

Dial: ENERGY 2 / RHYTHM 2 / MOTION 2

Owner direction (2026-11-09): a very smooth, modern environment. Not as
colorful or ornate as the adventure preview images. Minimal, but never dull.
Keep the current icons, fonts and illustrated items (stations, landmarks,
wordmark); remove the ornament around them.

Design Read: a private, single-learner math and physics study app for one
Persian-reading student on Android, in a quiet night-sky language where the
illustrated stations and the parchment manuscript are the only rich
objects, dial 2 / 2 / 2.

## Identity

- Gauss is an instrument for navigating knowledge, not a dashboard and not a
  school test sheet.
- The Map is the primary surface and fills the screen. Chrome floats over it
  as calm, opaque tonal panels.
- A question is one continuous, writable manuscript: prompt, ink and answer
  rails are a single object.
- Richness lives in content (station art, parchment, the learner's ink). The
  interface around it is matte and quiet: no ticks, engraved rings, brackets,
  grids, starfields or glows as decoration.
- Rewards are earned receipts, never pressure.

## Surfaces

- One card surface (`GaussSurface`): opaque `surface #101B1E` or
  `surfaceInset #0B1417`, neutral hairline, radius 20. No gradients, no blur,
  no brass outlines. `emphasized` marks the single current item.
- Phone navigation is the SonusKt pill (GlassNavBar): 64dp stadium, the
  selected destination filled brass with its label, the others icon-only,
  over a bottom scrim. No blur.
- Buttons are plain shapes: a filled brass primary, tonal secondaries, and
  icon buttons without rings.

## Palette (2 core + 1 accent + neutrals)

| Role | Token | Hex | Reason |
|---|---|---|---|
| Core: environment | `abyss` → `panelHigh` | `#03090B` → `#19282C` | night-sky depth the Map and chrome sit in |
| Core: study material | `parchment` / `ivory` / `parchmentInk` | `#F2E4C3` / `#F6ECD6` / `#261E12` | questions read as paper, not as a dark form |
| Accent: direction and action | `brass` / `brassLight` | `#C79238` / `#F0C36A` | the one gesture that says "go here" |
| Signal: progress and correctness | `signal` / `signalBright` | `#62AE9C` / `#8BD7C0` | teal means solved, mastered, forward |
| Ink on parchment | `GaussParchmentInk.*` | teal `#1E6D71`, brass `#855919`, sepia `#755F3B`, positive `#256E5A`, negative `#9A493E` | the same roles re-inked to hold 4.5:1 on paper |
| Status only | `error`, `warning` | `#FF7564`, `#E6A84C` | never decorative |
| Subject only | `ice` (Physics), `violet` (rare boss/insight) | `#77BFD1`, `#AA83D5` | subject identity, not general decoration |

Dark is the only theme. Reason: the product's world is a night sky and the
parchment manuscript provides the light reading surface inside it.
Contrast floor: 4.5:1 for normal text, 7:1 preferred for primary copy.

## Typography

- Chrome: Manrope (600 secondary, 700 titles, 800/900 actions and insignia).
  Reason: geometric but warm, reads well at small HUD sizes.
- Learning content: Vazirmatn, RTL per block, line height 1.55 to 1.7, no
  letter spacing. All numerals in question content render as ASCII `0-9`.
- Type ramp: 10 (insignia only), 11, 12, 14, 16, 18, 22, 28, 36.
- Labels are sentence case with tracking of 0.4 or less. All caps is only for
  insignia of four characters or fewer (LVL, XP).
- No essential phrase is ellipsized. When space runs out, the composition
  reflows.

## Shape, depth, motion

- Radius: 10 control, 16 component, 24 sheet/modal, pill only for capsule
  chips and the floating nav. Reason: radius encodes hierarchy.
- Depth comes from tone, borders and overlap. Elevation 0/2/6/12. Blur only
  inside the real footprint of fixed chrome.
- Glow marks one thing: current, selected or just-completed. Never resting
  decoration.
- Motion follows the SonusKt grammar (`docs/design-references/sonuskt-ui-kit.md`):
  routes fade through (in 220ms after 60ms, out 140ms) with no slide or
  scale; selection animates color; size changes use a critically damped
  spring; reveals fade and expand.
- Motion durations 140/220/280/360/520/760 ms. One focal animation at a time.
  Everything respects reduced motion; animation never produces XP or progress.

## Identity motif

The brass orbital ring: the current lesson's aura, the Mission Compass
action, the progress bearings and the completion receipt all share one
ring gesture. Reuse it instead of inventing new decoration.

## Iconography

Material rounded glyphs chosen for meaning (route, book, chart, pen,
eraser). One meaning per glyph: the bolt is XP, the summation sign is
Mathematics, the atom is Physics (`SubjectGlyph`), the diamond is the literal
Gem shelf. No sparkle, star or lightning icons as generic "magic"; a star
is allowed only where it literally means a collected star.

## Copy

- English chrome, short, specific verbs: "Start lesson", "Check answer",
  "Back to map". No "Get started", "Explore", "Discover".
- No em dashes in UI strings. Use a comma, colon, period or parentheses.
- No invented numbers. Every count, XP value and streak comes from persisted
  data; when there is none, show an honest empty state.

## Layout rules

- Window classes and composition ratios: see `GaussComposition` and
  `GaussViewport` in code. 320dp phones, tablets, RTL/LTR and 200% text are
  release gates.
- Every control has at least a 48dp hit box and 8dp spacing from neighbours.
- Every data view ships loading, empty and error states.
