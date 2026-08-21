# برنامه اجرایی پرفکشن Android گائوس

- Status: `active`
- Binding baseline: `f3edce84a54a89f1be3051ff435659e26d1e9e7c`
- Target: Flutter/Dart → Android
- Modernization mode: `Recompose` برای shell و Map UX، `Radical rebuild` برای Map renderer و question interaction، `Elevate` برای مسیرهای فرعی، `Showpiece` فقط برای milestoneهای کمیاب
- Accepted visual direction: Gauss Orrery + Astral Manuscript

## 1. نتیجه مطلوب

گائوس باید مثل یک ابزار یادگیری نجومیِ واقعاً حرفه‌ای حس شود: Map یک مسیر زنده و روان برای انتخاب پنج سؤال بعدی باشد؛ صفحه سؤال یک manuscript قابل نوشتن و خوانا باشد؛ هر لمس پاسخ فوری و واضح بگیرد؛ و هیچ footer، dock، label، animation یا texture مانع خواندن، اسکرول یا تصمیم‌گیری نشود.

این برنامه line-count، تعداد commit یا تعداد iteration را معیار پیشرفت نمی‌داند. پیشرفت فقط با خروجی پذیرفته‌شده و گیت پاس‌شده محاسبه می‌شود.

## 2. قرارداد حفظ

موارد زیر در تمام مراحل باید بدون reset، حذف یا جایگزینی حفظ شوند:

- بانک سؤال، رسانه‌ها و source JSONهای immutable.
- شناسه پایدار هر سؤال و سازگاری content deltaهای آینده.
- حساب‌ها، session، RLS/Supabase contract، پیشرفت، streak، XP، reward receipt، history و feedback.
- پنج سؤال دقیق برای هر micro-lesson و گروه‌بندی آموزشی فعلی.
- route/back/deep-link، save/retry/resume، offline/degraded و error behavior.
- English app chrome، Persian learning content و ASCII numeral rendering.
- package identity نسخه شخصی؛ تست runtime با `com.gauss.app.debug` در کنار آن انجام می‌شود.

هر تغییری که یکی از این قراردادها را لمس کند باید migration/rollback و regression test خودش را داشته باشد. ساده‌کردن UI مجوز حذف function نیست.

## 3. شواهد baseline و علت‌های محتمل

| سطح | شاهد فعلی | نتیجه اجرایی |
|---|---|---|
| سلامت کد | analyzer پاس و 43 تست متمرکز پاس | foundation قابل حفظ است؛ بازسازی از صفرِ منطق دامنه لازم نیست. |
| Map scroll | stage بلند در `SingleChildScrollView`، full-height `CustomPaint` و listener دارای `setState` | ابتدا trace، سپس lazy/segmented rendering و narrow invalidation. |
| Map raster | blurهای ثابت روی محتوای متحرک و painterهای وابسته به scroll | blur روی مسیر متحرک حذف/جایگزین و repaint به bandهای کوچک محدود شود. |
| Map visual | هدر شلوغ، strip فصل سنگین، labelهای کم‌کنتراست، دو لایه مزاحم بالای footer | سلسله‌مراتب و bottom chrome بازترکیب شود؛ یک context layer کافی است. |
| Question rebuilds | `QuestionManuscript` و `InlineQuestionScratch` هر دو به ink گوش می‌دهند | ink فقط canvas را repaint کند؛ parent فقط هنگام تغییر semantic state rebuild شود. |
| Question touch | `RawGestureDetector` مالک gesture است | stylus/palm/touch با pointer-kind contract و تست displacement جدا شوند. |
| Question visual | فضای استدلال بی‌استفاده بزرگ، rail ابزار غالب، گزینه‌های دور از prompt و dock سنگین | manuscript فشرده و expandable، ابزار contextual و پاسخ‌های content-driven. |
| ساختار | فایل‌های Map/Mission/Practice/Scratch بسیار بزرگ و coupled | decomposition بر اساس render/state ownership، نه خردکردن مکانیکی فایل‌ها. |
| performance proof | probe قدیمی روی SwiftShader دارای raster p95 حدود 207ms و غیرقابل تعمیم | harness deterministic و before/after هم‌شرایط ساخته شود؛ عدد قدیمی acceptance نیست. |

## 4. تز طراحی و تجربه

### Map: Celestial Expedition

- صفحه نخست یک نقشه تمام‌صفحه می‌ماند، نه dashboard دارای card.
- viewport اول فقط سه سؤال را جواب می‌دهد: الان کجا هستم، پنج سؤال بعدی چیست، چطور شروع کنم.
- هدر به سه track هم‌وزن تبدیل می‌شود: daily signal، crest/progress و dual subject orbit؛ محور واقعی wordmark/progress حفظ می‌شود.
- انتخاب subject/course/chapter در یک Orbit Navigator واحد قرار می‌گیرد: sheet در phone و inspector در tablet landscape.
- مسیر یک curve پیوسته، واضح و آرام است؛ current، next و distant سه وزن بصری متفاوت دارند.
- labelها حداکثر دو خط، anchored و collision-aware هستند و هرگز mid-word شکسته نمی‌شوند.
- landmarkهای بزرگ در حاشیه مسیر depth می‌سازند، اما hit target یا متن را نمی‌پوشانند.
- Current Mission از یک card دائمیِ بزرگ به Mission Compass جمع‌وجور تبدیل می‌شود؛ در حالت idle خلاصه است و با tap/node selection باز می‌شود.
- progress strip تکراری حذف و داخل همان Mission Compass ادغام می‌شود.
- footer فقط دور سه مقصد خودش فضا دارد، safe-area بیرون آن محاسبه می‌شود و هیچ backdrop blur روی path متحرک ندارد.

### Question: Writable Astral Manuscript

- سؤال، فضای نوشتن و چهار پاسخ یک manuscript پیوسته باقی می‌مانند.
- prompt زودتر دیده می‌شود و فضای reasoning در حالت بدون ink محدود است؛ با شروع نوشتن یا expand به‌نرمی بزرگ می‌شود.
- قلم سخت‌افزاری مستقیماً می‌نویسد؛ انگشت همیشه scroll می‌کند مگر کاربر صریحاً finger-pen را فعال کند.
- tool spine هویت تصویری خود را حفظ می‌کند، اما inactive toolها سبک‌ترند؛ phone کوچک reflow و tablet حالت ثابت خودش را دارد.
- Undo، eraser، expand و Clear/Restore state عوض می‌کنند ولی ارتفاع manuscript یا dock را جابه‌جا نمی‌کنند.
- چهار پاسخ به‌صورت engraved answer rails در همان کاغذ دیده می‌شوند؛ ارتفاعشان تابع محتواست، نه چهار box هم‌اندازه و بلند.
- selected/correct/wrong/disabled/source-warning با material، symbol، live copy و semantics مشخص‌اند؛ رنگ تنها سیگنال نیست.
- bottom solve instrument content-hugging، safe-area aware و در tablet دارای max-width است.
- solution و reflection در phone ادامه طبیعی manuscript و در tablet یک pane مکمل‌اند، بدون از دست‌رفتن ink یا انتخاب.

### Tablet اختصاصی

- Tablet portrait: stage مرکزی خوانا با gutter/inspector کنترل‌شده؛ هیچ phone UI کشیده‌ای پذیرفته نیست.
- Tablet landscape Map: مسیر حدود 60–68% و inspector زمینه‌ای حدود 32–40%، با rail ناوبری کم‌عرض.
- Tablet landscape Question: manuscript و response/solution workspace دوپنجره‌ای با state مشترک و scroll مستقل.
- تغییر orientation انتخاب، ink، scroll anchor، focus و session را حفظ می‌کند.

## 5. Opinion ledger کل تجربه

| سطح | تصمیم | نتیجه مورد انتظار |
|---|---|---|
| Gauss wordmark، Theorem Star، brass/teal/abyss identity | KEEP | هیچ افت هویت یا جایگزینی generic رخ ندهد. |
| Launcher/adaptive icon و splash فعلی | KEEP / VERIFY | فقط mask، monochrome و runtime دوباره اثبات شوند. |
| design tokens، English chrome و mixed-script renderer | REFINE | type/spacing/contrast/state tokenها یکپارچه شوند. |
| Map-first mental model و پنج سؤال در هر node | KEEP | منطق آموزشی و جهت اصلی محصول ثابت بماند. |
| Map scroll/render architecture | REDESIGN | lazy segmented scene با geometry cache و repaint محدود. |
| Map header/HUD | REDESIGN | تراکم کمتر، محور روشن، subject switch قابل فهم. |
| Orbit/course/chapter selector | REDESIGN | یک navigator مرکزی به‌جای stripهای پراکنده. |
| node shell و landmark art | REFINE | اندازه، state و fidelity بهتر؛ assetهای خوب حفظ شوند. |
| node labels و path connections | REDESIGN | خوانایی، collision control و مسیر پیوسته قوی. |
| Current Mission + progress strip | REDESIGN / MERGE | یک Mission Compass، نه دو نوار مزاحم. |
| floating footer/navigation | REDESIGN | compact، safe، content-hugging و بدون blur پرهزینه. |
| Astral parchment material | KEEP / REFINE | material حفظ و composition فشرده‌تر شود. |
| question hierarchy و answer rails | REDESIGN | prompt-to-answer time کمتر و stateهای واضح‌تر. |
| stylus/tool interaction | REDESIGN | direct stylus، native touch scroll، contextual tools. |
| Study، Insights، auth، feedback و system states | REFINE | همان DNA بصری و action hierarchy را بگیرند. |
| route transitions و five-question celebration | REDESIGN | continuity، feedback و reward receipt حرفه‌ای و قابل skip. |
| sharing/public competition/monetization | REMOVE / DO NOT ADD | در محصول وجود نداشته باشد. |
| Web-specific layout/build work | OUT OF SCOPE | این چرخه فقط Android را می‌بندد. |

## 6. نقشه مراحل و وزن Goal

درصد Goal از صفر محاسبه می‌شود؛ هر مرحله فقط پس از عبور گیت خودش امتیاز می‌گیرد.

| فاز | وزن | وضعیت | خروجی پذیرفته‌شده |
|---|---:|---|---|
| P0 — Baseline، instrumentation و preservation | 8% | completed | journeyهای تکرارپذیر، trace baseline، hash/data guard و screenshot baseline |
| P1 — UI system، geometry و production manifest | 7% | active | token math، surface manifest، motion/precision ledgers و vertical-slice spec |
| P2 — بازسازی engine اسکرول و رندر Map | 18% | planned | lazy path bands، cached geometry، narrow repaint، native scroll و benchmark بهتر |
| P3 — بازسازی بصری و UX کامل Map | 17% | planned | header، navigator، path، node/label، Mission Compass و footer نهایی |
| P4 — بازسازی Question، answers و stylus | 20% | planned | manuscript فشرده، قلم/لمس بی‌نقص، answer states و solution/completion |
| P5 — shell، Study، Insights، auth، feedback و tablet | 12% | planned | یکپارچگی همه routeهای ضروری و composition اختصاصی tablet |
| P6 — motion، feedback، reward و accessibility | 8% | planned | Motion Bible اجراشده، reduced motion، haptic/semantic feedback و no-jank proof |
| P7 — integration، adversarial QA و Android release proof | 10% | planned | suite کامل، matrix بصری، profile comparison، APK/install و clean mismatch ledger |

## 7. جزئیات اجرای هر فاز

### P0 — Baseline و ابزار اندازه‌گیری

1. repo/data/auth/progress contracts، package IDs و asset inventory فریز می‌شوند.
2. سه journey deterministic ساخته می‌شود:
   - cold/warm launch → first usable Map؛
   - 20 ثانیه scroll مسیر + انتخاب node + بازگشت؛
   - ورود Mission → ink با stylus simulation → touch scroll → انتخاب پاسخ → next.
3. profile runner شرایط build/device/cache/run-count را به JSONL ثبت می‌کند.
4. پنج اجرای هم‌شرایط برای frame timing، missed frames، input-to-next-frame، memory و rebuild/repaint count گرفته می‌شود.
5. screenshot و semantics baseline در phone و tablet ثبت می‌شوند.

گیت: baseline قابل تکرار باشد، artifact/hashها ثبت شوند و هیچ تغییر UX قبل از داشتن عدد/تصویر مبنا merge نشود.

### P1 — سیستم بصری و معماری vertical slice

1. accepted Map و Astral Manuscript به layer manifest تبدیل می‌شوند: raster، vector، live semantic و hybrid.
2. spacing/type/radius/stroke/elevation/hit-target ramp و breakpoint rules از constraint واقعی مشتق می‌شوند.
3. composition occupancy، symmetry axis، z-order، safe-area و state matrix برای Map و Question نوشته می‌شوند.
4. یک vertical slice از first Map viewport و Question 1 به spec اجرایی تبدیل می‌شود؛ direction تازه ساخته نمی‌شود.
5. Motion Bible برای route arrival، node selection، answer feedback، question advance و lesson completion ایجاد می‌شود.

گیت: manifest، precision ledger، state matrix و acceptance screenshot positions کامل باشند.

### P2 — Map engine

1. stage یک‌تکه به `CustomScrollView`/sliver و bandهای lazy با ارتفاع bounded تبدیل می‌شود.
2. path geometry یک‌بار با key شامل topic/section، width، node count و text-scale bucket cache می‌شود.
3. هر band فقط segment، node، label و landmark مربوط به خودش را paint/build می‌کند؛ path continuity با مختصات global→local حفظ می‌شود.
4. scroll listener دیگر کل stage را `setState` نمی‌کند؛ viewport window و parallax decoration به notifier/repaint کوچک و thresholded محدود می‌شوند.
5. `BackdropFilter`های روی محتوای متحرک با material لایه‌ای کم‌هزینه جایگزین یا به سطح ثابت محدود می‌شوند.
6. jump-to-current، restoration، semantics order و node focus روی geometry جدید حفظ می‌شوند.
7. image decode/cache بر اساس rendered size و density bounded می‌شود؛ source asset دست‌نخورده می‌ماند.

گیت: journey اسکرول در شرایط برابر بهبود tail frame/jank نشان دهد؛ هیچ node، path، label، focus یا semantics گم نشود.

### P3 — Map visual و UX

1. header/HUD با trackهای هم‌وزن و hierarchy روشن بازسازی می‌شود.
2. subject/course/chapter در Orbit Navigator یکپارچه می‌شوند.
3. spiral route، node spacing، special landmarks و label anchors روی phone/tablet جدا تنظیم می‌شوند.
4. selected/current/next/locked/completed states از نظر contrast، scale، motion و semantics کامل می‌شوند.
5. Current Mission و lesson progress در Mission Compass ادغام می‌شوند.
6. footer در bounding box واقعی controls، بیرون system navigation و بدون نوار پشتی مزاحم قرار می‌گیرد.
7. اولین viewport و پنج موقعیت میانی/انتهایی با reference side-by-side بسته می‌شوند.

گیت: هیچ overlap/clip/broken phrase وجود نداشته باشد؛ path در پشت chrome قابل دنبال‌کردن و primary action در پنج ثانیه قابل تشخیص باشد.

### P4 — Question و stylus

1. ink controller ownership باریک می‌شود: stroke update فقط canvas را repaint می‌کند؛ manuscript فقط تغییرهای state مهم مثل empty↔nonempty را می‌گیرد.
2. pointer contract بر اساس `PointerDeviceKind` و stylus buttons نوشته می‌شود؛ touch scroll، stylus draw، palm rejection، eraser و cancellation تست جدا دارند.
3. reasoning field content-aware و expandable می‌شود تا dead space کم و ink حفظ شود.
4. answer rails برای short/long/math/media، selected/correct/wrong/disabled/source-warning بازطراحی می‌شوند.
5. bottom solve instrument و tool spine بدون layout jump و با 48dp targets ساخته می‌شوند.
6. phone، 320dp/200%، tablet portrait و tablet landscape compositionهای جدا تکمیل می‌شوند.
7. route exit، resume، retry، solution، reflection و completion با همان ink/answer state سازگار می‌شوند.

گیت: touch هیچ‌وقت در pan mode توسط scratch surface بلعیده نشود؛ stylus latency و repaint scope بهتر شود؛ همه سؤال‌ها و گزینه‌ها قابل دسترسی و خواندن باشند.

### P5 — یکپارچگی همه routeها و tablet

1. Study، Insights، auth، feedback، loading/empty/error/offline و dialogs با token/action/state system تازه همسو می‌شوند.
2. duplicate header/footer/actionها حذف و navigation/back/focus restoration تست می‌شوند.
3. tablet landscape برای Map و Question و tablet portrait برای همه routeهای اصلی screenshot و semantics اختصاصی می‌گیرد.
4. session/account/progress isolation، content delta و feedback sync regression می‌گیرند؛ هیچ داده‌ای reset نمی‌شود.

گیت: هیچ route اصلی ظاهر وارداتی یا قدیمی نداشته باشد و function/persistence testها پاس بمانند.

### P6 — motion، feedback و accessibility

1. transitions فقط روی hierarchy-defining elements اجرا می‌شوند؛ shell anchorها ثابت می‌مانند.
2. node→lesson continuity، answer feedback، next-question و five-question completion طبق Motion Bible ساخته می‌شوند.
3. full/reduced/minimal motion، rapid reversal، back، background/resume و repeated-open تست می‌شوند.
4. reward animation فقط receipt ذخیره‌شده را نشان می‌دهد و هیچ XP/progress از animation تولید نمی‌شود.
5. TalkBack، focus order، contrast، live announcements، large text و haptic fallback تکمیل می‌شوند.

گیت: motion مسیر را روشن‌تر کند، کاربر را منتظر نگذارد، قابل skip باشد و frame budget را نشکند.

### P7 — ادغام، آزمون خصمانه و release proof

1. analyzer، focused suites، full Flutter suite و Android debug/profile/release build اجرا می‌شوند.
2. debug artifact کنار نسخه شخصی نصب می‌شود؛ نسخه امضاشده و داده آن uninstall/clear نمی‌شود.
3. ماتریس screenshot، side-by-side، mismatch، precision و symmetry در همه viewport/stateهای الزامی بسته می‌شود.
4. benchmarkها با baseline هم‌شرایط مقایسه و confidence/variance ثبت می‌شوند.
5. long-session scroll، repeated navigation، memory retention، offline/error و orientation stress اجرا می‌شوند.
6. بازبینی خصمانه نهایی فقط findingهای قابل بازتولید می‌پذیرد؛ Mustها رفع و Materialها رفع یا با شاهد منتفی می‌شوند.
7. docs به `done`، commit اتمیک روی `main` و push پس از verification انجام می‌شود.

گیت: هیچ P0/P1، هیچ Must و هیچ Material اثبات‌شده باقی نماند؛ محدودیت hardware صریح بماند و به‌جای ادعای جعلی ثبت شود.

## 8. ماتریس اجباری responsive و state

| کلاس | اندازه‌های حداقل | حالت‌های اجباری |
|---|---|---|
| phone narrow | 320×568dp و 320dp با 200% text | first viewport، long question، ink، answer feedback، error |
| phone representative | 360×800، 390×844، 430×932dp | Map start/middle/end، Mission 1/5 و 5/5، auth/feedback |
| tablet portrait | 600–840dp portrait | Map، navigator، Study، Question، Insights، dialogs |
| tablet landscape | 840×600، 1024×768 و بزرگ‌تر | Map+inspector، Question split، keyboard/IME، rotation restore |
| accessibility | همه کلاس‌های مرتبط | 200% text، TalkBack، reduced/minimal motion، high contrast، RTL/mixed math |

قواعد blocking: target کمتر از 48dp، clip/ellipsis متن ضروری، mid-word break، overlap، scroll trap، footer روی system bar، route state loss و عدد غیر ASCII در learning content.

## 9. بودجه عملکرد

اعداد نهایی پس از P0 با refresh rate و variance واقعی تثبیت می‌شوند. حد اولیه:

| معیار | Target | Warning | Blocking |
|---|---:|---:|---:|
| missed/janky frames در journey scroll | ≤1% | >1% | >3% یا stall تکرارشونده |
| frame overrun p95 | ≤0 در deadline دستگاه | تا یک frame | بیش از یک frame تکرارشونده |
| input→visible feedback | ≤1 vsync هدف | 2 vsync | ≥3 vsync تکرارشونده |
| stall منفرد UI | هیچ مورد >100ms | 50–100ms | >100ms قابل بازتولید |
| retained memory بعد از 10 چرخه Map↔Mission | نزدیک baseline و bounded | >5% رشد | >10% رشد تکرارشونده/leak |
| fidelity/accessibility/data | بدون regression | — | هر regression blocking است |

AVD برای تشخیص و comparison استفاده می‌شود. smoothness سخت‌افزار فیزیکی فقط با profile/release همان دستگاه ادعا می‌شود؛ battery/thermal خارج از claim این Goal است مگر واقعاً اندازه‌گیری شود.

## 10. معماری فایل و ownership پیشنهادی

- `map_screen.dart` به shell، scene geometry، sliver bands، node/label، navigator و mission compass با ownership روشن شکسته می‌شود.
- `mission_screen.dart` و `practice_screen.dart` از یک question experience/shared state استفاده می‌کنند بدون ادغام منطق scored/unscored.
- `question_manuscript.dart` مالک layout/semantics و scratch painter مالک stroke repaint می‌ماند.
- `scratchpad.dart` gesture engine، controller و presentation را از هم جدا می‌کند.
- component extraction فقط وقتی انجام می‌شود که rebuild boundary، testability یا reuse واقعی بهتر شود؛ خردکردن فایل برای افزایش line count ممنوع است.

## 11. راهبرد تست و شواهد

- هر slice: focused analyze + focused unit/widget tests + `git diff --check`.
- هر phase مشترک: affected regression suite + Android runtime screenshot.
- P2/P4/P7: پنج اجرای performance هم‌شرایط و raw log در `logs/`.
- P3/P4/P5: side-by-side reference/runtime، mismatch ledger، precision/symmetry ledger.
- P7: full analyze/test/build، ADB install/launch/logcat/semantics، data/auth/progress preservation و artifact metadata.
- هیچ screenshot مفهومی proof runtime محسوب نمی‌شود.

## 12. اقتصاد اجرا و تصمیم‌گیری

- تصمیم‌های معماری، Map/Question UX، root-cause performance و ادغام نهایی با reasoning قوی انجام می‌شوند.
- کارهای مکانیکی مثل inventory، capture، formatting و اجرای تست با scriptهای deterministic انجام می‌شوند، نه مصرف reasoning سنگین.
- ابتدا یک vertical slice کامل اثبات می‌شود؛ سپس pattern به routeهای دیگر تعمیم می‌یابد.
- full suite بعد از هر edit تکرار نمی‌شود؛ focused checks در slice و full suite در integration gate اجرا می‌شود.
- تغییر dependency، معماری یا asset pipeline فقط با شاهد و rollback انجام می‌شود.
- subagent در این Goal استفاده نمی‌شود مگر کاربر صریحاً اجازه تازه بدهد.

## 13. گزارش پیشرفت

هر milestone باید این پنج مورد را اعلام کند:

1. فاز و درصد Goal؛
2. چه defect ریشه‌ای بسته شد؛
3. چه شاهدی پاس شد؛
4. ریسک یا blocker واقعی؛
5. مرحله بعد و ETA به‌روز.

درصد فقط بعد از عبور کامل گیت فاز افزایش می‌یابد. کار نیمه‌تمام، queued یا صرفاً compile‌شده «done» شمرده نمی‌شود.

## 14. commit، rollback و توقف

- هر فاز یک commit اتمیک و قابل revert دارد؛ فایل‌های نامرتبط و `references/` دست‌نخورده می‌مانند.
- قبل/بعد performance و visual evidence به همان revision متصل می‌شود.
- تغییر ناموفق rollback می‌شود؛ با polish بیشتر روی علت غلط ادامه داده نمی‌شود.
- Goal زمانی complete است که P0 تا P7 پاس، docs به‌روز، `main` push و محدودیت‌های غیرقابل‌اثبات صریح باشند.
- ایده‌های marginal پس از یک adversarial pass پاک به backlog می‌روند؛ «پرفکشن» به معنی churn بی‌پایان نیست.
