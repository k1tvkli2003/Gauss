# Adventure Visual Mismatch Ledger

Accepted preview:
- `C:\Users\K1\.codex\attachments\882a022d-1566-40e7-9b51-cd79fed7d542\image-1.png`
- Reference hash: `AB6A8E8DF435554FEE27F4A606D29583279666136A00425B44CF89424A872D2C`

Current native status as of 2026-07-03:
- `AdventureMapScreen`, `AdventureArenaScreen`, `AdventureRewardScreen`, and `AdventureProfileScreen` are native Compose production paths.
- `ReferencePreviewScreen`, `PreviewHitBox`, `ReferenceArt`, and the full-screen preview drawable assets have been removed from the production adventure UI.
- `scripts/verify_adventure_native_contracts.ps1` now guards against scaffold regressions, stale doc claims, Arabic-script app chrome in the adventure layer, and unexpected `drawable-nodpi` preview assets.
- `scripts/extract_adventure_reference_oracle.py` now generates and checks four canonical reference crops plus `docs/adventure-reference-measurements.json` from the accepted preview hash.
- `scripts/compare_adventure_visual_oracle.py` now provides MAE/RMSE/p95 channel-error comparison for future rendered screenshots, with a self-test wired into the native contract verifier.
- Visual parity is still not screenshot-proven because the available API 37 emulator path failed install/start/screencap service checks.

## 2026-07-01 Map Native Slice

Preview evidence:
- Accepted four-screen preview contact sheet from the user.
- Target screen for this slice: first phone, `Map`.

Rendered evidence:
- `:app:assembleDebug` passed after replacing the Map reference-image path with native Compose.
- `:app:testDebugUnitTest` passed after the Map patch.
- Emulator screenshot was attempted but not usable.

Viewport/state:
- Intended compact Android portrait Map surface.
- Default `Math Road` state with `Level 18`, `7/10` focus, `12 days` streak, `Daily Quest`, bottom nav, native map nodes, and `Start Mission`.

Mismatch:
- Map is now native Compose, but it is not yet screenshot-proven against the accepted preview.
- At this slice boundary, Arena, Reward Vault, and Profile were still pending native migration; later slices below resolved those production paths.
- Mascot is still the current `gauss_mentor` asset, not a user-approved full mascot state sheet.

Fix made:
- Removed the Map screen's dependency on `preview_map_full` and `adventure_map_art`.
- Added native HUD, focus/streak metrics, separated `Math Road` / `Physics Road` switch, native island/path/node renderer, current mission mascot/CTA cluster, daily quest dock, and bottom nav.
- Routed topic labels through `AdventureDisplayLabels`.
- Routed preview level and quest reward values through gamify contracts.

Approved deviation or blocker:
- `Math Road` / `Physics Road` separation is intentional because the user explicitly requested not mixing math and physics in one road.
- Visual screenshot blocker: API 37 emulator booted, but Android services were unstable. `adb install` returned `cmd: Can't find service: package`, direct `am start` returned `cmd: Can't find service: activity`, and `screencap` produced an assertion text file instead of a PNG. The invalid screenshot artifact was deleted.

## 2026-07-01 Arena Native Slice

Preview evidence:
- Accepted four-screen preview contact sheet from the user.
- Target screen for this slice: second phone, `Challenge Arena`.

Rendered evidence:
- `:app:assembleDebug` passed after replacing the Arena reference-image path with native Compose.
- `:app:testDebugUnitTest` passed after the Arena patch.
- Static search confirms `preview_arena_full` is no longer referenced by `AdventureArenaScreen`.

Viewport/state:
- Intended compact Android portrait Arena surface.
- Default active question state with back button, centered title/subtitle, progress/focus/timer, combo ribbon, mascot coach, cream question card, trap hint, 2x2 answer grid, scratchpad action, and primary answer/reward CTA.

Mismatch:
- Arena is now native Compose, but it is not yet screenshot-proven against the accepted preview.
- At this slice boundary, Reward Vault and Profile were still pending native migration; later slices below resolved those production paths.
- Exact mascot state art and reward-triggered expressions are still pending user-approved mascot asset production.

Fix made:
- Removed the Arena screen's dependency on `preview_arena_full`.
- Replaced hitbox-only behavior with native controls for answer selection, correct/wrong states, scratchpad overlay, settings/info overlay, and `Check Answer` / `Next` / `Claim Rewards`.
- Fixed the old hitbox behavior where pressing `Check Answer` with no selected option could submit the correct answer implicitly; the CTA is now disabled until a real option is selected.
- Preserved question data direction by keeping question and option content in an RTL content provider while keeping app chrome English.

Approved deviation or blocker:
- The UI keeps question data untouched; Persian content can appear as data, while labels and controls remain English.
- Visual screenshot blocker remains the unstable API 37 emulator path recorded in the Map slice.

## 2026-07-01 Reward Vault Native Slice

Preview evidence:
- Accepted four-screen preview contact sheet from the user.
- Target screen for this slice: third phone, `Reward Vault`.

Rendered evidence:
- `:app:assembleDebug` passed after replacing the Reward Vault reference-image path with native Compose.
- `:app:testDebugUnitTest` passed after the Reward patch.
- Static search confirms `preview_reward_full` is no longer referenced by `AdventureRewardScreen`.

Viewport/state:
- Intended compact Android portrait reward recap surface.
- Mission complete state with confetti, vault hero, mascot, XP earned, combo/accuracy/focus stats, completed daily quest, found items, claim action, and back-to-map action.

Mismatch:
- Reward Vault is now native Compose, but it is not yet screenshot-proven against the accepted preview.
- At this slice boundary, Profile was still pending native migration; the Profile slice below resolved that production path.
- Reward display is now sourced from the Kotlin reward-rule mapper when an Arena mission exists, with preview events only as a no-mission fallback. Durable reward-claim persistence is still pending the full reward-engine repository adapter.

Fix made:
- Removed the Reward screen's dependency on `preview_reward_full`.
- Replaced image-hitbox behavior with native `VaultDoor`, `ConfettiLayer`, mascot, XP/stats cards, quest card, found-items panel, and CTA stack.
- Reward display is sourced from `AdventureRewardRules.summarize(AdventureRewardRules.previewRewardEvents())`, producing the preview-aligned `+520 XP`, `+120 Coins`, `+2 Gems`, `+2 Focus`, and common gear state from deterministic rule grants.
- `Claim Rewards` is idempotent at the UI layer: after one claim, the button enters `Rewards Claimed` and cannot be tapped again.

Approved deviation or blocker:
- Durable reward claim transactions, offline replay, and rollback remain part of the full reward-engine adapter workstream.
- Visual screenshot blocker remains the unstable API 37 emulator path recorded in the Map slice.

## 2026-07-01 Profile Native Slice

Preview evidence:
- Accepted four-screen preview contact sheet from the user.
- Target screen for this slice: fourth phone, `My Profile`.

Rendered evidence:
- `:app:assembleDebug` passed after replacing the Profile reference-image path with native Compose.
- `:app:testDebugUnitTest` passed after the Profile patch.
- Static search confirms `preview_map_full`, `preview_arena_full`, `preview_reward_full`, `preview_profile_full`, `ReferencePreviewScreen`, `PreviewHitBox`, and `ReferenceArt` are no longer referenced in `AdventureScreens.kt`.

Viewport/state:
- Intended compact Android portrait Profile surface.
- Default `Mastery` tab with profile header, league badge, segmented tabs, brain map, weak topics, revenge queue, badge wall, cosmetics shop, offline/local-save panel, and bottom nav.

Mismatch:
- Profile is now native Compose, but it is not yet screenshot-proven against the accepted preview.
- Native panels are structurally faithful but still use generated/native placeholder art for mascot/badges/shop until the mascot studio asset approval gate is complete.
- Full catalog/quest/reward persistence adapters are still staged rather than fully migrated into a durable production event ledger.

Fix made:
- Removed the Profile screen's dependency on `preview_profile_full`.
- Replaced hitbox-only profile behavior with native tabs and panels.
- Profile header uses the shared preview level curve (`Level 18`, `2,460 / 3,200 XP`).
- Badge counts use `AdventureAchievementCatalog`.
- `Go Revive` remains wired to the real revenge launcher.
- `Shop` is no longer a dead button; it opens a native cosmetics overlay with local close behavior.
- Removed old reference/hitbox helper functions from `AdventureScreens.kt`.
- Removed the unreferenced scaffold bitmaps from `app/src/main/res/drawable-nodpi` so the full-screen preview assets and sliced preview panels are no longer packaged as production resources.
- Added `AdventureRewardEventMapper` so live Arena results can produce mission, trap, quest, chest, combo, accuracy, and focus-left events for the Reward Vault instead of always using preview events.
- Reward Vault claim now exposes a real retry path when mission XP persistence fails, while keeping the preview-aligned `Claim Rewards` state for successful flows.
- Added a reference oracle generation/check path: `docs/adventure-reference-crops/adventure-reference-*.png` and `docs/adventure-reference-measurements.json` define frame crops, region anchors, mean colors, and palettes for future screenshot comparison.
- Added a visual oracle comparison helper so future emulator/device screenshots can be compared against the canonical crops with repeatable numeric metrics instead of ad hoc visual judgement.
- Added the native UI contract verifier script to keep scaffold removal, English adventure chrome, reference hash, four phone frames, and drawable inventory under a single repeatable gate.

Approved deviation or blocker:
- Analytics-derived panels use real local analytics when available, with preview-aligned fallback values for a fresh install.
- Visual screenshot blocker remains the unstable API 37 emulator path recorded in the Map slice.

## 2026-07-03 Reference Oracle Slice

Preview evidence:
- Accepted four-screen preview contact sheet from the user.
- `docs/adventure-reference-manifest.json` still points at the accepted hash `AB6A8E8DF435554FEE27F4A606D29583279666136A00425B44CF89424A872D2C`.

Rendered evidence:
- `scripts/extract_adventure_reference_oracle.py --write` generated four canonical crops under `docs/adventure-reference-crops/`.
- `scripts/extract_adventure_reference_oracle.py --check` passed.
- `scripts/compare_adventure_visual_oracle.py --self-test` passed.
- `scripts/verify_adventure_native_contracts.ps1` now runs both oracle checks.

Viewport/state:
- Reference phone frames are fixed at `376 x 821 px` inside the accepted `1626 x 908 px` contact sheet.
- Each screen now has named region anchors for status/header/content/action/nav surfaces in `docs/adventure-reference-measurements.json`.

Mismatch:
- This slice proves the target reference evidence, not the rendered Android parity.
- Native screenshots from an emulator/device are still needed before numeric visual mismatch can be closed.

Fix made:
- Added reproducible crop and measurement generation.
- Added numeric visual comparison metrics: mean absolute channel error, root mean square channel error, and p95 channel error.
- Wired the oracle checks into the native adventure contract verifier.

Approved deviation or blocker:
- Documentation crops are allowed as oracle artifacts only; they are not packaged under Android production resources.
- Visual screenshot blocker remains the unstable API 37 emulator path recorded in the Map slice.

## 2026-07-04 API35 Map Screenshot Slice

Preview evidence:
- Canonical Map crop: `docs/adventure-reference-crops/adventure-reference-map.png`.
- Measurement oracle: `docs/adventure-reference-measurements.json`.

Rendered evidence:
- Stable emulator path found: `Codex_API35` boots, installs `app-debug.apk`, launches `com.gauss.app/.MainActivity`, and returns a valid PNG from `screencap`.
- Rendered screenshot: `docs/adventure-rendered-screenshots/gauss-map-api35-2026-07-04.png`.
- Visual metrics: `docs/adventure-rendered-screenshots/gauss-map-api35-2026-07-04.metrics.json`.
- Current Map comparison after the compact road-control pass: MAE `48.250`, RMSE `72.689`, p95 channel error `211`.

Viewport/state:
- Emulator physical size: `1080 x 2400`, density `420`.
- App starts on `Routes.MAP` with `Math Road` selected.

Mismatch:
- Status bar icon contrast is fixed to white/light icons in the latest render.
- Major mismatch remains: the native Map is much more component-panel heavy than the accepted preview, and the island map lacks the preview's dense painted-world detail.
- Numeric parity is not close enough to claim visual completion.

Fix made:
- Forced the rebuilt frontend shell into dark adventure mode.
- Set edge-to-edge system bar appearance to light icons over transparent bars in both `MainActivity` and `GaussTheme`.
- Replaced the separate `Math Road` / `Physics Road` map band with a compact icon road-control inside the map stage, preserving subject separation while giving the map more vertical room.
- Preserved the screenshot and metrics as repeatable evidence for the next density/art pass.

Approved deviation or blocker:
- `Math Road` / `Physics Road` separation remains intentional; its current compact icon affordance is a functional compromise until a preview-faithful subject switching treatment is designed.
- API35 is now the preferred screenshot path; API37 remains recorded as unstable.

## 2026-07-05 Map Art/Region Metrics Slice

Preview evidence:
- Canonical Map crop: `docs/adventure-reference-crops/adventure-reference-map.png`.
- Region oracle: `docs/adventure-reference-measurements.json`.

Rendered evidence:
- Current screenshot: `docs/adventure-rendered-screenshots/gauss-map-api35-2026-07-05-pass6.png`.
- Current metrics: `docs/adventure-rendered-screenshots/gauss-map-api35-2026-07-05-pass6.metrics.json`.
- Current Map comparison: MAE `47.409`, RMSE `71.271`, p95 channel error `205`.
- Region metrics: status bar MAE `25.214`, level HUD `40.306`, metrics row `25.700`, map stage `56.613`, primary CTA `79.894`, daily quest `23.206`, bottom nav `33.431`.

Viewport/state:
- Emulator: `Codex_API35`, rendered at `1080 x 2400`, app starts on `Routes.MAP`.
- Default `Math Road` state with English app chrome and untouched question/data localization policy.

Mismatch:
- Visual parity is still not close enough to claim completion.
- The map stage is materially more faithful than the component-card version, but it still lacks the accepted preview's painterly detail, crop, and mascot/world scale.
- The CTA is closer than the 2026-07-04 baseline but remains the largest measured mismatch region.
- Native status/nav bars remain emulator-dependent and continue to affect pixel metrics.

Fix made:
- Added region-level visual metrics to `scripts/compare_adventure_visual_oracle.py`, with self-test coverage for full-frame and region comparisons.
- Added `scripts/generate_adventure_map_background.py` to generate an original project-bound bitmap map background. This asset is not a preview crop or screenshot.
- Added `app/src/main/res/drawable-nodpi/adventure_map_background.png` and wired it into `AdventureMapScreen` as native Compose background art.
- Reworked Map nodes from large glass cards into compact map markers with small dark labels.
- Reworked the current mission cluster into a smaller `Current Mission` plate plus compact `Start Mission` button.
- Rebuilt the Daily Quest dock into a compact preview-like row with progress, count, and diamond reward.
- Verified and reverted an attempted fullscreen navigation-bar hide because Android displayed a first-run fullscreen education overlay that broke screenshot fidelity.

Approved deviation or blocker:
- `pass5` produced a slightly lower aggregate MAE (`47.153`) but allowed worse title/Boss overlap; `pass6` is kept as the current app state because the composition is more deliberate and less visibly broken.
- Further parity likely needs dedicated high-resolution art direction/bitmap generation for the full map, mascot state sheet, and bottom-nav/reward/profile assets rather than only Compose primitives.

## 2026-07-05 Full-Screen Island Map Direction Slice

Preview evidence:
- User correction on 2026-07-05: the main Map/Lessons home should be the island map itself, not a small map boxed inside a dashboard; other items should move into overlays or other destinations.
- Game-pattern direction: use a guided path map like Duolingo, with Clash Royale-like progression/reward chrome and action overlays.

Rendered evidence:
- Current screenshot: `docs/adventure-rendered-screenshots/gauss-map-api35-2026-07-05-pass13-fullscreen-immersive-nav.png`.
- Current metrics file: `docs/adventure-rendered-screenshots/gauss-map-api35-2026-07-05-pass13-fullscreen-immersive-nav.metrics.json`.
- Build and tests passed after the full-screen map conversion: `:app:assembleDebug`, `:app:testDebugUnitTest`, `git diff --check`, and `scripts/verify_adventure_native_contracts.ps1`.

Viewport/state:
- Emulator: `Codex_API35`, rendered at `1080 x 2400`, default Map route with Math road selected.
- Map is now the full page stage; the level HUD, quest shortcut, road switcher, lesson action sheet, and bottom nav are overlays on top of the map instead of separate stacked page sections.

Mismatch:
- The old region oracle still compares against the accepted preview's card-based map layout, so aggregate MAE rose after the intentional full-screen structural change and is no longer a direct completion metric for this revised direction.
- Full-screen map art is much closer in craft and density, but exact 99.99% parity is still not achieved. Remaining visible gaps include nav/sheet polish, node animation, reward transition choreography, and extending this same island-map model through the Missions/Lessons flow.

Fix made:
- Generated a dedicated original island-map bitmap asset with high-density floating islands, castle, reward chest, crystal island, algebra grove, treasure island, locked lab, waterfall, and glowing dotted road.
- Saved the project-bound source under `docs/adventure-generated-assets/map-island-art-2026-07-05-source.png`.
- Updated `scripts/generate_adventure_map_background.py` so the production `adventure_map_background.png` is reproducibly derived from the workspace source art instead of reverting to the older procedural map.
- Rebuilt `AdventureMapScreen` as a full-screen `FullScreenIslandMap` surface.
- Moved the old Top HUD, focus/streak row, daily quest dock, and map card structure out of the main layout.
- Added compact game HUD overlays, round quest/road controls, a lesson action sheet, and immersive bottom-nav styling for the Map route.

Approved deviation or blocker:
- This slice intentionally prioritizes the user's newest direction over the prior card-bound visual oracle. A new oracle or screenshot target should be created for full-screen map matching before treating MAE as a strict acceptance number again.

## 2026-07-05 Missions/Lessons Island Map Slice

Preview evidence:
- User correction on 2026-07-05: both the main Map and Lessons/Missions surfaces should use the same large island-map experience.

Rendered evidence:
- Missions screenshot: `docs/adventure-rendered-screenshots/gauss-missions-api35-2026-07-05-fullscreen-map-pass2.png`.
- Verification after the Missions conversion: `:app:assembleDebug`, `:app:testDebugUnitTest`, `git diff --check`, and `scripts/verify_adventure_native_contracts.ps1` passed.

Viewport/state:
- Emulator: `Codex_API35`, Missions tab selected from the bottom navigation.
- Missions now opens on the same full-screen island art with mission nodes, compact game HUD, daily-quest progress, selected mission action sheet, and immersive bottom navigation.

Mismatch:
- The Missions screen is now structurally aligned with the new full-screen map direction, but deeper transition choreography remains pending: node enter/selection animation, lesson-start travel animation, arena handoff, reward-return animation, and richer Clash Royale-like chest/arena feedback.

Fix made:
- Replaced the old Missions screen list/stack of panels with `FullScreenIslandMap`.
- Reused road nodes and subject separation so Math and Physics stay on separate roads.
- Added `MissionLessonSheet` with selected island title, mission start, and catalog-backed daily quest progress (`0/2` on a fresh install).
- Kept app chrome in English while preserving data/question localization policy.

Approved deviation or blocker:
- Exact motion inspiration from Duolingo/Clash Royale is partially implemented through press scaling and map overlay hierarchy; full transition choreography is still a remaining `$perfect` target rather than a completed claim.

## 2026-07-05 Full-Screen Map Motion Verification

Preview evidence:
- User correction on 2026-07-05: Map and Lessons/Missions should feel like the island world itself, with game-like item placement, transitions, and animation references from Duolingo and Clash Royale.

Rendered evidence:
- Map screenshot after the motion patch: `docs/adventure-rendered-screenshots/gauss-map-api35-2026-07-05-pass14-motion.png`.
- Missions/Lessons screenshot after the motion patch: `docs/adventure-rendered-screenshots/gauss-missions-api35-2026-07-05-pass3-motion.png`.
- Verification after the motion patch: `:app:assembleDebug`, `:app:testDebugUnitTest`, `git diff --check`, and `scripts/verify_adventure_native_contracts.ps1` passed.

Viewport/state:
- Emulator: `Codex_API35`, rendered at `1080 x 2400`.
- Map starts as a full-screen island progression surface with top HUD overlays, round quest/road buttons, selected mission sheet, and immersive bottom navigation.
- Missions/Lessons reuses the same island map and selected lesson sheet, with catalog-backed Daily Quest progress showing `0/2` on a fresh install.

Mismatch:
- The old pixel oracle targets the previous card-framed map layout, so it is now only a regression guard for broad visual sanity, not an exact full-screen acceptance metric.
- Remaining work for a stronger game feel: animated camera/path travel, node unlock bursts, chest/arena transition staging, and reward return choreography.

Fix made:
- Added animated slide/fade transitions for map lesson sheets.
- Added selected-node scale feedback for island labels.
- Kept Map and Missions/Lessons as full-screen map-first routes instead of rebuilding them as dashboards.

Approved deviation or blocker:
- This pass implements the corrected structure and first layer of motion. It does not claim final 99.99% parity; the next strict acceptance artifact should be a new full-screen visual oracle based on the corrected direction.
