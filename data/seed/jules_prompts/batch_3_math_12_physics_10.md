# Jules dataset batch 3: Math 12 gaps and Physics 10 measurement

Create a review-only dataset expansion for the Iranian experimental-sciences high-school curriculum.

Modify only these three new JSON files:

- `data/seed/review/jules_v2/math_12_functions_monotonic_composition.json`: exactly 42 questions
- `data/seed/review/jules_v2/math_12_derivative_applications.json`: exactly 36 questions
- `data/seed/review/jules_v2/physics_10_physics_measurement.json`: exactly 60 questions

Do not add generators, Python/Node scripts, validators, documentation, or changes outside those files. The files must contain UTF-8 Persian JSON arrays, not mojibake.

Each record must have exactly these fields: `id`, `subject`, `category`, `sub_category`, `difficulty`, `question_text`, `image_url`, `option_1`, `option_2`, `option_3`, `option_4`, `correct_option_index`, `classic_solution`, `smart_shortcut`, `source`.

For math files use `subject: math` and `category: math_12`; for physics use `subject: physics` and `category: physics_10`. Use the chapter key from the filename, `image_url: null`, and `source: jules_curated_v2`. IDs must be `jules_v2_<chapter_key>_001` through the exact file count. `correct_option_index` is 1-based. Allowed difficulties are `above_average`, `hard`, `very_hard`, and only genuinely demanding `olympiad` questions.

Quality contract:

- Questions must be original, self-contained, correct, and strictly within the stated Iranian textbook chapter.
- Write formal, fluent Persian without emojis, slang, or filler.
- Use JSON-safe LaTeX with `$...$` and escaped backslashes.
- Give four distinct plausible options based on common mistakes; balance correct positions across 1..4.
- Solutions must show units, domains, signs, endpoints, and assumptions where relevant.
- `smart_shortcut` must teach a reliable faster method, not repeat the full solution.
- Do not use number-swapped templates. No more than 4 questions may share one reasoning archetype.
- Recompute every answer and verify every option index before finishing.

Topic distribution:

- `functions_monotonic_composition`: increasing/decreasing behavior, interval reasoning, composition order and domain, monotonicity of compositions, graphical/textual comparisons, parameters, and multi-step function reasoning.
- `derivative_applications`: critical points, local/absolute extrema, monotonicity tables, optimization, tangent/normal interpretation when relevant, endpoint checks, parameter questions, and contextual maximum/minimum problems.
- `physics_measurement`: SI base/derived units, prefixes, scientific notation, unit conversion, dimensional analysis, measurement instruments and resolution, significant figures, uncertainty/error at textbook level, order-of-magnitude estimates, and multi-step measurement scenarios. Do not drift into the separate matter-properties chapter.

Deliver only the three review JSON files and report counts plus your correctness audit.
