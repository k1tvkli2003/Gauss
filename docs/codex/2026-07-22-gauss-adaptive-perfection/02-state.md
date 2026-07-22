# State

- Current status: `ready-for-review`
- Last updated: 2026-07-23T02:00:00+03:30
- Owner: Codex

## Current State
پیاده‌سازی و گیت‌های release تکمیل شده‌اند. analyzer بدون issue و suite کامل 86/86 پاس شده است؛ web release و APK امضاشدهٔ 1.0.106 از revision نهایی ساخته شده‌اند. داده، media و مسیر upgrade درجا دوباره اثبات شده‌اند.

## Decisions
| Date | Decision | Reason | Source |
|---|---|---|---|
| 2026-07-22 | Orrery/Theorem Star/wordmark حفظ شوند | کاربر جهت و icon را قبلاً انتخاب کرده است | user + accepted assets |
| 2026-07-22 | dark-only، English chrome و single-user/offline-first | قیود قطعی محصول | user + project AGENTS.md |
| 2026-07-22 | window classes برابر 600/1024/1440 | رفع drift و پوشش phone/tablet/desktop | accepted plan + Critics finding 01 |
| 2026-07-22 | Study Room در فضای کافی دوپنجره‌ای و در compact تک‌ستونه باشد | کاهش scroll/context loss بدون شکنندگی 600dp | anatomy + layout constraints |
| 2026-07-22 | performance فقط با شرایط comparable گزارش شود | emulator معیار battery/thermal نیست | performance skill |
| 2026-07-22 | imagegen اجرا نشود | direction و identity از قبل پذیرفته شده‌اند | user-approved previews |
| 2026-07-23 | رفرنس Map کاربر به copy contract تبدیل شود | مسیر طلایی، instrumentهای بزرگ، HUD فشرده و labelهای زنده باید در runtime دیده شوند، نه یک screenshot بیک‌شده | user reference + `$copy` |
| 2026-07-23 | پس از بسته‌شدن tour، Map به ابتدای مسیر بازگردد | انتقال focus نباید نمای نخست مسیر را به dock پایین ببرد | runtime screenshot loop |

## Blockers
- دستگاه Android فیزیکی فعلاً در دسترس نیست؛ نتیجهٔ battery/thermal/GPU blocked نیست، بلکه صریحاً خارج از claim نهایی می‌ماند.

## Done
- Critics baseline JSON/Markdown/PDF بیرون از ریپو؛ PDF ۱۶ صفحه‌ای کاملاً بازبینی شد.
- preservation/function/surface inventory و accepted-reference capture.
- Map copy loop با رفرنس کاربر، web phone/tablet و Android phone/tablet runtime capture.
- analyzer، 86 تست، web release، APK signed و upgrade واقعی 105→106.

## Remaining
- PDF نهایی RTL، completion audit، commit و push روی `main`.
