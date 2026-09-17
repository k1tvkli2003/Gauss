# راستی‌آزمایی

## خلاصه

- Result: partial
- Last verified: 2026-09-17
- Scope: P0–P4 closed; P5 Study integration active; Goal 70%

## بررسی‌ها

### checkpoint محلی shuffle — 2026-09-17

- قبل: `flutter test --no-pub test/study_experience_test.dart --plain-name "shuffling a study set preserves uncharted hypotheses" --reporter expanded` با exit 1؛ انتظار یک semantics `Your private hypothesis.`، واقعی 0.
- بعد: همان regression با پوشش افزودهٔ reveal و تغییر جلسه، exit 0، 1/1، 2s.
- `flutter test --no-pub test/study_experience_test.dart test/mission_resume_test.dart test/study_session_celebration_test.dart --reporter expanded`: exit 0، 54 passed، 10s، پس از format.
- `flutter analyze --no-pub lib/screens/archive_screen.dart test/study_experience_test.dart`: exit 0، No issues found، 68.8s.
- وضعیت پیش از runtime: diff محلی روی `f321203` بود؛ آن زمان دستگاه متصل نبود. نتیجهٔ بعدی این checkpoint در بند زیر آمده است.
- تکمیل شاهد: full suite `flutter test --no-pub --reporter expanded` exit 0، `254 passed / 1 skipped`، حدود 32s. analyzer محصول/تست و driver بدون issue. Android shuffle probe روی `Codex_API35` با Profile APK v90 isolated پاس شد: انتخاب UI، واقعی `study-room-shuffle-action`، بازگشت به سؤال اصلی با semantics ID `429`، persisted_records=0 و encountered_slots=0. device رم `Codex_API35`، شروع cold boot بدون snapshot. بستهٔ شخصی v106/dataDir/firstInstallTime/lastUpdateTime دست‌نخورده ماند. فایل‌های PNG و result.json در `logs/study-runtime-f321203-phone-shuffle/` ثبت شدند.
- گیت کامل محلی نهایی: analyzer کامل بدون issue در 98.8s؛ suite کامل در اجرای نهایی 35s، `254 passed / 1 skipped`، exit 0. skip فقط web deep link روی میزبان غیرweb است.
- بازتولید driver از `flutter_app`: متغیر `GAUSS_STUDY_OUTPUT` را به پوشهٔ خروجی تازه تنظیم کنید؛ سپس `flutter drive --driver=test_driver/study_shuffle_driver.dart --target=tool/study_runtime_main.dart --dart-define=GAUSS_SHUFFLE_PROBE=true --profile --no-pub -d emulator-5554 --keep-app-running`. دو invocation بدون متغیر خروجی با `GAUSS_STUDY_OUTPUT is required` شکست خوردند؛ invocation صحیح exit 0 و result ثبت کرد. گزینهٔ نامعتبر `--use-existing-application` نیز پیش از اجرا رد شد. این‌ها failure ابزار اجرا هستند، نه regression محصول.
- مرز پذیرش: شاهد Android فقط حفظ hypothesis در shuffle و نبود ثبت reflection است؛ reveal و تغییر جلسه شاهد widget دارند. screenshotها ذخیره‌اند، اما ابزار مشاهدهٔ تصویر در این نوبت پشتیبانی نشد؛ بازبینی بصری/مقایسه با مرجع، کل P5، CI تغییر تازه و release نهایی بازند. این checkpoint ادعای عملکرد یا frame pacing ندارد.

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
| P4 completion regression gate | `flutter analyze --no-pub lib/screens/mission_screen.dart test/mission_resume_test.dart test_driver/performance_driver.dart` + پنج suite Question/Focus Pen/Android/UI/Mission | passed checkpoint | analyzer بدون issue در `77.6s`؛ 63/63 test passed؛ skip semantics و 48×48، reduced-motion static، retry reward idempotence، pending-finalize pause/resume و ellipsis-free 320dp/200% پوشش داده شد |
| P4 completion Profile/package guard | `scripts/refresh_android_preview.ps1 -Device emulator-5554 -Mode profile` + package dump | passed checkpoint | Profile APK `171.6MB` در `165.2s` ساخته و in-place نصب شد؛ `com.gauss.app.profile` v91؛ signed `com.gauss.app` v106/dataDir/firstInstallTime بدون تغییر؛ تنها `Codex_API35` |
| P4 exact-revision performance gate | `pwsh tool/run_android_performance.ps1 -DeviceId emulator-5554 -Runs 5` روی `3f2cddba788b915dd012253a8e064d9f5c01b1da` | passed phase gate | 5/5 journeys passed؛ Map scroll UI/raster p95=`7.472/20.825ms`، missed median=`20.75%`؛ stylus missed=`0%`؛ answer missed median=`3.45%`؛ [aggregate](logs/performance-p4-final-3f2cddb/aggregate.json)؛ نسبت به P2 در همهٔ این tailها بهتر است؛ emulator GPU caveat باقی است |

## گیت تثبیت — 2026-09-17

### تأیید تازهٔ continuation و CI

- CI `35158850067` روی `f321203b1936a233518e16e325f99fd919f60528` با `conclusion=success` تمام شد؛ run اصلاح SDK `35158147125` هم موفق است. failureهای قدیمی پایین، تاریخچه‌اند نه وضعیت جاری CI.
- تست مستقل recap/next-session پاس؛ کل `study_experience_test.dart` نیز در این بررسی `29/29`، exit 0، پاس شد. assertion واقعی سؤال جدید و پاسخ دیررس در همین suite حاضرند.
- لاگ CI اولیه `34553314888` مشخصاً شکست geometry هنگام ink داشت: bottom انتظار `979`، واقعی `1043`؛ جهش `64px`. همان regression اکنون پاس است؛ تست صرفاً برای سبزشدن ضعیف نشده است.
- `Codex_API35` از offline پس از cold boot بدون snapshot به `device` و `sys.boot_completed=1` رسید؛ AVD جدید ساخته نشد.
- harness اختصاصی Study در `tool/study_runtime_main.dart` و `test_driver/study_runtime_driver.dart` اضافه شد؛ 4 reflection آماده‌سازی، پنجم از UI، recap و سؤال واقعی جلسه بعد. حساب local-only تازه است؛ این harness شاهد ورود کامل از Map یا auth زنده نیست.
- analyzer نخست دو فایل پاک؛ Profile build `137.3s` و نصب بستهٔ `com.gauss.app.profile` موفق. اجرای نخست driver پیش از اولین frame با null root شکست خورد؛ ready handshake افزوده شد. شاهد runtime موفق هنوز تا نتیجهٔ اجرای مجدد باز است.
- بستهٔ شخصی پیش از probe: `com.gauss.app` v106، dataDir `/data/user/0/com.gauss.app`، firstInstallTime `2026-07-18 13:02:33`، lastUpdateTime `2026-07-23 01:53:36`؛ هیچ clear/uninstall برای آن اجرا نشده است.
- Android runtime سه بار روی همین Profile APK موفق شد: دو run قبلی و run renderproof در `logs/study-runtime-f321203-phone-renderproof/`. خروجی آن `status=passed`، save `4→5`، slots `4→5`، سؤال بعد `nardebam_math_1405_0017`، semantics ID `488` و `screenshot_changed_after_continuation=true` را ثبت کرد. hashهای recap/next متفاوت‌اند: `210C…B495` و `3C5B…65DA`.
- مرز شاهد visual: تصویرهای واقعی runtime ذخیره شدند، اما بازبینی انسانی/normalize frame در این نوبت انجام نشد؛ گیت بصری full P5 باز می‌ماند. driver قبلاً پیش از first frame شکست خورد و handshake آن اصلاح شد.

| بررسی | دستور/روش | نتیجه | مرز شاهد |
|---|---|---|---|
| Analyzer کامل | `flutter analyze --no-pub` | passed، exit 0، 98.7s | worktree اصلاح Manuscript |
| Full Flutter suite | `flutter test --no-pub --reporter expanded` | passed، exit 0، 250 passed / 1 skipped، 36s | شامل regression تقویت‌شدهٔ geometry حین stroke و قفل paging؛ تنها skip متعلق به `web_deep_link_test.dart` با شرط `!kIsWeb` است |
| تست مستقل قلم | `flutter test --no-pub test/study_experience_test.dart --plain-name "study-room ink suspends horizontal paging while the pen is active" --reporter expanded` | passed، exit 0، 1/1، 2s | هندسه حین stroke، paging، clear/restore و خروج |
| اعتبارسنجی اسناد | validator رسمی work-docs + `git diff --check` | passed | ساختار و محتوای اسناد؛ فقط هشدار تبدیل LF به CRLF در Git |
| CI جاری | `gh run list --limit 3 --json databaseId,headSha,status,conclusion,url` | failed | run `34553314888` روی `81044c8`؛ CI اصلاح هنوز اجرا نشده |
| Release جاری | `gh release view --json tagName,targetCommitish,url` | نسخهٔ قدیمی | `v1.0.277` روی `1936b0974ab49da2e420c08c9411e4f3b644e52d` |

## هنوز اجرا نشده

### checkpoint CI و rotation — 2026-09-17

- `b6773fb` روی origin/main ثبت شد. run `35157330917` در `Set up Android SDK` با `Failed to find package 'tools'` خاتمه یافت؛ تست Flutter اصلاً اجرا نشد. این failure محیط مستقل از regression قبلی قلم است.
- metadata upstream action در SHA پین‌شده، default `tools platform-tools` را تأیید کرد. اصلاح ورودی explicit `platform-tools` و تست contract اضافه شد؛ شاهد GitHub برای اصلاح هنوز باز است.
- `flutter test --no-pub test/release_pipeline_contract_test.dart test/study_experience_test.dart --reporter expanded`: 30 passed، exit 0، 6s. تست rotation مستقل هم 1/1 پاس شد؛ phone→tablet→phone همان سؤال، hypothesis، ink controller، strokeCount و recordedWidths را حفظ کرد.
- `audit_release_docs.py --timeout 5`: exit 0 و همهٔ markerهای منابع رسمی موجود. actionlint نصب نیست؛ lint مستقل YAML اجرا نشد.
- دستگاه متصل: هیچ‌کدام؛ AVD inventory: فقط `Codex_API35`. هیچ نصب، پاک‌سازی یا راه‌اندازی runtime در این checkpoint انجام نشد.

### گیت‌های باز

### P5 continuation — شاهد قبل/بعد

- تست `completing a session opens the recap with its reward lines` با انتظار سؤال واقعی مجموعهٔ بعد، قبل از اصلاح در `study-ink-nardebam_math_1405_0017` fail شد (0 widget در برابر 1)، با وجود offset=5 در URL.
- بعد از didUpdateWidget و generation guard: همان تست مستقل 1/1 پاس؛ تست `late study loads cannot replace the current session` هم 1/1 پاس. بارگذاری دیررس offset=5 بعد از offset=10 مجموعهٔ جدید را تغییر نمی‌دهد.
- چهار suite Study/Mission resume/Study celebration/route motion: 57 passed، exit 0، 9s. analyzer دو فایل: exit 0، no issues، 48s. runtime دستگاه برای این تغییر اجرا نشده است.
- full suite پس از اصلاح continuation: `flutter test --no-pub --reporter expanded`، exit 0، 253 passed / 1 skipped در 35s؛ skip مخصوص web بدون تغییر است. validator اسناد نیز OK بود.

### باقی‌ماندهٔ نهایی

- full Flutter suite روی نامزد نهایی P7؛ suite گیت تثبیت 2026-09-17 پاس شده است.
- Android release build جدید؛ profile spot-check P3 و debug build پاس شده‌اند.
- physical-device Xiaomi Focus Pen profile؛ emulator proof جای آن را نمی‌گیرد.

## مشکلات شناخته‌شده

- Map P3 phase-complete است: renderer، route/node، header/identity/Navigator، landmark/Mission Compass/footer و responsive capture matrix بسته‌اند.
- blur زندهٔ moving chrome حذف شده و blur footer فقط در footprint محدود خودش باقی مانده است.
- یک‌نمونه profile P3 برای regression spot-check است، نه ادعای آماری چند-run؛ proof نهایی چند-run در P7 تکرار می‌شود.
- P4 phase-complete است؛ tail performance نسبت به P2 بهتر شد ولی missed-frame مطلق روی emulator همچنان در P6/P7 و روی hardware سنجیده می‌شود.
- touch/stylus behavior در دستگاه Xiaomi باید با runtime سخت‌افزار خودش نیز تأیید شود.
- emulator/SwiftShader raster p95 نمایندهٔ GPU گوشی نیست، اما برای before/after هم‌شرایط معتبر است.
- raw Timelineها محلی و بازتولیدپذیر نگه داشته می‌شوند؛ Git فقط aggregate، compact summaries، metadata و visual samples را حمل می‌کند.
- P1 عمداً composition screenها را تغییر نداد؛ این قرارداد در P2–P6 اجرا و با captureهای ماتریس بسته می‌شود.
- P2 phase-complete است؛ paired same-window evidence اثر engine را از drift میزبان جدا کرد و پنج run نهایی revision-bound حفظ semantics/package را ثابت کرد.
- absolute raster اعداد emulator تحت host/GPU drift هستند؛ بهبود tail ادعاشده بر paired same-window comparison تکیه دارد و physical-device proof همچنان در P7 انجام می‌شود.
- outlierهای transition در Map→Mission UI و Mission→Map raster به‌عنوان finding باز P4/P6 نگه داشته شده‌اند و در بستن این فاز پنهان نشده‌اند.
