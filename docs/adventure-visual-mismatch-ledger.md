# Adventure Visual Mismatch Ledger

Accepted preview:
- `C:\Users\K1\.codex\attachments\882a022d-1566-40e7-9b51-cd79fed7d542\image-1.png`
- Reference hash: `AB6A8E8DF435554FEE27F4A606D29583279666136A00425B44CF89424A872D2C`

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
- Arena, Reward Vault, and Profile still use `ReferencePreviewScreen` scaffolds in production paths.
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
- Reward Vault and Profile still use `ReferencePreviewScreen` scaffolds in production paths.
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
- Profile still uses `ReferencePreviewScreen` scaffolding in its production path.
- Claim state is local UI idempotency for this slice; durable reward-claim persistence is still pending the full reward-engine repository adapter.

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

Approved deviation or blocker:
- Analytics-derived panels use real local analytics when available, with preview-aligned fallback values for a fresh install.
- Visual screenshot blocker remains the unstable API 37 emulator path recorded in the Map slice.
