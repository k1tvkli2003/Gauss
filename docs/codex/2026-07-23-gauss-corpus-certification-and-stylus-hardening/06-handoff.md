# Handoff

## Outcome
Checkpoint اجرایی: preservation، renderer، Focus Pen path، certification schema،
forensic queues، weighted Luna batches و release proof تکمیل شده‌اند. محتوای علمی
هنوز عمداً `0 certified / 0 usable` است و کار ادامه دارد. Batch نخست Luna Medium
با 25 سؤال و 19 رسانه اجرا و ادغام شده است.

## Changed Artifacts
- `data/certification/v1/`
- `scripts/corpus_certification.mjs`
- `flutter_app/lib/widgets/content_blocks.dart`
- `flutter_app/lib/widgets/scratchpad.dart`
- `flutter_app/android/app/src/main/kotlin/com/gauss/app/MainActivity.kt`
- renderer/stylus tests

## How To Continue
- batch 0001 با attestation
  `codex-luna-medium-screening-0001-20260723` ادغام شده است.
- batch بعدی `screening-0002` را دقیقاً با `LUNA_SCREENING_PROMPT.md` و یک
  runtime attestation مستقل در همین thread اجرا کنید.
- پس از هر merge، `validate` و `summarize` اجرا و batch بعدی از index انتخاب شود.

## Done
- تمام موارد بخش Outcome و release checkpoint 1.0.107.
- screening 0001: 6 accepted، 17 needs repair، 2 ambiguous؛ 15 incomplete و 2 ambiguous extraction.

## Remaining
- Luna screening/classification، freeze taxonomy، solve/verify/repair و runtime gate.
- source PDF و physical Focus Pen proof.

## Verification
- Analyzer و 94/94 tests پاس؛ Web و APK امضاشده پاس؛ data/media parity پاس.
- post-merge validate: 3672 source-bound، 25 screened، 0 usable.
- محدودیت‌های اثبات در `05-verification.md` صریح ثبت شده‌اند.
