# پیش‌نمایش‌ها و شواهد بصری

## سیاست اثبات

تصاویر mock فقط برای تصمیم هنری‌اند. تصاویر `release-*` مستقیماً از APK نهایی نصب‌شده روی Android API 35 با `adb screencap` گرفته شده‌اند و مدرک runtime هستند. متن، داده، control، focus و semantics در این تصاویر زنده‌اند؛ دارایی‌های raster فقط لایه‌های هنری ماژولار را تأمین می‌کنند.

## شواهد نهایی release

| سطح | دستگاه / state | لینک | آنچه ثابت می‌کند |
|---|---|---|---|
| Map | Phone 1080×2400 | [تصویر](assets/release-phone-map.png) | path-first map، wordmark، theorem engine، node states، mission dock و bottom navigation. |
| Practice | Phone 1080×2400 | [تصویر](assets/release-phone-practice.png) | modeها، فیلترها، کتابخانه‌ی کامل 7,353 سؤالی و copy عمومی بدون jargon داخلی. |
| Insights | Phone 1080×2400 | [تصویر](assets/release-phone-insights.png) | first-use guide، achievement seals و حذف دیوار صفرها. |
| Mission | Phone 1080×2400 | [تصویر](assets/release-phone-mission.png) | سؤال فارسی واقعی، math زنده، wordmark، progress و scratchpad اختصاصی. |
| Completion | Phone 1080×2400، 0% | [تصویر](assets/release-phone-complete.png) | Mira thinking، copy انسانی، reward ledger و CTAهای پایان؛ بدون جشن جعلی. |
| Accessibility | Phone، font scale 1.5 | [تصویر](assets/release-phone-font150.png) | افزایش واقعی اندازه‌ی متن بدون clipping یا overflow در HUD، path، dock و nav. |
| Map | Tablet landscape 2560×1600 | [تصویر](assets/release-tablet-map.png) | rail، radial 29-topic map، inspector و fit کامل حلقه‌های بیرونی. |
| Map | Tablet portrait 1600×2560 | [تصویر](assets/release-tablet-portrait-map.png) | rail فشرده، مسیر عمودی scrollable، header و mission dock بدون scale-down مصنوعی. |
| Mission | Tablet landscape 2560×1600 | [تصویر](assets/release-tablet-mission.png) | question stage وسیع، supporting pane برای Mira و action layout تطبیقی. |

## مرجع و baseline

| نام | نقش | لینک |
|---|---|---|
| Orrery of Proofs | mock منتخب و specification ترکیب‌بندی | [تصویر](assets/mock-preview-c-orrery-of-proofs.png) |
| Theorem Star | concept منتخب کاربر و منبع cleanup برداری | [تصویر](assets/brand-concept-theorem-star-selected.png) |
| Baseline phone map | وضعیت پیش از overhaul | [تصویر](assets/gauss-baseline-phone-map.png) |
| Baseline tablet map | وضعیت پیش از overhaul | [تصویر](assets/gauss-baseline-tablet-landscape-map.png) |

## نتیجه‌ی تطبیق

- mock به‌صورت یک تصویر تخت داخل اپ قرار نگرفت؛ atmosphere، theorem engine، topic shell، boss observatory، Mira، wordmark و Theorem Star مصرف‌کننده‌های مستقل دارند.
- نقشه در موبایل عمودی و در تبلت radial است، اما state model و visual grammar مشترک‌اند.
- titleهای موضوع، شمارنده‌ها، progress، Persian question content، CTAها و accessibility labels کاملاً live باقی مانده‌اند.
- crop، scale، z-order و safe-area روی دو اندازه‌ی واقعی و text scale 1.5 بررسی شده‌اند.
