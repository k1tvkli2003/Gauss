# راستی‌آزمایی

## خلاصه

- Result: partial
- Last verified: 2026-08-23T02:03:50+03:30
- Scope: P0 baseline + P1 executable UI system/manifest + P2 closed Map engine + active P3 route/node/identity/navigator slices

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

## هنوز اجرا نشده

- full Flutter suite پس از بازسازی‌های runtime.
- Android profile/release build جدید؛ debug build identity پاس شده است.
- runtime screenshot matrix پس از بازسازی.
- physical-device Xiaomi Focus Pen profile؛ emulator proof جای آن را نمی‌گیرد.

## مشکلات شناخته‌شده

- Map renderer دیگر stage یک‌تکه یا rebuild وابسته به scroll ندارد؛ route/node P3 بازطراحی و gate موقت را پاس کرده، ولی P3 تا closure کل HUD/identity/navigator/landmark و responsive capture matrix باز است.
- blur زندهٔ moving chrome حذف شده و blur footer فقط در footprint محدود خودش باقی مانده است.
- mission/progress/footer و بعضی landmarkها هنوز برای closure کامل P3 نیاز به بازسازی و matrix دارند؛ identity و Orbit Navigator دیگر finding باز نیستند.
- question ink به بیش از یک سطح rebuild متصل است.
- question manuscript فضای مرده و controls غالب دارد؛ answer access دیر می‌شود.
- touch/stylus behavior در دستگاه Xiaomi باید با runtime سخت‌افزار خودش نیز تأیید شود.
- emulator/SwiftShader raster p95 نمایندهٔ GPU گوشی نیست، اما برای before/after هم‌شرایط معتبر است.
- raw Timelineها محلی و بازتولیدپذیر نگه داشته می‌شوند؛ Git فقط aggregate، compact summaries، metadata و visual samples را حمل می‌کند.
- P1 عمداً composition screenها را تغییر نداد؛ این قرارداد در P2–P6 اجرا و با captureهای ماتریس بسته می‌شود.
- P2 phase-complete است؛ paired same-window evidence اثر engine را از drift میزبان جدا کرد و پنج run نهایی revision-bound حفظ semantics/package را ثابت کرد.
- absolute raster اعداد emulator تحت host/GPU drift هستند؛ بهبود tail ادعاشده بر paired same-window comparison تکیه دارد و physical-device proof همچنان در P7 انجام می‌شود.
