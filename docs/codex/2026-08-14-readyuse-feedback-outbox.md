# ReadyUse feedback outbox — 2026-08-14

## Source and integration mode

- canonical component: `flutter.private-feedback-capture` version `1.2.2`;
- canonical source: personal Components library, verified independently with
  `verify_component.py` before adaptation;
- target: `flutter_app/lib/feedback`;
- integration mode: target-owned snapshot and behavioral adaptation. Gauss has
  no runtime dependency on the machine-local Components library.

## Frozen behavior retained

- app-surface screenshot capture under a `RepaintBoundary`;
- the capture control is absent from its own screenshot;
- screenshot preview before save, with an explicit pixel-privacy warning;
- typed feedback categories and route context;
- credential-pattern redaction before text reaches persistent storage;
- bounded screenshot dimensions, pixel ratio, individual byte size, aggregate
  byte size, and report count;
- private review, detail, delete, and clear actions;
- a draggable capture control with a 52dp target and constrained positioning.

## Gauss adaptations

- replaced the canonical filesystem/index store with one additive Drift table,
  so report metadata and optional PNG bytes commit atomically;
- added `pending/syncing/synced/failed` state and a stable outbox id for the
  forthcoming authenticated Supabase idempotency key;
- upgraded the existing question-report path instead of creating a competing
  repair system; it retains question id, topic, session, mission index,
  selected choice, issue category, and optional screenshot;
- kept pre-outbox AppFlag reports readable and deletable without rewriting or
  discarding them;
- made the floating lens opt-in and exposed it through the centered Insights
  tools action, avoiding permanent Map/HUD clutter;
- anchored overlay presentation to the root GoRouter navigator so the lens can
  open sheets even though it deliberately lives above the routed surface;
- waits for the feedback menu's reverse transition before capture and hides
  the lens for the complete feedback flow, so preview pixels contain only the
  selected app surface and never the feedback UI itself;
- keeps immutable source question ids in storage while displaying a neutral
  `Question <year>-<number>` reference in product chrome;
- used Gauss astronomical tokens and full English product chrome;
- screenshot failure is fail-soft: the learner can still save a text report.

## Intentionally excluded

- ZIP export, native share sheets, file pickers, external storage, and every
  share/export dependency. Gauss explicitly has no sharing feature.
- diagnostic-log interception and global error hooks. This checkpoint captures
  owner-authored feedback only; no hidden telemetry or upload was added.
- network sync. Reports remain local until the separate account-scoped
  Supabase/RLS lane passes its own runtime gate.

## Verification

- canonical `verify_component.py`: passed, 20 files scanned;
- focused Flutter analyze: clean over every changed app, feedback, data,
  Mission, and test surface;
- the complete Flutter suite passed before the final runtime-derived fixes
  (197 passed, one pre-existing skip); subsequent focused suites passed across
  feedback, migration, repository, Mission, Insights, Android experience,
  English chrome, and route motion;
- schema 7 to 8 migration test preserves the existing `tour_seen` progress
  flag and creates an empty outbox additively;
- widget tests cover 320dp/200% text, 48dp capture action, mandatory preview
  ordering, text redaction, corrupt PNG rejection, and Mission screenshot
  persistence;
- dedicated feedback composition tests pass at 800x1280 tablet portrait and
  1280x800 tablet landscape, including bounded reading width, safe bounds, and
  reachable 70dp actions;
- debug APK build 129 was installed beside the untouched signed personal
  `com.gauss.app` build 106 on `Codex_API35`;
- real Android evidence:
  - `.codex-tmp/gauss-feedback-tools-126.png` caught and then proved the fix for
    the shell footer overlay;
  - `.codex-tmp/gauss-feedback-menu-127.png` proves the navigator-wired lens;
  - `.codex-tmp/gauss-feedback-preview-128.png` proves a clean app-only preview;
  - `.codex-tmp/gauss-feedback-outbox-129.png` proves screenshot persistence
    across reinstall/restart, legacy-entry preservation, and source-neutral
    question chrome;
- fresh logcat after the final flow contained no Flutter exception, FATAL,
  RenderFlex, or SQLite error.
