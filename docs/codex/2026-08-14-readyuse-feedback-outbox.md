# ReadyUse feedback outbox — 2026-08-14

## Source and integration mode

- canonical component: `flutter.private-feedback-capture` version `1.2.2`;
- canonical source:
  `C:/Users/K1/Desktop/Projects/Components/flutter/private-feedback-capture`,
  verified independently with `verify_component.py` before adaptation;
- target: `C:/Users/K1/Desktop/Projects/Gauss/flutter_app/lib/feedback`;
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
- added `pending/syncing/synced/failed` state and a stable outbox id used as
  the authenticated Supabase idempotency key;
- upgraded the existing question-report path instead of creating a competing
  repair system; it retains question id, exact served revision, topic,
  session, mission index, selected choice, issue category, and optional
  screenshot;
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
- screenshot failure is fail-soft: the learner can still save a text report;
- added account-bound Supabase delivery: reports commit locally first, recover
  interrupted sync, retry idempotently, and remain local after any upload
  failure. Private screenshots use an owner-prefixed Storage path and the
  report row stores its SHA-256;
- retained the reviewed canonical ZIP export, but adapted delivery to Android
  `ACTION_CREATE_DOCUMENT`. The user chooses the destination directly; no
  Share Sheet opens. The export snapshot is one SQLite transaction and
  contains redacted notes, stable question ids/revisions, optional PNG files,
  and screenshot hashes;
- bounded the export confirmation to a 640dp reading width on tablets and made
  its warning scroll-reachable at 320dp with 200% text.

## Intentionally excluded

- social sharing, native Share Sheets, `share_plus`, recipients, and every
  public/social distribution path. Private ZIP export is explicitly allowed;
  it uses Android's Save Document picker and needs no broad storage permission.
- diagnostic-log interception and global error hooks. This checkpoint captures
  owner-authored feedback only; no hidden telemetry was added.
- credentials and account identity inside exports. Email, password, Supabase
  user id, access tokens, progress, and other account data are not written to
  the ZIP.

## Verification

- canonical `verify_component.py`: passed, 20 files scanned;
- complete `flutter analyze --no-pub`: no issues;
- complete `flutter test --no-pub`: 223 passed and one intentional benchmark
  skip; the final focused feedback/export suite passed 14/14 after the
  runtime-derived accessible-dialog repair;
- schema 7 to 8 migration test preserves the existing `tour_seen` progress
  flag and creates an empty outbox additively;
- widget tests cover 320dp/200% text, 48dp capture action, mandatory preview
  ordering, text redaction, corrupt PNG rejection, and Mission screenshot
  persistence;
- dedicated feedback composition tests pass at 800x1280 tablet portrait and
  1280x800 tablet landscape, including bounded reading width, safe bounds, and
  reachable 70dp actions;
- export tests prove exact question revision binding, retry after failure,
  credential exclusion, redaction, screenshot SHA-256, and an accessible
  confirmation at 320dp/200% text;
- live Supabase proof created two temporary confirmed accounts through the real
  `gauss-signup` function. The owner could upload/read its PNG and report; the
  second account saw zero rows, could not insert across accounts, and could not
  read the PNG. All temporary users, rows, and objects were removed;
- visual QA APK build 139 was installed as `com.gauss.app.debug` beside the
  untouched signed personal `com.gauss.app` package;
- real Android evidence:
  - `.codex-tmp/gauss-feedback-tools-126.png` caught and then proved the fix for
    the shell footer overlay;
  - `.codex-tmp/gauss-feedback-menu-127.png` proves the navigator-wired lens;
  - `.codex-tmp/gauss-feedback-preview-128.png` proves a clean app-only preview;
  - `.codex-tmp/gauss-feedback-outbox-129.png` proves screenshot persistence
    across reinstall/restart, legacy-entry preservation, and source-neutral
    question chrome;
  - `.codex-tmp/gauss_feedback_outbox_tablet.png` proves the account-local
    Outbox composition in tablet landscape;
  - `.codex-tmp/gauss_feedback_document_picker_tablet.png` and the pulled
    910-byte runtime ZIP prove native Save Document delivery and valid
    `manifest.json` plus `report.md` contents;
  - `.codex-tmp/gauss_feedback_export_confirm_138_tablet.png` proves the
    corrected bounded tablet dialog;
  - `.codex-tmp/gauss_feedback_outbox_320dp_200pct.png` and
    `.codex-tmp/gauss_feedback_export_confirm_139_320dp_200pct_scrolled.png`
    prove full reflow and reachable warnings at the accessibility gate;
- fresh logcat after tablet and 320dp/200% export flows contained no Flutter
  exception, FATAL, RenderFlex, or feedback-export error.

The canonical component source was not modified. All product-specific behavior
lives in the Gauss target snapshot.
