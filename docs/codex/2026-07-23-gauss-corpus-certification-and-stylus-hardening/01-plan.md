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
| 4 | active | Luna Medium discovery screening برای ۳۶۷۲ سؤال |
| 5 | planned | freeze زیرمبحث‌ها و classification pass با registry ثابت |
| 6 | planned | blind solve، fresh verifier، solution audit و adversarial review |
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
- Gauss در منابع Jules متصل نیست؛ session بی‌دسترسی عمداً ساخته نشد.
- خروجی model می‌تواند اشتباه باشد؛ merge با attestation و داوری مستقل fail-closed است.
- Focus Pen واقعی در دسترس نیست؛ hardware latency/pressure curve هنوز اثبات نشده است.

## Acceptance Checks
- manifest دقیقاً ۳۶۷۲ ID و media manifest دقیقاً ۳۴۱۰ فایل داشته باشد.
- batchها هرگز topic را cross نکنند و max weight را رد نکنند.
- static blocker توسط screening پذیرفته نشود.
- کل Flutter suite و release artifact verifier pass شوند.
