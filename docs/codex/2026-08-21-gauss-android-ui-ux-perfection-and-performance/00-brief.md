# پرفکشن UI/UX و عملکرد نسخه Android گائوس

- Task ID: `2026-08-21-gauss-android-ui-ux-perfection-and-performance`
- Status: `active`
- Created: 2026-08-21T18:02:38+03:30
- Language: fa
- Baseline revision: `f3edce84a54a89f1be3051ff435659e26d1e9e7c`
- Primary execution spec: [01-plan.md](01-plan.md)

## Request

یک برنامه اجرایی روشن و قابل سنجش برای ارتقای شدید ظاهر، رابط کاربری، تجربه کاربری و روانی نسخه Flutter/Dart اندروید گائوس نوشته شود؛ سپس همان برنامه به Goal فعال تبدیل و تا عبور واقعی از همه مراحل دنبال شود.

## Success Criteria

- اسکرول Map و صفحه سؤال روی Android بدون گیر، ناحیه مرده لمسی یا rebuild/repaint غیرضروری کار کند و بهبود با اندازه‌گیری هم‌شرایط اثبات شود.
- Map همچنان یک تجربه تمام‌صفحه، نجومی و مسیرمحور بماند، اما هدر، انتخاب درس، نودها، اتصال مسیر، نوار مأموریت و footer سبک‌تر، واضح‌تر و حرفه‌ای‌تر شوند.
- صفحه سؤال به نسخه اجراییِ پذیرفته‌شده Astral Manuscript نزدیک شود؛ سؤال، استدلال با قلم، گزینه‌ها و اقدام بعدی در یک جریان خوانا و گیمیفای‌شده قرار گیرند.
- قلم سخت‌افزاری بنویسد، لمس انگشت همیشه امکان اسکرول داشته باشد، پاک‌کردن/برگرداندن فوری و قابل فهم باشد و هیچ حرکت قلم باعث بازسازی کل صفحه نشود.
- گوشی کوچک، گوشی معمول، تبلت عمودی و تبلت افقی ترکیب‌بندی‌های اختصاصی داشته باشند؛ در 200% text هیچ متن ضروری شکسته، clip، ellipsize یا روی جزء دیگری نیفتد.
- هویت Gauss، Theorem Star، wordmark، بانک سؤال و رسانه، IDهای پایدار، حساب‌ها، پیشرفت کاربر، دیتابیس و قراردادهای Supabase بدون حذف یا reset حفظ شوند.
- همه app chrome انگلیسی بماند؛ متن آموزشی می‌تواند فارسی باشد و همه ارقام سؤال/پاسخ/راه‌حل در مرز نمایش ASCII `0-9` باقی بمانند.
- analyzer، تست‌های متمرکز و کامل، build اندروید، نصب debug کنار نسخه شخصی، ماتریس اسکرین‌شات، accessibility و performance gate پاس شوند.
- Goal فقط وقتی complete شود که همه موارد Must بسته باشند و یک بازبینی خصمانه مورد Material حل‌نشده‌ای پیدا نکند.

## Context

کد فعلی از نظر قراردادهای اصلی و تست‌های متمرکز پایه خوبی دارد، اما تجربه نهایی هنوز «پرفکت» نیست. در baseline فعلی `flutter analyze --no-pub` پاس شده و 43 تست متمرکز Map، سؤال، قلم، motion و Android composition سبز هستند. با این حال Map هنوز یک stage بسیار بلند را داخل `SingleChildScrollView` کامل paint می‌کند، چند blur روی محتوای متحرک دارد و حین scroll بخشی از state بالادست را rebuild می‌کند. صفحه سؤال نیز هم در `QuestionManuscript` و هم در scratch layer به controller قلم گوش می‌دهد و در runtime فضای مرده، ابزارهای بزرگ و تراکم ضعیف دارد.

آمادگی محصول برای هدف کیفیِ این چرخه حدود 60–65% برآورد می‌شود. این عدد تخمینی است؛ درصد Goal جدید از صفر و فقط بر اساس گیت‌های پذیرفته‌شده محاسبه می‌شود تا کار قدیمی دوباره به‌عنوان پیشرفت تازه شمرده نشود.

## In Scope

- Flutter/Dart نسخه Android و کد مشترک لازم برای آن.
- Map، shell/header، انتخاب subject/course/chapter، path/node/landmark، current mission و floating navigation.
- Mission/Study question experience، answer states، stylus/touch، inline ink، deep scratch، solution و completion.
- Study، Insights، auth، feedback و stateهای loading/empty/error به‌اندازه لازم برای یکپارچگی کامل UI/UX.
- phone/tablet portrait/tablet landscape، safe areas، large text، RTL/mixed math، TalkBack و reduced motion.
- profile instrumentation، frame/jank/rebuild/repaint/memory evidence و Android runtime screenshots.

## Out of Scope

- build یا پولیش اختصاصی Web در این چرخه.
- بازنویسی، حذف یا جایگزینی داده یا رسانه منبع.
- اشتراک‌گذاری، لیگ عمومی، monetization یا شبکه اجتماعی.
- تغییر هویت انتخاب‌شده Gauss/Theorem Star به یک direction تازه.
- ادعای battery/thermal یا عملکرد سخت‌افزار فیزیکی بدون اندازه‌گیری همان سخت‌افزار.
- تغییر credential یا reset حساب/پیشرفت برای ساده‌کردن تست.

## Assumptions

- دو رفرنس پذیرفته‌شده Map و Astral Manuscript جهت الزام‌آور این چرخه‌اند؛ انتخاب کانسپت تازه از کاربر لازم نیست.
- فقط AVD موجود `Codex_API35` مجاز است؛ AVD تازه ساخته نمی‌شود.
- در لحظه شروع هیچ دستگاه ADB متصل نیست؛ این مانع طراحی، تست و اندازه‌گیری تشخیصی emulator نیست، ولی ادعای physical-device را محدود می‌کند.
- اجرای این Goal بدون subagent ادامه پیدا می‌کند مگر کاربر صریحاً دوباره اجازه دهد.
