# Jules dataset batch 1: empty Math 10 chapters

Create a review-only dataset expansion for the Iranian grade-10 experimental-sciences mathematics curriculum.

Modify only these three new JSON files:

- `data/seed/review/jules_v2/math_10_sets_patterns_sequences.json`: exactly 60 questions
- `data/seed/review/jules_v2/math_10_rational_powers_algebraic_expressions.json`: exactly 60 questions
- `data/seed/review/jules_v2/math_10_equations_inequalities.json`: exactly 60 questions

Do not add generators, Python/Node scripts, validators, documentation, or changes outside those files. The files must contain UTF-8 Persian JSON arrays, not mojibake.

Each record must have exactly these fields: `id`, `subject`, `category`, `sub_category`, `difficulty`, `question_text`, `image_url`, `option_1`, `option_2`, `option_3`, `option_4`, `correct_option_index`, `classic_solution`, `smart_shortcut`, `source`.

Use `subject: math`, `category: math_10`, the chapter key from the filename, `image_url: null`, and `source: jules_curated_v2`. IDs must be `jules_v2_<chapter_key>_001` through the exact file count. `correct_option_index` is 1-based. Allowed difficulties are `above_average`, `hard`, `very_hard`, and only genuinely demanding `olympiad` questions.

Quality contract:

- Questions must be original, self-contained, mathematically correct, and within the official Iranian grade-10 experimental curriculum.
- Write formal, fluent Persian. Do not use emojis, slang, or filler such as «رفیق».
- Use JSON-safe LaTeX with `$...$` and escaped backslashes.
- Give four distinct plausible options based on common mistakes, with balanced correct positions across 1..4.
- `classic_solution` must independently derive the answer step by step and verify domain/sign restrictions.
- `smart_shortcut` must teach a valid faster route, not merely repeat the solution.
- Do not create mechanical variants by changing numbers. No more than 4 questions may share the same reasoning archetype, and their presentation must still differ materially.
- Before finishing, manually recompute every correct answer and check that the stated option index points to it.

Topic distribution:

- `sets_patterns_sequences`: set notation and operations, complements and De Morgan, intervals, Venn counting, finite/infinite patterns, arithmetic sequences, geometric sequences, recursive sequences, mixed reasoning and multi-step applications.
- `rational_powers_algebraic_expressions`: exponent laws, rational exponents, radicals and domains, rationalizing, identities, factoring, algebraic simplification, nested expressions, parameter questions, and error-analysis items.
- `equations_inequalities`: linear and quadratic equations, root relations, parameterized quadratics, sign analysis, absolute-value equations/inequalities, rational and radical equations with extraneous-root checks, systems, intervals, and contextual modeling.

Deliver only the three review JSON files and report counts plus your correctness audit.
