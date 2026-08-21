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
- Verified: direction approved only; production runtime match remains unverified.
- Asset: [accepted concept](../2026-08-02-android-perfect-cycle/assets/concepts/question-astral-codex-v1.png)

## گیت بعدی

پس از P1، manifest لایه‌ها و composition spec برای یک vertical slice نوشته می‌شود. پس از P3 و P4، reference و runtime با viewport همسان side-by-side مقایسه و هر delta Material در mismatch ledger ثبت می‌شود.
