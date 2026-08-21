# راستی‌آزمایی

## خلاصه

- Result: partial
- Last verified: 2026-08-21T20:23:24+03:30
- Scope: preservation و performance/visual/semantics baseline روی Android phone و tablet

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

## هنوز اجرا نشده

- full Flutter suite پس از تغییرات.
- Android debug/profile/release build جدید.
- runtime screenshot matrix پس از بازسازی.
- physical-device Xiaomi Focus Pen profile؛ emulator proof جای آن را نمی‌گیرد.

## مشکلات شناخته‌شده

- Map stage یک‌تکه و repaint/rebuild وابسته به scroll دارد.
- blurهای moving chrome می‌توانند raster cost را بالا ببرند.
- header، orbit strip، mission/progress/footer تراکم و انسداد بصری دارند.
- question ink به بیش از یک سطح rebuild متصل است.
- question manuscript فضای مرده و controls غالب دارد؛ answer access دیر می‌شود.
- touch/stylus behavior در دستگاه Xiaomi باید با runtime سخت‌افزار خودش نیز تأیید شود.
- emulator/SwiftShader raster p95 نمایندهٔ GPU گوشی نیست، اما برای before/after هم‌شرایط معتبر است.
- raw Timelineها محلی و بازتولیدپذیر نگه داشته می‌شوند؛ Git فقط aggregate، compact summaries، metadata و visual samples را حمل می‌کند.
