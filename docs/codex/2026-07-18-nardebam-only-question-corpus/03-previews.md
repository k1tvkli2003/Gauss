# Runtime Preview Ledger

## Policy

Only captures from the compiled Flutter release or installed signed Android APK
are marked verified. Blank in-app-browser diagnostics and any capture showing a
different foreground package were deleted rather than presented as evidence.

## No Previews Required

No mock previews were required for the final verification ledger. The accepted
concept image informed the direction, but every item below is real runtime
evidence rather than a mock presented as implementation.

## Verified Web Release Captures

| Surface | Viewport | Direct route | Asset |
|---|---:|---|---|
| Map | 411×820 | `/#/map` / root redirect | `runtime-map-phone-release.png` |
| Map | 1440×900 | `/#/map` | `runtime-map-desktop-release.png` |
| Study Observatory | 411×820 | `/#/study` | `runtime-study-phone-release.png` |
| Study Observatory | 1440×900 | `/#/study` | `runtime-study-desktop-release.png` |
| Personal Constellation | 411×820 | `/#/insights` | `runtime-insights-phone-release.png` |
| Study Room | 411×820 | in-app set route | `runtime-study-room-phone-release.png` |

## Verified Android v90 Captures

| Surface | Evidence | Asset |
|---|---|---|
| Continuous Map | Signed APK, cold-launched on Android 15 | `runtime-map-android-v90.png` |
| Study Observatory | Semantic navigation to tab 2 | `runtime-study-android-v90.png` |
| Study Room | Semantic `Begin set` action and real preserved question | `runtime-study-room-android-v90.png` |
| Direct question ink | Native DOWN/MOVE/UP sequence; Clear became enabled | `runtime-study-room-pen-android-v90.png` |

## Visual Inspection Result

- Phone: no render overflow; floating navigation stays legible and content has
  a usable bottom inset.
- Desktop: full-height rail, continuous path, inspector, and two-column Study
  atlas use the available width without turning into a dashboard grid.
- Identity: the Gauss wordmark, Theorem Star, brass/teal system, astronomical
  field, parchment question plate, and sculpted node assets read as one system.
- Persian learning content remains readable and correctly directed while all
  app chrome stays English.
