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
- Added migration `202608140005_gauss_content_manifest_delta.sql`: Android now
  reads a hash-only question manifest in bounded 500-row pages, reuses every
  exact local `(id, revision, metadata, SHA-256)` match, and requests only cache
  misses in ordered batches of at most 250. Release artifacts use the same
  hash-first contract, so an unchanged five-question plan, certification
  runtime, index, or media manifest is not downloaded again.
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
- Content refresh traffic is now genuinely manifest-first and payload-delta.
  A deterministic real-corpus budget compares uncompressed RPC-equivalent JSON
  and requires a one-question update, including both question and artifact
  manifests, to remain below 15% of a complete payload refresh. This is a
  conservative application-payload gate, not a claim about compressed carrier
  bytes. Every reused and downloaded row is still reconciled into the complete
  corpus SHA before atomic activation.

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
- `flutter test --no-pub`: 229 passed, one intentional benchmark skip.
- Focused Auth matrix: 7/7 passed at 320x760 phone, 800x1280 tablet portrait,
  1280x800 tablet landscape, 100% and 200% text, plus landscape keyboard inset.
- Account and backup isolation: 9/9 passed.
- Content release store: 10/10 passed, including atomic activation, offline
  reopen, corrupt-newer rollback, minimum-build fallback, unsafe-path rejection,
  first-install reuse from bundled assets, one-question payload selection,
  incomplete-delta rollback, a safe legacy fallback only when the new RPC is
  genuinely unavailable, the <15% real-corpus transfer budget, and exact
  3672-row receipt reconciliation.
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
- Migration 005 was applied through the checksum ledger with SHA-256
  `d6d21d8864f9e637e642bd88e27ff214be3a0ffa7abfaeacfc7830da690082ce`.
  The refreshed live proof returned two ordered hash-only question descriptors,
  two exactly bound requested payloads, four artifact descriptors, and one
  requested artifact payload; the anonymous delta call was rejected with 401.
  Both temporary accounts and all proof artifacts were removed afterward.
- Debug APK build 130 installed beside the untouched personal package.
- Earlier production-entry debug APK build 140 compiled from `lib/main.dart` at
  250,695,702 bytes with SHA-256
  `305ef5e6eeb58183ad66e2708663d1666e80545d10a3f488a5adaf3653556210`.
- Manifest-delta production-entry debug APK build 141 compiled from
  `lib/main.dart`, installed as isolated `com.gauss.app.debug`, and launched on
  the 2560x1600 tablet emulator. It is 250,711,014 bytes with SHA-256
  `5f867b22ed1a1df999a32d7dba91cbb28bdadb7a3969f49f52473811038b5f70`.
  Fresh launch logs contained no FlutterError, RenderFlex, fatal exception, or
  AndroidRuntime crash; `.codex-tmp/gauss_main_141.png` records the real Auth
  surface. No command targeted the personal `com.gauss.app` application id.
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

## Physical-device Auth recovery — 2026-08-18

- Galaxy A73 runtime evidence showed that registration reached the deployed
  `gauss-signup` boundary and received HTTP 409; this was not an offline or
  missing-Supabase failure. A fresh public-key health probe returned GoTrue 200,
  and a non-mutating invalid-input probe reached the function and returned its
  expected structured 400 response.
- Registration now treats 409 as a recoverable acknowledgement race/existing
  account: it privately attempts password sign-in with the credential the owner
  already supplied, then opens the owner-scoped profile. A wrong credential
  moves the same form to Sign in and exposes password recovery instead of
  leaving the owner in a registration dead end. Other function failures remain
  fail-closed and never trigger a password request.
- The Supabase transport is isolated behind `GaussAuthGateway`, keeping one
  controller state owner and allowing deterministic error-path regression
  coverage without touching live accounts.
- Focused Auth/controller verification passed 10/10; focused analysis reported
  no issues. Production-entry debug APK build 142 is 250,712,238 bytes with
  SHA-256
  `f99b71c44687c7f46f7d96736ab7b740d65b798312b9532f3bcf27add63dd7bc`.
  It updated `com.gauss.app.debug` in place on the physical Galaxy A73, launched
  as the focused Activity, and emitted no immediate Flutter or Android fatal.
  The signed personal package and all app data remained untouched.

## Physical-device Auth identity repair — 2026-08-20

- The credentials already visible in the Galaxy A73 Auth form reproduced the
  contradiction precisely: registration reported an unavailable account while
  password sign-in returned `invalid_credentials`. A direct Auth request also
  returned 400, so this was not a Flutter-only message or connectivity fault.
- The existing Auth row had a primary email and accepted a password update, but
  it lacked the corresponding email-provider identity required by password
  sign-in. The existing user was repaired in place through the server-only
  Admin API by supplying the same email, password, and confirmation state in
  one update. The user was not deleted or recreated, so its stable ID and any
  owner-bound records were preserved.
- Live proof returned repair 200, password Auth 200, a non-empty session, and
  `gauss_ensure_profile` 200. The temporary repair function was protected by a
  one-time high-entropy secret, then both the remote function and secret were
  deleted; a final remote inventory reported both absent. No elevated key or
  repair source remains in the Android app or repository.
- Build 142 then signed in on the physical Galaxy A73 and reached the first-run
  learning-path onboarding. After a force-stop and launcher restart it returned
  to onboarding rather than Auth (`AUTH_SCREEN_PRESENT=False`), proving native
  session persistence across process death. The signed personal package and
  its data were not replaced.

## Remaining release gates

1. Exercise the authenticated manifest/delta path through the real Android app,
   then prove offline relaunch from its activated cache. Existing media remains
   bundled and hash-bound; a future release that introduces new media still
   needs a reviewed Storage delivery lane.
2. Complete the remaining physical-device matrix: Xiaomi Focus Pen hover/button
   behavior cannot be proven by the Android emulator, and process-death plus
   authenticated offline relaunch still need final device evidence.
3. Continue the Critics/Perfect pass over secondary sheets and completion
   celebrations; the primary Map, Study, Insights, and five-question Mission
   now have explicit phone, tablet-portrait, tablet-landscape, short-height,
   rotation, and accessible-text contracts.
