# Jules dataset batch 2: under-covered Math 11 chapters

Create a review-only dataset expansion for the Iranian grade-11 experimental-sciences mathematics curriculum.

Modify only these five new JSON files:

- `data/seed/review/jules_v2/math_11_geometry.json`: exactly 60 questions
- `data/seed/review/jules_v2/math_11_statistics_probability.json`: exactly 60 questions
- `data/seed/review/jules_v2/math_11_functions_inverse_operations.json`: exactly 29 questions
- `data/seed/review/jules_v2/math_11_trigonometry_advanced.json`: exactly 55 questions
- `data/seed/review/jules_v2/math_11_exponential_logarithmic.json`: exactly 35 questions

Do not add generators, Python/Node scripts, validators, documentation, or changes outside those files. The files must contain UTF-8 Persian JSON arrays, not mojibake.

Each record must have exactly these fields: `id`, `subject`, `category`, `sub_category`, `difficulty`, `question_text`, `image_url`, `option_1`, `option_2`, `option_3`, `option_4`, `correct_option_index`, `classic_solution`, `smart_shortcut`, `source`.

Use `subject: math`, `category: math_11`, the chapter key from the filename, `image_url: null`, and `source: jules_curated_v2`. IDs must be `jules_v2_<chapter_key>_001` through the exact file count. `correct_option_index` is 1-based. Allowed difficulties are `above_average`, `hard`, `very_hard`, and only genuinely demanding `olympiad` questions.

Quality contract:

- Questions must be original, self-contained, correct, and strictly within the official Iranian grade-11 experimental curriculum.
- Write formal, fluent Persian without emojis, slang, or conversational filler.
- Use JSON-safe LaTeX with `$...$` and escaped backslashes.
- Give four distinct plausible distractors based on common misconceptions; balance correct positions across 1..4.
- Every `classic_solution` must derive the answer step by step. Every `smart_shortcut` must be a valid test-taking insight.
- Do not mass-produce number-swapped templates. No more than 4 questions may share one reasoning archetype.
- Recompute all answers and verify every option index before finishing.

Topic distribution:

- `geometry`: mathematical reasoning, direct/contradiction arguments, converse statements, Thales theorem and converse, proportional segments, similarity criteria, perimeter/area ratios, constructions described in text, and multi-step similarity applications. Keep questions image-free and fully describable in text.
- `statistics_probability`: data representation, mean/weighted mean, median/mode, range/variance/standard deviation at textbook level, transformations of data, counting-based probability, unions/intersections/complements, conditional reasoning within curriculum, and multi-step word problems.
- `functions_inverse_operations`: domains of sums/products/quotients/compositions, algebra of functions, composition order, inverse existence, finding/evaluating inverses, restricted domains, and parameterized questions.
- `trigonometry_advanced`: trig functions, signs and quadrants, complementary/supplementary relations, identities, exact values, graphs/ranges where curricular, equations reducible using identities, and multi-step expression evaluation.
- `exponential_logarithmic`: exponentials, logarithm definition and domain, log laws, change of base, exponential/log equations and inequalities within curriculum, graphs and transformations, parameters, and applied growth/decay reasoning.

Deliver only the five review JSON files and report counts plus your correctness audit.
