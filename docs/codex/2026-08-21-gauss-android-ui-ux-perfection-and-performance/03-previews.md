# پیش‌نمایش‌ها و baseline بصری

## سیاست

رفرنس یا concept تا زمانی که با اجرای واقعی مقایسه نشده proof نیست. screenshotهای runtime فعلی فقط baseline «قبل» هستند و موفقیت نسخه نهایی را ثابت نمی‌کنند. همه متن، داده، progress و controlها در محصول نهایی live و semantic می‌مانند.

## دفتر پیش‌نمایش

| نام | نوع | منبع | تأیید | لینک | کاربرد |
|---|---|---|---|---|---|
| Gauss Orrery Map | User-approved visual reference | تصویر انتخابی کاربر | direction approved؛ runtime proof خیر | [normalized reference](../2026-08-02-android-perfect-cycle/assets/comparison/gauss-map-reference-normalized-1080x2400.png) | مسیر پیوسته، Map-first، node/landmark، brass/teal و chrome شناور |
| Astral Manuscript | User-approved mock preview | concept انتخابی کاربر | direction approved؛ runtime proof خیر | [accepted concept](../2026-08-02-android-perfect-cycle/assets/concepts/question-astral-codex-v1.png) | manuscript واحد، قلم روی سؤال، answer rails و bottom instrument |
| Current Map | Android runtime baseline | app در worktree فعلی | yes برای baseline؛ no برای acceptance نهایی | [baseline Map](assets/baseline-map-f3edce8.png) | شاهد شلوغی header، label hierarchy و bottom obstruction |
| Current Mission | Android runtime baseline | app در worktree فعلی | yes برای baseline؛ no برای acceptance نهایی | [baseline Mission](assets/baseline-mission-f3edce8.png) | شاهد dead space، tool dominance، option spacing و dock size |
| Profile Phone Map | Android profile baseline | `Codex_API35`، 1080×2400 | yes برای P0 baseline | [phone Map](logs/performance-baseline-08a7817/run-01/map.png) | مرجع before برای Map، chrome و bottom obstruction |
| Profile Phone Mission | Android profile baseline | `Codex_API35`، 1080×2400 | yes برای P0 baseline | [phone Mission](logs/performance-baseline-08a7817/run-01/mission.png) | مرجع before برای prompt، ink، answers و solve dock |
| Tablet Portrait Map/Mission | Android profile baseline | 800×1280dp | yes برای P0 baseline | [portrait Map](logs/performance-tablet-portrait-08a7817/run-01/map.png)، [portrait Mission](logs/performance-tablet-portrait-08a7817/run-01/mission.png) | فضای عمودی مرده و کشیدگی phone composition را آشکار می‌کند |
| Tablet Landscape Map/Mission | Android profile baseline | 1280×800dp | yes برای P0 baseline | [landscape Map](logs/performance-tablet-landscape-798aa03/run-01/map.png)، [landscape Mission](logs/performance-tablet-landscape-798aa03/run-01/mission.png) | rail/inspector درست است؛ density و scroll/answer workspace هنوز P3–P5 work queue است |
| P4 Manuscript — blank phone | Android Profile runtime checkpoint | `df7b17e`، `Codex_API35`، 1080×2400 | yes برای vertical slice phone؛ نه برای گیت کامل P4 | [blank manuscript](assets/p4-manuscript-blank-phone.webp) | prompt، فضای reasoning جمع‌شونده، چهار answer rail و dock مستقل |
| P4 Manuscript — ink phone | Android Profile runtime checkpoint | `df7b17e`، `Codex_API35`، 1080×2400 | yes برای ink ownership/tool-state slice؛ نه برای hardware latency | [ink manuscript](assets/p4-manuscript-ink-phone.webp) | tool spine زمینه‌ای، ink زنده و نبود کنترل تکراری در action dock |
| P4 Manuscript — review phone | Android Profile runtime checkpoint | `16160f7`، `Codex_API35`، 1080×2400 | yes برای answer→review phone؛ نه برای گیت کامل P4 | [review manuscript](assets/p4-manuscript-review-phone.webp) | پاسخ درست، reflection و solution روی یک parchment؛ بازگشت خودکار Finger Ink به Touch Scroll |
| P4 Performance run — map/mission | Android Profile exact-revision | `3f2cddb`، `Codex_API35`، 1080×2400 | yes برای journey/matrix runtime؛ نه برای completion-only capture یا hardware pen | [run map](logs/performance-p4-final-3f2cddb/run-01/map.png)، [run mission](logs/performance-p4-final-3f2cddb/run-01/mission.png) | پنج run پاس؛ ownership/review/performance با aggregate و visual sample قابل بازبینی است |

## قرارداد مرجع Map

- حفظ: صحنه نجومی عمیق، مسیر یکپارچه، instrumentهای بزرگ، nodeهای قابل لمس و هویت Gauss.
- اصلاح لازم: header سبک‌تر، subject switch واضح، labelهای خوانا، path با frame pacing بهتر، یک bottom context layer و footer content-hugging.
- ممنوع: screenshot بیک‌شده به‌جای Map زنده، dashboard card، generic glass slab یا labelهای غیر semantic.

## قرارداد مرجع Question

- حفظ: parchment یکپارچه، قلم مستقیم، چهار پاسخ حک‌شده و عمل اصلی نمادین.
- اصلاح لازم: app chrome انگلیسی، prompt/answer density بهتر، reasoning space قابل گسترش، tool rail adaptive و scroll لمسی بی‌نقص.
- ممنوع: flatten کردن سؤال/پاسخ، چهار card عمومی، toolbar متنی سنگین یا از دست‌رفتن ink هنگام expand/rotate.

## Mock Preview: Astral Manuscript

- Label: Mock Preview
- Source: user-selected concept preserved in the prior task assets
- Assumptions: همه متن‌ها، اعداد، stateها و کنترل‌ها در production زنده و semantic خواهند بود.
- Limitations: تصویر، proof runtime یا مختصات ثابت یک دستگاه نیست و app chrome فارسی آن به production منتقل نمی‌شود.
- Verified: direction approved؛ vertical slice phone برای prompt/reasoning/answers/tool spine و action dock روی `df7b17e` زنده تأیید شده، اما tablet/large-text/solution/completion و Focus Pen فیزیکی هنوز gate باز هستند.
- Asset: [accepted concept](../2026-08-02-android-perfect-cycle/assets/concepts/question-astral-codex-v1.png)

## Findings ورودی طراحی

- phone Map: header و orbit strip چند مرکز توجه هم‌زمان دارند؛ Mission dock و footer بیش از حد از مسیر را می‌پوشانند.
- tablet portrait: rail ناوبری مفید است، ولی stage به‌صورت phone بلند کش آمده و پایین Mission فضای مردهٔ زیادی دارد.
- tablet landscape Map: سه‌پنجره‌ای شدن منطقی است، اما primary CTA و inspector باید در manifest رسمی یکی شوند.
- tablet landscape Mission: manuscript خواناست، ولی پاسخ‌های پایین و solve instrument باید در pane/scroll اختصاصی بدون overlay مبهم سازمان‌دهی شوند.
- هر سه viewport از نظر هویت از reference درست استفاده می‌کنند؛ مسئلهٔ بعدی composition، ownership و performance است، نه ساخت direction تازه.

## گیت بعدی

vertical slice phone اکنون با viewport همسان ثبت شده است. گیت بعدی P4، matrix phone/tablet/large-text و حالت‌های انتخاب، صحیح/غلط، solution، completion و restore است؛ هر delta مادی نسبت به reference باید پیش از phase-complete بسته یا صریحاً ثبت شود.
