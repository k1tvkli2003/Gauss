# Plan

## Approach
فرایند fail-closed و evidence-led است: ابتدا preservation و mirror integrity،
سپس screening دوپاس taxonomy، بعد حل/verification علمی، و در پایان runtime
admission فقط برای certified overlay. هیچ رأی مدل به‌تنهایی proof محسوب نمی‌شود.

## Steps
| Step | Status | Notes |
|---|---|---|
| 1 | done | canonical/runtime/media freeze و SHA-256 reconciliation |
| 2 | done | Persian/TeX parser hardening و Focus Pen scratch hardening |
| 3 | done | schema، baseline، risk queues، validator و ۱۷۹ shard وزنی |
| 4 | done | Luna Medium discovery screening برای هر ۳۶۷۲ سؤال با attestation مستقل merge شد. |
| 5 | active | taxonomy و difficulty برای هر ۳۶۷۲ سؤال screen شده‌اند؛ freeze registry و تثبیت زیرمبحث‌ها باقی است. |
| 6 | active | blind solve، fresh verifier، solution audit و adversarial review آغاز شده‌اند؛ ۵۰ answer و ۴۸ solution/review کاملِ مستقل ثبت شده و repair draftها هنوز promotion نیستند. |
| 7 | planned | certified overlay و fail-closed Flutter admission |
| 8 | active | analyzer/test/build/runtime/docs/release evidence |

## Interfaces and Artifacts
- `data/certification/v1/`
- `scripts/corpus_certification.mjs`
- `flutter_app/lib/widgets/content_blocks.dart`
- `flutter_app/lib/widgets/scratchpad.dart`
- Android channel `com.gauss.app/stylus_input`

## Risks
- PDF اصلی در environment فعلی resolve نشده؛ source-fidelity نهایی نمی‌تواند pass شود.
- اتصال Jules در این window پاسخ پایدار نمی‌دهد؛ هفت session موجود repair-011 تا repair-017 بدون ساخت session تازه منتظر harvest هستند.
- خروجی model می‌تواند اشتباه باشد؛ merge با attestation و داوری مستقل fail-closed است.
- Focus Pen واقعی در دسترس نیست؛ hardware latency/pressure curve هنوز اثبات نشده است.

## Acceptance Checks
- manifest دقیقاً ۳۶۷۲ ID و media manifest دقیقاً ۳۴۱۰ فایل داشته باشد.
- batchها هرگز topic را cross نکنند و max weight را رد نکنند.
- static blocker توسط screening پذیرفته نشود.
- کل Flutter suite و release artifact verifier pass شوند.
