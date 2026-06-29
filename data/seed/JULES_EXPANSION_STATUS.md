# Jules Expansion Status

- Source: `sources/github/yousefnedaei2003/Gauss`
- Started from branch: `main`
- Review destination: `data/seed/review/jules_v2/`
- Secret handling: `JULES_API_KEY` stays local and is not committed.

## Curated v2 sessions

- Math 10 empty chapters: `sessions/9886535212738493828`
  - https://jules.google.com/session/9886535212738493828
  - Prompt: `data/seed/jules_prompts/batch_1_math_10.md`
- Math 11 coverage gaps: `sessions/16248436911242928592`
  - https://jules.google.com/session/16248436911242928592
  - Prompt: `data/seed/jules_prompts/batch_2_math_11.md`
- Math 12 and Physics 10 gaps: `sessions/10547606036530113536`
  - https://jules.google.com/session/10547606036530113536
  - Prompt: `data/seed/jules_prompts/batch_3_math_12_physics_10.md`

The earlier broad session `sessions/14713659749495864237` is intentionally not
an integration source because its generated records were too template-driven.

## Official coverage

- Curated review questions imported: 557.
- Official Gauss questions: 3681.
- All 32 official curriculum chapters have at least 60 valid questions.
- `node scripts/validate_dataset.mjs --asset --strict-coverage` passes.

## Nardebam completion

Updated: 2026-06-29 Asia/Tehran

- Import progress: 100%.
- Math transcripts, solutions, and keys: `2042/2042` each.
- Physics transcripts, solutions, and keys: `1630/1630` each.
- Join conflicts: 0.
- All obsolete/in-progress Jules sessions were deleted after integration.
- Final source questions: 3672.
- Final comprehensive bank: 7353 questions across 29 topic shards.
- Final app split: 3977 math questions and 3376 physics questions.
- Generated media: 3410 WebP assets, about 63.4 MiB.
- Media review queue: 66 unusable source regions (51 without a reliable page
  reference and 15 invalid/tiny boxes). They are omitted instead of guessed.

Four low-reasoning workers handled disjoint completion slices:

- Worker 1: math solutions `1040-1069` and `1253`.
- Worker 2: math solutions `1771` and `1936-1948`.
- Worker 3: physics transcript `51-60` and keys `119-129`, `215-220`.
- Worker 4: math boundary transcript `1732-1734` and topic-07 review.

Final focused Jules transcript sessions:

- `sessions/1314371673103984223`: math functions `522-550`, 29 rows.
- `sessions/14081852667253595935`: math functions `551-579`, 29 rows.
- `sessions/3523984717644688198`: math functions `580-608`, 29 rows.

## Verification

- `node scripts/nardebam_progress.mjs`: all six source metrics at 100%.
- `node scripts/validate_comprehensive_dataset.mjs --strict-source-counts --asset`: passes with 7353 questions and 3407 media blocks.
- `./gradlew.bat :app:lintDebug`: passes.
- `./gradlew.bat :app:testDebugUnitTest :app:assembleDebug`: passes; this project currently has no unit-test sources.
- Debug APK: `app/build/outputs/apk/debug/app-debug.apk` (89,177,648 bytes).
- Emulator smoke test was not completed because the configured API 37 AVD remained `offline` in two cold/headless boot attempts.
