# Plan

## Approach
ابتدا baseline با Critics فریز شد. سپس foundation مشترک ساخته می‌شود و هر سطح در چرخهٔ «سه candidate → انتخاب بیشترین اثر → patch → test → screenshot critique» بهبود می‌یابد. منطق دامنه و داده تغییر نمی‌کند؛ لایهٔ adaptive و presentation در برش‌های کوچک و قابل‌راستی‌آزمایی اصلاح می‌شود.

## Steps
| Step | Status | Notes |
|---|---|---|
| 1 | done | ممیزی read-only، opinion ledger، preservation contract و PDF ۱۶ صفحه‌ای فریز شدند. |
| 2 | active | `GaussWindowClass`، tokenهای layout/type/control/motion و contrast foundation. |
| 3 | planned | App shell، Map inset/inspector و Study 1/2×2/4 + atlas محتوامحور. |
| 4 | planned | Study Room دوپنجره‌ای، ink gesture coordination و scratch sheet adaptive. |
| 5 | planned | Insights medium hierarchy، Vault/state polish و accessibility sweep. |
| 6 | planned | performance before/after، تست ماتریسی، Android/Chrome screenshots و mismatch closure. |
| 7 | planned | docs/PDF نهایی، release artifacts، commit و push `main`. |

## Interfaces and Artifacts
- `flutter_app/lib/app/gauss_design_system.dart`
- `flutter_app/lib/app/gauss_theme.dart` و `gauss_app.dart`
- `map_screen.dart`، `practice_screen.dart`، `archive_screen.dart`، `insights_screen.dart`
- `scratchpad.dart` و تست‌های `android_experience_test.dart` / `study_experience_test.dart`
- این task docs، screenshot assets و verification logs

## Risks
- تغییر breakpoint می‌تواند viewport مفید را با rail/inspector کوچک کند؛ در مرزهای دقیق تست می‌شود.
- دوپنجره‌ای‌کردن Study Room ممکن است focus order یا scroll ownership را بشکند؛ semantics و keyboard/touch جداگانه بررسی می‌شوند.
- بزرگ‌کردن متن‌های micro ممکن است overflow پنهان ایجاد کند؛ text scale 2.0 و mixed Persian/English معیار blocking است.
- visual assets و blur ممکن است raster cost داشته باشند؛ فقط تغییر trace-supported نگه داشته می‌شود.

## Acceptance Checks
- data/media contract tests دقیقاً همان شمارش و bytes را حفظ کنند.
- 599/600/1023/1024/1439/1440، 320×568، 390×844، 768×1024، 1024×768 و 1440×900 بدون exception/overflow.
- touch targets ≥48dp؛ متن عادی ≥4.5:1؛ reduced motion و 200% text سالم.
- Map/Study/Insights/Study Room/Vault actions، routes و persistence واقعی کار کنند.
- `dart analyze --fatal-infos`، `flutter test`، Android release و Web release پاس شوند.
