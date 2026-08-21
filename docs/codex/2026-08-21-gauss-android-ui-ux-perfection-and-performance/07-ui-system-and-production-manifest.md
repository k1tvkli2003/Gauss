# UI System و Production Manifest

- Status: `binding`
- Phase: P1
- Revision anchor: `8c24d64` (P0 baseline)
- Runtime target: Flutter/Dart on Android
- Accepted directions: Celestial Expedition Map + Writable Astral Manuscript

این سند direction تازه‌ای پیشنهاد نمی‌کند. وظیفه‌اش این است که دو رفرنس پذیرفته‌شده را به قرارداد قابل‌کدنویسی و قابل‌آزمون تبدیل کند تا در P2 تا P7 کیفیت بصری، عملکرد، دسترس‌پذیری و رفتار از هم جدا نشوند.

## 1. Design DNA الزام‌آور

### هویت

- Gauss یک «ابزار ناوبری در دانش» است، نه dashboard و نه برگهٔ آزمون مدرسه.
- Map سطح اصلی و تمام‌صفحه است؛ مسیر، node و landmark محتوا هستند و chrome روی آن شناور می‌شود.
- Question یک manuscript پیوسته و قابل‌نوشتن است؛ prompt، ink و answer rail یک شیء واحد را می‌سازند.
- brass جهت و کنش اصلی، teal پیشرفت/صحت، parchment مطالعه، و abyss عمق محیط است.
- متن chrome فقط انگلیسی است. محتوای آموزشی می‌تواند فارسی باشد، ولی تمام ارقام visible/semantic آن ASCII `0-9` می‌ماند.

### تایپوگرافی

- English UI: `Manrope`؛ وزن 600 برای secondary، 700 برای title، 800/900 فقط برای action و insignia.
- Persian learning content: `Vazirmatn`؛ بدون letter spacing، با line-height حدود `1.55–1.7` و جهت RTL در سطح بلوک.
- wordmark یک asset هویتی و semantic image واحد است؛ رشتهٔ `Gauss` جایگزین تصویریِ آن در نقاط برند نمی‌شود.
- هیچ عبارت ضروری ellipsis یا mid-word break نمی‌شود. در کمبود فضا، composition reflow می‌شود.

### ماده و عمق

- عمق dark theme عمدتاً با border، tone و overlap ساخته می‌شود؛ blur بزرگ روی محتوای متحرک ممنوع است.
- raster فقط texture/atmosphere/landmark است. متن، progress، انتخاب، پاسخ، ID و control همیشه live و semantic می‌مانند.
- glow یک signal محدود برای current/selected/completion است، نه decoration دائمی همهٔ nodeها.

## 2. Precision ledger و token math

| دسته | Ramp/قاعده | مصرف مجاز |
|---|---|---|
| Grid | `4, 8, 12, 16, 20, 24, 32, 40, 48, 56, 64dp` | ساختار و فاصله |
| Optical correction | `2dp`, `6dp` | فقط stroke/centering ظریف؛ نه layout اصلی |
| Touch target | `48, 56, 64, 72dp` | minimum تا hero |
| Icon | `18, 20, 24, 28, 32dp` | glyph داخل hit target مستقل |
| Type | `10, 11, 12, 14, 16, 18, 22, 28, 36sp` | insignia تا display |
| Stroke | `1, 1.5, 2, 3dp` | hairline، emphasis، selected، focus |
| Radius | `10, 16, 24, pill` | control، component، modal، capsule |
| Elevation | `0, 2, 6, 12` | flat، raised، floating، ceremonial |
| Motion | `140, 220, 280, 360, 520, 760ms` | micro تا completion |

قواعد precision:

1. هر control مستقل حداقل `48×48dp` semantic hit box دارد؛ تصویر یا glyph می‌تواند کوچک‌تر باشد.
2. دو control مجاور حداقل `8dp` فاصلهٔ hit-box و هر overlay با مسیر حداقل `12dp` optical moat دارد.
3. alignment بر اساس محور محتوای واقعی است، نه مرز تصویر decorative. در phone محور Map مرکز route-owned width است؛ در tablet محور مسیر مرکز pane چپ است، نه مرکز کل screen.
4. symmetry ساختاری است: header سه track دارد (left utility / centered identity-progress / right context). عرض trackهای کناری برابر می‌شود، ولی داده‌های نامتقارن به زور mirror نمی‌شوند.
5. focus ring با stroke `3dp` بیرون component رسم می‌شود و اندازه layout را تغییر نمی‌دهد.
6. normal text pairs باید حداقل `4.5:1` و متن/هویت اصلی ترجیحاً `7:1` contrast داشته باشند.

## 3. Responsive composition، occupancy و safe area

### کلاس‌ها

| Window | Composition |
|---|---|
| `<360dp` | narrow phone؛ stack تک‌ستونه، compact labels، هیچ row توضیحی متراکم |
| `360–599dp` | phone؛ Map full-width و Manuscript تک‌ستونه |
| `600–839dp` portrait | tablet portrait؛ density اختصاصی، reading width bounded، فضای عمودی بین content پخش می‌شود نه dead band |
| `840–1199dp` landscape | two-pane در صورت height `>=480dp` و text scale `<1.55` |
| `>=1200×600dp` | Map + inspector و Question + support pane؛ rail مستقل |
| text scale `>=1.55` | accessible reflow؛ split/dense controls غیرفعال و live text stack می‌شود |

### Map occupancy

- phone header حداکثر `23%` ارتفاع usable اولیه را می‌گیرد.
- در first viewport حداقل `55%` ارتفاع usable به route و nodeها تعلق دارد.
- مجموع overlayهای پایین در phone بیش از `24%` ارتفاع usable نیست؛ footer خارج از system navigation قرار دارد.
- tablet landscape: route pane برابر `66%` و inspector برابر `34%` route-owned width است؛ rail قبل از این تقسیم کم می‌شود.
- node target: phone `72dp`، medium `88–96dp`، tablet `96–108dp`. label anchor مستقل از shell است و حداقل `12dp` moat دارد.
- spiral amplitude حداکثر `25%` عرض در phone و `31–34%` در tablet است؛ node و label هیچ‌وقت از gutter خارج نمی‌شوند.

### Question occupancy

- phone: parchment هدف `94%` عرض route است؛ margin با حداقل `8dp` در 320dp و `12–16dp` در phone عادی.
- prompt و answerها در scroll واحدند؛ reasoning field بین `112dp` و `240dp` content-aware است و حالت comfortable برابر `176dp` است.
- tool spine visual برابر `56dp` است و controlهایش `48dp` target دارند؛ اگر فضا کم شود به contextual row/overlay تبدیل می‌شود، نه اینکه manuscript را له کند.
- tablet landscape: manuscript `62%` و support/solution pane `38%` عرض content را می‌گیرد؛ هر pane scroll مستقل و state مشترک دارد.
- bottom solve instrument height محتوامحور است و هیچ‌وقت روی آخرین answer rail قرار نمی‌گیرد.

### Safe-area ownership

1. shell مالک Android system insets است؛ child footer/dock آن inset را دوباره مصرف نمی‌کند.
2. floating footer دقیقاً bounding box سه destination + padding `8–12dp` است؛ full-width opaque band پشت آن ممنوع است.
3. Map scroll end برابر آخرین node/label + overlay footprint + `32dp` است.
4. Question scroll end برابر آخرین answer/solution + solve instrument footprint + `16dp` است.
5. IME فقط pane فعال را resize/scroll می‌کند؛ footer و question state حذف یا reset نمی‌شوند.

## 4. Production layer manifest

نسخهٔ machine-readable در `flutter_app/lib/app/gauss_experience_spec.dart` است.

### Map — back to front

| ID | Kind | Z | Repaint owner | Semantic/interactive |
|---|---|---|---|---|
| `map.atmosphere` | raster | atmosphere | static scene | no/no |
| `map.celestial-grid` | vector | material | visible band | no/no |
| `map.continuous-route` | vector | route | visible band | no/no |
| `map.landmarks` | raster | route | visible band | no/no |
| `map.lesson-instruments` | hybrid | content | visible band + state | yes/yes |
| `map.chapter-annotations` | live | content | visible band | yes/no |
| `map.orbit-navigator` | live | chrome | selected course/chapter | yes/yes |
| `map.mission-compass` | hybrid | chrome | selected/current node | yes/yes |
| `map.navigation` | live | chrome | route destination | yes/yes |

Assets: `orrery_atmosphere_portrait.png` فقط background؛ `theorem_engine.png` و `boss_observatory.png` landmark؛ `topic_shell.png` پوستهٔ node؛ glyph/progress/label/control live باقی می‌مانند.

### Question — back to front

| ID | Kind | Z | Repaint owner | Semantic/interactive |
|---|---|---|---|---|
| `question.atmosphere` | raster | atmosphere | static scene | no/no |
| `question.parchment` | raster | material | question boundary | no/no |
| `question.prompt-and-media` | hybrid | content | question boundary | yes/no |
| `question.ink` | hybrid | content | stroke canvas only | yes/yes |
| `question.answer-rails` | live | content | answer state | yes/yes |
| `question.solution-and-reflection` | live | content | checked state | yes/yes |
| `question.progress` | live | chrome | question index | yes/no |
| `question.context-tools` | live | chrome | tool state | yes/yes |
| `question.solve-instrument` | live | chrome | readiness/check state | yes/yes |
| `question.completion` | hybrid | transient | persisted receipt | yes/yes |

`manuscript_parchment_v1.png` فقط material است. prompt، فرمول، media، ink، پاسخ، correct/wrong state و solution هرگز داخل parchment raster نمی‌شوند.

## 5. Z-order و repaint boundaries

`atmosphere → material → route → content → chrome → transient`

- atmosphere یک `RepaintBoundary` ثابت دارد.
- Map route به bandهای bounded شکسته می‌شود؛ scroll offset فقط viewport window/parallax کوچک را invalidate می‌کند.
- node shell، progress، label و hit target ownership جدا دارند؛ تغییر selected کل stage را repaint نمی‌کند.
- ink stroke فقط scratch painter را repaint می‌کند؛ manuscript parent فقط empty↔nonempty، clear/restore و tool-mode boundary را می‌بیند.
- blur روی moving route/ink/answers ممنوع است. blur ثابت chrome نیز فقط پس از profile و در سطح کوچک مجاز است.

## 6. State matrix

### Map

| State | Visual truth | Primary action | Semantic requirement |
|---|---|---|---|
| loading | مسیر placeholder ثابت، بدون fake progress | none | `Loading study map` live region یک‌بار |
| offline-ready | Map و progress محلی کامل؛ dot آرام | open current | offline در label، بدون modal مزاحم |
| current | brass/teal aura محدود و مسیر ورودی روشن | start/continue 5-question lesson | `Current lesson`, reflected/revisit count |
| selected | scale محدود + Mission Compass هماهنگ | open selected | selected state روی همان node |
| completed | teal closed ring، بدون pulse دائمی | review | completed + count |
| locked | contrast کم اما readable، بدون tap دروغین | none | disabled + prerequisite hint |
| all-mastered | مسیر کامل؛ CTA review/next orbit | review/next orbit | completion summary |
| empty | فضای روشن با علت و reset filters/context | retry/context action | empty reason |
| error | Map data محفوظ؛ panel کوچک و retry | retry | error + no progress loss |

### Question

| State | Manuscript/answer behavior | Solve instrument | Announcement |
|---|---|---|---|
| loading | frame سبک؛ پاسخ جعلی ندارد | disabled | loading question |
| prompt | stem + reasoning + covered/live answers | select/derive | question index + stem |
| ink-active | stroke فوری؛ touch scroll محفوظ | ink tools contextual | tool/mode only on change |
| choice-selected | یک rail selected؛ layout ثابت | Check enabled | selected option |
| checking | interaction locked، state retained | saving indicator | checking answer |
| correct | teal proof current، answer rail ثابت | Next | correct once |
| incorrect | selected wrong + correct source distinction | Review/Next | incorrect + solution availability |
| source-warning | amber provenance warning، بدون ادعای verified | report/continue | source answer warning |
| solution | phone ادامه manuscript؛ tablet support pane | Next | solution heading/focus |
| completion | receipt از persisted result | Back to Map / retry | score, XP, streak result |
| save-error | انتخاب و ink حفظ می‌شوند | Retry | save failed, progress preserved |

## 7. Vertical slice اجرایی

### First Map viewport

1. safe top → سه track header با utilities برابر، wordmark/progress روی axis و subject context در track مقابل.
2. Orbit Navigator فقط یک context layer است: subject، course و chapter بدون strip تکراری.
3. first node در upper-middle reading zone می‌آید؛ حداقل یک segment بعدی دیده می‌شود.
4. landmark کنار path است و هیچ hit target یا label را نمی‌پوشاند.
5. Mission Compass روی node انتخابی sync می‌شود و CTA با نماد orbital + semantic label کار می‌کند؛ button متنی مستطیلیِ جدا ممنوع است.
6. footer پایین فقط سه destination را می‌گیرد، system bar را clear می‌کند و پشتش Map دیده می‌شود.

### Question 1

1. header: close / centered wordmark / scratch workspace؛ progress پنج‌مرحله‌ای زیر آن.
2. manuscript از prompt به reasoning field و سپس answer rails پیوسته است.
3. stylus هر جای reasoning/prompt surface مجاز به ink است؛ finger scroll پیش‌فرض و palm contact ignored است.
4. toolها contextual‌اند: pen، eraser، undo، expand، clear/restore؛ هیچ تغییر tool ارتفاع paper را جابه‌جا نمی‌کند.
5. answer rail با emblem و current line انتخاب می‌شود؛ correct/wrong فقط پس از Check ظاهر می‌شود.
6. solve instrument حالت `select → ready → checking → feedback → next` دارد و آخرین answer را نمی‌پوشاند.

## 8. Motion Bible

| Moment | Duration | حرکت | ثابت می‌ماند | Reduced motion |
|---|---:|---|---|---|
| route arrival | 360ms | content fade + 8dp settle | shell/footer | instant visibility |
| node select | 220ms | scale `1→1.06` + one aura arc | path geometry/labels | color/stroke only |
| open lesson | 520ms | selected-node continuity into manuscript accent | navigation anchor | cross-fade کوتاه |
| answer select | 140ms | current line + emblem settle | row height/text | immediate state |
| answer feedback | 280ms | color/stroke reveal + optional haptic | option positions | color + announcement |
| question advance | 360ms | outgoing content 6dp/fade، incoming reverse | header/progress frame | direct replace + focus |
| lesson completion | 760ms max | one star/receipt reveal، skippable | persisted truth/actions | static receipt |

قواعد:

- حداکثر یک focal animation هم‌زمان؛ decorative star motion با scroll متوقف/thresholded است.
- animation هیچ XP، streak یا progress تولید نمی‌کند؛ فقط receipt ذخیره‌شده را نمایش می‌دهد.
- rapid tap، back، background/resume و reduced motion state را دو بار commit نمی‌کنند.

## 9. Acceptance screenshot positions

نسخهٔ machine-readable در `GaussAcceptanceMatrix.shots` است.

| ID | Viewport / scale | State / anchor |
|---|---|---|
| `map-phone-start` | `360×800 @1x` | current / first node |
| `map-phone-middle-selected` | `390×844 @1x` | selected / middle node |
| `map-phone-end-completed` | `430×932 @1x` | completed / last node |
| `map-narrow-accessible` | `320×568 @2x text` | current / first node |
| `map-tablet-portrait` | `800×1280 @1x` | selected / middle node |
| `map-tablet-landscape` | `1280×800 @1x` | selected + inspector |
| `question-phone-prompt` | `390×844 @1x` | Q1 prompt |
| `question-phone-ink` | `390×844 @1x` | Q1 active ink |
| `question-phone-feedback` | `430×932 @1x` | wrong + solution |
| `question-narrow-accessible` | `320×568 @2x text` | long Q1 |
| `question-tablet-portrait` | `800×1280 @1x` | choice selected |
| `question-tablet-landscape` | `1280×800 @1x` | wrong + solution pane |
| `question-five-completion` | `390×844 @1x` | Q5 completion |

هر capture باید همراه commit SHA، logical size، density، text scale، orientation، state seed و artifact path ثبت شود. تصویر reference یا concept به‌تنهایی runtime proof نیست.

## 10. P1 gate

- [x] Design DNA و token ramp به کد production منتقل شد.
- [x] Map/Question layer manifest و repaint ownership تعریف شد.
- [x] occupancy، axis، z-order و safe-area قرارداد شد.
- [x] state matrix برای Map و Question کامل شد.
- [x] first Map viewport و Question 1 vertical slice مشخص شد.
- [x] Motion Bible و acceptance positions تعریف شد.
- [x] analyzer و focused tests پاس شدند (`32/32`).
- [x] validator رسمی work-docs و `git diff --check` پاس شدند.
- [ ] commit و push.
