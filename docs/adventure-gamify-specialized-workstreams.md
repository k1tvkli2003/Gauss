# Adventure Specialized Gamify Workstreams

تاریخ سند: 2026-07-01

این سند سه skill جدید را به صورت سنگین و اجرایی وارد plan می کند:

- `gamify-mascot-studio`
- `gamify-reward-engine`
- `gamify-achievement-catalog`

هدف این نیست که چند asset قشنگ کنار UI بگذاریم. هدف این است که mascot، reward logic و achievement catalog به یک سیستم واحد، قابل تست و قابل رندر در Android native تبدیل شوند.

## 1. Gamify Mascot Studio

### Mascot Job Map

| نقش | سطح در preview | وظیفه محصولی | Screenها |
|---|---|---|---|
| Companion | crest avatar و map center | هویت همراه کاربر و حس adventure | Map, Profile |
| Coach | Arena speech bubble | راهنمایی کوتاه و بدون لو دادن کامل جواب | Arena |
| Celebration lead | کنار vault و chest | شادی بعد از mission complete | Reward |
| Shopkeeper | cosmetics shop | شخصیت inventory و gear | Profile |
| Comeback guide | revenge/offline states | بازگشت بدون shame | Profile, Revenge |

### Mascot Family Directions

| direction | silhouette | personality | production risk | no-copy note |
|---|---|---|---|---|
| `Explorer Gauss` | small wizard explorer, crown-hat, cloak, compass/star motif | curious, proud, warm, clever | medium because multiple poses need consistency | must avoid Duolingo/Lingo proportions, green-first palette, owl silhouette |
| `Astro Scholar` | tiny astronaut mathematician with star satchel and floating chalk | futuristic, playful, science-forward | medium/high because helmet reflections and expressions are harder | no NASA/logos; not a generic space mascot |
| `Clockwork Mentor` | toy-like brass automaton tutor with gem core | precise, puzzle-minded, reward-machine friendly | medium because metal can feel cold if overdone | no copied robot/IP silhouettes |

Recommendation for current preview fidelity: `Explorer Gauss`, because the preview already shows a wizard-explorer character and the app identity says `Explorer Gauss`.

### Mascot State Matrix

| stateId | trigger | emotion/pose | UI consumer | reduced-motion fallback | alt text |
|---|---|---|---|---|---|
| `neutral_hud` | app loaded | calm smile, small wave | Map HUD, Profile hero | static image | Explorer Gauss avatar |
| `map_current` | current mission selected | pointing to path | Map | glow only | Explorer Gauss points to the current mission |
| `coach_hint` | trap hint available | leaning forward with raised wand | Arena | static bubble | Explorer Gauss gives a hint |
| `answer_correct` | correct answer submitted | excited check gesture | Arena | check icon + static smile | Explorer Gauss celebrates a correct answer |
| `answer_wrong` | wrong answer submitted | gentle thinking pose | Arena | static thinking icon | Explorer Gauss suggests trying again |
| `combo` | combo >= 3 | sparkling wand | Arena ribbon | ribbon pulse disabled | Explorer Gauss celebrates the combo |
| `low_focus` | focus <= 2 | tired but encouraging | HUD/Arena | static low-focus badge | Explorer Gauss warns that focus is low |
| `mission_complete` | mission completed | full-body celebration | Reward Vault | single static hero | Explorer Gauss celebrates mission completion |
| `quest_complete` | daily quest completed | thumbs-up/wand star | Reward quest row | checkmark only | Explorer Gauss marks the quest complete |
| `gear_shop` | shop opened | holding wand/gear | Profile shop | static | Explorer Gauss shows new gear |
| `comeback` | returning after missed day | welcoming pose | Map/Profile | static | Explorer Gauss welcomes the user back |
| `offline_safe` | offline local save active | calm shield pose | Profile offline panel | static shield icon | Explorer Gauss says progress is saved locally |

### ImageGen Prompt Set Requirements

Each production prompt must include:

- original `Explorer Gauss` identity, not protected mascot references;
- teal/gold/purple fantasy-academy palette;
- no extra text, no watermark, no logos;
- transparent/chroma-key plan when isolated;
- same proportions and costume across states;
- generous padding for Android cropping;
- no UI labels baked into mascot art.

### Mascot Asset Manifest Shape

```json
{
  "assetId": "mascot_mission_complete",
  "characterId": "explorer_gauss",
  "stateId": "mission_complete",
  "file": "app/src/main/res/drawable-nodpi/mascot_mission_complete.webp",
  "targetWidthDp": 150,
  "targetHeightDp": 180,
  "safePaddingPercent": 8,
  "background": "transparent_or_flat_key_removed",
  "themeVariants": ["dark"],
  "contentDescription": "Explorer Gauss celebrates mission completion",
  "triggerEvent": "MissionCompleted"
}
```

### Mascot Completion Gate

- At least three family directions recorded.
- `Explorer Gauss` no-copy checklist complete.
- All 12 states have asset specs and event triggers.
- Integrated screenshots prove mascot does not cover text or controls.

## 2. Gamify Reward Engine

### Event Ledger

| eventType | stable id pattern | emitted by | reward consumer | farming risk |
|---|---|---|---|---|
| `MissionStarted` | `mission_started:{missionId}` | Map/Arena launcher | analytics/session | low |
| `AnswerSubmitted` | `answer:{missionId}:{questionId}:{attemptNo}` | Arena | combo/focus/accuracy | medium |
| `CorrectAnswer` | `correct:{missionId}:{questionId}` | Arena rule adapter | XP/combo | medium |
| `MistakeCorrected` | `mistake_corrected:{questionId}:{missionId}` | review rule | XP/mastery | medium |
| `TrapSolved` | `trap_solved:{missionId}:{questionId}` | shortcut detector | daily quest, XP | high |
| `MissionCompleted` | `mission_completed:{missionId}` | ExamViewModel save | reward summary | medium |
| `QuestCompleted` | `quest_completed:{questId}:{dayKey}` | quest engine | XP/currency/mascot | medium |
| `RewardClaimed` | `reward_claimed:{rewardSummaryId}` | Reward Vault | transaction finalization | high |
| `ChestOpened` | `chest_opened:{chestId}` | Reward Vault | coins/gems/gear | high |
| `FocusSpent` | `focus_spent:{missionId}:{questionId}` | Arena | focus wallet | low |
| `FocusRecovered` | `focus_recovered:{sourceEventId}` | reward engine | focus wallet | medium |
| `StreakAdvanced` | `streak_advanced:{dayKey}` | daily activity rule | profile/map | low |

### Reward Rule Matrix

| ruleId | eligible event | reward | cap/cooldown | explanation copy |
|---|---|---|---|---|
| `correct_answer_v1` | `CorrectAnswer` | `+5 XP` | practice XP daily cap | Correct answer |
| `trap_solved_v1` | `TrapSolved` | `+20 XP`, quest progress +1 | max 2 per daily quest | Trap solved |
| `mission_complete_v1` | `MissionCompleted` | `+120 XP` base | once per missionId | Mission complete |
| `combo_x4_v1` | combo >= 4 at completion | multiplier stat, optional `+80 XP` | once per mission | Combo bonus |
| `accuracy_90_v1` | accuracy >= 90 | `+100 XP`, badge progress | once per mission | Accuracy bonus |
| `focus_left_v1` | focus left >= 2 | `+2 Focus` or carryover stat | once per mission | Focus left |
| `daily_trap_quest_v1` | 2 trap solves in day | `+200 XP`, chest tick | once per day | Daily quest |
| `chest_common_v1` | reward chest opened | `+120 Coins`, `+2 Gems`, `Common Gear` | deterministic per chestId | You found gear |
| `streak_day_v1` | first useful mission in day | streak +1 | once per local day | Streak advanced |
| `comeback_v1` | first mission after missed day | `+30 XP`, comeback mascot | once per comeback window | Welcome back |

### Level Curve Requirement

Preview target requires:

```text
level = 18
currentXpInLevel = 2460
nextLevelXp = 3200
progress = 76.875%
```

The current repository level curve in `GamificationRepository.levelFor()` does not obviously match this display. The reward-engine workstream must either:

1. define a new adventure level curve where Level 18 has `3200` XP required and current display can be `2460 / 3200`, or
2. keep the existing curve but change preview-derived example values with a documented visual decision.

For exact preview fidelity, option 1 is preferred.

### Atomic Reward Summary

```text
RewardSummaryV2
- id
- missionId
- rulesVersion
- xpBase
- xpCombo
- xpAccuracy
- xpQuest
- xpTotal
- coins
- gems
- focusDelta
- gearDropId
- chestId
- levelBefore
- levelAfter
- streakBefore
- streakAfter
- questDeltas
- achievementUnlocks
- mascotState
- claimState: preview | claimable | claimed | rollback_required
```

### Anti-Abuse And Ethics

- No paid chance mechanics.
- Chest output deterministic or transparent.
- Repeat easy practice capped.
- Wrong answers never shame the user.
- Streak has grace/comeback; no coercive loss language.
- Essential learning not blocked by payment or cosmetics.

### Reward Engine Completion Gate

- Duplicate `RewardClaimed` does not double grant.
- Offline event replay dedupes by stable event ID.
- Time-zone boundary tests for daily quest and streak.
- Rule matrix versioned and testable.
- Reward Vault UI reads `RewardSummaryV2`, not literals.

## 3. Gamify Achievement Catalog

### Achievement Families

| family | purpose | example IDs | preview surface |
|---|---|---|---|
| Mastery | identity through topic mastery | `mastery_algebra_i`, `mastery_mechanics_i` | Profile badge wall, brain map |
| Consistency | humane rhythm | `streak_3`, `streak_7`, `streak_30` | Map streak, Profile badges |
| Correction | reward learning from mistakes | `mistake_mender_10` | Reward/Profile |
| Exploration | encourage trying roads separately | `math_trailblazer`, `physics_trailblazer`, `dual_road_scout`, `map_vault_finder` | Map/Profile |
| Challenge | boss/challenge completion | `boss_algebra_grove`, `boss_physics_workshop` | Map/Profile |
| Quest | daily/weekly quest identity | `trap_spotter_daily`, `review_rescuer_weekly` | Reward/Profile |
| Collection | cosmetics and gear | `first_common_gear`, `full_apprentice_set` | Shop/Profile |
| Comeback | shame-free return | `welcome_back`, `streak_saved` | Map/Profile |

### Quest Catalog

| questId | cadence | criteria | reward | preview link |
|---|---|---|---|---|
| `daily_trap_spotter` | daily | solve 2 trap questions | `+200 XP`, chest progress | Map/Reward daily quest |
| `daily_focus_keeper` | daily | finish a mission with >=2 focus left | coins + focus | Reward focus stat |
| `weekly_review_rescue` | weekly | revive 8 due questions | badge progress + gems | Profile revenge queue |
| `weekend_boss_run` | weekend | beat one boss stage with >=85% accuracy | rare chest | Boss Arena |
| `comeback_warmup` | comeback | finish one short review after absence | XP + streak grace | comeback mascot |
| `mastery_push` | weekly | raise one weak topic by 10 points | badge progress | Brain map/weak topics |

### Badge Rarity

| rarity | use | visual treatment | accessibility |
|---|---|---|---|
| `common` | first steps and basic collection | bronze/gold outline, simple gem | label includes Common |
| `rare` | meaningful streak/mastery | blue/purple edge, extra shine | label includes Rare |
| `epic` | boss/challenge excellence | star frame, stronger contrast | label includes Epic |
| `legendary` | long-term identity | premium frame, limited animation | label includes Legendary; no essential info hidden |

### Seed Definition Shape

```json
{
  "id": "mastery_algebra_i",
  "version": 1,
  "family": "mastery",
  "titleKey": "achievement.mastery_algebra_i.title",
  "descriptionKey": "achievement.mastery_algebra_i.description",
  "criteria": {
    "type": "topic_mastery_percent",
    "subject": "math",
    "topicKey": "quadratic_equations_functions",
    "threshold": 70
  },
  "rarity": "common",
  "rewardRef": "reward.badge.mastery_algebra_i",
  "iconAsset": "badge_mastery_algebra_i",
  "states": ["locked", "in_progress", "unlocked", "claimed"],
  "hidden": false
}
```

### Catalog Counts For First Full Pass

| group | target count | notes |
|---|---:|---|
| Math mastery badges | 18 | one per math topic |
| Physics mastery badges | 11 | one per physics topic |
| Streak badges | 6 | 3, 7, 14, 30, 60, 100 days |
| Correction badges | 4 | mistake correction milestones |
| Exploration badges | 4 | separate road discovery and vault/map discovery |
| Boss badges | 8 | map-visible boss/challenge stages |
| Quest badges | 8 | daily/weekly/weekend/comeback |
| Collection badges | 8 | cosmetics/gear |
| Secret badges | 4 | delightful, non-essential |

Target first catalog: 71 achievements. The Profile preview `12 / 24` can remain a filtered `featured badge wall`, while full catalog includes more achievements.

### Achievement Catalog Completion Gate

- Stable IDs and version fields.
- Criteria tied to real events/projections.
- Rewards reference reward engine definitions.
- Localization keys English-first for app chrome.
- Icon/art requirements handed to mascot/art direction.
- Tests for thresholds, locked/secret/claimed/expired states.

## Cross-Workstream Integration

| event/result | reward engine | achievement catalog | mascot studio | UI surface |
|---|---|---|---|---|
| correct answer | XP/combo | correction/mastery progress | `answer_correct` | Arena |
| wrong answer | no shame, focus cost maybe | none or correction setup | `answer_wrong` | Arena |
| trap solved | XP + daily quest | quest progress | `coach_hint` -> `combo` | Arena/Reward |
| mission complete | RewardSummaryV2 | boss/mastery/consistency | `mission_complete` | Reward Vault |
| daily quest complete | `+200 XP` | quest badge progress | `quest_complete` | Reward Vault |
| chest opened | coins/gems/gear | collection progress | `mission_complete` or `gear_shop` | Reward/Profile |
| weak topic revived | review rewards | correction/comeback progress | `comeback` | Profile/Revenge |
| offline save active | event queue | none | `offline_safe` | Profile |

## Implementation Status And Targets

Created foundation artifacts:

- `app/src/main/java/com/gauss/app/gamify/AdventureRewardRules.kt`
- `app/src/main/java/com/gauss/app/gamify/AdventureLevelCurve.kt`
- `app/src/main/java/com/gauss/app/gamify/AdventureAchievementCatalog.kt`
- `app/src/main/java/com/gauss/app/gamify/AdventureMascotManifest.kt`
- `app/src/main/assets/gamify/reward_rules.json`
- `app/src/main/assets/gamify/achievement_catalog_manifest.json`
- `app/src/main/assets/gamify/mascot_manifest.json`
- `app/src/test/java/com/gauss/app/gamify/AdventureGamifyContractsTest.kt`

Still required for production completion:

- Split or wrap event contracts into `AdventureEvents.kt` if the current reward file becomes too large.
- Add repository adapters that turn app mission/session state into `AdventureRewardEvent` records.
- Replace preview-only reward projections with rule-sourced UI projections on Map, Reward Vault, and Profile.
- Add separate boundary tests for duplicate claim, offline replay, daily reset, time-zone edges, and cap/cooldown enforcement.
- Add generated or typed `achievement_catalog.json` and `quest_catalog.json` if runtime seed loading becomes the chosen architecture.
- Produce user-approved mascot concept previews before final mascot asset integration.
- Create `docs/adventure-gamify-specialized-ledger.md` and close originality, reward-ethics, catalog-balance, and visual-mismatch gates.
