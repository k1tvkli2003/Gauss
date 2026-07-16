# Handoff

## Outcome

بازسازی Android Gauss برای موبایل و تبلت تکمیل شد. محصول اکنون یک رصدخانه‌ی آموزشی map-first با هویت Theorem Star، wordmark هنری Gauss، typography دوخطی Manrope/Vazirmatn، art kit ماژولار، مأموریت قابل‌حل، scratchpad، بازخورد، completion و insights سازگار است.

## Artifact نهایی

- APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- SHA-256: `D89C90814482AD7340377A71BB69F2CBB6D5CC7F2461438A887B7ACA243A9ABA`
- نصب محلی: `adb install -r flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- package/activity: `com.gauss.app/.MainActivity`

## اسناد تحویل

- [نقد و fix plan کامل](07-critique-and-fix-plan.md)
- [PDF ممیزی](critics-report-gauss-android-2026-07-15.pdf)
- [دفتر تصاویر release](03-previews.md)
- [نتایج verification](05-verification.md)
- [قرارداد art و asset manifest](08-art-direction-and-asset-manifest.md)

## تغییرات مهم

- `flutter_app/lib/screens/`: بازسازی Map، Practice، Mission و Insights.
- `flutter_app/lib/widgets/`: brand primitives، content rendering و scratchpad بهینه.
- `flutter_app/assets/visual/`: art kit مستقل برای brand/map/nodes/mascot.
- `flutter_app/assets/fonts/`: Manrope variable + OFL؛ Vazirmatn حفظ شده.
- `flutter_app/android/app/src/main/`: package درست، adaptive/themed icon و splash.
- `flutter_app/test/`: Android experience، responsive/accessibility و data/media invariants.

## وضعیت داده

هیچ سؤال، shard یا فایل رسانه‌ای حذف یا بازنویسی نشده است. app همچنان تمام 7,353 سؤال و 3,410 فایل رسانه‌ای را نگه می‌دارد؛ فقط eligibility سؤال‌های mission-ready مطابق قرارداد قبلی اعمال می‌شود.

## نگهداری بعدی

- برای sideload شخصی همین APK قابل استفاده است.
- اگر روزی انتشار Store خواسته شد، keystore اختصاصی، backup امن کلید و signing configuration محیطی اضافه شود؛ هیچ تغییر محصولی دیگری برای دامنه‌ی فعلی لازم نیست.
