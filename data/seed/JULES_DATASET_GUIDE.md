# Gauss — Dataset Generation Contract (for Jules)

You are generating an **elite** question bank for an Iranian Konkur-level
Math/Physics trainer. Output **only** valid JSON files in `data/seed/`, one
array per file, each element matching this exact shape:

```json
{
  "subject": "math | physics",
  "category": "<one of the category keys below>",
  "sub_category": "<short key, e.g. limits, kinematics>",
  "difficulty": "above_average | hard | very_hard | olympiad",
  "question_text": "markdown + LaTeX. Inline math $...$, block math $$...$$",
  "image_url": null,
  "option_1": "$...$",
  "option_2": "$...$",
  "option_3": "$...$",
  "option_4": "$...$",
  "correct_option_index": 1,
  "classic_solution": "Persian 'khodmooni' step-by-step (markdown+LaTeX)",
  "smart_shortcut": "Persian test-taking shortcut (markdown+LaTeX)"
}
```

## Hard rules
1. **No easy questions.** Only `above_average`, `hard`, `very_hard`, `olympiad`.
2. **Tone:** Persian, informal, friendly mentor ("ببین رفیق...", "این تست تله داره...").
3. `correct_option_index` is **1-based** (1–4). Distribute the correct answer
   across positions — don't always make it option 1.
4. Every question MUST have a `classic_solution`. `smart_shortcut` is strongly
   encouraged (the whole point of the app) — give the high-IQ test trick.
5. Math must render in KaTeX. Use `\dfrac`, `\sqrt`, `\lim`, `\int`, etc.
   Escape backslashes properly for JSON (`\\dfrac`).
6. Curriculum = Iranian Dovvom-e Motevaseteh (grades 10–12) only.
7. Distractor options must be *plausible* (common mistakes), not random.

## Category keys
**math:** `hesaban` (limits, derivatives, integrals, functions, trigonometry),
`hendeseh` (analytical, spatial, circle, conics),
`gosasteh_amar` (discrete, combinatorics, probability, statistics, number_theory)

**physics:** `mechanics` (kinematics, dynamics, work_energy, momentum),
`electromagnetism` (electrostatics, circuits, magnetism, induction),
`thermodynamics` (heat, gas_laws, fluids),
`waves_modern` (oscillations, waves, optics, modern)

## Suggested batches (one file each)
- `math_hesaban.json` — 25 questions, mostly very_hard/olympiad
- `math_hendeseh.json` — 25
- `math_gosasteh_amar.json` — 25
- `physics_mechanics.json` — 25
- `physics_electromagnetism.json` — 25
- `physics_thermo_waves.json` — 25

See `seed_questions.json` for 4 fully-worked reference examples.
After generation, `npm run seed` loads everything into Supabase.
