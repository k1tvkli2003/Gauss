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
| 2026-08-23T01:33:40+03:30 | active | identity raster دارای plate پس از رد بصری کامل حذف شد؛ theorem mark شفاف و مرکزچین با paint چندلایه، Android vector و adaptive safe foreground جای آن را در auth، Splash و launcher گرفت. | analyze پاک؛ 36/36 + 33/33 تست؛ دو debug build/install؛ [Splash](assets/p3-brand-splash-transparent.png) و [Auth](assets/p3-brand-auth-centered.png) زنده |
| 2026-08-23T02:03:50+03:30 | active | Orbit Navigator از modal بلند و list/form به constellation switcher content-hugging بازسازی شد؛ پنج فصل، تغییر subject، preview منتخب و action نمادین بدون پوشاندن Map یا scroll ثانویه در یک قاب قرار گرفتند. | analyze پاک؛ 41/41 تست؛ debug build/install؛ [Phone](assets/p3-orbit-navigator-constellation.png) و [320dp/200%](assets/p3-orbit-navigator-320dp-200text.png) زنده |
| 2026-08-23T02:48:54+03:30 | phase-complete | P3 بسته شد: node/aura نخست از Orbit header جدا شد، blank tail انتهای route حذف شد، Mission Compass/footer و landmarkها در matrix هفت‌نمای phone/tablet بدون overlap یا clip پاس شدند. P4 آغاز شد. | `894bdaf`؛ analyzer پاک؛ 42/42 تست؛ [start](assets/p3-map-phone-start.webp)، [end](assets/p3-map-phone-end.webp)، [tablet landscape](assets/p3-map-tablet-landscape.webp)؛ Map UI/raster p95=`4.359/20.250ms` |
| 2026-08-24T00:46:32+03:30 | active | vertical slice نخست P4 بسته شد: rebuildهای per-point از manuscript حذف، stylus side-button/inverted eraser اضافه، tool spine زمینه‌ای و مالک یگانهٔ ink شد و کنترل‌های تکراری از action dock حذف شدند. | `df7b17e`؛ analyzer پاک؛ 27/27 تست؛ Profile build/install؛ [blank](assets/p4-manuscript-blank-phone.webp) و [ink](assets/p4-manuscript-ink-phone.webp) زنده |
| 2026-08-24T07:06:37+03:30 | active | checkpoint دوم P4 مسیر answer→review را بست: Finger Ink هنگام Check به Touch Scroll برمی‌گردد، اسکرول خودکار correct/feedback را آشکار می‌کند و reflection/solution داخل parchment پیوسته‌اند. | `16160f7`؛ analyzer پاک؛ 28/28 تست؛ Profile build/install؛ [review](assets/p4-manuscript-review-phone.webp) زنده |
| 2026-09-11T05:07:17+03:30 | active | checkpoint سوم P4 مسیر completion را بست: ceremony bounded با skip semantic و reduced-motion، retry idempotence، pending-finalize pause/resume، reward فقط از receipt و panel responsive بدون ellipsis. | analyzer پاک؛ 63/63 تست در پنج suite؛ Profile build/install v91؛ signed package guard |
| 2026-09-11T05:22:00+03:30 | phase-complete | P4 با پنج run exact-revision روی `3f2cddb` بسته شد. همهٔ journeyها پاس شدند، Map/Question/transition tail نسبت به P2 بهتر شد و signed package/data حفظ شد. P5 آغاز شد. | [aggregate](logs/performance-p4-final-3f2cddb/aggregate.json)؛ 5/5 run؛ Map scroll UI/raster p95=`7.472/20.825ms`؛ stylus missed=`0` |

## انجام‌شده تا اینجا

- مشکل به چهار ریشه تقسیم شد: Map rendering، Map composition، Question/pen interaction و app-wide responsive/motion consistency.
- scope فقط Android و بدون تغییر dataset/media تثبیت شد.
- رفرنس‌های پذیرفته‌شده و runtime baseline از هم تفکیک و ثبت شدند.
- پیشرفت Goal با وزن گیت‌ها تعریف شد تا compile یا حجم کد به‌اشتباه completion حساب نشود.
- P0 تا P4 کامل شدند: کل Goal اکنون 70% است؛ این درصد فقط با عبور گیت بالا رفته است.
- finding بصری P3 قفل شد: spiral و nodeهای فعلی خشک، تکراری و مکانیکی‌اند و به‌جای polish سطحی باید با زبان مسیر/عمق/حالت تازه بازسازی شوند.
- هستهٔ route/node همین finding اکنون در code و Android runtime اصلاح شده است؛ bounds واقعی aura/header و tail واقعی scene نیز regression دارند.
- identity P3 از gate بصری عبور کرده است: mark و wordmark در auth محور مشترک دارند، Splash در مرکز واقعی است و هیچ baked/internal plate باقی نمانده است.
- Orbit Navigator نیز از gate بصری و responsive عبور کرده است: در حالت عادی content-hugging است، در `320dp` با متن `200%` تمام کنترل‌ها حداقل `48dp` می‌مانند و summary/labels نمی‌شکنند یا ellipsize نمی‌شوند.
- Mission Compass، footer، landmark hierarchy و matrix کامل مسیر بسته‌اند؛ exact-revision profile و package guard نیز P3 را phase-complete کرده‌اند.
- P4 ownership checkpoint بسته است: stroke point فقط canvas را repaint می‌کند، blank/ink tool state بدون پرش dock تغییر می‌کند، touch-scroll پیش‌فرض حفظ شده و Focus Pen side buttons تست مستقل دارند.
- P4 review checkpoint نیز بسته است: finger mode دیگر solution scroll را نمی‌بلعد، ابتدای reflection قطع نمی‌شود و phone review از زبان بصری manuscript خارج نمی‌شود.
- P4 completion checkpoint بسته است: reveal در یک duration مشخص تمام می‌شود، skip همان receipt را نگه می‌دارد، retry reward را تکرار نمی‌کند و pause/resume در میانهٔ finalize بدون double-commit برمی‌گردد.
- P4 phase-complete است: ownership، stylus، review، responsive matrix، completion و exact-revision performance proof بسته‌اند.

## مرحله بعد

- P5: shell، Study، Insights، auth، feedback، state systems و tablet. سپس P6/P7.

## ادامهٔ 2026-09-17

- قرارداد ادامه تا تحویل کامل ثبت شد؛ Focus Pen فیزیکی گیت قطعی است و پیشرفت همچنان 70% می‌ماند.
- اصلاح ارتفاع writing space روی 112 ثابت و regression به حرکت قلم در حالت down تعمیم یافت؛ paper/dock ثابت و paging قفل می‌مانند.
- `flutter analyze --no-pub`: پاک، exit 0، 98.7s. `flutter test --no-pub --reporter expanded`: exit 0، 250 passed / 1 skipped، 36s؛ هیچ تستی حذف یا smoke نشده است.
- وضعیت زنده GitHub: CI روی `81044c8` شکست‌خورده؛ آخرین release `v1.0.277`. CI اصلاح هنوز منتظر commit/push است. runtime تازه در این checkpoint اجرا نشده.

### checkpoint پس از push

- `b6773fb` push شد. run `35157330917` در setup SDK پیش از تست‌ها شکست خورد: default action شامل بستهٔ حذف‌شدهٔ `tools` بود. metadata همان SHA از upstream خوانده شد؛ `packages: platform-tools` صریح و regression pipeline افزوده شد. هویت، signing و versioning دست‌نخورده‌اند.
- آزمون P5 چرخش Study از phone به split tablet و برگشت، سؤال، hypothesis و controller/stroke/widthهای ink را حفظ کرد؛ نقص state در این سناریو بازتولید نشد، کد صفحه تغییر نکرد.
- دو suite Study و release pipeline: 30 passed، exit 0، 6s. audit رسمی اسناد actions پاس شد؛ actionlint محلی موجود نبود. CI جدید باید اثر اصلاح SDK را اثبات کند.

### P5 — continuation واقعی Study

- اصلاح SDK در `ad3df3d` push شد؛ run `35158147125` از setup، signing restore و quality gates گذشت و APK release در حال ساخت بود.
- نقص بازتولیدشده: Continue next session آدرس را به offset=5 تغییر می‌داد ولی محتوای جلسهٔ قبلی باقی می‌ماند. assertion تازه روی شناسهٔ سؤال بعد پیش از اصلاح fail و پس از اصلاح pass شد؛ تست قبلی فقط URL را بررسی می‌کرد.
- علت: ArchiveScreen بارگذاری را یک‌بار در didChangeDependencies انجام می‌داد؛ router همان State را برای ورودی تازه نگه می‌داشت. didUpdateWidget فقط تغییر هویت مجموعه را reload می‌کند؛ rotation عادی state را حفظ می‌کند. load generation پاسخ دیررس مجموعهٔ قبلی و نتیجهٔ save قدیمی را از UI جدید جدا می‌کند؛ transaction داده تغییر نکرده است.
- تست کنترل‌شدهٔ پاسخ دیررس offset=5 پس از offset=10 پاس شد. چهار suite Study/Mission/celebration/route برابر 57 passed در 9s؛ analyzer دو فایل بدون issue در 48s. suite کامل نهایی این slice برابر 253 passed / 1 skipped، exit 0 در 35s پاس شد؛ skip همان تست مخصوص web است.
- runtime Android این slice اجرا نشده: دستگاه متصل وجود ندارد و RAM آزاد هنگام بررسی حدود 1.4GiB بود. emulator راه‌اندازی نشد. P5 و Goal همچنان 70% باقی‌اند.
