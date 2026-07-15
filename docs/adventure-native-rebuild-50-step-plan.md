# Gauss Adventure Android Native Rebuild Plan

تاریخ سند: 2026-07-01

این سند برنامه اجرایی سنگین برای بازسازی کل frontend اندروید Gauss از صفر است. هدف، رسیدن به همان preview تاییدشده، ولی به شکل بومی، زنده، قابل لمس، قابل تست، سریع، و از نظر gamification قوی تر است.

## منبع حقیقت

- تصویر مرجع اصلی goal: `C:\Users\K1\.codex\attachments\882a022d-1566-40e7-9b51-cd79fed7d542\image-1.png`
- SHA256 تصویر مرجع اصلی: `AB6A8E8DF435554FEE27F4A606D29583279666136A00425B44CF89424A872D2C`
- ابعاد تصویر مرجع اصلی: `1626 x 908`
- تصویر temp قبلی مشابه اما غیرهمسان است: `C:\Users\K1\AppData\Local\Temp\codex-clipboard-d033c29e-7b3d-4f44-b849-6c4ffd591bcf.png`, hash `AF47B6A1E1808C885A8FBFBEBB4FE35C6026269F0B9682E388BDE83B2412E2AE`, ابعاد `1693 x 929`
- از این لحظه هر crop، manifest، visual diff و screenshot gate باید attachment اصلی goal را source of truth بداند.
- صفحات هدف داخل تصویر: `Map`, `Challenge Arena`, `Reward Vault`, `My Profile`
- وضعیت فعلی پیاده سازی در 2026-07-03: هر چهار صفحه production در `AdventureScreens.kt` بومی Compose هستند و helperهای reference/hitbox حذف شده اند.
- وضعیت فعلی assetهای مرجع تمام صفحه: از `app/src/main/res/drawable-nodpi` حذف شده اند تا production UI از تصویر preview بسته بندی شده تغذیه نشود.
- وضعیت فعلی reference oracle: `scripts/extract_adventure_reference_oracle.py` چهار crop canonical و `docs/adventure-reference-measurements.json` را از hash پذیرفته شده تولید و check می کند.
- وضعیت فعلی visual comparison: `scripts/compare_adventure_visual_oracle.py` برای screenshotهای آینده MAE/RMSE/p95 channel error می دهد و self-test دارد.
- وضعیت فعلی screenshot evidence: `Codex_API35` مسیر قابل اجرا برای install/start/screencap است و اولین Map render در `docs/adventure-rendered-screenshots/` ثبت شده است.
- وضعیت فعلی gate خودکار: `scripts/verify_adventure_native_contracts.ps1` حذف scaffold، English adventure chrome، hash reference، چهار phone frame، reference oracle، visual comparison self-test، و drawable inventory را کنترل می کند.

## خط قرمزهای محصول

- اپ بومی Android و Jetpack Compose باشد، نه webview و نه shell قدیمی.
- ظاهر نهایی باید اول به preview تاییدشده وفادار باشد، بعد با motion، state واقعی، دسترسی پذیری، و feedback بهتر شود.
- رشته های خود اپ و UI chrome باید English باشند: `Map`, `Missions`, `Rewards`, `Profile`, `Start Mission`, `Claim Rewards`, `Check Answer`.
- داده آموزشی می تواند زبان خودش را داشته باشد، ولی app strings نباید Persian باشند.
- مسیر ریاضی و فیزیک نباید در یک road قاطی شود. `Math Road` و `Physics Road` باید taxonomy، map، mission، reward، boss و review queue جدا داشته باشند.
- استفاده از reusable gamify repo باید به شکل port مفهومی به Kotlin/Compose و contractهای خود Gauss باشد، نه کپی بی کنترل.
- static reference image فقط visual oracle است. خروجی production باید component-native بماند و gateها جلوی برگشت scaffold را بگیرند.
- «سنگین بودن» یعنی معماری، مدل داده، component system، test، screenshot gate، و performance budget. پر کردن پروژه با کد بی مصرف هدف نیست.

## مهارت های اعمال شده

- `orchestrator`: شکستن کار به sliceهای قابل تحویل و gateهای روشن.
- `anatomy`: اطلاعات، routeها، thumb zone، task path، و جداسازی roadها.
- `gamify`: core loop، XP، focus، streak، reward، league، cosmetic، quest، revenge queue.
- `style`: tokenها، typography، color، motion، contrast، responsive behavior.
- `imagegen`: تولید و اصلاح assetهای mascot، vault، badge، chest، map landmark فقط با prompt دقیق و invariant.
- `integrity`: ownerهای canonical برای topic، progress، reward، achievement، strings، assets.
- `function`: اتصال هر control از tap تا state و persistence.
- `performance`: بودجه asset، frame، startup، memory، و jank.
- `string`: انگلیسی بودن app strings، terminology، accessibility labels، و state copy.
- `dataman`: audit و validation دیتاست topic/question/progression.
- `ideas`: انتخاب featureهایی که core loop را تقویت می کنند، نه تزئین اضافی.
- `critics`: audit مستقل قبل از اعلام completion.
- `gamify-mascot-studio`: mascot family، state matrix، no-copy checklist، prompt set، asset manifest، و اتصال mascot state به UI/reward events.
- `gamify-reward-engine`: event ledger، rule engine، XP/level/currency/focus/streak/chest policies، idempotent reward transactions، و deterministic tests.
- `gamify-achievement-catalog`: achievement families، badge rarity، quest cadence، catalog seed manifest، unlock/claimed/secret states، و art/localization requirements.

## جایگذاری سنگین سه skill جدید

این سه skill فقط به عنوان polish انتهای کار استفاده نمی شوند. از این نقطه، هر screen باید یک مسیر زنده از این سه سیستم داشته باشد:

- Mascot Studio مالک identity و stateهای `Explorer Gauss` است: حداقل 3 direction، preview approval، no-copy checklist، prompt set، asset manifest، reduced-motion fallback، و screenshot evidence.
- Reward Engine مالک همه عددهای reward است: `+520 XP`, `+120 Coins`, `+2 Gems`, focus carryover، streak، claim state، replay، rollback، caps، cooldown، و deterministic tests.
- Achievement Catalog مالک badge/quest/profile progression است: 71 achievement اولیه، 8 quest، rarity/unlock/secret/claimed states، localization keys، icon requirements، و seed/version contract.
- Gate مشترک: هر event مهم باید همزمان مشخص کند کدام reward rule اجرا می شود، کدام achievement/quest تغییر می کند، mascot چه stateای می گیرد، و UI کجا آن را نشان می دهد.

## 90 مرحله سنگین اجرایی

| # | مرحله | خروجی قابل تحویل | Gate پذیرش |
|---:|---|---|---|
| 1 | ثبت نسخه مرجع و hash در documentation و test metadata | `docs/adventure-native-rebuild-50-step-plan.md` و یک `reference-manifest.json` | hash و ابعاد با فایل ورودی match باشد |
| 2 | استخراج دقیق چهار viewport از تصویر مرجع | چهار crop canonical برای map/arena/reward/profile در `docs/adventure-reference-crops/` | هر crop با محدوده موبایل مرجع align باشد و oracle check پاس شود |
| 3 | ساخت measurement grid برای هر screen | `docs/adventure-reference-measurements.json` شامل frameها، region anchorها، mean color و palette | CTAها، nav، cards، heroها و safe areas anchor داشته باشند |
| 4 | ساخت color sampling sheet | palette sampled با role پیشنهادی | هر رنگ به semantic token وصل شده باشد، نه raw color |
| 5 | ساخت typography corpus | corpus English UI strings و sample question data | app strings انگلیسی و long labels تست شده باشند |
| 6 | تعریف visual mismatch ledger | `docs/adventure-visual-mismatch-ledger.md` | هر اختلاف preview با screenshot واقعی ثبت و بسته شود |
| 7 | audit routeهای فعلی و shell قدیمی | route map قبل از redesign | مسیرهای legacy که باید bypass یا migrate شوند مشخص باشد |
| 8 | انتخاب architecture نهایی navigation | bottom nav چهارگانه با `Map/Missions/Rewards/Profile` | top tasks در 0 تا 1 tap از root باشند |
| 9 | تعریف road architecture جدا | `Math Road`, `Physics Road`، و امکان اضافه شدن subjectهای جدید | هیچ node مشترک بین math و physics بدون adapter رسمی نباشد |
| 10 | تعریف independent back stacks برای bottom nav | NavGraph contract | tab switch state را reset نکند |
| 11 | تعریف immersive arena flow | Arena به عنوان flow متمرکز با back to map | bottom nav داخل arena مزاحم حل سوال نباشد |
| 12 | تعریف reward flow | completion -> reward vault -> claim -> map | claim دوبار XP اضافه نکند |
| 13 | تعریف profile information architecture | Mastery، Stats، Badges، League | هر tab مقصد یا state روشن داشته باشد |
| 14 | تعریف accessibility traversal برای هر screen | traversal order spec | screen reader order با visual hierarchy یکی باشد |
| 15 | inventory دیتاست سوالات و topicها | dataset audit برای `questions.json` و loaders | category، subject، difficulty، locale، ID، duplicate گزارش شود |
| 16 | تعریف canonical subject taxonomy | Kotlin model برای subject/road/topic/node | math و physics از source of truth جدا خوانده شوند |
| 17 | تعریف mission node contract | `AdventureNode`, `RoadStage`, `BossStage`, `RewardStage` | هر node statusهای locked/current/complete/review داشته باشد |
| 18 | تعریف progression state ownership | owner table برای XP, streak, focus, mastery | duplicate truth بین UI و ViewModel حذف شود |
| 19 | تعریف reward economy | `Coins`, `Gems`, `Gear`, `XP`, `Combo`, `Accuracy` | هر reward source idempotent باشد |
| 20 | تعریف quest system | daily quest, trap quest, review quest | progress و claim جدا ذخیره شوند |
| 21 | تعریف league/rank model | Bronze/Silver/Gold یا current scheme | Profile badge و rank از model واحد بخواند |
| 22 | تعریف cosmetics contract | mascot gear، wand، chest، shop | shop placeholder نباشد و inventory state داشته باشد |
| 23 | تعریف revenge queue contract | weak topics -> review queue | queue فقط topicهای همان road را نشان دهد |
| 24 | ساخت validation script برای data | command برای parse، unique IDs، orphan refs | CI یا local validation fail-fast داشته باشد |
| 25 | انتخاب visual direction قطعی | `Gauss Adventure Academy` dark teal fantasy academy | با preview وفادار و از shell قدیمی مستقل باشد |
| 26 | ساخت theme token layer | `AdventureTokens.kt` برای colors, spacing, radius, elevation | feature components raw color hardcode نداشته باشند |
| 27 | تعریف typography tokens | UI Latin font و Persian/data fallback | app UI English خوانا، formula/data safe باشد |
| 28 | تعریف shape/elevation system | panel, card, chip, button, vault, badge tokens | corner/elevation drift نداشته باشیم |
| 29 | تعریف motion grammar | press scale، screen enter، reward celebration، answer feedback | reduced motion مسیر جدا داشته باشد |
| 30 | تعریف icon system | Material Symbols Rounded یا existing vectors | emoji در app strings استفاده نشود |
| 31 | ساخت asset brief برای mascot | idle, happy, focus, success, profile, shop states | character identity ثابت بماند |
| 32 | ساخت asset brief برای map landmarks | Boss Arena, Reward Vault, Algebra Grove, Physics Workshop | هر asset subject و state مشخص داشته باشد |
| 33 | ساخت asset brief برای reward vault | vault, chest, coins, gems, gear | text داخل image حداقلی یا بدون text باشد |
| 34 | ساخت badge and league asset set | mastery badges, Silver I, shop gear | ابعاد و density Android تایید شود |
| 35 | optimize asset pipeline | WebP/AVIF decision، sizes، density، source notes | install size و decode cost در budget باشد |
| 36 | port gamify core loop به Kotlin | domain contracts inspired by reusable repo | loop: question -> answer -> XP/focus/streak -> reward |
| 37 | پیاده سازی event pipeline | `MissionStarted`, `AnswerSubmitted`, `MissionCompleted`, `RewardClaimed` | eventها idempotent و testable باشند |
| 38 | پیاده سازی XP و level curve | `LevelProgress` و thresholds | Level 18 و `2,460 / 3,200 XP` قابل تولید باشد |
| 39 | پیاده سازی focus mechanic | `7/10`, spend, restore, reward carryover | UI عدد را از state واقعی بخواند |
| 40 | پیاده سازی streak mechanic | daily activity و missed day policy | Profile و Map یک عدد ببینند |
| 41 | پیاده سازی combo mechanic | `COMBO x4` و multiplier | wrong answer combo را reset کند |
| 42 | پیاده سازی trap hint mechanic | trap detection و hint card | hint فقط برای سوالات مناسب ظاهر شود |
| 43 | پیاده سازی mastery brain map data | topic mastery percent و weak topics | Profile diagram از state واقعی تغذیه شود |
| 44 | ساخت component primitives | `AdventurePanel`, `AdventureButton`, `MetricTile`, `ProgressBar`, `BottomNav` | همه stateهای enabled/pressed/disabled/loading داشته باشند |
| 45 | ساخت native top HUD | status/time safe area، level card، XP bar | با preview هم ارتفاع و هم rhythm باشد |
| 46 | ساخت native bottom nav | icon+label، active state، insets | 4 مقصد، touch target >= 48dp |
| 47 | ساخت native Map background scene | layered islands, sky, path, labels | static full image fallback حذف نشده، ولی component-native جایگزین شود |
| 48 | ساخت road node renderer | node icon، lock، complete check، current marker | absolute pixel positioning به relative constraints تبدیل شود |
| 49 | ساخت current mission CTA | `Start Mission` در thumb zone | tap -> mission flow واقعی |
| 50 | ساخت daily quest dock | progress، target، reward pill | progress از quest model بخواند |
| 51 | ساخت Missions screen جدید | road-specific mission list، filters، progress | math و physics جدا و قابل switch باشد |
| 52 | ساخت native Arena header | back، title، settings، question count، timer، focus | safe area و accessibility درست باشد |
| 53 | ساخت native question card | question body، formula support، data language support | app chrome انگلیسی، question data untouched |
| 54 | ساخت answer grid native | A/B/C/D cards، correct/wrong states، disabled saving | state با ViewModel sync شود |
| 55 | ساخت answer feedback motion | green correct، red wrong، shake، checkmark، next | animation زیر 600ms و reduced-motion safe |
| 56 | ساخت scratchpad sheet | pencil action، local canvas یا notes | state flow را خراب نکند |
| 57 | ساخت native Reward Vault | hero vault، XP earned، daily quest، found items، claim/back CTAs | `Claim Rewards` idempotent باشد |
| 58 | ساخت reward celebration | confetti canvas، count-up XP، chest reveal | فقط milestone/completion، نه هر tap |
| 59 | ساخت native Profile header | mascot, level, XP bar, league badge | Profile از same progress source بخواند |
| 60 | ساخت mastery dashboard | brain/subject mastery cards، weak topics، revenge queue | topic labels English باشد |
| 61 | ساخت badge wall و shop panels | badges, `View all`, cosmetics shop | dead button نماند |
| 62 | ساخت offline panel | offline status و local save claim | با connectivity state واقعی یا stub معتبر وصل باشد |
| 63 | migration از reference-hitbox screens | `ReferencePreviewScreen` از production path حذف شد | برگشت scaffold با verifier fail شود |
| 64 | unit tests برای gamify domain | level, XP, reward, quest, streak, queue | duplicate claim، wrong answer، daily reset تست شوند |
| 65 | Compose UI tests برای controls | map start, arena answer, reward claim, profile review | هر control واقعا handler داشته باشد |
| 66 | string audit و grep gate | scan hardcoded app strings و Persian UI chrome | app strings غیر data انگلیسی باشند |
| 67 | visual screenshot matrix | map/arena/reward/profile در phone sizes و text scale | screenshotها با `compare_adventure_visual_oracle.py` و mismatch ledger compare شوند |
| 68 | emulator stabilization | نصب stable API 35/36 یا repair SDK، ساخت AVD قابل اعتماد | `sys.boot_completed=1` و user unlocked و install/start/screencap کار کند |
| 69 | performance budget pass | asset size، startup، frame time، memory، decode cost | debug claim کافی نیست، trace یا اندازه گیری ثبت شود |
| 70 | critics freeze audit | audit نهایی بدون edit: UX، function، strings، visual، performance، accessibility | release posture و blockers روشن باشد |
| 71 | mascot family exploration | حداقل 3 direction برای original Gauss mascot | هیچ silhouette/name/copy protected یا Duolingo-like نباشد |
| 72 | mascot state matrix | neutral, coach, correct, wrong, thinking, low-focus, combo, level-up, quest-complete, reward, comeback, offline | هر state trigger و reduced-motion fallback داشته باشد |
| 73 | mascot preview and approval gate | concept sheet یا storyboard برای mascot states | قبل از production asset integration، preview پذیرفته شود |
| 74 | mascot prompt and asset manifest | prompt set، negative prompts، filenames، sizes، safe padding، alt text | assetها project-bound و قابل رندر در Android باشند |
| 75 | reward event taxonomy | event IDs برای mission start/answer/complete/claim/focus/streak/quest/chest | idempotency key برای هر event تعریف شود |
| 76 | reward rule matrix | XP, coins, gems, focus, streak, chest, gear rules | caps، cooldown، first-time/repeat distinction و anti-abuse مشخص باشد |
| 77 | level curve reconciliation | curve سازگار با `Level 18` و `2,460 / 3,200 XP` یا تصمیم مستند برای تغییر | Map/Profile/Reward همه یک curve ببینند |
| 78 | reward claim/offline replay design | claim state، rollback، duplicate prevention، offline queue | duplicate claim و replay تست داشته باشد |
| 79 | achievement family matrix | mastery, consistency, correction, exploration, challenge, comeback, collection | achievementها معنی واقعی داشته باشند، نه badge inflation |
| 80 | quest cadence catalog | daily, weekly, weekend, comeback, mastery, review quests | questها فقط `earn X XP` نباشند و behavior-specific باشند |
| 81 | badge rarity and unlock states | common/rare/epic/legendary یا مقیاس پروژه، locked/secret/claimed states | rarity accessible label و visual treatment داشته باشد |
| 82 | catalog seed manifest | stable IDs، version، criteria، rewards، localization keys، icon/art requirements | catalog migration-safe و تست پذیر باشد |
| 83 | mascot-reward-achievement integration | trigger map از reward/achievement events به mascot state و UI surface | reward vault/profile/map stateها با eventها sync باشند |
| 84 | specialized gamify audit | audit مستقل روی mascot originality، reward ethics، catalog balance | gate قبل از completion کلی |
| 85 | mascot production preview batch | concept sheet/storyboard برای HUD، Arena coach، Reward celebration، Profile/shop states | قبل از asset integration، preview یا blocker رسمی داشته باشد |
| 86 | reward engine Kotlin adapter | `AdventureEvent` -> `RewardSummaryV2` -> UI projection adapter | هیچ preview number بدون rule source در UI نماند |
| 87 | achievement/quest seed writer | generated یا typed seed برای achievements، quests، badge wall و featured wall | stable ID collision و missing localization/icon ref fail شود |
| 88 | mascot/reward/badge asset QA | density، padding، alt text، reduced-motion، file-size budget، no baked app text | assetها روی dark teal و cream panels خوانا باشند |
| 89 | end-to-end gamify loop rehearsal | `Start Mission -> Answer -> Complete -> Claim -> Badge/Profile update` | reward، achievement، mascot و UI همه یک event trace را ببینند |
| 90 | specialized signoff ledger | `docs/adventure-gamify-specialized-ledger.md` برای originality، ethics، balance، mismatch | بدون ledger بسته شده completion اعلام نشود |

## Sliceهای پیشنهادی برای اجرا

### Slice 1: foundation and oracle

- بسازیم: reference manifest، measurement JSON، mismatch ledger، theme token skeleton.
- فایل های اصلی: `docs/*`, `app/src/main/java/com/gauss/app/ui/adventure/*`.
- نتیجه: همه می دانند target دقیق چیست و اختلاف ها با evidence بسته می شود.

### Slice 2: domain and data

- بسازیم: taxonomy جدا برای math و physics، gamify models، reward/event contracts، validation command.
- نتیجه: map و profile دیگر hardcoded fantasy screen نیستند، از state واقعی تغذیه می شوند.

### Slice 3: native component system

- بسازیم: panel/button/nav/progress/metric/badge/node/quest primitives.
- نتیجه: همه screenها از یک زبان بصری و behavioral contract استفاده می کنند.

### Slice 4: screens

- بسازیم: Map -> Arena -> Reward -> Profile به ترتیب core loop.
- نتیجه: مسیر کامل `Start Mission -> Answer -> Complete -> Claim Rewards -> Profile progress` زنده است.

### Slice 5: verification and polish

- بسازیم: screenshot matrix، visual diff ledger، emulator path، performance report، critics report.
- نتیجه: کار فقط با build pass تمام نمی شود، با تصویر واقعی و audit بسته می شود.

## Definition of Done

- چهار screen بومی Compose با preview تاییدشده در hierarchy، rhythm، palette، mascot، reward feel و CTA placement match باشند.
- app strings غیر data انگلیسی باشند و grep/string audit این را نشان دهد.
- math و physics roadها جدا باشند و Profile فقط summary cross-subject نشان دهد، نه road مخلوط.
- تمام controls قابل لمس، focusable، accessible و stateful باشند.
- هر reward claim، XP update، streak update و review queue update idempotent و test شده باشد.
- static full-screen reference assets از production UI حذف یا پشت debug/visual-oracle flag قرار گرفته باشند.
- emulator واقعی screenshot بدهد و mismatch ledger بدون blocker اصلی باشد.
- `:app:assembleDebug`, unit tests، Compose UI tests در scope، data validation، string audit، asset inventory، و performance report پاس یا با blocker دقیق ثبت شده باشند.

## ریسک های شناخته شده فعلی

- AVDهای API 37 ناپایدارند: user state در `BOOTING` گیر می کند و `install/start/screencap` قابل اعتماد نیست. `Codex_API35` فعلا مسیر سالم screenshot است.
- آخرین مقایسه عددی Map روی API35 هنوز mismatch بزرگ دارد: MAE `48.250`، RMSE `72.689`، p95 `211`.
- چهار صفحه adventure دیگر full-screen reference scaffold نیستند، اما screenshot parity هنوز به emulator/preview پایدار و visual diff نیاز دارد.
- mascot فعلا با `gauss_mentor.webp` نمایش داده می شود و برای رسیدن به preview باید batch asset مستقل و user-approved از mascot studio تولید و جایگزین شود.
- durable reward claim/offline replay هنوز به adapter کامل event ledger نیاز دارد، هرچند Reward Vault اکنون از نتایج live mission event می سازد.
- `questions.json` بزرگ است و data validation باید قبل از اتصال کامل gamify انجام شود.

## قدم بعدی پیشنهادی

قدم بعدی، بستن سه gate باقی مانده است: emulator/screenshot پایدار برای visual parity، تولید و تایید assetهای mascot/vault/badge مستقل، و durable reward claim/offline replay روی event ledger.

## Artifactهای دقیق تر

- Spec اجرایی صفحه به صفحه: `docs/adventure-preview-implementation-spec.md`
- Manifest ماشین خوان reference: `docs/adventure-reference-manifest.json`
- Workstream تخصصی gamify: `docs/adventure-gamify-specialized-workstreams.md`
