# Screenshot-backed Map and Study QA — 2026-07-30

## Why this pass exists

The corpus repair queue remains the main release blocker, but the map-first
experience must improve alongside it. This pass inspected the built Flutter
web app rather than relying only on widget-tree tests, while leaving the
user-owned `map_screen.dart` working change untouched.

## Observed release-build states

| Surface | Viewport | Observed result |
| --- | --- | --- |
| Map after onboarding | 411 × 890 | Compact header, continuous illuminated route, live Persian topic plaques, current-study dock, and floating bottom navigation all fit without clipping. |
| Study Observatory | 411 × 890 | Subject switch, continuation instrument, study modes, and floating navigation remain distinct touch targets above the atmospheric backdrop. |
| Map after onboarding | 900 × 1180 | Rail navigation replaces the compact dock; wide path keeps a stable focal landmark and readable labels without turning the map into a card dashboard. |

The browser uses the same release web bundle built by Flutter. This is visual
browser evidence only: it does not replace Android device or Xiaomi Focus Pen
proof.

## Change made from the review

The Study Observatory rendered the grammatically inverted line
`0 of 2,042 questions reflected on`. It now says
`0 of 2,042 question cards reflected`, which is both readable English and
accurately describes a personal study record rather than an answer-correctness
claim. `study_experience_test.dart` asserts this initial state.

## Semantic follow-through

The visual review found that the unscored study path was called
`CURRENT MISSION` while the controller deliberately exposes zero
mission-ready questions during certification. The map-header edit owned by
the user does not overlap the dock implementation, so the dock now says
`CURRENT STUDY` in both visible copy and accessibility semantics. Its focused
map-dock test passes, and the independent user-owned compact-header changes
remain unstaged.
