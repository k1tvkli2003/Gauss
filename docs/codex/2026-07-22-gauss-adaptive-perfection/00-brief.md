# پرفکشن تطبیقی UI/UX گائوس

- Task ID: `2026-07-22-gauss-adaptive-perfection`
- Status: `active`
- Created: 2026-07-22T14:47:01+03:30
- Language: fa

## Request
محیط Flutter گائوس با استفاده از `$style`، `$anatomy`، `$automate`، `$perfect`، `$performance`، `$function` و `$critics` به‌صورت خودکار و عمیق از نظر UI/UX، responsive behavior، دسترس‌پذیری، عملکرد و صحت تعاملات کامل شود؛ همهٔ صفحات روی موبایل و تبلت بررسی شوند و هیچ ایده یا انتخاب تازه‌ای از کاربر خواسته نشود.

## Success Criteria
- جهت Orrery و هویت Theorem Star دقیقاً حفظ شود و کیفیت سیستم UI بالا برود، نه اینکه سبک تازه‌ای جایگزین شود.
- `compact <600`، `medium 600–1023`، `expanded 1024–1439` و `wide ≥1440` یک منبع حقیقت واحد داشته باشند.
- Map، Study، Study Room، Insights، Vault، tour و stateها در موبایل/تبلت/دسکتاپ بدون overlap، clipping، target کوچک یا hierarchy ضعیف کار کنند.
- inline scratch روی سؤال و scratch sheet مستقل، clear فوری و هماهنگی gesture سالم داشته باشند.
- 3,672 سؤال، 3,410 رسانه، Room/SRS/progress، مسیرها، package/signing و رفتار offline-first بدون تغییر مخرب بمانند.
- analyzer، همهٔ تست‌ها، Android/Web builds، runtime screenshots و ماتریس دسترس‌پذیری پاس شوند؛ ادعای performance فقط با شواهد هم‌شرایط باشد.
- همهٔ P2/P3های baseline یا رفع شوند یا با محدودیت اثبات‌شده و صریح بسته شوند.

## Context
Baseline ثابت `8e404ca4` / `v1.0.105` روی `main` است. ممیزی read-only بیرون از ریپو در `C:/Users/K1/Documents/Gauss-Audits/2026-07-22/baseline` فریز شد: 0×P0، 0×P1، 6×P2 و 4×P3 پس از تصحیح evidence. ۷۵ تست و analyzer در baseline پاس شدند.

## In Scope
- design system، window classes، shell/navigation و floating chrome.
- Map، Study، Study Room/ink، Insights، Vault/system states.
- typography/contrast/touch targets، responsive composition و reduced motion.
- تست‌های adaptive/accessibility، Android emulator و Chrome screenshots، release builds و گزارش‌ها.

## Out of Scope
- auth، monetization، social/league و multi-user.
- جایگزینی dataset یا ساخت سؤال تازه.
- لوگو، wordmark یا visual direction جدید.
- ادعای battery/thermal/GPU دستگاه فیزیکی بدون دستگاه واقعی.

## Assumptions
- dark-only و English app chrome تصمیم‌های قطعی کاربر هستند.
- اسکرین‌شات Orrery پذیرفته‌شده و implementation فعلی مرجع ترکیب‌بندی‌اند؛ refinement مجاز است، تغییر concept نیست.
- تغییرات reversible و محلی‌اند و migration داده لازم نیست.
