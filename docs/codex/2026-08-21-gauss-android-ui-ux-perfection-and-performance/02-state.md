# وضعیت

- Current status: `active`
- Last updated: 2026-09-17
- Owner: Codex
- Baseline revision: `f3edce84a54a89f1be3051ff435659e26d1e9e7c`
- Current phase: P5 — shell, Study, Insights, auth, feedback and tablet integration
- Goal progress: 70%
- Product-readiness estimate: برآورد تاریخی 78–82%؛ تأیید مستقل نشده و معیار تحویل نیست.

## Current State

P0 تا P4 بسته‌اند. P3 روی `894bdaf` با 42 regression و هفت capture، Map/identity/Navigator و clearance ابتدا و انتهای مسیر را بست. P4 ownership قلم، answer→review و completion مبتنی بر receipt را با checkpointهای ثبت‌شده در Done و verification بست؛ گیت سخت‌افزاری قلم در P7 است، نه بازگشایی P4.

گیت exact-revision P4 روی `3f2cddb` با پنج run profile بسته شد: در مقابل P2، tail Map به UI/raster p95 `7.472/20.825ms` و missed ratio میانهٔ `20.75%` رسید؛ mission stylus بدون missed frame و mission answer با median `3.45%` بود. همهٔ journeyها پاس شدند، package اصلی حفظ شد و P4 به‌عنوان phase-complete بسته شد. P5 برای یکپارچه‌سازی shell/Study/Insights/auth/feedback و tablet فعال است؛ physical Xiaomi Focus Pen تا P7 باقی می‌ماند.

## Decisions

| تاریخ | تصمیم | دلیل | منبع |
|---|---|---|---|
| 2026-09-17 | قلم واقعی، ریلیز امضاشده و آزمون upgrade گیت قطعی تحویل‌اند | انتخاب صریح کاربر؛ نبود شاهد سخت‌افزار با caveat جبران نمی‌شود | قرارداد ادامه در `01-plan.md` |
| 2026-08-21 | یک task تازه برای این چرخه ساخته شود | اسناد July پایان نسخه‌های قبلی را ثبت کرده‌اند و نباید evidence تازه را با آن‌ها مخلوط کرد | work-docs contract + repo state |
| 2026-08-21 | Map renderer و question interaction بازسازی عمیق شوند | polish ظاهری علت اسکرول و rebuild را رفع نمی‌کند | source inspection + runtime screenshots |
| 2026-08-21 | accepted Orrery/Astral previews حفظ شوند | جهت محصول انتخاب شده و نیاز به نظرخواهی تازه نیست | user-approved references |
| 2026-08-21 | Android تنها release target این چرخه باشد | دامنه صریح پروژه | user + project AGENTS.md |
| 2026-08-21 | داده، media، IDs، auth و progress بدون reset حفظ شوند | قرارداد محصول و ریسک داده | user + current architecture |
| 2026-08-21 | performance فقط با سناریو و شرایط هم‌سان ادعا شود | probe نرم‌افزاری قدیمی نماینده device واقعی نیست | performance contract |
| 2026-08-21 | این Goal بدون subagent اجرا شود | دستور پروژه تا اجازه صریح تازه | project AGENTS.md |
| 2026-08-21 | `01-plan.md` objective الزام‌آور Goal همین thread باشد | جلوگیری از drift بین برنامه و اجرا | user request + active Goal |
| 2026-08-21 | evidence runner از package ایزولهٔ `com.gauss.app.profile` استفاده کند | نسخهٔ شخصی و dataDir آن در هیچ run پاک، uninstall یا overwrite نشود | package metadata guard |
| 2026-08-21 | CTA سناریوی performance بر اساس orientation انتخاب شود | phone/portrait از dock و landscape از Study Inspector استفاده می‌کند | responsive runtime evidence |
| 2026-08-21 | raw timelineهای چندمگابایتی در Git ذخیره نشوند | summary، screenshot و metadata کافی و raw evidence بازتولیدپذیر است | evidence hygiene |
| 2026-08-21 | raster فقط decoration و live truth همیشه semantic بماند | reference نباید progress، text، ID یا control را به تصویر تخت تبدیل کند | `07-ui-system-and-production-manifest.md` |
| 2026-08-21 | Map route به viewport band با geometry cache مهاجرت کند | baseline raster-bound و full-stage invalidation است | P1 manifest + P0 benchmark |
| 2026-08-21 | blur زنده فقط در footprint واقعی header/footer مجاز باشد؛ full-width opaque backing ممنوع بماند | chrome باید بدون محوکردن Map حس شیشه‌ای بدهد و raster tail را منفجر نکند | user correction + paired profile |
| 2026-08-21 | node و spiral فعلی در P3 polish نشوند و زبان فرمشان از پایه بازسازی شود | route مکانیکی، nodeهای تکراری و اتصال خشک کیفیت direction پذیرفته‌شده را نمی‌رسانند | user visual finding + runtime capture |
| 2026-08-23 | Math و Physics station topology مستقل داشته باشند و topic icon روی node حذف شود | subject باید از silhouette، material و energy language خوانده شود، نه badge چسبانده‌شده | user correction + Android visual comparison |
| 2026-08-23 | rail با tangent analytic، trim تا socket و occlusion dissolve ساخته شود | chord، elbow، endpoint bead و عبور node زیر HUD حس محصول مبتدی ایجاد می‌کرد | geometry tests + live Android captures |
| 2026-08-23 | identity raster دارای navy plate حذف و mark فقط به‌صورت transparent live/vector نگه داشته شود | کاربر صریحاً background و off-center composition را رد کرد؛ لوگو باید در auth، Splash و header مستقل از هر plate باشد | user correction + Android auth/splash captures |
| 2026-08-23 | Orbit Navigator همهٔ فصل‌ها را به‌صورت constellation یک‌نگاه نشان دهد و فقط chapter فعال preview شود | navigation فصل نباید با یک فرم بلند، scroll ثانویه و CTA نوشتاری مسیر اصلی Map را بپوشاند | user UX direction + 320dp/200% runtime proof |
| 2026-08-23 | clearance Map با bounds بصری کامل node/aura سنجیده شود و scene دقیقاً پس از آخرین محتوای واقعی پایان یابد | center-point کافی نبود و cadence مصنوعی در انتهای مسیر dead air می‌ساخت | user runtime screenshot + geometry/runtime regressions |
| 2026-08-24 | ابزارهای ink فقط در tool spine خود manuscript مالکیت داشته باشند و action dock فقط وضعیت/اقدام سؤال را نمایش دهد | کنترل تکراری در دو ناحیه، توجه و state ownership را دوپاره می‌کرد | accepted Question reference + Android Profile runtime |
| 2026-09-11 | celebration یک state صریح و skip/back-resume contract دارد؛ reward فقط از receipt ذخیره‌شده خوانده می‌شود | animation نباید gate برای دادهٔ persisted باشد و retry/lifecycle نباید reward تکراری بسازد | mission completion tests + P4/P6 plan |
| 2026-09-11 | P4 performance gate با tail بهبودیافته بسته شود؛ absolute missed-frame threshold روی emulator به‌عنوان proof گوشی تفسیر نشود | drift GPU emulator اثبات‌شده است و مقایسهٔ same-journey معتبرتر از عدد مطلق است | P4 aggregate vs P2 aggregate + plan limitation |

## Blockers

- blocker اجرایی برای P4 وجود ندارد.
- Xiaomi Focus Pen فیزیکی در این baseline در دسترس نبود؛ stylus contract روی Android با `PointerDeviceKind.stylus` اثبات شده، اما latency و palm rejection سخت‌افزاری تا P7 یک physical-device gate باقی می‌ماند.

## Done

- skill contracts مربوط به work docs، modernization، responsive fidelity، identity/asset fidelity، execution economy و performance خوانده شد.
- repo، task history، current screenshots و hot files بررسی شد.
- دو screenshot runtime فعلی به‌عنوان baseline در `assets/` فریز شد.
- برنامه مرحله‌ای، وزن Goal، acceptance matrix، preservation contract و performance budgets نوشته شد.
- harness profile ایزوله، runner پنج‌باره، semantics probe، stylus synthesis و aggregate summarizer ساخته و analyze شدند.
- پنج run phone با status پاس، semantic IDs معتبر و حفظ کامل package اصلی ثبت شد.
- tablet portrait و landscape واقعی روی `1280×800dp`/`800×1280dp` ثبت شدند؛ هر دو journey نهایی پاس شدند و تنظیمات AVD به `1080×2400 @ 420dpi` برگشت.
- corpus gate با `3672` source-bound record و asset inventory با `3461` فایل بدون mutation ثبت شد.
- P1 Design DNA و precision ledger به توکن‌های Flutter تبدیل شد؛ contrast، ramp، breakpoints، manifests و acceptance matrix با 32 regression test پاس شدند.
- P2 geometry در bandهای bounded و lazy partition شد؛ scroll listener سراسری، moving blurهای میانی و RepaintBoundaryهای تو‌در‌تو حذف شدند و path/node semantics حفظ شد.
- paired baseline موقت روی commit `08a7817` ثبت شد: engine تازه با footer blur محدود در یک پنجرهٔ میزبان، Map UI p95 را از `13.731ms` به `5.720ms` و raster p95 را از `49.598ms` به `24.319ms` رساند؛ worktree از ثبت Git خارج شد.
- پنج run نهایی revision-bound روی `13d6597` با 5/5 journey پاس، semantic IDs ثابت، PSS میانهٔ `157.033MiB` و حفظ کامل hash نسخهٔ شخصی ثبت شد؛ P2 با caveat صریح emulator GPU drift بسته شد.
- P3 Map vertical slice روی Android اجرا شد: station سه‌بعدی Math/Physics با alpha واقعی، مسیر بزرگ‌قطر tangent-continuous، socketهای جهت‌دار، پنج progress bearing زنده و fade بدون backing در محدودهٔ HUD ساخته شد.
- gate موقت P3 شامل analyze پاک و 41/41 تست geometry/responsive/Android/UI-system پاس شد؛ captureهای phone Math و Physics به‌صورت زنده با footer و Mission Compass بررسی شدند.
- mark ردشدهٔ raster و تمام resourceهای plate آن حذف شد؛ Flutter theorem mark چندلایه، Android transparent vector، adaptive safe inset و auth composition روی محور مرکزی بازسازی شدند.
- گیت identity شامل analyze کامل پاک، 36/36 سپس 33/33 regression، دو debug APK موفق، نصب in-place بستهٔ ایزوله و بررسی زندهٔ Splash/auth/adaptive icon پاس شد؛ `com.gauss.app` v106 و dataDir آن تغییر نکرد.
- Orbit Navigator با پنج beacon حداقل `48dp`، railهای constellation، subject switch دوحالته، preview تک‌فصل و action نمادین بازسازی شد؛ analyzer پاک، 41/41 regression، debug build/install و runtime در phone عادی و `320dp`/`200%` text پاس شد.
- Mission Compass و footer در footprint واقعی خودشان بسته شدند؛ مسیر پشت chrome بدون نوار مات باقی ماند و content/gesture shield با safe area واقعی همسو شد.
- matrix نهایی P3 در phone start/chapter/mid/late/end و tablet portrait/landscape بررسی شد؛ نود اول با bounds کامل aura از header جدا و آخرین نود بدون dead-air tail داخل route field نگه داشته شد.
- گیت نهایی P3 روی `894bdaf` با analyzer پاک، 42/42 تست، debug APK موفق، نصب in-place و profile spot-check پاس شد؛ Map scroll در نمونهٔ exact-revision به UI/raster p95 برابر `4.359/20.250ms` رسید و signed package/data دست‌نخورده ماند.
- vertical slice نخست P4 روی `df7b17e` با 27/27 تست Question/Focus Pen/Mission، analyzer متمرکز پاک، Profile APK موفق و بررسی Android زندهٔ blank/ink/clear پاس شد؛ ابزارهای تکراری dock حذف و signed `com.gauss.app` v106 دست‌نخورده ماند.
- checkpoint دوم P4 روی `16160f7` مسیر answer→review را اصلاح کرد: ورود به review حالت Finger Ink را به Touch Scroll برمی‌گرداند، viewport به انتهای پاسخ درست و ابتدای reflection می‌رسد، و reflection/solution به‌جای Card جدا ادامهٔ همان parchment هستند؛ 28/28 تست، analyzer پاک و Android Profile زنده پاس شد.
- checkpoint سوم P4 completion را بست: ceremony 760ms با skip و reduced-motion، retry idempotence، pending-finalize pause/resume، bounded visual panel و 63/63 focused regression روی پنج suite پاس شد؛ Profile build/install روی `Codex_API35` انجام شد و signed `com.gauss.app` v106/dataDir دست‌نخورده ماند.
- گیت نهایی P4 روی `3f2cddb` با پنج run profile بسته شد؛ aggregate P4 از baseline P2 در همهٔ journeyهای اصلی tail بهتری داشت و signed package guard حفظ شد.

## Remaining

- checkpoint محلی shuffle در 2026-09-17: پاک‌شدن hypothesis ذخیره‌نشده بازتولید و اصلاح شد؛ همان shelf اکنون draft و reveal را فقط برای اعضای خودش حفظ می‌کند، persisted record اولویت دارد. full suite `254 passed / 1 skipped`، analyzer محصول/تست و driver پاس‌اند. Android probe واقعی روی `Codex_API35` و package ایزولهٔ `com.gauss.app.profile` در `logs/study-runtime-f321203-phone-shuffle/` پاس شد؛ بستهٔ شخصی v106/dataDir دست‌نخورده ماند. CI این diff هنوز باز است؛ P5 active، 70%.
- P5 continuation در `f321203` ثبت و push شده؛ CI همان SHA با run `35158850067` موفق است و در این نوبت دوباره تأیید شد. suite تازه Study با shuffle برابر `30/30` پاس شد. runtime محدود continuation پاس است؛ full journey از Map و گیت بصری همچنان بازند.
- گیت CI اصلاح SDK روی `ad3df3d` با run `35158147125` موفق است. failureهای `34553314888` و `35157330917` تاریخی‌اند، نه blocker جاری.
- harness محدود Android Study اضافه و سه بار موفق اجرا شد؛ run renderproof ذخیره `4→5`، recap، سؤال بعد و تغییر تصویر را ثبت کرد. کد محصول تغییر نکرد. گیت بصری، full journey از Map و بقیهٔ P5 باز است.
- تست تازهٔ P5 حفظ سؤال، hypothesis و committed ink در چرخش phone→tablet→phone پاس شد؛ این شاهد widget است، نه Android runtime. هیچ دستگاهی متصل نبود؛ AVD موجود فقط `Codex_API35` است.
- اجرای P5: shell، Study، Insights، auth، feedback، loading/empty/error/offline/dialogs و tablet landscape/portrait.
- اجرای P6 تا P7 و به‌روزرسانی پیوسته state/progress/verification.
- commit و push فقط پس از validation سند و سپس در پایان هر فاز پذیرفته‌شده.
