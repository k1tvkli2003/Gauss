# Adventure Preview Implementation Spec

تاریخ سند: 2026-07-01

این spec مکمل پلن 70 مرحله ای است. هدفش این است که هر چیزی که در preview دیده می شود به یک قرارداد اجرایی تبدیل شود: داده، component، asset، interaction، تست، و معیار visual fidelity.

## Source Of Truth

- Reference اصلی goal: `C:\Users\K1\.codex\attachments\882a022d-1566-40e7-9b51-cd79fed7d542\image-1.png`
- SHA256: `AB6A8E8DF435554FEE27F4A606D29583279666136A00425B44CF89424A872D2C`
- Canvas: `1626 x 908`
- چهار frame هدف در manifest: `docs/adventure-reference-manifest.json`
- temp preview قبلی همسان نیست و نباید معیار crop یا visual diff باشد.

## Product Truths

| مفهوم | مقدار target در preview | owner نهایی | توضیح |
|---|---|---|---|
| Player name | `Explorer Gauss` | profile/player model | در Map زیر Level، در Profile header کامل تر |
| Level | `18` | gamification level curve | progress باید از XP واقعی محاسبه شود |
| XP progress | `2,460 / 3,200 XP` | XP transaction summary | در Map و Profile یکسان |
| Focus | `7/10` | focus wallet | Map و Arena باید same source داشته باشند |
| Streak | `12 days` | streak service | Map metric tile |
| Current road | `Algebra Grove - Stage 7` | road/stage projection | Arena نباید فیزیک را با Algebra stage قاطی کند |
| Mission length | `Question 6 of 12` | ExamViewModel/session state | پیشرفت header و progress bar |
| Timer | `08:45` | session timer | pause/resume و lifecycle لازم دارد |
| Combo | `x4` | answer streak in session | در Arena و Reward summary |
| Reward XP | `+520 XP` | reward summary | final screen number, not hardcoded |
| Accuracy | `93%` | session results | reward stat card |
| Focus left | `+2` | focus settlement | reward stat card |
| Coins | `+120` | economy ledger | reward found row |
| Gems | `+2` | economy ledger | reward found row |
| Gear | `Common Gear` | inventory item | deterministic chest result |
| League | `Silver I`, `Top 48%` | league projection | Profile header |
| Badge count | `12 / 24` | achievement projection | Profile badge wall |
| Revenge queue | `8 questions` | due SRS/revenge query | road-specific queue |
| Offline status | `You're offline`, `All progress is saved locally` | connectivity/local persistence | Profile footer panel |

## Existing App Data Baseline

> Current runtime baseline, updated 2026-07-18: the dataset is Nardebam-only.
> All retained rows are source-preserved and archive-only; scored missions remain
> unavailable until independent answer/solution validation exists. The later
> mission-flow details in this historical preview specification are therefore
> not current runtime behavior.

Question bank authority:

- `app/src/main/assets/question_bank/index.json`
- `schema_version`: `2`
- total questions: `3672`
- math: `18` topics, `2042` questions
- physics: `11` topics, `1630` questions

Current Kotlin authority:

- `app/src/main/java/com/gauss/app/data/Models.kt`
- `app/src/main/java/com/gauss/app/data/ComprehensiveTaxonomy.kt`
- `app/src/main/java/com/gauss/app/data/GamificationRepository.kt`
- `app/src/main/java/com/gauss/app/ui/exam/ExamViewModel.kt`

### Math Road Data

| order | key | preview-facing English label | count |
|---:|---|---|---:|
| 1 | `sets` | Sets | 50 |
| 2 | `patterns_sequences` | Patterns & Sequences | 50 |
| 3 | `quadratic_equations_functions` | Algebra Grove | 115 |
| 4 | `rational_inequalities_sign` | Rational Inequalities | 46 |
| 5 | `radicals_algebraic_expressions` | Radicals & Expressions | 47 |
| 6 | `absolute_value_floor` | Absolute Value & Floor | 132 |
| 7 | `functions` | Functions | 264 |
| 8 | `trigonometry` | Trigonometry | 236 |
| 9 | `limits_continuity` | Limits | 215 |
| 10 | `derivatives` | Calculus | 92 |
| 11 | `derivative_applications` | Derivative Applications | 219 |
| 12 | `exponential_logarithmic` | Exponential & Logarithmic | 102 |
| 13 | `analytic_geometry` | Analytic Geometry | 69 |
| 14 | `visual_thinking_conics` | Conics | 97 |
| 15 | `combinatorics` | Combinatorics | 88 |
| 16 | `probability` | Probability | 113 |
| 17 | `geometry` | Geometry | 63 |
| 18 | `statistics` | Statistics | 44 |

### Physics Road Data

| order | key | preview-facing English label | count |
|---:|---|---|---:|
| 1 | `physics_measurement` | Physics Measurement | 50 |
| 2 | `physical_properties_matter` | Matter Properties | 121 |
| 3 | `work_energy_power` | Work & Energy | 94 |
| 4 | `temperature_heat` | Heat | 123 |
| 5 | `electrostatics` | Electrostatics | 147 |
| 6 | `current_electricity` | Circuits | 140 |
| 7 | `magnetism_induction` | Electromagnetism | 130 |
| 8 | `one_dimensional_motion` | Kinematics | 248 |
| 9 | `dynamics` | Mechanics | 155 |
| 10 | `oscillation_waves` | Waves | 283 |
| 11 | `atomic_nuclear` | Atomic & Nuclear | 139 |

## Screen 1: Map

### Visual Hierarchy

| Layer | Preview detail | Native implementation |
|---|---|---|
| Status | `9:30`, system icons | edge-to-edge safe area; system bar color dark teal |
| Player HUD | mascot crest, `Level 18`, `Explorer`, XP text and gold bar | `PlayerHudCard` |
| Metrics | Focus card, Streak card | `MetricTile` with icon, value, label |
| World title | `Gauss Adventure Academy` | centered title over map scene |
| Map scene | floating islands, star sky, dotted gold path, waterfalls/clouds | native layered scene plus raster landmarks |
| Nodes | Boss Arena, Reward Vault, Calculus Cliffs, Physics Workshop, Treasure Chest, Algebra Grove, Quantum Lab locked | `RoadNodeView` with states |
| Current mission | `Current Mission`, `Start Mission` | road-specific CTA in thumb zone |
| Daily quest | `Beat 2 trap questions`, `0/2`, gem reward `200` | `DailyQuestDock` |
| Bottom nav | Map selected; Missions, Rewards, Profile inactive | `AdventureBottomNav` |

### Map Interaction Contract

- Tap `Start Mission` starts current road mission with `subject = MATH`, `topic = quadratic_equations_functions`, `count = 12`.
- Tap `Algebra Grove` selects the current math node.
- Tap `Physics Workshop` switches to Physics Road or opens the Physics road map, not a mixed road.
- Tap `Reward Vault` opens rewards only when pending reward exists; otherwise shows locked/empty state.
- Tap locked `Quantum Lab` gives an English locked-state message and does not start a mission.
- Bottom nav preserves tab state.

### Map Acceptance

- All visible UI chrome is English.
- Persian topic labels from source data are not shown in app chrome on this screen.
- Math and Physics nodes are not on one progression spine in final native architecture; the preview can show cross-road portals, but active road state is singular.
- Screenshot comparison must verify HUD height, gold CTA position, bottom nav height, and path/node rhythm.

## Screen 2: Challenge Arena

### Visual Hierarchy

| Layer | Preview detail | Native implementation |
|---|---|---|
| App bar | Back icon, `Challenge Arena`, `Algebra Grove - Stage 7`, settings | `ArenaTopBar` |
| Progress | `Question 6 of 12`, green progress bar | `ArenaProgressHeader` |
| Focus/timer | `Focus 7/10`, `08:45` | `FocusTimerCapsule` |
| Combo | purple ribbon `COMBO x4` | `ComboRibbon` |
| Coach | mascot head, speech `Find the shortcut.` | `CoachBubble` |
| Question card | cream paper card, Persian question content, trap tag | `QuestionCard` with data text |
| Hint | `Trap Hint: Don't expand directly!` | `TrapHintBar` |
| Answers | A=15 idle, B=18 correct green, C=21 idle, D=30 wrong red | `AnswerGrid` |
| Actions | `Scratchpad`, `Check Answer` | bottom action row |

### String Rule For Arena

- Question body can remain Persian because it is educational data.
- UI labels must be English. The small trap chip should be `Trap` unless it is explicitly stored as question-data text.
- Formula rendering must preserve math direction and not force English direction into Persian question paragraphs.

### Arena Interaction Contract

- Before answer selection: answer cards idle, `Check Answer` enabled only after selection or intentionally auto-selects current answer if preview mode demands.
- Correct answer: green card, check icon, combo increments, feedback motion, next transition.
- Wrong answer: red card, close icon, combo resets, hint remains helpful without shame.
- Scratchpad opens a native sheet/canvas and survives orientation/background.
- Back opens a confirmation only if session has recorded attempts.

### Arena Acceptance

- `Question 6 of 12`, timer, focus, selected answer, combo, and progress are derived from session state.
- Correct and wrong colors are not the only state indicator; icons and content descriptions exist.
- Persian data and English UI do not visually fight or reorder punctuation.
- No static full-screen image in production path.

## Screen 3: Reward Vault

### Visual Hierarchy

| Layer | Preview detail | Native implementation |
|---|---|---|
| Header | `Reward Vault` | top title |
| Celebration hero | confetti, mascot, vault, `Mission Complete!` | original hero asset or native composition |
| XP panel | `XP Earned`, `+520 XP` | `RewardXpPanel` |
| Stat cards | combo `x4`, accuracy `93%`, focus left `+2` | `RewardStatGrid` |
| Daily quest | `Beat 2 trap questions`, `2/2`, `+200 XP` | `RewardQuestCard` |
| Found items | `+120 Coins`, `+2 Gems`, `Common Gear` | `RewardFoundRow` |
| Primary CTA | `Claim Rewards` | idempotent claim button |
| Secondary CTA | `Back to Map` | returns to map after claim or explicit skip |

### Reward Data Contract

```text
RewardSummaryV2
- missionId
- subject
- roadId
- stageId
- xpEarned
- comboBonusMultiplier
- accuracyPercent
- focusDelta
- coinsEarned
- gemsEarned
- gearDrop
- questProgressBefore/After
- claimedAt nullable
```

### Reward Acceptance

- `Claim Rewards` cannot grant XP twice.
- `Back to Map` after unclaimed rewards must either prompt or auto-claim according to one documented policy.
- Confetti and count-up obey reduced motion.
- `+520 XP` is attainable from rule engine, not a literal in UI.

## Screen 4: My Profile

### Visual Hierarchy

| Layer | Preview detail | Native implementation |
|---|---|---|
| Header | `My Profile`, settings | `ProfileTopBar` |
| Player card | crest, `Explorer Gauss`, `Level 18`, XP bar, `Silver I`, `Top 48%` | `ProfileHeroCard` |
| Tabs | Mastery selected, Stats, Badges, League | `ProfileTabs` |
| Brain map | Algebra 78, Calculus 72, Geometry 64, Physics 69, Mechanics 62, Electromag. 55 | `MasteryBrainPanel` |
| Weak topics | Sequences & Series 28, Limits 34, Rotational Dynamics 42 | `WeakTopicsPanel` |
| Revenge queue | `8 questions`, `Go Revive` | `RevengeQueuePanel` |
| Badge wall | `12 / 24`, five badges, `View all` | `BadgeWallPanel` |
| Shop | `Cosmetics Shop`, `New items!`, `Shop` | `CosmeticsShopPanel` |
| Offline | `You're offline`, `All progress is saved locally` | `OfflineStatusPanel` |
| Bottom nav | Profile selected | `AdventureBottomNav` |

### Profile Data Contract

```text
ProfileProjection
- player: name, level, title, xpCurrent, xpNext
- league: tier, division, percentile
- masteryByTopic: topicKey, subject, percent, trend
- weakTopics: topicKey, percent, dueCount
- revengeQueue: questionIds, subject, topicKeys, dueCount
- achievements: unlocked, total, rarity, latest
- cosmetics: owned, newItems, equippedSet
- sync: online/offline, lastSavedAt, pendingEvents
```

### Profile Acceptance

- Brain map can summarize both Math and Physics, but it is analytics/profile, not a shared road.
- `Go Revive` launches a review session using due questions, filtered by selected queue context.
- Badge and shop buttons are not dead controls.
- Offline panel reflects real connectivity or local event queue state.

## Component System Required

| Component | States | Files target |
|---|---|---|
| `AdventureScaffold` | compact/tall, nav/no-nav, safe areas | `ui/adventure` |
| `PlayerHudCard` | loading, loaded, offline, long XP | `ui/adventure/components` |
| `MetricTile` | default, warning, depleted, pressed | `ui/adventure/components` |
| `RoadNodeView` | locked, available, current, completed, boss, chest, portal | `ui/adventure/map` |
| `AdventureBottomNav` | selected, inactive, pressed, disabled route | `ui/adventure/navigation` |
| `ArenaTopBar` | active, paused, saving | `ui/adventure/arena` |
| `QuestionCard` | text, image, mixed content, trap | `ui/adventure/arena` |
| `AnswerCard` | idle, selected, correct, wrong, disabled | `ui/adventure/arena` |
| `RewardVaultHero` | entering, complete, reduced motion | `ui/adventure/reward` |
| `ProfilePanel` | loaded, empty, offline, overflow | `ui/adventure/profile` |

## Visual Tokens

| Token | Target feel | Preview source |
|---|---|---|
| `adventure.bg.night` | deep teal-black | all screens |
| `adventure.surface.panel` | translucent dark teal panels | HUD/cards |
| `adventure.border.goldStone` | warm stone outline | phone/card borders |
| `adventure.cta.gold` | primary action | Start/Claim/Check |
| `adventure.state.correct` | green answer/reward check | Arena B, reward quest |
| `adventure.state.wrong` | red answer/error | Arena D |
| `adventure.subject.math` | purple/pink | Algebra/Calculus/badges |
| `adventure.subject.physics` | cyan/blue | Physics/Mechanics |
| `adventure.reward.coin` | warm gold | coins/XP |
| `adventure.reward.gem` | cyan crystal | gems |

## Asset Plan

| Asset family | Target | Generation/edit policy |
|---|---|---|
| Mascot | same wizard explorer identity across HUD, coach, reward, profile, shop | original Gauss mascot, no protected brand copy |
| Map landmarks | castle, grove, cliff, workshop, vault, chest, lab lock | generated or hand-composed raster with stable dimensions |
| Reward vault | vault door, star glow, chest, coins, gems | raster hero plus native text/buttons |
| Badges | mastery badges, league badge, cosmetics | vector-like raster or native vector where simple |
| Brain map | colorful mastery brain | can be generated raster, but labels/percentages native |

## Specialized Gamify Workstreams

جزئیات کامل این سه workstream در `docs/adventure-gamify-specialized-workstreams.md` آمده و در implementation باید مثل requirement عمل کند، نه ایده تزئینی:

- `gamify-mascot-studio`: mascot family directions، state matrix، prompt set، no-copy checklist، asset manifest.
- `gamify-reward-engine`: event ledger، reward rules، XP/level/currency/focus/streak/chest policies، idempotency و replay.
- `gamify-achievement-catalog`: achievement/quest/badge catalog، rarity، unlock states، seed manifest، tests.

## Function And Integrity Gates

- Every visible button has a target route, state mutation, or deliberate disabled reason.
- Every reward-related event has a stable eventId and duplicate prevention.
- `Math Road` and `Physics Road` share components, not progression nodes.
- `ComprehensiveTaxonomy` keeps Persian labels for educational data, but adventure UI maps to English display labels.
- `GamificationRepository` current daily quest target `10` conflicts with preview `2`; final must either update quest config by quest type or render preview-specific quest from a new quest engine.
- Current XP curve may not produce Level 18 at `2,460 / 3,200 XP`; final must define a level curve that matches preview or intentionally revise displayed example.

## Verification Matrix

| Gate | Evidence |
|---|---|
| Reference | hash and dimensions from manifest |
| Data | question bank parse, subject counts, topic counts |
| Strings | grep/static audit: no Persian app chrome in adventure UI |
| Function | UI tests for Start Mission, answer, claim, Go Revive, bottom nav |
| Visual | screenshot matrix against four phone frames |
| Performance | asset inventory, decode budget, frame/jank measurement |
| Accessibility | content descriptions, touch target >= 48dp, focus order |
| Critics | final read-only report before completion |

## First Implementation Slice From This Spec

1. Add `AdventureReferenceManifest` test/fixture or keep JSON manifest in docs until a test harness exists.
2. Create `AdventureDisplayLabels.kt` mapping topic keys to English adventure labels.
3. Create gamify projection contracts for `PlayerProgress`, `RoadProgress`, `RewardSummaryV2`, `ProfileProjection`.
4. Replace static Map screen first with native HUD, bottom nav, daily quest dock, and road node layer.
5. Keep reference image available only as visual oracle while native component parity is built.
