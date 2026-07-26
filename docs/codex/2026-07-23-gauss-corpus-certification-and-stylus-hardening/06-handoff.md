# Handoff

## Outcome
Checkpoint اجرایی: preservation، renderer، Focus Pen path، certification schema،
forensic queues، weighted Luna batches و release proof تکمیل شده‌اند. محتوای علمی
هنوز عمداً `0 certified / 0 usable` است و کار ادامه دارد. تا batch 0059
تعداد 1391 سؤال (37.88%) غربال شده و batchهای موازی مطابق دستور جدید کاربر با
ساب‌ایجنت‌های موازی و attestation وابسته به SHA-256 خروجی ادغام شده‌اند.

## Changed Artifacts
- `data/certification/v1/`
- `scripts/corpus_certification.mjs`
- `flutter_app/lib/widgets/content_blocks.dart`
- `flutter_app/lib/widgets/scratchpad.dart`
- `flutter_app/android/app/src/main/kotlin/com/gauss/app/MainActivity.kt`
- renderer/stylus tests

## How To Continue
- batchهای 0001 تا 0059 با attestation مستقل ادغام شده‌اند.
- `screening-0023` پس از رد اجرای اول، با worker تازه و blind rerun ادغام شد؛
  بررسی‌ها فقط در ساب‌ایجنت‌های ایزوله
  انجام شوند و خروجی دقیقاً به attestation همان worker هش شود.
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
- screening 0013: 22 needs repair؛ هر 32 رسانه‌ی واقعی بررسی و به‌خاطر cropهای سؤال‌های مجاور، splice چندسؤالی، گزینه‌های نامرتبط یا solution ناقص قرنطینه شد.
- screening 0014: 25 needs repair؛ هر 19 رسانه‌ی واقعی نامرتبط بود و تمام solutionها به‌جای معادلات قدرمطلق/جزءصحیح، تمرین‌های رادیکال و توان بودند.
- screening 0015: 25 needs repair؛ هر 9 رسانه‌ی واقعی نامرتبط بود و solution تمام ردیف‌ها متعلق به تمرین‌های رادیکال/توان بود، نه معادلات قدرمطلق.
- screening 0016: 25 needs repair؛ solution یا media با stemهای قدرمطلق/نامعادله جفت نبود و cropهای چندسؤالی/رادیکالی قرنطینه شد.
- screening 0017: 25 needs repair؛ همه‌ی solutionها رادیکالی و نامرتبط با stemهای نمودار/قدر مطلق بودند و 3 crop گرافی ناقص/نامرتبط قرنطینه شد.
- screening 0018: 25 needs repair؛ همه‌ی solutionها یا mediaها با stem جفت نبودند و 5 رسانه بررسی شد.
- screening 0019: 7 needs repair؛ چهار رسانه بررسی و crop/محتوای نامرتبط قرنطینه شد.
- screening 0020: 8 accepted، 14 needs repair، 3 ambiguous؛ چهار رسانه بررسی و graph/domain/formula mismatchها fail closed شدند.
- screening 0021: 13 accepted، 11 needs repair، 1 ambiguous؛ پنج رسانه بررسی و crop/solution mismatchها قرنطینه شد.
- screening 0022: 6 accepted، 18 needs repair، 1 ambiguous؛ شانزده رسانه بررسی و placeholder/condition/solution mismatchها قرنطینه شد.
- screening 0023: 2 accepted، 12 needs repair، 11 ambiguous؛ اجرای اول رد و اجرای blind تازه با 22 media ادغام شد.
- screening 0024: 7 accepted، 8 needs repair، 10 ambiguous؛ assetهای blank/cropped/unrelated قرنطینه شد.
- screening 0025: 3 accepted، 22 needs repair؛ یازده media crop و solution mismatchهای گسترده قرنطینه شد.
- screening 0026: 9 accepted، 16 needs repair؛ پنج رسانه بررسی و formula/zero/solution mismatchها قرنطینه شد.
- screening 0027: 19 needs repair، 6 ambiguous؛ دو رسانه بررسی و همه‌ی solutionهای نامرتبط قرنطینه شد.
- screening 0028: 1 accepted، 22 needs repair؛ 32 رسانه بررسی و solution/media mismatchها قرنطینه شد.
- screening 0029: 8 accepted، 17 needs repair؛ 22 رسانه بررسی و graph/solution mismatchها قرنطینه شد.
- screening 0030: 11 accepted، 5 needs repair؛ 28 رسانه بررسی و diagramهای misbound/missing قرنطینه شد.
- screening 0031: 17 needs repair، 8 ambiguous؛ 17 رسانه بررسی و همه‌ی ردیف‌ها fail closed ماندند.
- screening 0032: 4 accepted، 8 needs repair، 13 ambiguous؛ 28 رسانه بررسی شد.
- screening 0033: 3 accepted، 13 needs repair، 9 ambiguous؛ 26 رسانه بررسی شد.
- screening 0034: 4 accepted، 21 needs repair؛ چهار رسانه بررسی و crop/mismatch قرنطینه شد.
- screening 0035: 2 accepted، 23 needs repair؛ 13 رسانه بررسی و placeholder/scan gaps قرنطینه شد.
- screening 0036: 24 needs repair، 1 ambiguous؛ 22 رسانه بررسی شد.
- screening 0037: 24 needs repair، 1 ambiguous؛ 30 رسانه بررسی شد.
- screening 0038: 25 needs repair؛ سه acceptance ناسازگار توسط gate رد و توسط worker اصلاح شد.
- screening 0039: 23 needs repair، 2 ambiguous؛ 26 رسانه بررسی شد.
- screening 0040: 11 ambiguous؛ 12 رسانه بررسی و همه‌ی rowها fail closed ماند.
- screening 0041: 8 accepted، 14 needs repair، 3 ambiguous؛ 11 رسانه بررسی شد.
- screening 0042: 24 needs repair، 1 ambiguous؛ 14 رسانه بررسی شد.
- screening 0043: 10 needs repair، 15 ambiguous؛ سه رسانه‌ی crop نامرتبط بررسی شد.
- screening 0044: 25 needs repair؛ 12 رسانه بررسی و placeholder options قرنطینه شد.
- screening 0045: 12 accepted، 11 needs repair، 2 ambiguous؛ سه رسانه بررسی شد.
- screening 0046: 17 accepted، 8 needs repair؛ دو رسانه بررسی شد.
- screening 0047: 16 accepted، 3 needs repair، 6 ambiguous؛ 28 رسانه بررسی شد.
- screening 0048: 19 accepted، 6 needs repair؛ سه crop آلوده قرنطینه شد.
- screening 0049: 10 accepted، 4 needs repair، 1 ambiguous؛ graph crop قرنطینه شد.
- screening 0050: 15 accepted، 3 needs repair، 7 ambiguous؛ 15 رسانه بررسی شد.
- screening 0051: 20 accepted، 4 needs repair، 1 ambiguous؛ دو رسانه بررسی شد.
- screening 0052: 15 accepted، 8 needs repair، 2 ambiguous؛ هر دو media ناسازگار قرنطینه شد.
- screening 0053: 11 accepted، 5 needs repair، 1 ambiguous؛ image نامرتبط سهمی قرنطینه شد.
- screening 0054: 18 needs repair، 1 ambiguous؛ 32 crop خراب/سفید/نامرتبط قرنطینه شد.
- screening 0055: 21 needs repair، 4 ambiguous؛ solutionها و graph cropهای نامرتبط قرنطینه شد.
- screening 0056: 25 needs repair؛ تمام solutionها با stem نامرتبط بودند.
- screening 0057: 21 needs repair، 4 ambiguous؛ solution/graph mismatchها قرنطینه شد.
- screening 0058: 7 accepted، 12 needs repair، 6 ambiguous؛ graph/option cropها قرنطینه شد.
- screening 0059: 7 accepted، 18 needs repair؛ graph/prose/token/formula mismatchها قرنطینه شد.
- screening 0060: 10 accepted، 15 needs repair؛ 30 asset بررسی و هر مورد ناقص fail closed شد.
- screening 0061: 16 accepted، 9 needs repair؛ 4 asset بررسی و solution/graph placeholderهای ناسازگار قرنطینه شد.
- screening 0062: 10 accepted، 11 needs repair، 1 ambiguous؛ 30 asset بررسی و cropهای misbound/نمودارِ ضروریِ گم‌شده قرنطینه شد.
- screening 0063: 3 accepted؛ 7 asset بررسی و همه hash-bound و خوانا بودند.
- screening 0065: 5 accepted، 15 needs repair، 5 ambiguous؛ هر دو asset خوانا و hash-bound بودند و rowهای ناقص fail closed ماندند.
- screening 0064: 2 accepted، 17 needs repair، 6 ambiguous؛ 24 asset بررسی و cropهای shifted/unrelated/ناقص قرنطینه شدند.
- screening 0066: 6 accepted، 14 needs repair، 5 ambiguous؛ 13 asset بررسی و cropهای نامرتبط/ناقص fail closed شدند.
- screening 0068: 2 needs repair؛ بدون asset وابسته و هر دو ردیف ناقص در قرنطینه ماندند.
- screening 0067: 5 accepted، 18 needs repair، 2 ambiguous؛ دو asset بررسی و graph crop ناقص قرنطینه شد.
- screening 0069: 9 accepted، 13 needs repair، 3 ambiguous؛ 9 asset بررسی و cropهای نامرتبط/مختصات ناسازگار قرنطینه شد.
- screening 0071: 10 accepted، 9 needs repair؛ دو asset خوانا بودند ولی mismatch گزینه/علامت و OCR ناقص در راه‌حل‌ها قرنطینه شد.
- screening 0070: 13 accepted، 12 needs repair؛ 16 asset بررسی شد. گیت merge ردیف 1599 را ناسازگار یافت و پس از بازبینی کور از accepted به needs repair منتقل شد.
- screening 0072: 13 needs repair، 12 ambiguous؛ 14 asset بررسی شد و همه solutionهای این batch نامرتبط بودند، پس هیچ ردیفی accepted نشد.
- screening 0073: 21 needs repair، 4 ambiguous؛ 8 asset بررسی و diagramهای ضروریِ crop‌شده/نامرتبط قرنطینه شد.
- screening 0074: 25 needs repair؛ بدون asset وابسته؛ solutionهای نامرتبط و exponentهای malformed قرنطینه شدند.
- screening 0075: 3 accepted، 19 needs repair؛ چهار asset خوانا و hash-bound، اما drift راه‌حل‌ها را تأیید کردند.
- screening 0076: 23 needs repair، 2 ambiguous؛ یک asset crop نامرتبط بود و diagram ضروریِ دیگری غایب بود؛ تمام solutionها نامرتبط ماندند.
- screening 0077: 24 needs repair، 1 ambiguous؛ asset از نظر hash درست اما از نظر محتوا نامرتبط و فاقد نمودار ضروری بود؛ همه solutionها drift داشتند.
- screening 0078: 25 needs repair؛ بدون asset وابسته؛ همه solutionها نامرتبط بودند.
- screening 0079: 13 needs repair؛ بدون asset وابسته؛ همه solutionها نامرتبط و یک نمودار ضروری مفقود بود.
- screening 0080: 6 needs repair؛ 35 asset بررسی شد؛ cropهای stem/option به‌طور سیستماتیک ناقص، سفید یا misaligned بودند.
- screening 0082: 7 needs repair؛ 35 asset بررسی شد؛ cropهای نامرتبط/ناقص و دو option تقریباً سفید قرنطینه شدند.
- screening 0083: 7 needs repair؛ 35 asset بررسی شد؛ همه cropها fragmentهای نامرتبط از صفحهٔ منبع بودند.
- screening 0081: 6 needs repair؛ 35 asset بررسی شد؛ stem و optionها fragmentهای truncate/نامرتبط بودند.
- screening 0084: 7 needs repair؛ 35 asset بررسی شد؛ cropها ناقص، نامرتبط، mismatch یا سفید بودند؛ تضاد 6-vs-5 balls نیز ثبت شد.
- screening 0085: 7 needs repair؛ 35 asset بررسی شد؛ همه cropها بریده، سفید یا نامرتبط بودند.
- screening 0086: 9 needs repair؛ 37 asset بررسی شد؛ همه assetها نامرتبط/بریده/سفید/mislabeled بودند؛ diagram ادعاییِ Venn یک تصویر ماشین‌حساب بود.
- screening 0087: 1 accepted، 16 needs repair؛ 33 asset بررسی شد؛ stem/optionها stripهای بریده یا blank بودند.
- screening 0088: 4 accepted، 21 needs repair؛ 19 asset بررسی شد؛ cropهای narrow/rotated/misaligned/blank/unrelated قرنطینه شدند.
- screening 0089: 9 needs repair؛ 35 asset بررسی شد؛ همه stripهای باریک و نامرتبط بودند و option تکراری نیز ثبت شد.
- screening 0090: 7 needs repair؛ 35 asset بررسی شد؛ optionهای blank/miscrop و solutionهای نامرتبط قرنطینه شدند.
- screening 0091: 6 needs repair؛ 30 asset بررسی شد؛ همه blank/strip نامرتبط بودند و تمام solutionها drift داشتند.
- screening 0092: 21 accepted، 4 needs repair؛ 19 asset بررسی شد؛ cropهای نامرتبط/mislabeled و یک مثال راه‌حل ناسازگار قرنطینه شدند.
- screening 0093: 8 accepted، 9 needs repair، 8 ambiguous؛ 29 asset بررسی شد؛ diagram/labelهای ضروری و solution media ناسازگار یا ناقص بودند.
- screening 0094: 2 accepted، 11 needs repair؛ 23 asset بررسی شد؛ solution assetهای نامرتبط/شدیداً بریده قرنطینه شدند.
- screening 0095: 9 needs repair؛ 36 asset بررسی شد؛ stem/option برای 2001 تا 2007 به‌طور سیستماتیک miscrop بودند.

## Remaining
- Luna screening/classification، freeze taxonomy، repair overlay evidence، solve/verify و runtime gate.
- source PDF و physical Focus Pen proof.

## Verification
- Analyzer و 94/94 tests پاس؛ Web و APK امضاشده پاس؛ data/media parity پاس.
- post-merge validate: 3672 source-bound، 2413 screened، 0 usable.
- repair queue: 2946 hash-bound tickets؛ 2659 blocking prompt/render و 287 correctness tickets؛ هیچ source حذف نشده است.
- active screening: next sequential batch after 0160; 0111/0112 remain unattested and unmerged.
- latest screening checkpoint: 3208/3672 (87.36%) taxonomy/extraction screened; 0 usable because solve, source-fidelity, and adversarial gates remain open.
- repair discipline: contradictory/internally inconsistent rows are reclassified, rehashed, and re-attested fail-closed; they are not discarded.
- محدودیت‌های اثبات در `05-verification.md` صریح ثبت شده‌اند.
