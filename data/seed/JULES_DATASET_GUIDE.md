# Gauss Dataset Contract

Generate elite Iranian Konkur-level questions for **رشته تجربی متوسط دوم** only.
Output valid JSON arrays under `data/seed/official/` or a review folder that will
later be copied there after validation.

Do not write API tokens into this repo. If Jules is used, read `JULES_API_KEY`
from the local environment. The expected API style is the Jules API base
`https://jules.googleapis.com/v1alpha` with `X-Goog-Api-Key`.

## JSON shape

```json
{
  "subject": "math",
  "category": "math_10",
  "sub_category": "sets_patterns_sequences",
  "difficulty": "hard",
  "question_text": "markdown + LaTeX. Inline math $...$, block math $$...$$",
  "image_url": null,
  "option_1": "$...$",
  "option_2": "$...$",
  "option_3": "$...$",
  "option_4": "$...$",
  "correct_option_index": 1,
  "classic_solution": "حل تشریحی فارسی، دقیق و مرحله‌به‌مرحله",
  "smart_shortcut": "میانبر تستی فارسی و قابل اتکا"
}
```

## Hard rules

1. Only Iranian experimental-sciences high-school Math/Physics curriculum.
2. No easy questions. Use only `above_average`, `hard`, `very_hard`, `olympiad`.
3. `correct_option_index` is 1-based and must be distributed across 1..4.
4. Every question must have a complete `classic_solution`.
5. `smart_shortcut` is strongly encouraged and should teach a real test trick.
6. Math must render with the app's LaTeX renderer; escape JSON backslashes.
7. Distractors must be plausible common mistakes.
8. Run `node scripts/validate_dataset.mjs` before merging.

## Official course and chapter keys

### math_10 — ریاضی دهم تجربی
- `sets_patterns_sequences` — مجموعه، الگو و دنباله
- `trigonometry` — مثلثات
- `rational_powers_algebraic_expressions` — توان‌های گویا و عبارت‌های جبری
- `equations_inequalities` — معادله‌ها و نامعادله‌ها
- `functions_domain_range` — تابع؛ مفهوم، دامنه و برد
- `counting_without_counting` — شمارش، بدون شمردن
- `statistics_probability` — آمار و احتمال

### math_11 — ریاضی یازدهم تجربی
- `analytic_geometry_algebra` — هندسه تحلیلی و جبر
- `geometry` — هندسه؛ استدلال، تالس و تشابه
- `functions_inverse_operations` — تابع؛ وارون و اعمال جبری
- `trigonometry_advanced` — مثلثات؛ توابع و روابط تکمیلی
- `exponential_logarithmic` — توابع نمایی و لگاریتمی
- `limits_continuity` — حد و پیوستگی
- `statistics_probability` — آمار و احتمال

### math_12 — ریاضی دوازدهم تجربی
- `functions_monotonic_composition` — تابع؛ صعودی، نزولی و ترکیب
- `trigonometry_period_equations` — مثلثات؛ تناوب و معادلات
- `infinite_limits` — حد بی‌نهایت و حد در بی‌نهایت
- `derivatives` — مشتق
- `derivative_applications` — کاربرد مشتق
- `geometry_conics_circle` — هندسه؛ مقاطع مخروطی و دایره
- `total_probability` — احتمال؛ قانون احتمال کل

### physics_10 — فیزیک دهم تجربی
- `physics_measurement` — فیزیک و اندازه‌گیری
- `physical_properties_matter` — ویژگی‌های فیزیکی مواد
- `work_energy_power` — کار، انرژی و توان
- `temperature_heat` — دما و گرما

### physics_11 — فیزیک یازدهم تجربی
- `electrostatics` — الکتریسیته ساکن
- `current_electricity` — الکتریسیته جاری
- `magnetism_induction` — مغناطیس و القای الکترومغناطیسی

### physics_12 — فیزیک دوازدهم تجربی
- `kinematics` — حرکت‌شناسی
- `dynamics_circular_motion` — دینامیک و حرکت دایره‌ای
- `oscillation_waves` — نوسان و امواج
- `atomic_nuclear` — فیزیک اتمی و هسته‌ای

## Coverage target

Release minimum is 60 valid questions per chapter. Balanced target is 120 per
chapter. `node scripts/validate_dataset.mjs --strict-coverage` enforces the
release minimum when the bank is ready for release gating.
