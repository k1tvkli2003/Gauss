# State

- Current status: `active`
- Last updated: 2026-07-23T16:41:06+03:30
- Owner: Codex

## Current State
زیرساخت certification برای تمام corpus فعال است، اما حقیقت علمی هنوز
`0/3672 certified` و `0/3672 usable` است. baseline شامل ۲۲۰۲ pending و ۱۴۷۰
quarantined است. ۴۰۹ سؤال extraction blocker، پنج راه‌حل ناکافی، ۴۸۱ solution
page نامعتبر، ۳۵۳ mismatch تاریخی، ۳۲۲ missing-solution تاریخی، دو تناقض قطعی
و ۱۸ ردیف duplicate با کلید متعارض ثبت شده‌اند.

Renderer تمام ۳۶۷۲ سؤال، ۲۲۰۳۲ text block و بیش از ۳۷هزار TeX segment را parse
می‌کند. Focus Pen path فشار، cancel rollback، exact palm rollback و multi-touch
ownership را دارد. Web 1.0.107 و APK امضاشدهٔ 1.0.107 ساخته و content parity
آن‌ها اثبات شده است.

## Decisions
| Date | Decision | Reason | Source |
|---|---|---|---|
| 2026-07-23 | source JSON/media immutable می‌مانند | preservation contract و امکان audit | user + repo |
| 2026-07-23 | کلید اشتباه فقط با effective overlay اصلاح می‌شود | source key ممکن است غلط باشد | forensic audit |
| 2026-07-23 | Luna فقط screening/classification است | مدل screening correctness proof نیست | user + certification architecture |
| 2026-07-23 | batchها topic-confined و weighted هستند | context drift و cross-topic leakage کاهش می‌یابد | implementation |
| 2026-07-23 | Android pointerId با `PointerEvent.device` route می‌شود | Flutter engine همین field را از MotionEvent.pointerId می‌سازد | engine source |

## Blockers
- Original PDF paths/variables در environment فعلی موجود نیستند؛ owner: local
  source configuration؛ unblock: resolve اصل PDFها بدون تغییر corpus.
- Gauss در Jules Sources متصل نیست؛ owner: Jules external source state؛ تا اتصال
  هیچ session سهمیه‌سوز ساخته نمی‌شود.
- Xiaomi Focus Pen physical proof نیازمند دستگاه واقعی است؛ software path همچنان
  با tests و Android API contract جلو می‌رود.

## Done
- canonical/runtime/media hashes و deterministic manifest.
- exact forensic queues و corrected certification evidence model.
- ۱۷۹ Luna input batch، بدون cross-topic.
- parser/render compatibility و display-math layout.
- Focus Pen/palm/multitouch/controller/performance fixes.
- analyzer، ۹۴ تست، Web build، signed APK و artifact parity.

## Remaining
- اجرای ۱۷۹ batch Luna و freeze taxonomy.
- حل و داوری علمی ۳۶۷۲ پاسخ و راه‌حل.
- repair overlay برای extraction/solution/key conflicts.
- runtime admission فقط برای certified records.
- physical-device Focus Pen validation و source-PDF fidelity.
