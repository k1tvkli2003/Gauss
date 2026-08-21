# راستی‌آزمایی

## خلاصه

- Result: partial
- Last verified: 2026-08-21T18:06:19+03:30
- Scope: baseline و سند؛ پیاده‌سازی Goal هنوز شروع نشده است.

## بررسی‌ها

| بررسی | فرمان/روش | نتیجه | شاهد |
|---|---|---|---|
| Git baseline | `git rev-parse HEAD` و `git status --short --branch` | passed | `f3edce8`؛ فقط docs تازه و `references/` قدیمی untracked |
| Static analysis baseline | `flutter analyze --no-pub` | passed | No issues found؛ 156.8s |
| Focused test baseline | 6 فایل تست Map/Question/Pen/Motion/Android | passed | 43/43 |
| Code hotspot inspection | bounded source reads و `rg` | passed | full-stage scroll/paint، blur، broad ink listeners و gesture surface تأیید شد |
| Runtime visual baseline | inspection تصاویر Android | passed | [Map](assets/baseline-map-f3edce8.png)، [Mission](assets/baseline-mission-f3edce8.png) |
| ADB availability | `adb devices` / runtime inventory | no device | فقط `Codex_API35` در AVD inventory موجود است |

## هنوز اجرا نشده

- deterministic profile journeys و پنج run هم‌شرایط.
- full Flutter suite پس از تغییرات.
- Android debug/profile/release build جدید.
- runtime screenshot matrix پس از بازسازی.
- physical-device profile؛ دستگاه فعلاً متصل نیست.

## مشکلات شناخته‌شده

- Map stage یک‌تکه و repaint/rebuild وابسته به scroll دارد.
- blurهای moving chrome می‌توانند raster cost را بالا ببرند.
- header، orbit strip، mission/progress/footer تراکم و انسداد بصری دارند.
- question ink به بیش از یک سطح rebuild متصل است.
- question manuscript فضای مرده و controls غالب دارد؛ answer access دیر می‌شود.
- touch/stylus behavior در دستگاه Xiaomi باید با runtime سخت‌افزار خودش نیز تأیید شود.
