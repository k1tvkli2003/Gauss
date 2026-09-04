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
| 2026-09-04T02:47:01+00:00 | active | چرخهٔ audit+کد بدون toolchain (Google/GitHub-assets/conda/nix در sandbox مسدود؛ فقط GitHub source/npm/PyPI). سه finding بسته شد: (1) state `source-warning` manifests در mission پیاده شد — tone source + shield + semantics صادقانه روی rail درستِ پاسخ preserved-unverified، اعلام amber «SOURCE ANSWER» در solve instrument به‌جای «PROOF HOLDS»، test regression تازه با fixture `solutionVerified=false`؛ (2) قرارداد مردهٔ `usesQuestionSplit` (840dp — با manifest 1200×600 و implementation verified ناسازگار) و fractionهای 62/38 با گیت window+stage+text-scale و توکن‌های `questionSupportPane*` جایگزین و در mission سیم شد (behavior-preserving)؛ (3) literals 820/112/176 به توکن‌های design system تبدیل شدند؛ `compactNavigationFootprint` و سه توکن مرده حذف. manifests و `_index.md` هم‌سو. | statik: diff reading کامل + brace/paren balance + trace fixture→`solutionVerified=false`→state؛ **analyze/test/build/runtime هنوز باز — toolchain در sandbox موجود نیست** |

## انجام‌شده تا اینجا

- مشکل به چهار ریشه تقسیم شد: Map rendering، Map composition، Question/pen interaction و app-wide responsive/motion consistency.
- scope فقط Android و بدون تغییر dataset/media تثبیت شد.
- رفرنس‌های پذیرفته‌شده و runtime baseline از هم تفکیک و ثبت شدند.
- پیشرفت Goal با وزن گیت‌ها تعریف شد تا compile یا حجم کد به‌اشتباه completion حساب نشود.
- P0 تا P3 کامل شدند: کل Goal اکنون 50% است؛ این درصد فقط با عبور گیت بالا رفته است.
- finding بصری P3 قفل شد: spiral و nodeهای فعلی خشک، تکراری و مکانیکی‌اند و به‌جای polish سطحی باید با زبان مسیر/عمق/حالت تازه بازسازی شوند.
- هستهٔ route/node همین finding اکنون در code و Android runtime اصلاح شده است؛ bounds واقعی aura/header و tail واقعی scene نیز regression دارند.
- identity P3 از gate بصری عبور کرده است: mark و wordmark در auth محور مشترک دارند، Splash در مرکز واقعی است و هیچ baked/internal plate باقی نمانده است.
- Orbit Navigator نیز از gate بصری و responsive عبور کرده است: در حالت عادی content-hugging است، در `320dp` با متن `200%` تمام کنترل‌ها حداقل `48dp` می‌مانند و summary/labels نمی‌شکنند یا ellipsize نمی‌شوند.
- Mission Compass، footer، landmark hierarchy و matrix کامل مسیر بسته‌اند؛ exact-revision profile و package guard نیز P3 را phase-complete کرده‌اند.
- P4 ownership checkpoint بسته است: stroke point فقط canvas را repaint می‌کند، blank/ink tool state بدون پرش dock تغییر می‌کند، touch-scroll پیش‌فرض حفظ شده و Focus Pen side buttons تست مستقل دارند.
- P4 review checkpoint نیز بسته است: finger mode دیگر solution scroll را نمی‌بلعد، ابتدای reflection قطع نمی‌شود و phone review از زبان بصری manuscript خارج نمی‌شود.

## مرحله بعد

- P4: تکمیل answer states، solution/completion، restore timing و compositionهای phone/tablet/large-text؛ سپس exact-revision performance proof.
