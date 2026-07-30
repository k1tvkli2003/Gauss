# Study Room ink toolbelt — UI elevation

## Scope and direction

This is an **Elevate** pass on the question plate inside the Study Room. The
app's map-first route, private-study flow, source-preserving corpus boundary,
and Focus Pen input model remain unchanged. The concrete job was to make
writing directly on a Persian question feel deliberate and immediately
recoverable instead of hiding the only destructive local action behind a faint
icon.

Working visual reference: the existing Study Room shell and question plate.
The accepted direction is a calm instrument strip inside that plate rather than
a new card, floating toolbar, or global editor. It keeps attention on the
question and does not turn the Persian learning content into app chrome.

## Whole-experience opinion ledger

| Surface | Opinion | Evidence and preserved behavior |
| --- | --- | --- |
| Map / mission entry | KEEP | The map is the primary surface and its mission dock already exposes the next action. |
| Study Room question plate | REFINE | It retains live Persian/TeX content and direct stylus writing; the tool state and clear action now have stronger information scent. |
| Focus Pen / pressure / palm rejection | KEEP | Native input, pressure response, page-scroll ownership, and Android palm-rejection handling are unchanged. |
| Finger drawing switch | KEEP / REFINE | It remains opt-in so fingers scroll by default; the status badge now reflects the mode. |
| Clear ink action | REFINE | Still immediate and session-local; it becomes text-visible as `Clear` when room allows and preserves a 48dp icon target at narrow widths. |
| Full scratchpad | KEEP | It remains a separate, full-size working sheet for free-form practice. |
| App / wordmark / icon | KEEP | No identity asset or platform surface changed in this slice. |

## Preview-to-production decomposition

| Layer | Implementation | Responsive rule | Semantics / performance |
| --- | --- | --- | --- |
| Persian question and TeX | Existing live `ContentBlocksView` | Keeps RTL layout; long math uses the existing safe renderer | Live, selectable semantic content; unchanged. |
| Ink strokes | Existing live `CustomPaint` canvas | Plate-bound at every size; session-local | No source or progress mutation; existing input performance limits retained. |
| Instrument state | New live `_InlineInkStatus` | Expands in available row width and ellipsizes rather than pushing controls | Announces pen-ready, finger-ink, or ink-present state. |
| Clear command | Existing live `IconButton`, refined | Text `Clear` appears only at >=280 logical px; the 48dp icon target remains stable everywhere | Exact tooltip and disabled state; immediate local clear. |
| Pen-width / finger controls | Existing live controls | Fixed touch targets; never displaced by the status chip | Existing tooltips, toggle semantics, and device behavior retained. |

No generated or raster identity asset was added. The three runtime captures are
saved as durable evidence:

- `assets/study-room-ink-toolbelt-web-phone.png`
- `assets/study-room-ink-toolbelt-web-tablet.png`
- `assets/study-room-ink-toolbelt-web-wide.png`

## Interaction contract

- A hardware Focus Pen or stylus still writes directly on the question.
- Finger/mouse drawing remains explicitly opt-in; normal finger drags remain
  available to scroll the Study Room.
- Once ink exists, the state becomes `INK ON PLATE`, the explanatory line says
  that clear is immediate, and the clear control becomes visually labelled on
  normal phone/tablet/wide layouts.
- Clearing only removes the current session's strokes. It never changes the
  immutable source question, answer, media, learner study record, or progress.
- On off-screen `PageView` children, input remains disabled so an old plate
  cannot intercept a new page's gesture.

## Screenshot matrix and visual result

| Viewport | Result |
| --- | --- |
| 390 × 844 phone | Question plate, badge, tool targets, Persian/TeX, options, and bottom pager fit without overlap or clipping. |
| 768 × 1024 tablet | The plate gains horizontal room while keeping the content-first single flow. |
| 1440 × 960 wide | The two-pane Study Room preserves the plate as the prompt surface and keeps response actions independently readable. |

The captures were taken from the actual release web build through the Flutter
CanvasKit runtime. The preview helper now enables Flutter semantics before
dismissing the first-run tour, avoiding a canvas-coordinate-only setup path.

## Mismatch ledger

| Preview / intent | Rendered evidence | Result |
| --- | --- | --- |
| Calm instrument strip, not a separate card | All three captures | Matched: status sits inside the parchment plate and no new frame competes with the question. |
| Clear must be obvious after marking | Widget interaction test + responsive implementation | Matched: labelled in normal room, icon + tooltip/semantics in narrow room. |
| Do not make finger drawing the default | Phone/tablet/wide captures and input tests | Matched: `PEN READY` is the default; the hand remains explicit opt-in. |
| Preserve Persian and TeX composition | Phone/tablet/wide captures plus corpus render tests | Matched. |

## Precision ledger

- **Math / ratio:** all persistent controls use the existing 48dp touch token;
  `Clear` is conditionally added only at a measured 280px local-content width.
- **Alignment:** system controls are LTR/start-aligned as app chrome; the
  question stays separately RTL. This avoids mixed-script toolbar ambiguity.
- **Placement:** destructive-local clear remains beside the instrument state it
  affects, not in the global header or pager.
- **Frames:** the question plate remains the only working frame; no nested card
  was introduced.
- **Overlap / clipping:** checked in the 390, 768, and 1440 runtime captures
  and the 320dp/200% widget-test coverage.
- **State stress:** ready, ink-present, finger-ink, canceled stroke, palm
  rejection, controller replacement, and disabled off-screen page paths are
  covered by tests.
- **Remaining proof gap:** CanvasKit automation can capture the ready layout,
  but synthetic `PointerEvent(pointerType: pen)` injection is not a substitute
  for device stylus hardware. Physical Xiaomi Focus Pen proof remains open.

## Verification

```text
dart analyze lib test                         # no issues
flutter test                                  # 96 passed
flutter build web --release --no-wasm-dry-run # passed
flutter build apk --debug                      # passed
```

The existing Android input tests cover direct stylus acceptance, pressure-based
stroke width, cancellation rollback, explicit finger mode, parallel-stylus
palm rejection, and page-scroll ownership. They do not claim physical device
or Xiaomi Focus Pen proof.

Latest debug APK: `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`
(`259,173,826` bytes, SHA-256
`942FBDDD401CD74F48E0D04745727F7ABDE1D794A2253687A1038B660F520721`).
