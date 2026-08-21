# وضعیت

- Current status: `active`
- Last updated: 2026-08-21T21:06:32+03:30
- Owner: Codex
- Baseline revision: `f3edce84a54a89f1be3051ff435659e26d1e9e7c`
- Current phase: P2 — Map scroll/render engine
- Goal progress: 15%
- Product-readiness estimate: 63–68%

## Current State

P0 با harness ایزولهٔ profile روی تنها AVD مجاز بسته شد. P1 نیز جهت پذیرفته‌شدهٔ Orrery/Astral را به token ramp، production layer manifest، repaint ownership، responsive occupancy، safe-area contract، state matrix، Motion Bible و acceptance positions قابل‌آزمون تبدیل کرد. P2 اکنون علت اصلی benchmark یعنی stage یک‌تکه، scroll-driven rebuild و raster tail سنگین Map را بازسازی می‌کند.

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
| 2026-08-21 | evidence runner از package ایزولهٔ `com.gauss.app.profile` استفاده کند | نسخهٔ شخصی و dataDir آن در هیچ run پاک، uninstall یا overwrite نشود | package metadata guard |
| 2026-08-21 | CTA سناریوی performance بر اساس orientation انتخاب شود | phone/portrait از dock و landscape از Study Inspector استفاده می‌کند | responsive runtime evidence |
| 2026-08-21 | raw timelineهای چندمگابایتی در Git ذخیره نشوند | summary، screenshot و metadata کافی و raw evidence بازتولیدپذیر است | evidence hygiene |
| 2026-08-21 | raster فقط decoration و live truth همیشه semantic بماند | reference نباید progress، text، ID یا control را به تصویر تخت تبدیل کند | `07-ui-system-and-production-manifest.md` |
| 2026-08-21 | Map route به viewport band با geometry cache مهاجرت کند | baseline raster-bound و full-stage invalidation است | P1 manifest + P0 benchmark |

## Blockers

- blocker اجرایی برای P1 وجود ندارد.
- Xiaomi Focus Pen فیزیکی در این baseline در دسترس نبود؛ stylus contract روی Android با `PointerDeviceKind.stylus` اثبات شده، اما latency و palm rejection سخت‌افزاری تا P7 یک physical-device gate باقی می‌ماند.

## Done

- skill contracts مربوط به work docs، modernization، responsive fidelity، identity/asset fidelity، execution economy و performance خوانده شد.
- repo، task history، current screenshots و hot files بررسی شد.
- دو screenshot runtime فعلی به‌عنوان baseline در `assets/` فریز شد.
- برنامه مرحله‌ای، وزن Goal، acceptance matrix، preservation contract و performance budgets نوشته شد.
- harness profile ایزوله، runner پنج‌باره، semantics probe، stylus synthesis و aggregate summarizer ساخته و analyze شدند.
- پنج run phone با status پاس، semantic IDs معتبر و حفظ کامل package اصلی ثبت شد.
- tablet portrait و landscape واقعی روی `1280×800dp`/`800×1280dp` ثبت شدند؛ هر دو journey نهایی پاس شدند و تنظیمات AVD به `1080×2400 @ 420dpi` برگشت.
- corpus gate با `3672` source-bound record و asset inventory با `3461` فایل بدون mutation ثبت شد.
- P1 Design DNA و precision ledger به توکن‌های Flutter تبدیل شد؛ contrast، ramp، breakpoints، manifests و acceptance matrix با 32 regression test پاس شدند.

## Remaining

- اجرای P2 تا P7 و به‌روزرسانی پیوسته state/progress/verification.
- commit و push فقط پس از validation سند و سپس در پایان هر فاز پذیرفته‌شده.
