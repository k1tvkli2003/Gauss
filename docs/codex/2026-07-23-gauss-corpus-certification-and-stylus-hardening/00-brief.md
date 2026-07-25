# Gauss corpus certification and stylus hardening

- Task ID: `2026-07-23-gauss-corpus-certification-and-stylus-hardening`
- Status: `active`
- Created: 2026-07-23T16:27:34
- Language: fa

## Repair policy update

Quarantine means a source-preserving repair workflow, not disposal. Every discovered prompt,
option, formula, media, answer, or solution defect is materialized as a hash-bound ticket in
`data/certification/v1/repair-queue.jsonl`. Fixes are proposed only in immutable overlays and
need source fidelity plus independent solve, fresh verification, solution review, and
adversarial review before any runtime promotion.

## Request
تمام ۳۶۷۲ سؤال حفظ‌شده باید قبل از استفاده در مأموریت‌ها از نظر استخراج
متن/گزینه/تصویر، مبحث و زیرمبحث، سختی، کلید صحیح و راه‌حل کامل بررسی شوند.
غربال اولیه باید با `gpt-5.6-luna` و reasoning `medium` انجام شود. هم‌زمان
نمایش فارسی و ریاضی و scratch مستقیم روی صورت سؤال برای Xiaomi Focus Pen باید
مقاوم و قابل‌آزمون شود.

## Success Criteria
- هیچ سؤال یا media منبع حذف یا بازنویسی نشود.
- canonical source، runtime shard و ۳۴۱۰ media با SHA-256 آشتی داده شوند.
- فقط سؤال `certified` بتواند `usable=true` و وارد scoring شود.
- غربال Luna، حل کور، verifier تازه، کنترل راه‌حل و adversarial review مستقل بمانند.
- کل corpus در parser واقعی Flutter Math بدون خطا عبور کند.
- قلم، فشار، cancel rollback، multi-touch و palm rejection تست شوند.
- analyzer، suite کامل، Web release و APK امضاشده عبور کنند.

## Context
Gauss یک محصول شخصی و offline-first برای Android و Web است. source corpus
عمداً immutable است؛ اصلاح کلید یا راه‌حل فقط به‌صورت overlay مشتق و قابل‌ممیزی
انجام می‌شود.

## In Scope
- certification schema/manifest/taxonomy/risk queues/batches.
- غربال و طبقه‌بندی کامل corpus و سپس داوری علمی پاسخ‌ها.
- compatibility renderer برای Persian + TeX.
- inline scratch و sheet scratch با رفتار native stylus.
- شواهد release و مستندات resume.

## Out of Scope
- auth، social، monetization و public leagues.
- ادعای latency سخت‌افزاری Xiaomi بدون دستگاه واقعی.
- تغییر خاموش source JSON یا media.

## Assumptions
- تا زمان تکمیل certification، `source_option` صرفاً دادهٔ منبع است نه حقیقت علمی.
- نبود PDF اصلی مانع source-fidelity نهایی است، اما مانع غربال و حل مستقل نیست.
