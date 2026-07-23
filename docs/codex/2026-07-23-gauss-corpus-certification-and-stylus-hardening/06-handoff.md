# Handoff

## Outcome
Checkpoint اجرایی: preservation، renderer، Focus Pen path، certification schema،
forensic queues، weighted Luna batches و release proof تکمیل شده‌اند. محتوای علمی
هنوز عمداً `0 certified / 0 usable` است و کار ادامه دارد. شش batch نخست Luna Medium
با 261 سؤال و 76 رسانه اجرا و ادغام شده‌اند.

## Changed Artifacts
- `data/certification/v1/`
- `scripts/corpus_certification.mjs`
- `flutter_app/lib/widgets/content_blocks.dart`
- `flutter_app/lib/widgets/scratchpad.dart`
- `flutter_app/android/app/src/main/kotlin/com/gauss/app/MainActivity.kt`
- renderer/stylus tests

## How To Continue
- batchهای 0001 تا 0006 با attestation مستقل ادغام شده‌اند.
- batch بعدی `screening-0012` را دقیقاً با `LUNA_SCREENING_PROMPT.md` و یک
  runtime attestation مستقل در همین thread اجرا کنید.
- پس از هر merge، `validate` و `summarize` اجرا و batch بعدی از index انتخاب شود.

## Done
- تمام موارد بخش Outcome و release checkpoint 1.0.107.
- screening 0001: 6 accepted، 17 needs repair، 2 ambiguous؛ 15 incomplete و 2 ambiguous extraction.
- screening 0002: 25 needs repair و 25 incomplete؛ خرابی غالب، راه‌حل‌های فصل/سؤال دیگر است.
- screening 0003: 11 accepted، 13 needs repair، 1 ambiguous؛ خرابی غالب digit corruption و mismatch اندیس/رابطه است.
- screening 0004: 18 accepted، 6 needs repair، 1 ambiguous؛ mismatch اندیس/نسبت و عبارت هدف ناقص قرنطینه شد.
- screening 0005: 16 accepted و 9 needs repair؛ sign/power/expression mismatch و splice بین دو راه‌حل قرنطینه شد.
- screening 0006: 15 accepted و 10 needs repair؛ sign drift در transformed roots و multi-question image crops قرنطینه شد.
- screening 0007: 21 accepted، 3 needs repair، 1 ambiguous؛ نمودار ضروریِ جایگزین‌شده، متغیر `m/a`، تغییر علامت جمله خطی و اختلاف `y=x+8` با `4y+x=8` قرنطینه شد.
- screening 0008: 21 accepted و 4 needs repair؛ چهار راه‌حل با تغییر عبارت گویا، رادیکال ناسازگار، تغییر دو طرف معادله و تبدیل رادیکال تو در تو قرنطینه شد.
- screening 0009: 6 accepted و 9 needs repair؛ تغییر چند معادله رادیکالی، راه‌حل ناقص/مدیای سفید، عدم تطابق گزینه و مقدار، و چندجوابی‌بودن گزینه‌ای قرنطینه شد.
- screening 0010: 5 accepted، 19 needs repair، 1 ambiguous؛ cropهای نامرتبط، چندجمله‌ای‌های تغییرکرده، صفرهای placeholder و راه‌حل‌های متعلق به سؤال‌های دیگر قرنطینه شد.
- screening 0011: 13 accepted، 7 needs repair، 1 ambiguous؛ نمودار سفید/نامرتبط، cropهای solution، تغییر چندجمله‌ای، ترتیب ریشه و علامت نادرست قرنطینه شد.
- screening 0012: 9 accepted و 16 needs repair؛ 24 رسانه‌ی crop/سفید/نامرتبط، راه‌حل ناقص، تغییر معادله و drift علامت/ضریب قرنطینه شد.

## Remaining
- Luna screening/classification، freeze taxonomy، solve/verify/repair و runtime gate.
- source PDF و physical Focus Pen proof.

## Verification
- Analyzer و 94/94 tests پاس؛ Web و APK امضاشده پاس؛ data/media parity پاس.
- post-merge validate: 3672 source-bound، 286 screened، 0 usable.
- محدودیت‌های اثبات در `05-verification.md` صریح ثبت شده‌اند.
