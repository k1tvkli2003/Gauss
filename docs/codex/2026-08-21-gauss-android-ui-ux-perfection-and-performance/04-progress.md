# پیشرفت

## Log

| زمان | وضعیت | رویداد | شاهد |
|---|---|---|---|
| 2026-08-21T18:02:38+03:30 | active | task docs ساخته شد. | task folder + `_index.md` |
| 2026-08-21T18:06:19+03:30 | active | baseline commit، status، code hotspots و runtime captures تثبیت شد. | `f3edce8` + source locations + `assets/` |
| 2026-08-21T18:06:19+03:30 | active | plan اجرایی P0–P7، preservation contract، opinion ledger و budgets نوشته شد. | [01-plan.md](01-plan.md) |
| 2026-08-21T18:17:37+03:30 | active | همان plan به Goal فعال thread تبدیل و P0 آغاز شد. | active Goal objective + plan tracker |
| 2026-08-21T19:18:00+03:30 | active | harness ایزولهٔ Flutter Driver برای launch، Map scroll، Mission، stylus، touch/answer و back ساخته شد. | `f7e42a3` |
| 2026-08-21T19:48:00+03:30 | active | semantics، stylus synthesis، signed-package guard و profile-data cold/warm protocol سخت‌گیرانه شد. | `08a7817` |
| 2026-08-21T20:16:00+03:30 | active | پنج run phone، tablet portrait و tablet landscape ثبت شدند؛ responsive CTA و Dart 3.12 summarizer اصلاح شد. | `798aa03` + `logs/performance-*` |
| 2026-08-21T20:23:24+03:30 | phase-complete | گیت P0 پاس شد؛ preservation، baseline، screenshots، semantics و aggregate metrics قفل شدند. P1 آغاز شد. | `05-verification.md` |
| 2026-08-21T21:06:32+03:30 | phase-complete | P1 به‌صورت اجرایی بسته شد: token ramp، manifest لایه‌ها، geometry/occupancy، state matrix، Motion Bible و screenshot positions هم در docs و هم در Dart ثبت و تست شدند. P2 آغاز شد. | `beb56d6` + 32/32 tests |
| 2026-08-21T21:43:00+03:30 | active | Map stage یک‌تکه به `CustomScrollView` و bandهای lazy مهاجرت کرد؛ geometry با LRU cache، path repaint با band ownership، raster decode bounded و moving blur حذف شد. | focused analyze + 48/48 tests؛ profile comparison بعدی |
| 2026-08-21T22:17:00+03:30 | active | اولین پنج run engine، بهبود محدود raster p95 ولی regression median/missed و هم‌زمان drift در journeyهای دست‌نخورده را آشکار کرد؛ نتیجه به‌عنوان pass پذیرفته نشد. | `performance-p2-engine-2b0864d` |
| 2026-08-21T23:06:00+03:30 | active | viewport تمام‌قد، hit shield پایین و cache bounded ساخته شد؛ 33/33 regression پاس شد، اما cold-AVD پنج‌باره drift شدید GPU و یک UI outlier داشت و باز هم pass اعلام نشد. | `6bb422f` + `performance-p2-engine-v2-6bb422f` |
| 2026-08-21T23:31:00+03:30 | active | blurهای میانی و repaint layerهای تو‌در‌تو حذف شدند؛ footer شفاف فقط در footprint خودش blur محدود دارد. paired baseline همان لحظه بهبود 58% UI p95 و 51% raster p95 را ثابت کرد. | pilot current `5.720/24.319ms` در برابر `08a7817` برابر `13.731/49.598ms` |
| 2026-08-21T23:47:24+03:30 | phase-complete | گیت P2 بسته شد: پنج run نهایی exact revision همگی پاس شدند، geometry/semantics حفظ شد و package شخصی دست‌نخورده ماند. P3 بازسازی بنیادی spiral/node/HUD آغاز شد. | `13d6597` + `performance-p2-final-13d6597`؛ Map UI/raster p95=`8.557/28.385ms`، PSS=`157.033MiB` |
| 2026-08-23T00:02:00+03:30 | active | vertical slice اصلی P3 بازسازی شد: curve بزرگ‌قطر با tangent مشترک، station سه‌بعدی مستقل Math/Physics، rail-to-socket docking و dissolve پیش از HUD جای shell/node/line مکانیکی را گرفت. | analyze پاک + 41/41 تست + `map-p3-math-rail-fade-live.png` و `map-p3-physics-rail-fade-live.png` محلی |

## انجام‌شده تا اینجا

- مشکل به چهار ریشه تقسیم شد: Map rendering، Map composition، Question/pen interaction و app-wide responsive/motion consistency.
- scope فقط Android و بدون تغییر dataset/media تثبیت شد.
- رفرنس‌های پذیرفته‌شده و runtime baseline از هم تفکیک و ثبت شدند.
- پیشرفت Goal با وزن گیت‌ها تعریف شد تا compile یا حجم کد به‌اشتباه completion حساب نشود.
- P0 تا P2 کامل شدند: کل Goal اکنون 33% است؛ این درصد فقط با عبور گیت بالا رفته است.
- finding بصری P3 قفل شد: spiral و nodeهای فعلی خشک، تکراری و مکانیکی‌اند و به‌جای polish سطحی باید با زبان مسیر/عمق/حالت تازه بازسازی شوند.
- هستهٔ route/node همین finding اکنون در code و Android runtime اصلاح شده است؛ P3 تا بسته‌شدن HUD/identity/navigator/landmark و matrix responsive همچنان active می‌ماند.

## مرحله بعد

- P3: تثبیت HUD/identity، Orbit Navigator، landmark و Mission Compass روی هستهٔ route/node تازه؛ سپس capture و اصلاح پنج موقعیت مسیر روی Android و profile spot-check.
