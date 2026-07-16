# برنامه

## رویکرد

کار در سه لایه انجام می‌شود: ۱) ممیزی فریز‌شده و بی‌رحمانه با مدرک runtime؛ ۲) تبدیل تصویر مرجع به قرارداد لایه‌ها، برند و component states؛ ۳) پیاده‌سازی و حلقه‌های Perfect تا عبور از گیت‌های Android. قراردادهای داده و پیشرفت در تمام مراحل immutable در نظر گرفته می‌شوند.

## مراحل

| مرحله | وضعیت | توضیح |
|---|---|---|
| 1 | done | خواندن مهارت‌ها و تعریف معیار نقد/پذیرش Android |
| 2 | done | ممیزی چندمرحله‌ای کد، داده، معماری و تمام سطوح تجربه/هویت |
| 3 | done | ماتریس screenshot و runtime موبایل/تبلت/متن بزرگ/دسترس‌پذیری |
| 4 | done | فریز Markdown، JSON و PDF نقد به‌همراه مسیر اصلاح |
| 5 | done | ثبت و اعتبارسنجی قواعد Modernize برای پوشش هویت و fidelity دارایی |
| 6 | done | تولید art kit ماژولار Orrery، برند، app icon، glyph، mascot و badges |
| 7 | done | بازسازی Flutter موبایل/تبلت با نقشه‌ی map-first و حلقه‌ی مأموریت کامل |
| 8 | done | Perfect cycles برای function، copy، gamify، errors، integrity و performance |
| 9 | done | پذیرش نهایی Android، APK نصب‌شونده، launch proof و screenshot matrix |

## رابط‌ها و مصنوعات

- UI و state در `flutter_app/lib/`.
- منابع Android در `flutter_app/android/app/src/main/`.
- دارایی‌های جدید تحت `flutter_app/assets/visual/` با manifest و variant contract.
- گزارش و وضعیت در همین task folder.
- شواهد خام مستقل در `C:/Users/K1/.codex/audit-output/gauss-android-masterpiece-2026-07-15/`.
- قراردادهای داده‌ی موجود و مسیرهای dataset/media بدون تغییر محتوایی.

## ریسک‌ها

- دارایی‌های تصویری بزرگ ممکن است memory/jank ایجاد کنند؛ با resolution variants، decode sizing، precache محدود و profiling کنترل می‌شود.
- گراف 29 موضوع اگر هم‌زمان برچسب‌گذاری شود شلوغ می‌شود؛ با مسیر پیشرفت، focus sector و LOD واکنش‌گرا حل می‌شود.
- متن فارسی و ریاضی در RTL ممکن است معنای بصری و semantics را بشکند؛ متن نمایشی و label دسترس‌پذیری جدا و تست TalkBack لازم است.
- بازطراحی شدید می‌تواند قراردادهای داده را آلوده کند؛ لایه‌ی presentation از repositories جدا می‌ماند و invariant tests قبل/بعد اجرا می‌شوند.

## گیت‌های پذیرش

- `flutter analyze` و همه‌ی تست‌ها سبز.
- build release و اجرای واقعی `com.gauss.app/.MainActivity` بدون `ClassNotFoundException`.
- screenshotهای موبایل و تبلت برای Map، Mission، Feedback، Reward، Practice، Insights و error/empty.
- بدون overlap/overflow در font scale 1.3 و 1.5؛ targetهای تعاملی حداقل 48dp.
- سؤال ریاضی یک معنای پیوسته برای screen reader داشته باشد.
- اندازه و شمار dataset/media دقیقاً با baseline برابر بماند.
- هر mock/generated asset تا زمان screenshot runtime با برچسب Mock Preview باقی بماند.
