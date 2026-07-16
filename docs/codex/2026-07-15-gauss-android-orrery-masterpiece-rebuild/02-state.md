# وضعیت

- Current status: `implementation complete / final acceptance passed`
- Last updated: 2026-07-16T23:38:58+03:30
- Owner: Codex (single-agent execution)

## نتیجه‌ی فعلی

نسخه‌ی Android موبایل و تبلت Gauss با جهت هنری «Orrery of Proofs» بازسازی شده است. mismatch پکیج Android که baseline را متوقف می‌کرد رفع شد؛ APK release فعلی نصب و cold-launch می‌شود، همه‌ی مسیرهای Map، Practice، Mission، Insights و Mission Complete روی runtime واقعی Android ثبت شده‌اند، و layout تبلت 2560×1600 و font scale برابر 1.5 نیز بدون overflow تأیید شده‌اند.

داده و رسانه دست‌نخورده و با تست invariant محافظت شده‌اند: 7,353 سؤال در 29 shard موضوعی، 3,681 سؤال mission-ready، 3,672 مورد reference-only، 3,610 توضیح verified، و 3,410 فایل رسانه‌ای با مجموع 66,450,076 بایت.

## تصمیم‌های قفل‌شده

| تاریخ | تصمیم | نتیجه‌ی اجرایی |
|---|---|---|
| 2026-07-15 | دامنه فقط Android موبایل و تبلت است. | هیچ کار جدیدی برای Web وارد rebuild نشد. |
| 2026-07-15 | مرجع بصری «Orrery of Proofs» است. | نقشه‌ی تمام‌صفحه، اورری مرکزی، پوسته‌های ماژولار و HUD زنده پیاده شد. |
| 2026-07-15 | متن، داده، state، focus و کنترل زنده می‌مانند. | raster فقط برای مواد/شخصیت/ماشین استفاده شد؛ semantics و interaction در Flutter باقی ماند. |
| 2026-07-15 | نشان نهایی «Theorem Star» است. | SVG، glyphهای داخل اپ، adaptive icon، monochrome themed icon و splash همگام شدند. |
| 2026-07-15 | نام Gauss در سطوح برند wordmark هنری باشد. | `gauss_wordmark.png` با semantic label زنده در HUD، mission و completion مصرف می‌شود. |
| 2026-07-15 | فونت انگلیسی Manrope باشد. | Manrope variable + OFL به پروژه افزوده و Vazirmatn برای فارسی حفظ شد. |
| 2026-07-15 | محصول خصوصی و تک‌کاربره بماند. | auth، social pressure، monetization و public league اضافه نشد. |
| 2026-07-15 | dataset/media و trust boundary ثابت بماند. | invariant tests سبز و هیچ migration داده‌ای انجام نشد. |
| 2026-07-15 | subagent استفاده نشود. | کل ممیزی، طراحی، پیاده‌سازی و اثبات در همین task انجام شد. |

## اصلاح‌های اصلی

- package/namespace و مسیر `MainActivity` روی `com.gauss.app` یکسان شد.
- startup فوری برندشده پیش از پایان initialization ساخته شد.
- Map موبایل path-first و Map تبلت radial + inspector شد.
- Practice از dashboard آرشیوی به mission forge با mode/filter زنده تبدیل شد.
- Mission به parchment question stage، scratchpad برداری، feedback و completion theater تبدیل شد.
- Insights به first-use guide و achievement seals اختصاصی تبدیل شد.
- بازسازی‌های گسترده‌ی `MaterialApp`، محاسبه‌ی تکراری progress و history بی‌کران scratchpad حذف شد.
- reduced motion، haptic feedback، semantics، text scale 1.5 و long mixed RTL/LTR math پوشش داده شد.
- Mira برای نتیجه‌ی ضعیف حالت thinking دارد و فقط برای امتیاز مناسب جشن می‌گیرد.

## مسدودکننده‌ها و محدودیت‌ها

- مسدودکننده‌ی عملکردی باقی نمانده است.
- APK فعلی به‌علت نبود keystore شخصی کاربر با debug certificate امضا شده است. برای sideload خصوصی معتبر و نصب‌پذیر است؛ برای Play Store باید keystore release اختصاصی تعریف شود.
- یک باگ renderer/capture در emulator API 37 با GPU 16KB-page دیده شد؛ همان APK روی API 35 software renderer نصب، اجرا و screenshot شد. این مورد failure محصول نبود و در package resolution و runtime تکرار نشد.

## اسناد مرجع

- [نقد کامل و مسیر فیکس](07-critique-and-fix-plan.md)
- [PDF ممیزی 24 صفحه‌ای](critics-report-gauss-android-2026-07-15.pdf)
- [اثبات‌های بصری release](03-previews.md)
- [پذیرش فنی](05-verification.md)
- [تحویل نهایی](06-handoff.md)
