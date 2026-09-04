# راستی‌آزمایی

## خلاصه

- Result: partial
- Last verified: 2026-08-24T07:06:37+03:30
- Scope: P0–P3 closed; P4 Question/stylus rebuild active

## بررسی‌ها

| بررسی | فرمان/روش | نتیجه | شاهد |
|---|---|---|---|
| Git baseline | `git rev-parse HEAD` و `git status --short --branch` | passed | `f3edce8`؛ فقط docs تازه و `references/` قدیمی untracked |
| Static analysis baseline | `flutter analyze --no-pub` | passed | No issues found؛ 156.8s |
| Focused test baseline | 6 فایل تست Map/Question/Pen/Motion/Android | passed | 43/43 |
| Code hotspot inspection | bounded source reads و `rg` | passed | full-stage scroll/paint، blur، broad ink listeners و gesture surface تأیید شد |
| Runtime visual baseline | inspection تصاویر Android | passed | [Map](assets/baseline-map-f3edce8.png)، [Mission](assets/baseline-mission-f3edce8.png) |
| ADB/AVD availability | `adb devices` / runtime inventory | passed | `emulator-5554` روی تنها AVD مجاز `Codex_API35` |
| Performance harness analysis | `dart analyze tool/perf_main.dart test_driver/performance_driver.dart tool/summarize_android_performance.dart` | passed | no issues |
| Phone deterministic profile | `run_android_performance.ps1 -Runs 5` | passed | 5/5 run؛ پنج journey در هر run؛ [aggregate](logs/performance-baseline-08a7817/aggregate.json) |
| Phone first usable Map | controller/first-frame probe | baseline captured | median `101.001ms` / `144.448ms`؛ emulator-only |
| Phone Map scroll | pooled Flutter Timeline، 271 UI و 269 raster frame | baseline captured | UI p95 `8.798ms`؛ raster p95 `26.843ms`؛ missed ratio mean `24.94%` |
| Phone Map → Mission | pooled Flutter Timeline | baseline captured | UI p95 `36.352ms`؛ raster p95 `26.514ms`؛ wall median `621ms` |
| Phone stylus ink | synthetic Android stylus journey | passed with baseline | UI p95 `6.750ms`؛ raster p95 `17.109ms`؛ missed ratio mean `6.76%` |
| Phone touch/answer | finger scroll + choice + check | passed with baseline | UI p95 `7.471ms`؛ raster p95 `6.037ms`؛ isolated transition outliers remain |
| Tablet portrait | 800×1280dp، one full journey | passed | status passed + four critical semantic IDs؛ [aggregate](logs/performance-tablet-portrait-08a7817/aggregate.json) |
| Tablet landscape | 1280×800dp، one full journey | passed | status passed + four critical semantic IDs؛ [aggregate](logs/performance-tablet-landscape-798aa03/aggregate.json) |
| Signed personal package guard | package metadata before/after every run | passed | `com.gauss.app` v106؛ metadata SHA-256 `9e7f9fa3…3916af` unchanged |
| AVD discipline and restore | inventory + `wm size`/density before/after | passed | تنها `Codex_API35`؛ restore به 1080×2400 و 420dpi |
| Corpus preservation | `node scripts/corpus_certification.mjs validate` + `summarize` | passed | 3672 source-bound؛ 51 scientifically usable؛ immutable source untouched |
| Asset inventory | bounded recursive file inventory | passed | 3461 files؛ 89,279,651 bytes؛ 3410 WebP + 9 PNG + 32 JSON + 6 TTF + 3 SVG + 1 TXT |
| P1 focused analysis | `flutter analyze --no-pub` روی design system، manifest و test | passed | No issues found |
| P1 design-system tests | `flutter test --no-pub test/gauss_ui_system_test.dart` | passed | 6/6؛ ramp، occupancy، manifest، assets، contrast، motion |
| P1 Android UI regression | همان run با `test/android_experience_test.dart` | passed | 26/26؛ مجموع P1 gate برابر 32/32 |
| P1 production manifest | Dart spec + human-readable contract | passed | `gauss_experience_spec.dart` + `07-ui-system-and-production-manifest.md` |
| P2 engine static gate | focused analyze روی Map/geometry/test | passed | No issues found |
| P2 Map regressions | geometry، dock، Android، HUD، motion و Study suites | passed | 48/48؛ lazy off-screen chapter با scroll دوباره semantic/live می‌شود |
| P2 geometry/cache unit gate | deterministic band coverage، continuity، LRU و text buckets | passed | 3/3؛ node/header/landmark ownership بدون duplication |
| P2 bounded viewport regression | full route canvas + bottom hit shield + 520–900px cache | passed | analyzer پاک + 33/33 Map/Android tests |
| P2 first five-run comparison | engine `2b0864d` در برابر baseline قدیمی | failed as phase gate | raster p95 فقط 7.1% بهتر ولی median/missed بدتر؛ نتیجه پذیرفته نشد |
| P2 cold-AVD five-run comparison | engine `6bb422f` پس از reboot | inconclusive as absolute baseline | untouched Mission journeys نیز 2–3× کند شدند؛ host/emulator GPU drift ثبت شد |
| P2 paired same-window baseline | current optimized layers در برابر detached `08a7817` | passed pilot | Map UI p95 `5.720` vs `13.731ms`؛ raster p95 `24.319` vs `49.598ms`؛ memory `168.48` vs `175.94MiB` |
| P2 glass policy | runtime profile + screenshot inspection | passed pilot | moving-card blur حذف؛ footer blur فقط در bounding box خودش، بدون full-width backing |
| P2 final exact-revision profile | `run_android_performance.ps1 -Runs 5` روی `13d6597` | passed | 5/5 run؛ Map UI p95=`8.557ms`، raster p95=`28.385ms`، PSS median=`157.033MiB`؛ [aggregate](logs/performance-p2-final-13d6597/aggregate.json) |
| P2 final semantics and package guard | five journeys + before/after package metadata | passed | semantic IDs ثابت؛ `com.gauss.app` v106 hash `9e7f9fa3…3916af` قبل/بعد دقیقاً یکسان |
| P3 station assets | decoded image metadata + runtime inspection | passed slice | Math `1254×1254` و Physics `1285×1224`، هر دو `Format32bppArgb` با transparency واقعی و semantic state زنده |
| P3 route geometry | unit tests روی cadence، lane، shared tangent، bow و contiguous metric | passed | curve واقعی در بیش از 70% segmentها از chord فاصله دارد و در هر station tangent پیوسته است |
| P3 route/node regressions | `flutter test --no-pub test/map_path_geometry_engine_test.dart test/map_geometry_test.dart test/android_experience_test.dart test/gauss_ui_system_test.dart` | passed | 41/41؛ phone 320dp، 200% text، tablet portrait/landscape، subject swap و semantic node IDs |
| P3 phone visual slice | Android `com.gauss.app.debug` روی `Codex_API35` | passed slice | Math/Physics current+future station، socket docking، label anchors و HUD dissolve دستی بررسی شد؛ فایل‌های capture محلی‌اند |
| P3 transparent identity static gate | `flutter analyze --no-pub` + resource contract tests | passed | analyzer بدون issue؛ vector هیچ `gauss_icon_background` داخلی ندارد، brass highlight و teal core حاضرند و adaptive foreground از safe inset `14dp` استفاده می‌کند |
| P3 identity responsive gate | auth phone/tablet portrait/landscape در 100% و 200% text + Android regressions | passed | نخست 36/36 و پس از inset نهایی 33/33؛ mark و wordmark در همه compositionها اختلاف محور کمتر از `0.1px` دارند |
| P3 identity Android builds | `flutter build apk --debug --no-pub` دو بار، قبل و بعد از inset نهایی | passed | `app-debug.apk` در `172.4s` و `91.9s` ساخته و هر دو بار با `adb install -r -d` موفق نصب شد |
| P3 Splash/auth visual proof | cold start بستهٔ `com.gauss.app.debug` روی `Codex_API35` | passed slice | [Splash](assets/p3-brand-splash-transparent.png) mark را بدون plate در مرکز واقعی و [Auth](assets/p3-brand-auth-centered.png) mark/wordmark را روی یک محور نشان می‌دهد |
| P3 package/data guard after identity | AVD/package inventory قبل و بعد | passed | تنها `Codex_API35`؛ `com.gauss.app` v106، dataDir و firstInstallTime بدون تغییر؛ فقط debug package in-place به‌روز شد |
| P3 Orbit Navigator interaction contract | widget tests روی بازکردن Navigator، subject switch، انتخاب chapter و action | passed | هر پنج chapter beacon حاضر و حداقل `48dp`؛ انتخاب با section ID پایدار؛ CTA نوشتاری و `FilledButton` حذف شده‌اند |
| P3 Orbit Navigator responsive gate | phone عادی + `320dp`/`200%` text روی widget و Android runtime | passed slice | summary فشرده، subject control نمادین در large text، بدون ellipsis/overflow؛ [Phone](assets/p3-orbit-navigator-constellation.png) و [320dp/200%](assets/p3-orbit-navigator-320dp-200text.png) |
| P3 Navigator regression gate | `flutter analyze --no-pub` + چهار suite اصلی Map/Android/UI | passed | analyzer بدون issue؛ 41/41 test passed |
| P3 Navigator Android build/install | `flutter build apk --debug --no-pub` + `adb install -r -d` | passed | debug APK در `186.8s` ساخته و نصب in-place موفق شد؛ AVD به `1080×2400 @ 420dpi` و `font_scale=1.0` برگشت |
| P3 complete Map capture matrix | Android runtime در phone start/chapter/mid/late/end و tablet portrait/landscape | passed | [start](assets/p3-map-phone-start.webp)، [chapter](assets/p3-map-phone-chapter-threshold.webp)، [mid](assets/p3-map-phone-mid.webp)، [late](assets/p3-map-phone-late.webp)، [end](assets/p3-map-phone-end.webp)، [tablet portrait](assets/p3-map-tablet-portrait.webp)، [tablet landscape](assets/p3-map-tablet-landscape.webp)؛ بدون overlap/clip/label collision |
| P3 first-node/header clearance | keyed aura bounds + Android regression و runtime capture | passed | تمام envelope بصری `map-node-aura-*` زیر Orbit header است؛ 8dp clearance فقط در segment اول بازیابی شد تا جای nodeهای بعدی ثابت بماند |
| P3 route-end geometry | unit + Android fling-to-end regression | passed | scene پس از آخرین node/label/landmark با tail اپتیکی 24–48dp پایان می‌یابد؛ آخرین lesson بالای Mission Compass و hit-testable است |
| P3 final static/regression gate | `flutter analyze --no-pub` + چهار suite Map/Android/UI | passed | analyzer بدون issue در `43.8s`؛ 42/42 test passed |
| P3 exact-revision profile spot-check | `run_android_performance.ps1 -Runs 1` روی `894bdaf5752c84db54e980eb61961406d78fc29a` | passed | 1/1 journey set؛ Map scroll UI p95=`4.359ms`، raster p95=`20.250ms`؛ [aggregate](logs/performance-p3-final-894bdaf/aggregate.json)؛ transition outlierها برای P4/P6 حفظ شدند |
| P3 final Android/package guard | debug build/install + AVD/package inventory | passed | debug APK در `206.8s` ساخته و in-place نصب شد؛ تنها `Codex_API35` در `1080×2400 @ 420dpi`؛ `com.gauss.app` v106، dataDir و firstInstallTime بدون تغییر |
| P4 focused Question/Pen regressions | `flutter test --no-pub test/question_manuscript_test.dart test/focus_pen_math_render_test.dart test/mission_resume_test.dart` | passed checkpoint | 28/28؛ semantic status فقط در empty/nonempty/restore عوض می‌شود، 30 move نمونه parent را rebuild نمی‌کند، pressure/palm/inverted/side-button و answer→review paths پاس‌اند |
| P4 focused static gate | `flutter analyze --no-pub` روی 3 source و 3 test مرتبط | passed checkpoint | No issues found؛ `88.6s` |
| P4 Android Profile visual slice | build/install `tool/perf_main.dart` + blank/ink/clear runtime inspection | passed checkpoint | Profile APK در `153.9s` ساخته شد؛ [blank](assets/p4-manuscript-blank-phone.webp) و [ink](assets/p4-manuscript-ink-phone.webp)؛ action dock بدون ابزار ink تکراری |
| P4 AVD and signed-package guard | AVD inventory + `dumpsys package com.gauss.app` پس از Profile install | passed | تنها `Codex_API35`؛ signed app همان v106، `dataDir=/data/user/0/com.gauss.app` و `firstInstallTime=2026-07-18 13:02:33` |
| P4 phone answer→review runtime | Finger Ink → wrong choice → Check روی Android Profile | passed checkpoint | Touch Scroll خودکار فعال، correct answer و ابتدای reflection در viewport، solution داخل parchment؛ [runtime](assets/p4-manuscript-review-phone.webp) |
| P4 source-warning answer state (چرخهٔ 2026-09-04) | audit statik: trace `Question.fromJson`→`solutionVerified`→`_AnswerChoice`/`_MissionActionBar` + reading کامل diff + brace/paren balance | **static-only — نه runtime** | `sourceConfirmed = checked && isCorrect && !solutionVerified`؛ tone `source` + shield + semantics «Marked as the correct answer by the preserved source»؛ اعلام «Source answer confirmed. It is preserved, not scientifically verified.» به‌جای «PROOF HOLDS»؛ test تازه `a correct choice on an unverified source never claims a verified proof` با fixture `correct_option_index=1` + solution «گزینه 2» (trace: `_solutionAnswerMatches`→false→`solutionVerified=false`) |
| P4 review-workspace contract reconciliation (چرخهٔ 2026-09-04) | audit statik: مقایسهٔ helper قدیمی (twoPane 840dp) با manifest (1200×600) و implementation verified + grep سراسری مصرف‌کنندگان | **static-only — نه runtime** | `GaussComposition.usesQuestionSplit(viewport, textScale, availableHeight)` = threePane ∧ stage≥480dp ∧ scale<1.35 — دقیقاً همان boolean قبلی mission؛ pane width 310/350@1250 به توکن تبدیل و در mission سیم شد؛ `gauss_ui_system_test` گیت جدید + حالت‌های portrait/height-kick را می‌فرد؛ `questionMaxReadingWidth`/`questionReasoning*` literals 820/112/176 را جایگزین کردند (همان مقادیر) |
| P4 completion/restore-timing بازبینی (چرخهٔ 2026-09-04) | reading کامل `_MissionComplete`، `StudySessionCelebration`، timerهای clear/restore در mission و study | no finding | receiptها فقط از persisted result می‌سازند (XP از animation نمی‌آید)؛ پنجرهٔ 4s restore با timer + `discardLastClear`/`restoreLastClear` و semantics `liveRegion` هماهنگ است؛ ink session-local و در exit با تأیید صریح پاک می‌شود |

## هنوز اجرا نشده

- **سند 2026-09-04: در sandbox این چرخه، Flutter/Dart toolchain، Android SDK و emulator در دسترس نبودند (storage.googleapis.com، dl.google.com، GitHub release assets، conda و nix همگی مسدود؛ فقط GitHub source، npm و PyPI). به‌دلیل همین، `flutter analyze`، `flutter test` (از جمله test source-warning تازه و `gauss_ui_system_test` بازنویسی‌شده)، هر build APK و هر capture runtime برای تغییرات این چرخه اجرا نشده‌اند و در جدول بالا «static-only» ثبت شده‌اند. پیش از گیت فاز، همه در محیط دارای toolchain باید اجرا شوند.**
- full Flutter suite پس از بازسازی‌های runtime.
- Android release build جدید؛ profile spot-check P3 و debug build پاس شده‌اند.
- physical-device Xiaomi Focus Pen profile؛ emulator proof جای آن را نمی‌گیرد.

## مشکلات شناخته‌شده

- Map P3 phase-complete است: renderer، route/node، header/identity/Navigator، landmark/Mission Compass/footer و responsive capture matrix بسته‌اند.
- blur زندهٔ moving chrome حذف شده و blur footer فقط در footprint محدود خودش باقی مانده است.
- یک‌نمونه profile P3 برای regression spot-check است، نه ادعای آماری چند-run؛ proof نهایی چند-run در P7 تکرار می‌شود.
- broad ink rebuild و مالکیت تکراری controls در vertical slice phone رفع شده است؛ اثبات نهایی performance چند-run هنوز باز است.
- manuscript phone جمع‌وجور و answer access نزدیک شده است؛ tablet/large-text و حالت‌های checked/solution/completion هنوز باید کامل بازرسی شوند.
- touch/stylus behavior در دستگاه Xiaomi باید با runtime سخت‌افزار خودش نیز تأیید شود.
- emulator/SwiftShader raster p95 نمایندهٔ GPU گوشی نیست، اما برای before/after هم‌شرایط معتبر است.
- raw Timelineها محلی و بازتولیدپذیر نگه داشته می‌شوند؛ Git فقط aggregate، compact summaries، metadata و visual samples را حمل می‌کند.
- P1 عمداً composition screenها را تغییر نداد؛ این قرارداد در P2–P6 اجرا و با captureهای ماتریس بسته می‌شود.
- P2 phase-complete است؛ paired same-window evidence اثر engine را از drift میزبان جدا کرد و پنج run نهایی revision-bound حفظ semantics/package را ثابت کرد.
- absolute raster اعداد emulator تحت host/GPU drift هستند؛ بهبود tail ادعاشده بر paired same-window comparison تکیه دارد و physical-device proof همچنان در P7 انجام می‌شود.
- outlierهای transition در Map→Mission UI و Mission→Map raster به‌عنوان finding باز P4/P6 نگه داشته شده‌اند و در بستن این فاز پنهان نشده‌اند.
