# Orrery of Proofs — قرارداد هویت و دارایی

## جهت نهایی

- Modernization mode: `Radical rebuild + Showpiece`
- Mental model: رصدخانه‌ی شخصی و اورری‌ای که حل مسئله را به نقشه‌ی تسلط تبدیل می‌کند.
- Material thesis: برنج کهنه، فولاد آبی تیره، سنگ آتشفشانی، کاغذ عاجی، نور کهربایی و سیگنال فیروزه‌ای.
- Product promise: **Chart what you can prove.**
- Supporting line: **Every solved question lights the map.**
- Companion: **Mira**، اتوماتون آرام و غیرقضاوتی با دو state تولیدشده‌ی thinking و correct.
- Brand mark: **Theorem Star**؛ حلقه‌ی باز G و چهار پایانه‌ی هندسی premise → construction → inference → conclusion دور هسته‌ی فیروزه‌ای.
- Typography: **Manrope** برای chrome انگلیسی، **Vazirmatn** برای فارسی، و wordmark هنری فقط برای سطوح برند.

## قواعد اجراشده

- کنترل، سؤال، جواب، شمارنده، progress، focus، CTA و semantics هرگز داخل raster پخته نشده‌اند.
- texture، ماشین مرکزی، پوسته‌ی node، landmark و شخصیت asset هستند؛ path و state overlay زنده‌اند.
- iconهای عملکردی یک خانواده‌ی vector اختصاصی دارند؛ fallback عمومی Material فقط جایی استفاده می‌شود که معنای استاندارد سیستم از craft مهم‌تر است.
- wordmark تصویری همیشه semantic label `Gauss` دارد.
- mark نهایی vector-first است و به adaptive icon، monochrome themed icon، nav/map glyph و reward seal گسترش یافته است.

## Manifest نهایی

| ID | نوع | مسیر | اندازه | مصرف‌کننده‌ی runtime | وضعیت |
|---|---|---|---:|---|---|
| `gauss_wordmark` | transparent PNG | `flutter_app/assets/visual/brand/gauss_wordmark.png` | 332,535 B | startup/HUD/mission/completion | integrated |
| `theorem_star` | SVG + Flutter vector + Android vector | `flutter_app/assets/visual/brand/theorem_star.svg` | 1,316 B | brand glyphs, seals, launcher/splash | integrated |
| `orrery_atmosphere` | portrait PNG | `flutter_app/assets/visual/map/orrery_atmosphere_portrait.png` | 2,564,948 B | map/mission/insights background crops | integrated |
| `theorem_engine` | transparent PNG | `flutter_app/assets/visual/map/theorem_engine.png` | 2,173,832 B | central map landmark | integrated |
| `topic_shell` | transparent PNG | `flutter_app/assets/visual/nodes/topic_shell.png` | 1,332,977 B | all topic nodes + live overlays | integrated |
| `boss_observatory` | transparent PNG | `flutter_app/assets/visual/nodes/boss_observatory.png` | 1,859,406 B | boss/landmark vocabulary | integrated |
| `mira_thinking` | transparent PNG | `flutter_app/assets/visual/mascot/mira_thinking.png` | 1,195,142 B | mission support + low-score completion | integrated |
| `mira_correct` | transparent PNG | `flutter_app/assets/visual/mascot/mira_correct.png` | 1,119,570 B | correct/high-score feedback | integrated |
| `custom_glyphs` | Flutter paths | `flutter_app/lib/widgets/gauss_brand.dart` | source | nav/topic/scratchpad/achievements | integrated |
| `adaptive_icon` | Android vector layers | `flutter_app/android/app/src/main/res/` | platform | circle/squircle/round/themed launcher | integrated |

## هندسه و crop

- Map master space normalized `0..1` است و node placement از asset مستقل می‌ماند.
- موبایل: theorem engine در مرکز روایت، HUD در safe top، mission dock و navigation در safe bottom، مسیر عمودی قابل scroll.
- تبلت landscape: rail چپ، scene مرکزی radial، inspector راست؛ ring radii نهایی `.18 / .275 / .36` و center Y برابر `.54` است تا همه‌ی 29 node از HUD و لبه‌ها فاصله داشته باشند.
- تبلت mission: سؤال فضای اصلی را می‌گیرد و Mira در supporting pane جداست؛ UI موبایل صرفاً scale-up نشده است.
- `cacheWidth` متناسب با مصرف‌کننده برای تصاویر محتوایی استفاده می‌شود تا decode بی‌جهت در اندازه‌ی کامل رخ ندهد.

## State contract گره

| State | ماده / نور | path | semantics |
|---|---|---|---|
| locked | سنگ سرد و نور خاموش | کم‌رنگ | Locked + prerequisite |
| available | لبه‌ی برنجی آرام | مسیر پیشین روشن | Available |
| current | برنج گرم و halo کهربایی | segment فعال | Current chapter |
| completed | patina فیروزه‌ای | مسیر پر | Completed + score |
| mastered | ivory/gold seal | gold/teal | Mastered |
| reference-only | desaturated + shield | signal قطع | Reference only + reason |

## پذیرش

- silhouette نشان و glyphها در اندازه‌ی کوچک خواناست.
- هیچ متن یا watermark ناخواسته در assetها وجود ندارد.
- familyهای asset material، نور و camera مشترک دارند.
- alpha edge روی background runtime بررسی شده است.
- circle/squircle/round و monochrome icon با contract test پوشش داده شده‌اند.
- همه‌ی assetهای manifest مصرف‌کننده‌ی runtime و screenshot release دارند.
