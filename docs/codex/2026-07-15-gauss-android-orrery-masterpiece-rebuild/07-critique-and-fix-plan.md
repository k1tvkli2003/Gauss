# گزارش فریز‌شده‌ی نقد «چرا Gauss هنوز شاهکار نیست؟»

> تاریخ ممیزی: 2026-07-15  
> دامنه: Flutter Android، موبایل و تبلت  
> وضعیت انتشار baseline: **BLOCK / غیرقابل انتشار**  
> مرجع الزام‌آور: [Orrery of Proofs](assets/mock-preview-c-orrery-of-proofs.png)

## خلاصه‌ی صادقانه

Gauss در لایه‌ی داده و پایداری، پایه‌ای بسیار بهتر از ظاهرش دارد: 7,353 سؤال و 3,410 رسانه حفظ شده‌اند؛ مرز اعتماد بین 3,681 سؤال mission-ready و 3,672 ردیف preserved روشن است؛ ثبت پیشرفت تراکنشی، idempotent و local-first است؛ تست‌های clock و نیمه‌شب وجود دارند. این بخش باید **حفظ** شود.

اما محصولی که کاربر می‌بیند نسخه‌ی اجرایی «Orrery of Proofs» نیست. یک تصویر مرجع غنی از ماده، عمق، نور، روایت، گره‌های سنگی/فلزی، مسیر روشن و inspector به مجموعه‌ای از دایره‌ها، `CustomPainter` ساده و `Material Icons` تقلیل یافته است. Practice و Insights نیز از همان جهان خارج می‌شوند و شبیه داشبورد داخلی داده‌اند. حلقه‌ی مأموریت سؤال را نشان می‌دهد، اما شخصیت، صحنه، هیجان بازخورد، پاداش، motion language و بازگشت معنادار به نقشه ندارد.

مشکل فقط «زیبا نبودن» نیست. APK فعلی repository اصلاً launch نمی‌شود. تست‌ها و build موفق، mismatch بین `applicationId` و package کلاس `MainActivity` را ندیده‌اند. بنابراین ادعای پایان قبلی بدون launch proof Android، یک شکست فرآیندی هم بوده است.

## مرز شواهد

- `flutter analyze`: بدون issue.
- `flutter test --reporter expanded`: هر 27 تست موجود سبز.
- APK repository: نصب می‌شود، اما launch با `ClassNotFoundException: com.gauss.app.MainActivity` شکست می‌خورد؛ [logcat](logs/current-apk-launch-logcat.txt).
- برای دیدن UI موجود، یک harness بیرون از repository ساخته شد که فقط package کلاس `MainActivity` را از `com.gauss.gauss` به `com.gauss.app` هماهنگ می‌کند. screenshotهای baseline، مدرک UI واقعی Flutter هستند؛ **مدرک سلامت APK repository نیستند**.
- موبایل: 1080×2400، density 420 (~411×914dp).
- تبلت افقی شبیه‌سازی‌شده: 2560×1600، density 240 (~1707×1067dp).
- font scale 1.3 و UIAutomator semantics نیز بررسی شدند.
- دستگاه فیزیکی در این مرحله در دسترس نبود؛ پذیرش نهایی باید این محدودیت را صریح نگه دارد.

## مقیاس قضاوت Modernize

| حکم | معنی |
|---|---|
| `KEEP` | قوی است؛ فقط در برابر regression محافظت شود. |
| `REFINE` | ساختار درست است، اجرای آن نیاز به پالایش دارد. |
| `REDESIGN` | هدف معتبر است اما فرم فعلی مانع کیفیت است. |
| `REMOVE` | نویز، بدهی یا تضاد بدون ارزش خالص است. |
| `ADD` | یک قابلیت/سطح لازم اصلاً وجود ندارد. |

## دفتر کامل نظر Modernize

| سطح | حکم | چرا شاهکار نیست | جهت قطعی |
|---|---|---|---|
| معماری local-first و trust boundary داده | `KEEP` | این بخش مشکل نیست؛ صادق، تراکنشی و قابل‌آزمون است. | repositories و invariantها را از redesign UI جدا نگه‌دار. |
| سه مقصد Map / Practice / Insights | `KEEP + REFINE` | تعداد و مدل ذهنی مناسب است، ولی presentation یک NavigationBar/Rail عمومی است. | همان سه مقصد، با glyph family اختصاصی و chrome جهان Orrery. |
| نقشه‌ی اصلی | `REDESIGN` | حلقه‌های ساده، nodeهای هم‌شکل، بدون مسیر، lock، chest، boss یا landmark؛ preview به کد خلاصه شده است. | scene لایه‌ای، path زنده، node shells چندحالته، فصل‌ها و نقاط اوج. |
| header / HUD | `REDESIGN` | با status bar برخورد می‌کند؛ XP و topic count شبیه chipهای عمومی‌اند. | HUD امن، فشرده و ابزاری: brand mark، وضعیت آفلاین، XP/streak و context action. |
| bottom navigation / navigation rail | `REDESIGN` | Material default و جدا از جهان؛ selected pill و iconها هویت ندارند. | قاب برنجی/ابزاری سبک، 48dp targets، focus و reduced-motion states. |
| mission inspector / compact dock | `REDESIGN` | اطلاعات آرشیوی، sample جعلی و CTA عمومی؛ hierarchy و ماده‌ی preview را ندارد. | preview سؤال واقعی، focus areas، difficulty، solution modes و CTA زنده. |
| Practice | `REDESIGN` | یک dashboard فیلتر و کارت است و زبان داخلی dataset را افشا می‌کند. | «اتاق تنظیم مأموریت» در دل رصدخانه؛ modeهای روشن و summary انسانی. |
| Insights | `REDESIGN` | first-use با چهار صفر و دیوار کارت‌ها شروع می‌شود؛ کاربر را راه نمی‌اندازد. | «دفتر رصد» با یک next-best-action، timeline شخصی و constellation badges. |
| Mission question layout | `REFINE + REDESIGN` | محتوا خواناست، اما صحنه و scale تبلت ضعیف است و RTL/math semantics شکسته است. | stage متمرکز موبایل؛ split-stage تبلت با سؤال، ابزار و راهنما. |
| answer feedback | `REDESIGN` | رنگ درست/غلط کار می‌کند، اما فاقد anticipation، reaction و explanation choreography است. | واکنش Mira، haptic، micro-motion، explanation reveal و بازگشت کنترل‌شده. |
| completion / reward | `REDESIGN` | یک Card متنی است، نه payoff؛ progression را روی نقشه قابل‌دیدن نمی‌کند. | recap سه‌مرحله‌ای: نتیجه، reward reveal، map consequence. |
| achievement catalog | `KEEP + REDESIGN` | منطق و rarity مفید است، ولی UI آن را به Material Icon تقلیل می‌دهد. | badge art اختصاصی، silhouette در حالت قفل، rarity material و reveal. |
| mascot / coach | `ADD` | هیچ صدای همراه یا حافظه‌ی احساسی وجود ندارد. | **Mira**، اتوماتون کوچک رصدخانه؛ آرام، کنجکاو و بدون فشار اجتماعی. |
| reward props / chests | `ADD` | XP عدد است و هیچ شیء قابل‌مالکیتی ندارد. | astrolabe fragments، star seals و chests محدودِ غیرپولی؛ reward ledger همان منبع حقیقت. |
| logo / brand mark | `REDESIGN` | mark منسجم و قابل‌مالکیت وجود ندارد؛ icon فعلی شبیه knot پاستلی نامرتبط است. | یک `G` مداری با ستاره‌ی قضیه و index notch؛ vector-first و خوانا در 16px. |
| Android app icon | `REDESIGN` | foreground فعلی پاستلی و خارج از palette است؛ monochrome ندارد. | adaptive foreground/background/monochrome در safe zone رسمی Android. |
| wordmark | `REDESIGN` | فقط متن Gauss با فونت عمومی است. | wordmark کنترل‌شده با serif علمی برای display و sans خوانا برای UI. |
| tagline / product promise | `ADD` | هیچ وعده‌ی به‌یادماندنی یا voice anchor وجود ندارد. | primary: **Chart what you can prove.** secondary: **Every solved question lights the map.** |
| typography | `REDESIGN` | Vazirmatn به‌صورت global روی chrome انگلیسی اعمال شده و hierarchy ماده‌ای ندارد. | family جدا برای Latin display، Latin UI و Persian learning text؛ metrics هماهنگ. |
| functional icons | `REDESIGN` | نگاشت مستقیم کلیدها به Material Icons، بدون وزن و هندسه‌ی مشترک. | یک خانواده‌ی vector تک‌وزن با optical sizing و state variants. |
| pictograms / topic glyphs | `REDESIGN` | بیشتر موضوع‌ها به Σ ختم می‌شوند؛ تشخیص سریع از بین می‌رود. | 29 glyph اختصاصی یا خوشه‌بندی‌شده، با silhouette متفاوت و live label. |
| posters / previews / store imagery | `ADD` | تصویر مرجع به runtime contract تبدیل نشده و هیچ poster system وجود ندارد. | key art اصلی + phone/tablet compositions + asset manifest + fidelity matrix. |
| splash / launch | `REDESIGN` | launch branding بی‌هویت و startup قبل از `runApp` است. | Android 12 splash با mark، سپس staged bootstrap با feedback واقعی. |
| loading / empty / error / retry | `REDESIGN` | generic یا خام‌اند؛ first-use Insights عملاً empty state طراحی‌نشده است. | stateهای world-native، اقدام روشن، copy انسانی و diagnostic امن. |
| footer / bottom action area | `REDESIGN` | Mission footer یک نوار خالی و CTA جدا از صحنه است. | action dock در thumb zone با state animation و explanation affordance. |
| motion / haptics / sound | `ADD` | زبان حرکتی وجود ندارد؛ reduced motion نیز gate نشده است. | spring محدود، orbit settle، reward reveal، haptic طبقه‌بندی‌شده و silent-by-default sound option. |
| accessibility | `REDESIGN` | overlap با status، font-scale break و math semantics قطعه‌قطعه. | SafeArea/insets، merged semantics، locale، 48dp، contrast/focus و TalkBack test. |
| performance strategy | `ADD + REFINE` | `Image.asset` بدون decode sizing، scratchpad repaint سنگین و broad rebuild. | variants، `cacheWidth`, precache محدود، RepaintBoundary، profiling روی release/profile. |
| متن داخلی/آرشیوی | `REMOVE` | «contract-checked»، «preserved archive» و توضیح تضاد source برای کاربر نهایی نوشته شده‌اند. | جزئیات integrity فقط در diagnostics؛ UI می‌گوید چه چیزی قابل تمرین است و چرا. |

## یافته‌های اولویت‌بندی‌شده

### P0-01 — APK repository launch نمی‌شود

- مسیر: `flutter_app/android/app/build.gradle.kts:10,20` و `flutter_app/android/app/src/main/kotlin/com/gauss/gauss/MainActivity.kt:1`
- انتظار: activity ثبت‌شده در manifest باید کلاس قابل‌بارگذاری داشته باشد.
- واقعیت: namespace/applicationId برابر `com.gauss.app` است، اما کلاس در package `com.gauss.gauss` قرار دارد. Android به‌دنبال `com.gauss.app.MainActivity` می‌گردد و crash می‌کند.
- اثر: هیچ کیفیت UI، dataset یا test موفقی این release را قابل استفاده نمی‌کند.
- اصلاح: package/path کلاس را هماهنگ کن؛ instrumentation launch test و نصب/launch release APK را گیت اجباری کن.

### P1-02 — preview منتخب به قرارداد پیاده‌سازی تبدیل نشده

- مدرک: [مرجع](assets/mock-preview-c-orrery-of-proofs.png) در برابر [runtime موبایل](assets/gauss-baseline-phone-map.png) و [runtime تبلت](assets/gauss-baseline-tablet-landscape-map.png).
- کد: `map_screen.dart:194-216,397-433` یک canvas ثابت 1100، painter ساده و Material icons می‌سازد.
- اثر: ماده، عمق، landmark، silhouette، مسیر و هویت حذف شده‌اند؛ کاربر یک placeholder می‌بیند.
- اصلاح: پیش از کدنویسی، decomposition manifest و fidelity rubric فریز شود؛ هر لایه asset/live و state/variant مشخص داشته باشد.

### P1-03 — موبایل با insets و متن بزرگ می‌شکند

- مدرک: [font scale 1.3](assets/gauss-baseline-phone-font130.png).
- واقعیت: HUD در `top: 16` و بدون SafeArea قرار گرفته؛ status/time روی Gauss و XP می‌افتد. canvas crop ثابت باعث قطع node و label می‌شود.
- اصلاح: viewport از `MediaQuery.padding` و display features آگاه شود؛ scale از اندازه‌ی واقعی node/label و safe bounds محاسبه شود؛ 1.0/1.3/1.5 test.

### P1-04 — نقشه progression نیست؛ فقط catalog دایره‌ای است

- واقعیت: 29 topic تقریباً هم‌ارز دیده می‌شوند. current/locked/completed/disabled، اتصال مسیر، reward milestone و chapter landmark خوانا نیست.
- اثر: کاربر نمی‌فهمد «الان کجا هستم، بعد کجا بروم، چرا؟»؛ map-first بودن به wallpaper تبدیل می‌شود.
- اصلاح: مسیر قابل‌دنبال‌کردن، current beacon، gateها، branchهای محدود، chest/encounter و focus sector با state machine واقعی.

### P1-05 — مأموریت حلقه‌ی بازی کامل ندارد

- مدرک: [سؤال](assets/gauss-baseline-phone-mission.png) و [بازخورد](assets/gauss-baseline-phone-mission-feedback.png).
- قوت: سؤال و انتخاب/ثبت پاسخ کار می‌کند.
- شکاف: coach، anticipation، feedback reaction، combo، reward reveal و اثر روی جهان وجود ندارد. completion یک card است.
- اصلاح: Mira + micro-interactions + feedback choreography + recap و روشن‌شدن node بعد از بازگشت.

### P1-06 — semantics سؤال ریاضی برای TalkBack شکسته است

- مدرک: UIAutomator سؤال را به بیش از 20 node جدا برای پرانتز، A، B، اجتماع و متن فارسی تقسیم می‌کند.
- کد: tokenهای `$...$` در `content_blocks.dart` با `Wrap` و spanهای جدا رندر می‌شوند.
- اثر: ترتیب شنیداری و معنای عبارت از بین می‌رود؛ mixed RTL/LTR می‌تواند بصری هم جابه‌جا شود.
- اصلاح: semantics واحد و زبان‌محور برای stem/choice، visual spans جدا اما `ExcludeSemantics` + label کامل؛ تست golden و semantics برای فرمول‌های mixed-direction.

### P1-07 — تست‌ها ادعای release را اثبات نمی‌کنند

- واقعیت: 27 تست داده/پایداری ارزشمندند، اما launch، widget، golden، overflow، font scale، TalkBack، adaptive window و reduced motion نداریم.
- اثر: build و tests سبز بودند ولی app launch نشد؛ preview mismatch نیز دیده نشد.
- اصلاح: launch instrumentation، smoke route matrix و screenshot fidelity را در CI/local release gate اضافه کن.

### P1-08 — هویت برند و app icon با محصول تضاد دارد

- مدرک: `drawable-nodpi/ic_launcher_foreground.png` یک knot پاستلی است؛ palette و داستان Orrery را ندارد و در adaptive XML لایه‌ی `<monochrome>` وجود ندارد.
- اثر: اولین و پرتکرارترین touchpoint محصول نامرتبط و کم‌مالکیت است.
- اصلاح: mark vector، adaptive layers، mask preview، themed icon و Android 12 splash هماهنگ.

### P2-09 — layout تبلت از فضای بزرگ استفاده نمی‌کند

- مدرک: [مأموریت تبلت](assets/gauss-baseline-tablet-landscape-mission.png).
- واقعیت: سؤال و گزینه‌ها در یک ستون باریک وسط هستند و بیشتر بوم خالی است؛ scratchpad همچنان bottom sheet است.
- اصلاح: canonical list-detail/supporting-pane؛ سؤال در stage اصلی، ابزار/راهنما/پیشرفت در supporting pane، scratchpad dockable.

### P2-10 — Practice به ابزار ممیزی dataset شبیه است

- مدرک: [Practice موبایل](assets/gauss-baseline-phone-practice.png).
- واقعیت: عبارت‌هایی مثل `mission-ready`, `preserved`, `contract-checked`, conflict و archive integrity با کاربر صحبت می‌کنند.
- اثر: اعتماد به‌جای افزایش، با زبان فنی و دفاعی سنگین می‌شود.
- اصلاح: «Available offline»، «Practice pool»، و explanation کوتاه؛ جزئیات trust boundary فقط در diagnostics قابل‌دسترسی.

### P2-11 — Insights first-use را تنبیه می‌کند

- مدرک: [Insights موبایل](assets/gauss-baseline-phone-insights.png).
- واقعیت: چهار کارت بزرگ صفر، quest صفر و badgeهای خاکستری بدون CTA.
- اصلاح: یک hero state با «اولین نور را روشن کن»، CTA مأموریت، preview قابل‌دستیابی و سپس progressive disclosure آمار.

### P2-12 — achievement art requirement اجرا نشده

- کد: catalog برای family/rarity/art requirement داده دارد، اما `insights_screen.dart:459-463` آن را به Material Icons تبدیل می‌کند.
- اثر: دستاورد قابل‌جمع‌آوری و به‌یادماندنی نیست.
- اصلاح: badge kit با locked silhouette، rarity frames، shimmer اختیاری و reveal؛ منطق فعلی حفظ شود.

### P2-13 — startup قبل از اولین frame متوقف می‌شود

- کد: `main.dart:18-19` ابتدا `await controller.initialize()` و سپس `runApp`.
- اثر: database/index طولانی یا failure می‌تواند صفحه‌ی سیاه طولانی بدهد؛ cold debug baseline حدود 6.3s بود (برای release نماینده نیست، اما معماری ریسک را ثابت می‌کند).
- اصلاح: app shell و branded bootstrap فوراً اجرا شوند؛ initialization مرحله‌ای، قابل retry و دارای state امن باشد.

### P2-14 — state و analytics با رشد تاریخچه گران می‌شوند

- کد: `GaussController` یک `ChangeNotifier` سراسری است؛ `AnimatedBuilder` بالای app قرار دارد؛ analytics در هر refresh همه‌ی attempts را بار می‌کند.
- اثر: rebuild گسترده و هزینه‌ی خطی با تاریخچه؛ در محصول شخصی طولانی‌مدت محسوس می‌شود.
- اصلاح: projectionهای DB، selectorهای کوچک، immutable view models و measurement قبل/بعد.

### P2-15 — media و scratchpad بودجه‌ی performance ندارند

- کد: `Image.asset` بدون `cacheWidth/cacheHeight`; scratchpad در هر pointer update `setState` می‌کند و points نامحدود است.
- اثر: decode حافظه‌ی بالا، GC/jank و repaint کل sheet.
- اصلاح: resolution variants، decode-to-display-size، `RepaintBoundary`، stroke batching/Path و سقف history/undo.

### P2-16 — loading/error copy و diagnostics امن نیستند

- واقعیت: برخی errorها raw object را در UI نشان می‌دهند؛ stateهای empty/error با جهان بصری یکی نیستند.
- اصلاح: failure taxonomy به copy انسانی و action مشخص map شود؛ جزئیات فنی فقط در log محلی opt-in.

### P3-17 — typography یک‌زبانه روی محصول دوزبانه تحمیل شده

- کد: `gauss_theme.dart:36`، `Vazirmatn` به‌صورت global.
- اثر: wordmark و chrome انگلیسی شخصیت و metrics مناسب ندارند؛ متن فارسی هم hierarchy تخصصی سؤال/توضیح ندارد.
- اصلاح: font roles مستقل و تست fallback/weight/line-height برای Latin، Persian و math.

### P3-18 — motion، haptic و reduced-motion contract وجود ندارد

- اثر: interactionها تخت‌اند و بازخورد بازی‌گونه نیست؛ افزودن motion بدون contract نیز بعداً خطر سرگیجه/jank دارد.
- اصلاح: motion tokens، `disableAnimations`/reduce-motion path، haptic taxonomy و تست instant transition.

## علت‌های سیستمی

1. **Preview بدون decomposition contract:** هیچ جدول الزام‌آوری نگفت کدام بخش asset است، کدام live، کدام state و کدام breakpoint دارد.
2. **کدنویسی پیش از art pipeline:** painter و Material Icon به‌عنوان جایگزین موقت وارد شدند و هیچ gateای موقتی بودنشان را شکست نداد.
3. **تعریف پایان بر اساس build/test:** launch واقعی، screenshot Android و fidelity comparison جزو Done نبود.
4. **سطح‌بندی ناقص Modernize:** نقد روی صفحه‌ی اصلی متمرکز شد و brand/icon/splash/poster/copy/state/motion بیرون ماند.
5. **داشبوردزدگی:** Practice و Insights به‌جای اتاق‌های یک جهان واحد، به cards-and-filters تبدیل شدند.

## سیستم برند پیشنهادی

### جوهر برند

**یک ابزار شخصی برای تبدیل مسئله‌های سخت به جهانی قابل‌دیدن از تسلط.** لحن آن آرام، دقیق، کنجکاو و کمی اسرارآمیز است؛ نه کودکانه، نه دانشگاهی خشک، نه رقابتی.

### promise و شعار

- Primary: **Chart what you can prove.**
- Supporting line: **Every solved question lights the map.**
- استفاده: primary در onboarding/poster؛ supporting line در first-use Insights و reward recap، نه روی همه‌ی صفحه‌ها.

### mark و icon

- فرم پایه: حرف `G` از دو قوس مداری، یک بریدگی شاخص در ساعت 12 و یک «ستاره‌ی قضیه» مرکزی.
- باید در 16px و monochrome قابل‌شناسایی باشد؛ جزئیات orrery فقط در نسخه‌ی display، نه launcher small size.
- adaptive Android: foreground، background و monochrome مستقل؛ safe zone 66×66dp در canvas 108×108dp.

### شخصیت

**Mira**: اتوماتون جیبی رصدخانه با یک لنز مرکزی و باله‌های برنجی. نقش‌ها: راهنما، شاهد تلاش و نگهبان آرام نقشه؛ نه قاضی و نه فروشنده. stateها: curious، thinking، hint، correct delight، gentle correction، milestone awe، idle، reduced-motion still.

## قرارداد art kit ماژولار

| گروه | نوع | variantهای ضروری | live یا flattened |
|---|---|---|---|
| starfield / parchment atmosphere | WebP/AVIF-like source → WebP assets | phone portrait، tablet portrait، tablet landscape، low-memory | flattened background |
| central theorem engine | transparent WebP layers + vector rings | base، glow، foreground occluder، reduced-motion | hybrid |
| topic node shell | 9-slice/vector + texture overlay | locked، available، current، completed، mastered، boss، disabled، focus | hybrid؛ label/progress live |
| path / orbit lines | vector/custom paint | dormant، available، active pulse، completed | live |
| topic glyph family | SVG/vector path | 29 topics، selected/locked contrast | live vector |
| inspector and docks | vector/9-slice frame | compact، portrait tablet، landscape tablet | live controls on scalable frame |
| Mira | transparent WebP sprite/short sequences | emotion matrix + reduced-motion stills | decorative asset + semantic label |
| achievements | transparent WebP/SVG | locked silhouette، unlocked، rarity frames | asset + live progress |
| reward props | transparent WebP | fragment، seal، chest states، glow | asset + live count |
| brand | SVG/vector + Android XML | mark، wordmark، adaptive fg/bg/mono، splash | vector-first |
| posters/previews | composed raster | phone، tablet، key art | flattened marketing/previews only |

متن سؤال، جواب، خطا، CTA، آمار، پیشرفت، legal/critical copy و هر داده‌ی قابل‌تغییر **نباید** داخل تصویر پخته شود.

## نقشه‌ی اصلاح

### فاز 0 — نجات release و گیت حقیقت

1. اصلاح package/path Android و افزودن launch test.
2. bootstrap فوری بعد از `runApp`، SafeArea/insets و font-scale smoke.
3. golden/screenshot baseline برای 411×914dp، 800×1280dp و 1707×1067dp.
4. invariant check dataset/media قبل و بعد هر فاز.

### فاز 1 — سیستم طراحی و قرارداد هویت

1. tokens: color/material/elevation/radius/spacing/type/motion/haptic.
2. brand mark، wordmark، adaptive icon و splash.
3. functional icon family و topic glyph mapping.
4. failure/empty/loading copy contract و slogan placement.

### فاز 2 — art pipeline و map engine

1. تولید background/orrery/node/inspector/Mira/badge/reward assets با promptهای خانواده‌ای.
2. cleanup، transparency، resolution variants، checksum و manifest.
3. map coordinate model بر اساس normalized anchors و window class، نه canvas ثابت.
4. path/progression states، focus sector، pan/zoom محدود و keyboard/focus path برای تبلت.

### فاز 3 — حلقه‌ی مأموریت

1. mobile stage و tablet split-stage.
2. semantics واحد برای Persian+math و choice labels.
3. scratchpad dockable با stroke batching، undo/erase.
4. feedback choreography، Mira reaction، recap و map consequence.

### فاز 4 — Practice، Insights و مجموعه‌ها

1. Practice به mission forge در جهان Orrery تبدیل شود؛ filterها progressive و انسانی.
2. Insights first-use، timeline، next action و badge constellation.
3. achievement/reward art به logic موجود وصل شود؛ بدون auth/social/monetization.

### فاز 5 — Perfect و release proof

1. profile frame/build/raster، image memory، startup و DB queries.
2. accessibility: TalkBack، font scale 1.5، contrast، 48dp، reduced motion.
3. failure injection: DB init، write، corrupt asset، empty filter، resume.
4. release build، install، cold/warm launch، screenshot matrix و artifact signing metadata.

## معیار پایان واقعی

این بازسازی فقط وقتی «تمام» است که همه‌ی این‌ها هم‌زمان درست باشند:

- repository APK روی Android launch شود؛ نه harness.
- تمام invariantهای dataset/media دقیقاً برابر baseline بمانند.
- Map/Mission/Practice/Insights روی موبایل و تبلت screenshot تأیید‌شده داشته باشند.
- comparison با reference در composition، crop، hierarchy، material، depth، state و brand ثبت شود.
- هیچ placeholder icon/painter/card که نقش asset مصوب را گرفته باقی نماند.
- TalkBack سؤال را یک عبارت معنادار بخواند و تمام کنترل‌ها label/role/state درست داشته باشند.
- font scale 1.5 و reduced motion بدون overlap/overflow عبور کنند.
- release profile هیچ jank یا memory regression اثبات‌نشده نداشته باشد.
- گزارش verification بگوید چه چیزی pass/fail/not-run بوده؛ نه اینکه build موفق را معادل product success بداند.

## منابع معیار فنی

- Flutter توصیه می‌کند adaptive UI بر اساس فضای در دسترس تصمیم بگیرد، نه نوع دستگاه: [Adaptive and responsive design](https://docs.flutter.dev/ui/adaptive-responsive/general) و [Best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices).
- برای variant و resolution دارایی‌ها: [Flutter assets and images](https://docs.flutter.dev/ui/assets/assets-and-images) و [precacheImage](https://api.flutter.dev/flutter/widgets/precacheImage.html).
- سنجش performance باید در profile و با DevTools انجام شود: [Rendering performance](https://docs.flutter.dev/perf/rendering-performance)، [Performance best practices](https://docs.flutter.dev/perf/best-practices) و [DevTools Performance](https://docs.flutter.dev/tools/devtools/performance).
- Android برای large screens، layoutهای تطبیقی و استفاده از فضای بیشتر را الزام کیفیت می‌داند: [Large screens](https://developer.android.com/guide/topics/large-screens) و [Large screen quality](https://developer.android.com/docs/quality-guidelines/archive/adaptive/large-screen-app-quality).
- adaptive icon باید لایه‌های 108×108dp، safe zone و monochrome داشته باشد: [Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).
- هدف تعاملی توصیه‌شده حداقل 48×48dp است: [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views).
- برای semantics و screen reader: [Flutter assistive technologies](https://docs.flutter.dev/ui/accessibility/assistive-technologies) و [Accessibility widgets](https://docs.flutter.dev/ui/widgets/accessibility).

## نقاط قوتی که نباید قربانی هنر شوند

- حفظ کامل dataset/media و stable IDs.
- trust boundary شفاف و عدم امتیازدهی به ردیف‌های نامطمئن.
- persistence محلی، transaction و idempotency.
- domain clock تزریق‌شده و تست‌های local midnight.
- نبود auth، social pressure، monetization و backend غیرضروری.
- محتوای فارسی واقعی و امکان کار کاملاً آفلاین.

این گزارش از این لحظه baseline فریز‌شده‌ی اصلاح است. هر تغییر بعدی باید به یکی از یافته‌ها یا حکم‌های سطحی بالا وصل و با مدرک runtime بسته شود.

