# Handoff

## Outcome
Checkpoint اجرایی: preservation، renderer، Focus Pen path، certification schema،
forensic queues، weighted Luna batches و release proof تکمیل شده‌اند. محتوای علمی
هنوز عمداً `0 certified / 0 usable` است و کار ادامه دارد.

## Changed Artifacts
- `data/certification/v1/`
- `scripts/corpus_certification.mjs`
- `flutter_app/lib/widgets/content_blocks.dart`
- `flutter_app/lib/widgets/scratchpad.dart`
- `flutter_app/android/app/src/main/kotlin/com/gauss/app/MainActivity.kt`
- renderer/stylus tests

## How To Continue
- اولین output باید در
  `data/certification/v1/batches/screening/screening-0001.output.jsonl` نوشته شود.
- runtime attestation واقعی Codex برای همان batch ثبت شود.
- سپس `node scripts/corpus_certification.mjs merge-screening --batch=screening-0001 --attestation=<id>` اجرا شود.
- پس از هر merge، `validate` و `summarize` اجرا و batch بعدی از index انتخاب شود.

## Done
- تمام موارد بخش Outcome و release checkpoint 1.0.107.

## Remaining
- Luna screening/classification، freeze taxonomy، solve/verify/repair و runtime gate.
- source PDF و physical Focus Pen proof.

## Verification
- Analyzer و 94/94 tests پاس؛ Web و APK امضاشده پاس؛ data/media parity پاس.
- محدودیت‌های اثبات در `05-verification.md` صریح ثبت شده‌اند.
