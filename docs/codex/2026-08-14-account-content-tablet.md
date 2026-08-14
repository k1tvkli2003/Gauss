# Account, content plane, and tablet gate — 2026-08-14

## Objective

Add a deliberately small Gauss account boundary without disturbing existing
StudyHUB accounts, isolate every local and cloud-owned record per user, prepare
stable question revisions for small data-only updates, and make tablet portrait
and landscape first-class Android targets rather than enlarged phone layouts.

## Completed account and security foundation

- Added Supabase email/password sign-in and instant Gauss registration through
  the deployed `gauss-signup` Edge Function. Registration validates inputs,
  applies server-only network/email throttles, avoids account enumeration, and
  confirms the new account without an email-verification step.
- Added `gauss_profiles` without a global `auth.users` trigger. Existing
  StudyHUB accounts are enrolled only after they actually open Gauss.
- Replaced permissive legacy Gauss policies with authenticated owner policies;
  anonymous access was revoked.
- Added owner-isolated progress snapshots, idempotent event rows, and feedback
  reports. Live two-account proof showed one owner row visible, zero rows visible
  cross-account, a cross-account insert rejected, and anonymous content access
  rejected. Temporary proof accounts were removed afterward.
- Local Drift files, backups, pending feedback, and controller lifecycles now
  use an opaque account-derived storage key. Switching accounts closes the old
  session before the new database is opened; backups from another account are
  rejected before restore.

## Versioned content foundation

- Added immutable content releases, release artifacts, stable question
  revisions, and named content channels in
  `supabase/migrations/202608140001_gauss_account_content_plane.sql`.
- Stable source identities such as `nardebam_math_1405_0001` remain the logical
  question key while a monotonically increasing revision carries later wording,
  answer, solution, taxonomy, or media corrections.
- The Android client receives only the public publishable key. No service-role
  or other server secret is present in Flutter source or Android resources.
- The live migration was rehearsed through rollback, then applied and audited
  with RLS enabled on every new table and no anonymous legacy privileges.
- Split immutable question revisions from release membership through
  `gauss_release_questions`. A later wording or solution fix creates one new
  revision and a small release-link delta instead of duplicating every
  unchanged question.
- Added the authenticated `gauss_release_payload` RPC with explicit bounded
  pagination. Live proof at offset 500 returned exactly ordinals 500 and 501;
  anonymous access remains denied.
- Published `gauss-2026.08.14.1` to `android-stable`: 3672 stable questions,
  29 topics, four hash-bound artifacts, minimum app build 90, and corpus SHA-256
  `af918908bd86f219ef27865f593eedb152359c0e9825a1319a9c3723badb2966`.
- Added a fail-closed Android content store. It downloads into staging,
  validates every artifact/question/order/identity/hash, verifies the staged
  files, then atomically moves the active pointer. Offline, corrupt,
  path-traversal, partial, or too-new releases preserve the last verified
  snapshot; the bundled corpus remains the final fallback.
- Added a secret-free publisher using the Supabase Management API access token
  from the protected environment. It validates all source rows and media,
  reconciles remote inserts before publish, and never exposes a service-role
  key to the app or command line.
- Cross-language contract tests independently rebuild the four artifact hashes
  and complete corpus hash from the real 3672-row corpus in both Python and
  Dart, then bind them to the checked-in live release receipt.
- Question-content edits now require no APK rebuild: the authenticated Android
  client checks the named channel and atomically activates a verified release.
  Stable question ids preserve the identity used by progress, reports, and
  future revisions while the served revision remains explicit.
- Precision boundary: Supabase storage/publishing is revision-delta today, but
  the current Android refresh still downloads the complete question payload of
  a changed release before activation. A manifest-first client payload cache is
  still required before claiming network-delta refreshes. This limitation does
  not affect APK independence, stable identity, rollback, or offline reuse.

## Account-bound feedback and private export

- Adapted ReadyUse `flutter.private-feedback-capture` 1.2.2 as a target-owned
  Gauss snapshot. Reports are persisted in the current account's Drift file
  before any network attempt and sync only through owner RLS.
- Every question report carries stable question id plus exact served revision.
  Screenshot uploads use a private owner-prefixed Storage object and the cloud
  row carries its SHA-256, content release, session, issue type, and selected
  choice without shipping any service-role credential.
- Export is allowed. Gauss builds a private ZIP with redacted notes,
  question ids/revisions, and optional PNG files, then opens Android Save
  Document. Social Share/Share Sheet remains absent. Exports omit email,
  password, access token, Supabase user id, and progress.
- Migrations `202608140003_gauss_feedback_delivery.sql` and
  `202608140004_gauss_feedback_storage_cleanup.sql` were applied through the
  checksum-ledger migration runner. The private bucket permits owner read,
  insert, update, and delete only.

## Dedicated adaptive Auth composition

- Phone portrait uses one scroll-safe centered instrument.
- Tablet portrait owns a wider but bounded identity stage and account
  instrument; it does not stretch controls edge-to-edge.
- Tablet landscape owns an independent two-pane composition: brand/context on
  the left and the account instrument on the right. Both panes can scroll
  independently under 200% text or an open keyboard.
- Authentication mode controls stack instead of compressing when text scaling
  or available width requires it. Interactive targets remain at least 48dp.

## Dedicated Android learning surfaces

- Added one two-axis window vocabulary for the whole app. Width and height are
  classified independently, so a physical tablet in split-screen never
  inherits a roomy landscape composition merely because the device is large.
  The canonical pane thresholds are 840dp for two panes and 1200x600dp for a
  full horizontal-tablet workspace.
- The app shell now gives medium windows a compact icon rail, a normal
  1280x800 tablet a labelled navigation rail, and a short 1440x479 window a
  compact rail again. The rail is content-hugging and clears Android system
  insets; phone navigation remains a floating glass dock sized around its
  three controls.
- Map landscape is a true three-region surface: labelled navigation, the
  continuous lesson path, and a persistent Study Inspector. Portrait removes
  the inspector and centers the selected-lesson instrument; 200% text and
  short windows also collapse safely rather than squeezing the path.
- Study landscape keeps the subject selector bounded, presents all four study
  tools on one axis, and lays chapter instruments in two columns. Tablet
  portrait uses a two-by-two tool rhythm and one-column chapters instead of a
  stretched landscape layout.
- Insights landscape exposes four equal metric instruments in one glance,
  followed by wide reflection and Private Orbit compositions. At 200% text it
  deliberately reflows to a two-by-two metric grid; compact phones use one or
  two columns as space permits.
- Mission landscape no longer spends space on a decorative companion panel.
  Before checking, the 820dp manuscript is centered and readable. After
  checking, a 1280x800 tablet becomes a focused Question + Solution workspace;
  portrait, 200% text, and short-height windows return to one complete vertical
  reading flow. A real-device-only bug where the Solution pane was gated by
  the remaining Column height instead of the Android window height was found
  and repaired.
- Rotation preserves the selected option, checked state, inline ink controller,
  and current question while the composition changes. Archive, Vault, Daily
  Orbit, Map inspector, and metric grids use the same window-first contract.
- Added a fail-closed visual-preview entry point for Android QA. It requires
  `GAUSS_VISUAL_PREVIEW=true`, uses an isolated preview-only local account, and
  is contract-tested to stay out of production `main.dart` and release builds.

## Verification

- `flutter analyze --no-pub`: no issues across the complete project.
- `flutter test --no-pub`: 223 passed, one intentional benchmark skip.
- Focused Auth matrix: 7/7 passed at 320x760 phone, 800x1280 tablet portrait,
  1280x800 tablet landscape, 100% and 200% text, plus landscape keyboard inset.
- Account and backup isolation: 9/9 passed.
- Content release store: 5/5 passed, including atomic activation, offline
  reopen, corrupt-newer rollback, minimum-build fallback, unsafe-path rejection,
  and exact 3672-row receipt reconciliation.
- Content publisher: 2/2 Python tests passed; deterministic dry-run reproduced
  the published question/topic counts and corpus hash. Focused Flutter analysis
  over the content/auth integration is clean.
- Feedback/Auth/content focused matrix: 27/27 passed; after the final
  runtime-derived accessibility repair the feedback/export subset passed
  14/14. Tests cover sync retry, revision binding, redaction, credential
  exclusion, screenshot hashing, tablet bounds, and 320dp/200% reachability.
- Live two-account feedback/storage proof passed against Supabase: owner row 1,
  cross-account row 0, cross-account insert rejected, owner PNG round-trip
  true, cross-account PNG read rejected. Post-proof audit found zero temporary
  users, reports, or Storage objects.
- Debug APK build 130 installed beside the untouched personal package.
- Final production-entry debug APK build 140 compiled from `lib/main.dart` at
  250,695,702 bytes with SHA-256
  `305ef5e6eeb58183ad66e2708663d1666e80545d10a3f488a5adaf3653556210`.
- Visual QA APK build 139 installed as `com.gauss.app.debug`; the signed
  `com.gauss.app` package and its data were not replaced.
- A dedicated `Gauss_Tablet_API35` Pixel Tablet AVD was created with a real
  2560x1600 / 320dpi Android 15 surface.
- Runtime captures:
  - `.codex-tmp/gauss_auth_phone_ready.png`;
  - `.codex-tmp/gauss_auth_tablet_portrait.png`;
  - `.codex-tmp/gauss_auth_tablet_landscape.png`.
- Learning-surface runtime captures:
  - `.codex-tmp/tablet_landscape_map.png`;
  - `.codex-tmp/tablet_landscape_study.png`;
  - `.codex-tmp/tablet_landscape_insights.png`;
  - `.codex-tmp/tablet_landscape_mission_no_companion_initial.png`;
  - `.codex-tmp/tablet_landscape_mission_no_companion_checked.png`;
  - `.codex-tmp/tablet_mission_checked_portrait_real.png`;
  - `.codex-tmp/tablet_landscape_mission_200pct.png`.
- Fresh Android logs contained no Flutter exception or fatal crash during the
  phone/tablet Auth and learning-surface captures, and no RenderFlex overflow
  occurred through the landscape/portrait/200%-text Mission cycle.
- The feedback runtime created and saved a real ZIP through DocumentsUI in
  Downloads; the pulled archive contained only `manifest.json` and `report.md`
  for the text-only fixture and had SHA-256
  `b5bcbdcf65efd6d78506dd20157bca597695dd87553d4f3cdc79ff89f1fa8b33`.
  The final tablet and 320dp/200% feedback cycles produced no Flutter,
  RenderFlex, FATAL, or native export-channel error.

## Remaining release gates

1. Exercise the authenticated remote download through the real Android app
   after the signup throttle window is available, then prove offline relaunch
   from the activated cache. Media remains bundled and hash-bound in this
   release; a future release that introduces new media needs a reviewed Storage
   delivery lane.
2. Add the manifest-first revision cache before describing Android content
   refresh traffic itself as delta-sized; the current server/publisher already
   reuses unchanged revisions and content updates already avoid APK releases.
3. Complete the remaining physical-device matrix: Xiaomi Focus Pen hover/button
   behavior cannot be proven by the Android emulator, and process-death plus
   authenticated offline relaunch still need final device evidence.
4. Continue the Critics/Perfect pass over secondary sheets and completion
   celebrations; the primary Map, Study, Insights, and five-question Mission
   now have explicit phone, tablet-portrait, tablet-landscape, short-height,
   rotation, and accessible-text contracts.
