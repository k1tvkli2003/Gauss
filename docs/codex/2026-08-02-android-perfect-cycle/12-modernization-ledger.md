# Android modernization ledger — 2026-08-02

## Product stance

Gauss remains a private, offline-first astronomy learning instrument. The Map
is the home surface; Study, pencil work, rewards, and course changes should
feel like actions on that instrument rather than separate dashboard screens.
The target is deliberate game-learning craft, not a copy of another product.

## Reference decomposition

The accepted visual direction is the astronomical, brass-and-teal continuous
path reference supplied in the task. Its reusable layers are:

| Layer | Implementation choice |
| --- | --- |
| Deep-space field, orbit lines, distant star texture | Existing live Map background and painters; decorative only. |
| Progress path, nodes, status, course title, selected lesson | Live Flutter widgets; semantic and state-driven. |
| Gold/teal identity, Theorem Star, instrument rings | Existing project-native brand and vector/painter system. |
| Question scratch, pen state, clear/undo, deep sheet | Live Flutter widgets; immediate and accessible. |
| End-of-session astrolabe, glow, particles | Live Flutter motion plus reusable static ornament only; reward values stay live. |

No critical learning content, answer, status, or Persian text will be flattened
into an image. All such values remain selectable, accessible Flutter text.

## Chosen working direction

The working concept preview is
[`ink-lens-orbit-resonance-concept-v1.png`](assets/concepts/ink-lens-orbit-resonance-concept-v1.png).
It is a **visual reference**, not a runtime screen or source of text. It
establishes the intended relationship between four interactive systems:

1. **Ink Lens** — the question is the writing surface; a small contextual
   Pen Halo appears only after ink, replacing an always-visible tool bar.
2. **Deep Sheet** — a voluntary expansion of the same ink session, not a
   second scratchpad that loses work.
3. **Five-question pulse** — one micro-lesson has five visible pips and a
   single calm continuation point.
4. **Orbit Resonance** — completing those five prompts charges the current
   map instrument and reveals the next real session with truthful rewards.

## Overlay contract

| Surface | Strategy | Anchor and responsive rule |
| --- | --- | --- |
| Pen Halo | Live semantic overlay | Anchored to the final active ink point, clamped to the question safe bounds; becomes a wrapped/linear control group when there is less than 300dp or text scale is at least 1.55. |
| Clear and undo | Live semantic controls | Minimum 48dp hit targets; clear is disabled until ink exists and never silently destroys a stroke. |
| Orbit Navigator | Live modal / side panel | Triggered by the current-orbit selector; bottom sheet below 600dp, end-aligned panel at medium and larger widths; course switch and chapter rail remain live. |
| Celebration instrument | Hybrid live composition | Decorative rings/particles may be painted; session name, 5/5 status, rewards, revisit count, and continuation remain live widgets. |
| Map lesson dock | Live semantic overlay | Its bottom baseline derives from the actual NavigationBar plus system inset and an optical gap; it reflows before copy and controls can collide. |

## Non-negotiable quality gates

- Every interactive target is at least 48dp and adjacent targets retain a
  visible gap.
- At 320dp, representative phones, tablets, RTL/LTR learning data, and 200%
  text, critical phrases reflow rather than clip or ellipsize.
- Reduced motion replaces animated travel/particles with a static completion
  state; it never removes the result or next action.
- Finger scrolling and answer selection remain available while a stylus owns
  a stroke; a palm arriving after the stylus cannot hijack that stroke.
- Android proof is a fresh debug variant installed next to, never over, the
  signed personal app.

## Evidence status

- Map dock geometry and Orbit Navigator: widget-tested; Android refresh queued
  after the current debug build.
- Ink Lens and Orbit Resonance: visual direction locked; implementation and
  runtime proof remain open.
- Physical Xiaomi Focus Pen behavior: code-level input handling tested;
  hardware confirmation remains open until tested on that device.

## Perfect cycle 95 — Orbit density and truthful micro-lessons

Frozen critique from the v94/reference comparison:

1. The first chapter was announced twice: once by the Orbit selector and again
   by a full-width `CHAPTER 1` gate. The duplicate consumed the most valuable
   first-frame Map height.
2. Map nodes exposed implementation copy (`Session x of y`) rather than the
   screened concepts inside each five-question micro-lesson.
3. Heavy label pills competed with the node instruments and reduced the
   reference's sense of one continuous route.

Implemented and verified locally:

- compact Chapter 1 identity and progress now live inside the Orbit selector;
  later chapter gates remain real route thresholds;
- every visible node is still exactly five questions, but its live label is
  derived deterministically from the screened concept metadata;
- the first compact gate no longer consumes geometry, revealing four complete
  route instruments in the physical first frame instead of three;
- label framing is quieter and concept labels retain semantic session ordinal
  information for accessibility;
- 24 focused Map/curriculum tests passed and full `flutter analyze` reported no
  issues before the next UI slice began.

Android evidence:

- debug package `com.gauss.app.debug`, versionCode 93, installed with `-r` on
  `emulator-5556`; signed `com.gauss.app` was not replaced or cleared;
- [`gauss-map-v95-ready.png`](assets/gauss-map-v95-ready.png) and
  [`gauss-map-v95-ready.xml`](assets/gauss-map-v95-ready.xml) prove the real
  1080 × 2400 Map frame and accessibility bounds.

## Frozen critique after Android v95

The physical frame exposed the next two high-impact defects, now active work:

- the 224dp Current Study card is too narrow for its information, producing a
  tall, visually unbalanced block with weak hierarchy and an ambiguous book
  action;
- the M/P segmented pill uses unexplained letters, dominates the top-right
  footprint, and does not express the mathematical/physical mode change;
- the first generated label allowed `Counterexample` to break mid-word, which
  violates the no-broken-phrase contract even though it did not overflow.

The chosen response is a centered, wide **Current Mission ribbon** with a live
five-question track and symmetric side slots, plus a **Dual Orbit** control
using function/atom identities and two independent 48dp targets. These changes
remain unverified until the post-gamification compile gate, focused tests, and a
fresh Android capture pass.

## Perfect cycle 96 — private progression and five-question closure

The Current Mission and Dual Orbit response is now implemented and verified.
The next cycle closes the private learning loop without adding hearts, leagues,
sharing, social comparison, authentication, or monetization:

- the reward engine emits stable, rule-versioned receipts from persisted study
  events rather than animation state;
- an injected local-day clock governs streaks and the daily quest, including
  local-midnight rollover, a monotonic day watermark against backwards clock
  travel, and one humane grace day;
- Map exposes a compact daily-streak target and a detailed Daily Orbit sheet;
- Insights uses one `PRIVATE ORBIT` instrument for quest, daily streak, level,
  and the next real seal rather than duplicating those facts across cards;
- completing the fifth question opens a presentation-only celebration that
  displays the already-persisted XP receipt and routes to the next real
  five-question session or back to Map after the terminal unit;
- a failed reflection stays on the same question with its hypothesis and ink
  intact, and retry is guarded against duplicate writes.

### Adversarial defects found and repaired

1. The first 320dp/200% pass exposed a 33px `RenderFlex` overflow in the
   expanded `OPEN PROGRESS` cue. The cue now yields its copy width and wraps.
2. The first Android Daily Orbit capture exposed a subtler language defect:
   three numeric columns fit their boxes while `STREAK` and `RHYTHM` split
   mid-word. Horizontal layout now requires enough width for whole English
   labels; phone sheets reflow into three calm rows.
3. A quest-only or level-only celebration could inherit the session visual and
   falsely show `5 / 5`. Celebration identity and seal copy now derive from the
   authoritative completion flags, with a regression for a zero-XP capped
   daily receipt.
4. The Insights integration test still searched for the retired duplicate
   quest card. It now verifies the unified `TODAY · QUEST` instrument.

### Automated proof

- 96 sequential focused tests passed across the reward engine, repository,
  five-question compatibility, Map HUD, Insights actions, Android composition,
  celebration, study persistence, RTL/math rendering, scratch input, and
  reduced-motion paths;
- the post-runtime breakpoint repair passed 26 focused Map/Android tests,
  including a 540dp physical-line regression for `DAY STREAK`, `DAILY RHYTHM`,
  `SAVED ON DEVICE`, and `DAILY QUEST`;
- full `flutter analyze` completed with no issues;
- the reward-specific suite proves midnight rollover, idempotent quest reward,
  backwards-clock resistance, humane grace, and database-reopen persistence.

### Android proof

The stable API 35 emulator completed a cold boot after the API 37 preview AVD
stalled in system boot animation. `com.gauss.app.debug` versionCode 95 was built,
installed with `-r`, launched, and inspected at 1080 × 2400. No command targeted
the signed `com.gauss.app` identity or its data.

- [`gauss-map-v96.png`](assets/gauss-map-v96.png) — continuous Map, Dual Orbit,
  Current Mission, and gesture-safe floating navigation;
- [`gauss-daily-orbit-v96-fixed.png`](assets/gauss-daily-orbit-v96-fixed.png) —
  repaired whole-word Daily Orbit composition;
- [`gauss-insights-orbit-v96.png`](assets/gauss-insights-orbit-v96.png) — unified
  quest, streak, level, and seal instrument;
- [`gauss-study-v96.png`](assets/gauss-study-v96.png) — live Persian question and
  mixed-direction mathematical options;
- [`gauss-celebration-v96.png`](assets/gauss-celebration-v96.png) — real fifth
  reflection, persisted `+24 XP` receipt, and next-session action.

The Android run also exposed a source-content mismatch: the first displayed
set-theory question carried an unrelated arithmetic-sequence explanation. The
Study UI correctly labels all imported answer material as unverified and makes
no correctness claim; the record remains a dataset-repair obligation rather
than being hidden, discarded, or silently rewritten by the UI lane.

## Perfect cycle 97 — Question Experience reconstruction

The question flow was treated as one continuous product surface rather than a
prompt card plus disconnected controls. This cycle covers both the unscored
Study Room and the certified scored Mission without changing source JSON,
media, answer contracts, or persistence semantics.

### Defects found and repaired

1. Study Room and Mission used separate ink ownership paths for inline writing
   and the expanded scratchpad. Both surfaces now share the same per-question
   `ScratchInkController`, so expanding never loses or forks a stroke.
2. Inline clear controls changed the height of the question paper. Ink tools
   now live in the floating action dock; prompt, choices, and navigation retain
   their geometry while Undo, expand, instant Clear, and four-second Restore
   replace the status instrument contextually.
3. Exiting could silently discard temporary ink or imply that an unchecked
   choice had been saved. Both flows now present a truthful, state-specific
   guard while preserving recorded progress and the remaining local queue.
4. At 320dp and 200% text, Mission metadata overflowed by 4.5px, the Study
   source label overflowed by 8.9px and later 7.4px, and the action dock changed
   height by 32px when ink controls appeared. Metadata and source identity now
   reflow vertically, the accessible dock height remains stable, and progress
   copy uses the requested text scale instead of a hidden scale clamp.
5. The scored completion view still used two generic rectangular text buttons
   and fragile horizontal XP rows. It is now a scroll-safe five-point orbital
   celebration with live score/reward text, adaptive XP receipts, reduced-
   motion behavior, and symbolic 48dp+ actions for a new mission or Map.
6. Dynamic save, correctness, and ink-restore feedback lacked a coherent live
   announcement. Concise visible copy and non-duplicated live semantics now
   report state without crowding the dock or announcing captions twice.
7. Answer-first mode ended in a generic `Uncover the choices` rectangle. It is
   now a semantic orbital lens with an explicit caption and a 56dp target;
   revealing the options remains one direct action at 320dp/200% text.

### Automated proof

- focused `flutter analyze` over the two question screens, scratch input,
  progress/action instruments, and their three regression suites completed
  with no issues;
- **44/44 sequential tests passed** across Mission save/retry/resume/exit,
  exact five-question completion, Study Room reflection and navigation,
  320dp/200% composition, tablet split layout, Persian RTL and mathematical
  rendering, invalid formula/media failure, stylus pressure, eraser, Undo,
  palm rejection, touch scrolling, Restore, and reduced motion;
- the completion regression drives all five real question positions, records
  five correct attempts, reaches the persisted receipt, verifies 48dp actions,
  scrolls the reward ledger, and rejects every ellipsized text widget;
- `git diff --check` is clean for the Question Experience slice apart from the
  repository's existing Windows line-ending notices.

### Android evidence boundary

Debug versionCode 111 was already installed beside the signed personal package
and proved the rebuilt normal-phone Mission, normal-phone Study Room, and a
real 320dp/200% Study Room without Flutter, RenderFlex, dataset-integrity, or
fatal logcat errors. That build predates the final completion receipt and the
last true-scale progress-label repair. A fresh post-cycle APK/capture remains
the final runtime gate; the shared emulator is currently owned by another
active preview run, so this ledger deliberately does not promote old imagery
as proof of the newest source.

## Perfect cycle 98 — Theorem Lens radical question rebuild

The Android v116 capture proved that the repaired flow was functional but not
yet a distinctive Gauss solving experience. In particular, the 320dp/200%
state let route copy dominate the viewport, the prompt behaved like a generic
paper card, answers read as four disconnected dark boxes, and the Study Room's
new reveal caption fell below the initial scroll viewport. This cycle therefore
uses **Radical rebuild** mode for the question presentation while preserving
every source, scoring, reflection, persistence, ink, and routing contract.

### Working preview and direction decision

Three repository-bound previews were generated from the real v116 Mission
capture:

- [`question-theorem-lens-v1.png`](assets/concepts/question-theorem-lens-v1.png)
- [`question-astral-codex-v1.png`](assets/concepts/question-astral-codex-v1.png)
- [`question-orbital-console-v1.png`](assets/concepts/question-orbital-console-v1.png)

**Theorem Lens** is the binding direction. It keeps the fastest reading model
and clearest answer stack. The production version may borrow the Console's
causal selection current and attached pen instrument, but not its dense panels
or generic readiness box. Astral Codex is rejected for production because its
large continuous manuscript and fixed tool gutter become inefficient at
320dp/200% text.

### Target-surface opinion ledger

| Surface | Opinion | Evidence, preserved function, and target |
| --- | --- | --- |
| Route/mission state, scoring, save/retry, exit guards | KEEP | Tests already prove the domain path; presentation must not grant or rewrite progress. |
| Balanced close/wordmark/tool header | REFINE | Preserve the true center axis; reduce large-text route dominance and turn five steps into a compact constellation. |
| Question paper | REDESIGN | Replace the generic rounded card with one layered theorem instrument whose frame and ink state belong to Gauss. Live Persian/math remains selectable and semantic. |
| Answer choices | REDESIGN | Replace disconnected cards with one connected answer orbit; keep long-content reflow, four explicit choices, selection, correct, wrong, disabled, and source-marked states. |
| Inline stylus and deep sheet | REFINE | Keep one shared per-question controller, direct pen input, pressure, palm rejection, Undo, expand, instant Clear, and four-second Restore; make state visible through the theorem instrument without shifting geometry. |
| Mission action dock | REDESIGN | Keep skip/status/submit functions but replace sentence-heavy center chrome with a compact semantic readiness signal and a content-hugging bounded instrument. |
| Study reveal | REDESIGN | Keep the truthful unverified-source action; use a fully visible symbol-first reveal rather than a rectangular text button or a clipped caption. |
| Solution, miss classification, reflection, completion | REFINE / KEEP | Preserve live content and mutations; inherit the same material/state language without hiding proof or recovery. |
| Map, Study Hub, Insights, branding, launcher/splash | OUT OF SCOPE for this slice | They remain governed by their existing ledger rows and later Goal steps. |

### Preview-to-production decomposition

| Layer/component | Type and source | Live state / semantics | Geometry and verification |
| --- | --- | --- | --- |
| Astronomical atmosphere | Existing bounded raster asset plus live dark veil | Decorative and pointer-transparent | Cover crop by phone/tablet class; verify no contrast loss. |
| Header and five-step constellation | Live Flutter | Route exit, scratch entry, question position, TalkBack | Equal outer action tracks; one-line/stack transformation from measured content, not viewport scaling. |
| Theorem Lens frame | Layered code-native vector painter plus existing Theorem Star mark | Neutral, ink-present, clear/restore; question remains live above it | Bounded flexible width, content-driven height, two frame rings, corner/axis markers; inspect at native scale. |
| Persian/math question and media | Existing live `ContentBlocksView` | Selectable, RTL/mixed-script semantics, render failures fail closed | 18sp question role with true system scaling and generous Persian line height; scrolls rather than clips. |
| Answer orbit rail | Layered code-native vector rail and live choice shells | Neutral, selected, disabled, correct, wrong, source-marked; explicit button semantics | 48dp medallions, content-driven row height, one connected rail; never assumes equal answer height. |
| Ink surface and controls | Existing live custom paint/controller | Pen, eraser, pressure, palm rejection, Undo, expand, Clear, Restore | Same normalized strokes in inline and deep sheet; no layout delta when ink appears. |
| Bottom solve instrument | Live Flutter + existing orbital action symbol | Skip, select/ready/feedback signal, save/retry, check/next/finish | Max functional width rather than tablet stretch; Android safe inset outside glass; all targets >=48dp. |
| Preview images | Documentation-only raster concepts | Never used as question text, controls, or runtime truth | Side-by-side reference gate against fresh Android captures. |

No generated preview text is shipped. No immutable corpus JSON or media is
changed. The only crafted runtime graphics in this slice are deterministic
vector layers whose live screenshots must prove material, scale, and contrast.

### Motion and symmetry contract

- `question_arrival`: stable shell; theorem frame settles with at most a
  220ms opacity/scale cue, then answers appear as one group. Reduced motion is
  immediate opacity only; ordinary rebuilds do not replay it.
- `answer_current`: selection moves a restrained teal/brass current through
  the selected answer shell for 140–180ms; it never delays submit or moves the
  target.
- `ink_present`: frame signal changes material/color in 140ms without changing
  bounds; Clear/Restore remains a state replacement in the fixed dock.
- Header is exact-axis symmetry (equal 48dp outer tracks, independently
  centered wordmark). The theorem frame is optical symmetry. Answer reading is
  controlled asymmetry: the physical LTR choice rail counterweights RTL/math
  content and does not mirror the mathematical reading plane.
- Acceptance viewports: 320dp/200%, 390–430dp normal phone, 840dp Study split,
  tablet Mission three-pane, reduced motion, RTL/mixed math, checked/wrong,
  ink/restore, loading/error, and five-question completion.

## Perfect cycle 99 — Accepted Astral Manuscript and language contract

The user selected the integrated astronomical manuscript preview as the final
question direction. Production now treats the question, writable reasoning
field, and all four answers as one continuous parchment instrument in both
Study Room and scored Mission. The parchment is a dedicated raster material;
all question text, mathematics, controls, ink, answer state, and semantics
remain live Flutter content.

### Product contracts closed

1. Every app-owned chrome string is English. Subject, difficulty, topic,
   navigation, progress, tool, feedback, and completion labels no longer use
   source-language UI aliases.
2. Every live numeral in question, answer, solution, shortcut, media alt text,
   and accessibility descriptions is normalized to ASCII `0-9` only at the
   render boundary. Immutable corpus rows are untouched. Media whose pixels
   contain non-ASCII numerals remains a certification/derived-asset obligation
   and cannot become mission-ready by this text normalization.
3. The generated blank parchment at
   `assets/visual/question/manuscript_parchment_v1.png` is used only as visual
   material. Its SHA-256 is
   `f54d06604cdd8e7e18b62d526c47a509c8b9e4ca75b3e6ce3f5ea523bb5b54fc`.
4. Normal phones bind Pen, Touch scroll, Undo, full scratchpad, stroke eraser,
   and Clear/Restore to a vertical left spine. At 320dp with 200% text those
   six 48dp controls reflow above the manuscript instead of shrinking or
   colliding. Hardware stylus writes in pan mode; finger pen and whole-stroke
   eraser are explicit modes.
5. Map now seeds its local orbit lens from the controller's durable selected
   topic on its first frame. This repairs a startup mismatch where Study could
   restore `Patterns & Sequences` while Map visually fell back to Sets.

### Automated evidence

- `question_manuscript_test.dart`: 3/3 passed, including 320dp/200% reflow,
  normal-phone vertical spine geometry, finger pen, and stroke eraser;
- `english_chrome_contract_test.dart`: 3/3 passed, including a production
  source scan and Persian/Arabic digit normalization;
- the combined question rendering, Focus Pen, Mission, and Study run passed
  51/51 before runtime proof;
- focused Map learning-context restore regression passed;
- focused analyze over each changed question and Map slice reported no issues;
- full `flutter analyze` reported no issues before the final Android
  breakpoint repair; the final whole-slice rerun is recorded below when this
  cycle is closed.

### Fresh Android evidence — debug versionCode 113

The debug identity `com.gauss.app.debug` was rebuilt, installed with `-r`, and
kept separate from the signed personal package. The actual scored proof used
the first fully hash-bound five-question plan at
`patterns_sequences:20:5`; no quarantined item was promoted or substituted.

- normal-phone Study: vertical tool spine, four complete engraved choices,
  scroll-clear bottom spacing, and a content-hugging safe-area dock;
- 320dp/200% Study: two-row tool reflow, full-scale Persian prose/math, all
  four choices reachable, and no RenderFlex/Flutter/fatal logcat error;
- tablet Study: wide manuscript, independent tool spine, four choices, and a
  compact centered navigation instrument rather than a stretched footer;
- normal-phone scored Mission: live Persian prompt, ASCII options `6`, `7`,
  `8`, `9`, selected state, submit, incorrect/correct answer frames, and the
  next action;
- 320dp/200% scored feedback: all choices and the review action remain
  reachable after scrolling, without clipped copy or collision;
- tablet scored feedback: manuscript, miss-classification controls, verified
  classic solution, and compact bottom action remain simultaneously usable.

For every captured Study/Mission semantics tree, the count of Persian or
Arabic numeral glyphs was exactly zero. No accepted logcat sample contained a
RenderFlex overflow, FlutterError, or fatal exception.

### Language-contract revalidation — Android debug v117

The language rule was promoted from a narrow renderer helper to one shared
domain boundary. `MaterialApp` now resolves only English and stays LTR even
when Android reports `fa-IR`; `ContentBlocksView` remains the local RTL island
for preserved Persian learning content. Eastern Arabic/Persian digits and the
decimal, group, and percent separators normalize to ASCII only in effective
presentation. The first-run tour's stale “twenty questions” claim was also
corrected to the product's real five-question micro-lesson contract.

Fresh Android evidence under `fa-IR` proves the Map, orbit selector, chapter,
selected lesson, footer, Study Room header, tool semantics, and bottom question
instrument are English. The live Persian manuscript preserved correct RTL
reading while UIAutomator exposed only ASCII mathematical numerals (`0`
non-ASCII numeral matches). The accepted log contained no RenderFlex,
FlutterError, or fatal exception. The emulator was then restored to `en-US`,
`1080x2400`, density `420`, font scale `1.0`, and rotation `0`.

Certification now also blocks any question with embedded media unless every
effective asset has a current hash-bound `no_digits` or `ascii_only` review.
The present 49 mission-ready questions contain zero such assets; no source
JSON or media was mutated to satisfy the policy.
