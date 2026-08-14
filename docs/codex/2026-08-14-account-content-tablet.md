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

## Dedicated adaptive Auth composition

- Phone portrait uses one scroll-safe centered instrument.
- Tablet portrait owns a wider but bounded identity stage and account
  instrument; it does not stretch controls edge-to-edge.
- Tablet landscape owns an independent two-pane composition: brand/context on
  the left and the account instrument on the right. Both panes can scroll
  independently under 200% text or an open keyboard.
- Authentication mode controls stack instead of compressing when text scaling
  or available width requires it. Interactive targets remain at least 48dp.

## Verification

- `flutter analyze`: no issues across the complete project.
- `flutter test`: 210 passed, one intentional benchmark skip.
- Focused Auth matrix: 7/7 passed at 320x760 phone, 800x1280 tablet portrait,
  1280x800 tablet landscape, 100% and 200% text, plus landscape keyboard inset.
- Account and backup isolation: 9/9 passed.
- Content release store: 5/5 passed, including atomic activation, offline
  reopen, corrupt-newer rollback, minimum-build fallback, unsafe-path rejection,
  and exact 3672-row receipt reconciliation.
- Content publisher: 2/2 Python tests passed; deterministic dry-run reproduced
  the published question/topic counts and corpus hash. Focused Flutter analysis
  over the content/auth integration is clean.
- Debug APK build 130 installed beside the untouched personal package.
- A dedicated `Gauss_Tablet_API35` Pixel Tablet AVD was created with a real
  2560x1600 / 320dpi Android 15 surface.
- Runtime captures:
  - `.codex-tmp/gauss_auth_phone_ready.png`;
  - `.codex-tmp/gauss_auth_tablet_portrait.png`;
  - `.codex-tmp/gauss_auth_tablet_landscape.png`.
- Fresh Android logs contained no Flutter exception or fatal crash during the
  phone and tablet Auth captures.

## Remaining release gates

1. Exercise the authenticated remote download through the real Android app
   after the signup throttle window is available, then prove offline relaunch
   from the activated cache. Media remains bundled and hash-bound in this
   release; a future release that introduces new media needs a reviewed Storage
   delivery lane.
2. Apply the same phone/tablet-portrait/tablet-landscape composition contract
   to Map, Current Study, the five-question Mission, stylus tools, and Insights.
3. Run the complete Android runtime matrix with keyboard, safe areas, 200% text,
   reduced motion, stylus input, rotation, process death, and offline relaunch.
