# SonusKt UI kit: owner's house reference for all projects

Owner preference (2026-11-11): the bottom navigation, the motion grammar and
the component vocabulary of the owner's SonusKt app
(`k1tvkli2003/SonusKt`, Jetpack Compose) are the default reference for every
one of the owner's apps, including Gauss. Port them natively to each stack
(Compose, Flutter, web); keep each project's own palette, fonts and
identity. Source of truth: `app/src/main/java/com/example/ui/components/`
(`GlassNavBar.kt`, `SonusComponents.kt`) and `MainActivity.kt`.

## Bottom navigation: GlassNavBar

- One floating pill, centered, `12dp` above the system navigation inset.
  No full-width bar, no rail on phones.
- Bar: height `64dp`, inner padding `6dp`, fully rounded (stadium), fill =
  surface at ~88-90% opacity (content faintly shows through, no blur
  needed), 1dp rim stroke as a vertical gradient (white 18% at top to 4% at
  bottom on dark; white 95% to line 70% on light), shadow elevation ~18dp
  with black ~60% on dark.
- Items: stadium, min height `52dp`, `2dp` gap between items, horizontal
  padding `18dp` selected and `15dp` idle, icon `24dp`.
- Selected item: filled with the action/accent color, icon and label in the
  on-accent color, label (`labelLarge`, one line) appears `8dp` after the
  icon. Idle items: icon only, muted ink. Only the selected label is shown,
  which keeps the bar short on narrow phones and at large text.
- Motion: fill and tint animate with `animateColorAsState`; the item width
  animates with `animateContentSize(spring(stiffness = 600f))`; the label
  enters with `fadeIn + expandHorizontally` and leaves with
  `fadeOut + shrinkHorizontally`.
- Semantics: each item is `selectable` with `Role.Tab` and a content
  description equal to its label.
- Shell: page content runs to the bottom edge and scrolls under the bar; a
  bottom scrim (transparent to canvas at 92%) of height
  `bar + 2 * margin + system inset + 16dp` keeps the last line of content
  from colliding with the bar. Screens add the bar inset
  (`LocalBottomBarInset`) as bottom content padding so the end of every list
  is reachable above the bar.

## Motion grammar

- Route change: fade-through only. Incoming `fadeIn(tween(220,
  delayMillis = 60))`, outgoing `fadeOut(tween(140))`. No slide, no scale,
  no depth.
- Step flows (onboarding, wizards): direction-aware
  `slideInHorizontally { it / 6 * dir } + fadeIn()` against
  `slideOutHorizontally { -it / 6 * dir } + fadeOut()`.
- Selection state (chips, segments, tabs, answer choices, cards): animate
  the background/border color with `animateColorAsState` (default spring).
  Nothing jumps.
- Size changes: `animateContentSize(spring(stiffness = 600f))` (critically
  damped, no bounce).
- Reveal/disclosure (answers, details, inline controls):
  `AnimatedVisibility` with `fadeIn() + expandVertically()`.
- Contextual action bars: `slideInVertically { it } + fadeIn()` from the
  bottom, out the same way.
- Values: meters `tween(450)`, rings/gauges `tween(700)`, page-indicator dot
  width `8dp -> 24dp` via `animateDpAsState`.
- Infinite animation only for live content (a playing waveform), never as
  resting decoration. Respect the system's reduced-motion setting.

## Component vocabulary

| Component | Spec |
|---|---|
| `ScreenHeader` | `displaySmall` title, optional `bodyMedium` supporting line in soft ink, trailing round icon actions; top padding 20dp |
| `SectionTitle` | `titleLarge`, sentence case, optional `bodySmall` muted supporting line, optional trailing action |
| `Panel` | flat surface fill, radius 22dp, padding 18dp, no border, no shadow; optional click |
| `Hairline` | 1dp divider in line color |
| `SonusButton` | stadium, min height 48dp, tones PRIMARY (accent fill), SECONDARY (muted surface), QUIET (transparent), DANGER (soft danger fill); semibold `labelLarge`; optional 18dp leading icon; disabled = 38% alpha |
| `RoundIconButton` | 48dp circle hit target, 22dp icon, optional fill |
| `Segmented` | stadium track in muted surface, 4dp padding, equal-width options, selected thumb = surface color, animated |
| `Chip` / `ChipRow` | stadium, min height 36dp, 1dp line border, selected fills with accent; rows scroll horizontally with 8dp gaps |
| `SwitchRow`, `LinkRow` | whole row is the target; title, description, trailing control |
| `Meter` | 6dp stadium track, animated fill `tween(450)` |
| `EmptyState` | no card: brand mark 56dp, `titleLarge`, `bodyMedium` soft body, optional action; vertical padding 40dp |
| `ContentWidth` | caps reading width on tablets and centers the column |
| Page gutter | 20dp horizontal on every screen |

## How Gauss applies it

- `flutter_app/lib/app/gauss_shell.dart`: `_GaussFloatingNavigation`
  (GlassNavBar port, brass selected pill, deep-ink on-accent), bottom scrim,
  fade-through `_BranchEntrance`.
- `flutter_app/lib/app/gauss_startup.dart`: detail routes fade in 60ms late
  over 220ms and fade out over 140ms.
- `flutter_app/lib/ui/components/gauss_state_panel.dart`: flat EmptyState.
- Gauss keeps its own night-sky palette, brass accent, Manrope/Vazirmatn
  type and the map-first composition (see `DESIGN.md`).
