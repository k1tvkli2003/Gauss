Gauss

An elite, **native Android** trainer for hard Iranian Konkur-level Math &
Physics. Dark, zen-hacker aesthetic. Split-screen exam UI with a stylus
scratchpad, a "Genius" answer key (classic solution **+** test-taking shortcut),
Revenge Mode (spaced repetition), and a GitHub-style Brain Heatmap.

> Built for a brain that misses high-level analytical problem solving. No easy
> questions allowed.

## Stack — 100% native, offline-first
- **Kotlin + Jetpack Compose** (Material 3, RTL/Persian, edge-to-edge)
- **Navigation-Compose** for screens, **AndroidViewModel** for state
- **Room** for the local history / analytics / spaced-repetition store
- **JLaTeXMath** for native LaTeX rendering (formulas drawn straight to the
  Android canvas — **no WebView, no HTML**)
- **Vazirmatn** Persian font, bundled
- The entire **question bank (~4,000 Qs) is bundled as an offline asset** —
  the app needs no network and no backend.

## Project layout
```
app/src/main/
  assets/questions.json              # the bundled question bank (~4k Qs)
  res/font/                          # Vazirmatn weights
  java/com/gauss/app/
    GaussApp.kt                      # Application + tiny service locator
    MainActivity.kt                  # Compose host (forces RTL)
    data/
      Models.kt  Curriculum.kt       # domain types + official course/chapter tree
      QuestionBank.kt                # loads & queries the bundled bank
      HistoryRepository.kt           # save exam, analytics, SM-2 revenge queue
      db/                            # Room entities, DAO, database
    ui/
      theme/                         # neon-on-charcoal palette + typography
      components/                    # MathText (LaTeX), DrawingCanvas, OptionButton, …
      exam/ExamViewModel.kt          # the shared exam engine
      screens/                       # Home, Setup, Session, Results, Revenge, Analytics
      nav/NavGraph.kt
data/seed/                           # legacy seeds + generated official curriculum bank
```

The bundled `assets/questions.json` is generated from `data/seed/official/**`.
Legacy topic-based seed files are reclassified into the official experimental
sciences curriculum with a stable `id` per question, so history/SRS keys survive
taxonomy rebuilds. Questions that do not belong to the experimental curriculum
are kept under `data/seed/quarantine/` and are not bundled into the app.

## Build & run
```bash
# Requires Android Studio (or the Android SDK + JDK 17).
./gradlew :app:assembleDebug      # debug APK → app/build/outputs/apk/debug/
./gradlew :app:installDebug       # install on a connected device/emulator
```
Open the folder in Android Studio and press ▶ to run. Works on phones and
tablets; the exam screen splits into question + scratchpad in landscape and
tabs them in portrait. minSdk 26, targetSdk 35.

## Continuous release (GitHub Actions → signed APK)
`.github/workflows/release-apk.yml` builds a real **release** APK on every push
and publishes it as a GitHub Release. `versionName` is `1.0.<run>`,
`versionCode` is the run number (always increasing).

For stable, upgrade-compatible signing, set these repo secrets (Settings →
Secrets and variables → Actions):
- `ANDROID_KEYSTORE_BASE64` — `base64 -w0 your.keystore`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Without them the workflow still produces a genuine release APK, signed with the
Android debug key (installs fine, but not upgrade-compatible across machines).

Create a keystore once:
```bash
keytool -genkeypair -v -keystore gauss.keystore -alias gauss \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 gauss.keystore   # paste into ANDROID_KEYSTORE_BASE64
```

## Adding questions
Drop new validated JSON arrays into `data/seed/official/`, then validate and
re-merge the bundled asset:

```bash
node scripts/validate_dataset.mjs
node scripts/merge_dataset.mjs
./gradlew :app:assembleDebug
```

Each object needs `subject, category, sub_category, difficulty, question_text,
image_url, option_1..4, correct_option_index (1–4), classic_solution,
smart_shortcut`. In the official bank, `category` is one of
`math_10`, `math_11`, `math_12`, `physics_10`, `physics_11`, `physics_12`;
`sub_category` is one of the official chapter keys in
`data/seed/JULES_DATASET_GUIDE.md`.

To regenerate the official bank from the legacy seeds:

```bash
node scripts/reclassify_dataset.mjs
node scripts/validate_dataset.mjs
node scripts/merge_dataset.mjs
```

## Data & privacy
All progress (exam history, per-question attempts, spaced-repetition state)
lives **on-device** in a Room database. Nothing leaves the phone.
