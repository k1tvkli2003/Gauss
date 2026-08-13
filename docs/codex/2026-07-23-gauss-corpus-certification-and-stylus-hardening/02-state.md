# State

- Current status: `active`
- Last updated: 2026-08-10T13:24:25+03:30
- Owner: Codex

## Current State
زیرساخت certification برای تمام corpus فعال است، اما حقیقت علمی هنوز
`0/3672 certified` و `0/3672 usable` است. baseline شامل ۲۲۰۲ pending و ۱۴۷۰
quarantined است. ۴۰۹ سؤال extraction blocker، پنج راه‌حل ناکافی، ۴۸۱ solution
page نامعتبر، ۳۵۳ mismatch تاریخی، ۳۲۲ missing-solution تاریخی، دو تناقض قطعی
و ۱۸ ردیف duplicate با کلید متعارض ثبت شده‌اند.

Snapshot فعلی 2026-08-09: هر ۳۶۷۲ ردیف screening/taxonomy/difficulty شده‌اند؛
۱۲۰۳ screening accepted، ۴۴۱ ambiguous و ۲۰۲۸ needs-repair هستند. manifest
فعلی ۲۷۹۱ ردیف quarantined و ۸۸۱ pending دارد و هنوز ۰ usable است. ledger
مشتق‌شدهٔ تعمیر اکنون ۲۶۹ overlay منبع‌نگهدار دارد. repair-044/045 در مجموع
۲۰ ردیف را با count/order/ID/hash gate تحویل دادند؛ حسابرسی کور مستقل ۱۸
addendum را پذیرفت و `nardebam_math_1405_1806` و
`nardebam_math_1405_1811` را به دلیل نبود پاسخ مشتق‌شده در گزینه‌های immutable
در قرنطینه نگه داشت. reconciliation بعدی repair-043/046 دو draft جدید
(`1883` و `1937`) افزود؛ ۱۸ خروجی دیگر همان overlayهای موجود بودند. برای
`nardebam_math_1405_0037` نیز توضیح نامرتبط دنباله با addendum مجموعه‌ها جایگزین
شد، ولی قید «غیرتهی» برای مجموعه‌های دلخواه تضمین‌پذیر نیست و رکورد همچنان
fail-closed است.

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
- تمام screening batchها با binding به source hash ادغام و taxonomy/difficulty
  هر ۳۶۷۲ ردیف ثبت شده است.
- ۲۶۹ source-preserving repair overlay از خروجی‌های ساختاری و حسابرسی‌شدهٔ
  مستقل؛ هیچ source JSON/media تغییر نکرده است.
- parser/render compatibility و display-math layout.
- Focus Pen/palm/multitouch/controller/performance fixes.
- analyzer، ۹۴ تست، Web build، signed APK و artifact parity.

## Remaining
- حل، تعمیر و داوری علمی ردیف‌های باقیمانده؛ ۳۶۲۲ answer هنوز `source_only`
  و ۳۶۱۵ solution هنوز `pending` است.
- repair overlay برای extraction/solution/key conflicts.
- runtime admission فقط برای certified records.
- physical-device Focus Pen validation و source-PDF fidelity.

## Current authoritative snapshot — 2026-08-13

The prior snapshot above is retained as history. The current validated state is
`50/3672 certified + usable`, `881 pending`, and `2741 quarantined`.
Screening remains complete for all source-bound records (`1205 accepted`, `441
ambiguous`, `2026 needs_repair`). The corpus still has `3620 source_only`
answers and `3613 pending` solutions, so full-dataset usability remains the
dominant Goal blocker.

Question `nardebam_math_1405_0088` has now been rechecked against exact source
PDF and page-render hashes. Its stem, four options, source key, and complete
solution match; its taxonomy is explicitly registered as
`patterns_sequences_geometric`. This closes an evidence-cohort omission, not a
source-content defect. The generic evidence promoter now preserves receipts
outside its own cohort, and certified runtime contract
`a617d5049cd0baf2ad9d9d43aa576d3310d15a7fc81716fcb2ac6f9a2dbfa79d`
also binds the embedded-media numeral receipt ledger.

The display-language contract is now enforced rather than assumed: product
chrome is English/LTR under a Persian Android device locale, while source
question/answer/solution prose remains locally RTL. All live learning strings
normalize Eastern Arabic/Persian numerals and separators to ASCII at the view
boundary. Embedded question media is stricter: a mission-ready image now needs
a hash-bound `no_digits` or `ascii_only` receipt, otherwise certification
validation fails closed. The current 49 usable questions contain no embedded
media, so this new rule preserves their admission without weakening the gate.

## Owner-approved provisional runtime policy — 2026-08-13

The owner explicitly changed runtime admission: every structurally valid source
question must remain playable now, while scientific repair continues as a
separate quality track. This does **not** relabel pending rows as certified.

- Runtime-playable: `3672/3672` immutable source rows.
- Hash-bound scientifically certified: `51/3672` rows.
- Curriculum coverage: `744` exact five-question lessons, `3720` total slots,
  and `48` explicitly marked mastery-review fills for topic remainders.
- Primary coverage: all `3672` source IDs appear exactly once as a primary slot.
- Map and Study entry actions now open the exact five-question mission even
  when some rows are provisional; no certified substitute is injected.
- Resume, review, and revenge queues retain provisionally usable rows instead
  of silently retiring them because certification is pending.
- Source answer keys and source solutions are shown provisionally. Certified
  rows keep their reviewed effective key and verified-solution badge.
- Every mission question exposes an offline `Report question issue` action.
  Reports append question ID, topic, issue category, optional note, session,
  lesson position, selected choice, and timestamp to local storage. Reporting
  never edits, deletes, hides, or automatically reclassifies source content.

The certification manifest, repair queue, receipts, source JSON, and source
media remain unchanged and continue to describe scientific confidence. Their
pending/quarantined labels are now audit metadata rather than runtime access
control under this private single-user policy.
