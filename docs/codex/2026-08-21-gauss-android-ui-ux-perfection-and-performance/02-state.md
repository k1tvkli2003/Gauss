# وضعیت

- Current status: `active`
- Last updated: 2026-08-21T18:06:19+03:30
- Owner: Codex
- Baseline revision: `f3edce84a54a89f1be3051ff435659e26d1e9e7c`
- Current phase: P0 — Baseline، instrumentation و preservation
- Goal progress: 0% until P0 gate passes
- Product-readiness estimate: 60–65%

## Current State

سند اجرایی این چرخه بر پایه کد، screenshot و تست‌های فعلی تدوین و به Goal فعال همین thread تبدیل شده است. جهت بصری قبلاً توسط کاربر برای Map و Astral Manuscript تأیید شده، بنابراین concept انتخابی تازه لازم نیست. defectهای اصلی در Map rendering/scroll ownership، bottom chrome، تراکم header، question rebuild scope و stylus/touch interaction مشخص شده‌اند. اجرای P0 آغاز شده است.

## Decisions

| تاریخ | تصمیم | دلیل | منبع |
|---|---|---|---|
| 2026-08-21 | یک task تازه برای این چرخه ساخته شود | اسناد July پایان نسخه‌های قبلی را ثبت کرده‌اند و نباید evidence تازه را با آن‌ها مخلوط کرد | work-docs contract + repo state |
| 2026-08-21 | Map renderer و question interaction بازسازی عمیق شوند | polish ظاهری علت اسکرول و rebuild را رفع نمی‌کند | source inspection + runtime screenshots |
| 2026-08-21 | accepted Orrery/Astral previews حفظ شوند | جهت محصول انتخاب شده و نیاز به نظرخواهی تازه نیست | user-approved references |
| 2026-08-21 | Android تنها release target این چرخه باشد | دامنه صریح پروژه | user + project AGENTS.md |
| 2026-08-21 | داده، media، IDs، auth و progress بدون reset حفظ شوند | قرارداد محصول و ریسک داده | user + current architecture |
| 2026-08-21 | performance فقط با سناریو و شرایط هم‌سان ادعا شود | probe نرم‌افزاری قدیمی نماینده device واقعی نیست | performance contract |
| 2026-08-21 | این Goal بدون subagent اجرا شود | دستور پروژه تا اجازه صریح تازه | project AGENTS.md |
| 2026-08-21 | `01-plan.md` objective الزام‌آور Goal همین thread باشد | جلوگیری از drift بین برنامه و اجرا | user request + active Goal |

## Blockers

- دستگاه ADB در لحظه baseline متصل نیست. P0 تا P6 با `Codex_API35` و تست‌های Flutter قابل پیشروی است؛ ادعای physical-device تا اتصال دستگاه ساخته نمی‌شود.

## Done

- skill contracts مربوط به work docs، modernization، responsive fidelity، identity/asset fidelity، execution economy و performance خوانده شد.
- repo، task history، current screenshots و hot files بررسی شد.
- دو screenshot runtime فعلی به‌عنوان baseline در `assets/` فریز شد.
- برنامه مرحله‌ای، وزن Goal، acceptance matrix، preservation contract و performance budgets نوشته شد.

## Remaining

- اجرای P0 تا P7 و به‌روزرسانی پیوسته state/progress/verification.
- commit و push فقط پس از validation سند و سپس در پایان هر فاز پذیرفته‌شده.
