# گائوس — Gauss

An elite, tablet-optimized Android trainer for **hard** Iranian Konkur-level
Math & Physics. Dark, zen-hacker aesthetic. Split-screen exam UI with a
stylus scratchpad, a "Genius" answer key (classic solution **+** test-taking
shortcut), Revenge Mode, and a GitHub-style Brain Heatmap.

> Built for a brain that misses high-level analytical problem solving. No easy
> questions allowed.

## Stack
- **Expo (React Native) + TypeScript**, expo-router (landscape-locked)
- **Zustand** for exam state
- **NativeWind / Tailwind** for styling
- **@shopify/react-native-skia** for the stylus drawing canvas
- **react-native-mathjax-svg** for native LaTeX rendering (MathJax → SVG, no
  WebView), RTL Persian aware
- **Supabase** (Postgres) backend — tables namespaced `gauss_*`

## Project layout
```
app/                       # expo-router screens
  _layout.tsx              # dark theme root
  index.tsx                # home dashboard (stats, streak, recent exams)
  exam/setup.tsx           # smart custom exam generator
  exam/session.tsx         # SPLIT-SCREEN: question (left) + canvas (right)
  exam/results.tsx         # kaarnaameh + Genius answer key per question
  revenge.tsx              # Revenge Mode (wrong/skipped retraining)
  analytics.tsx            # accuracy, weak topics, Brain Heatmap
src/
  api/                     # questions.ts, history.ts (Supabase queries)
  components/              # MathText, DrawingCanvas, OptionButton, Heatmap, ...
  store/examStore.ts       # Zustand exam engine
  lib/                     # supabase client, local profile id
  data/categories.ts       # Iranian curriculum tree
  theme/colors.ts          # neon-on-charcoal palette
data/seed/                 # question JSON + Jules generation contract
scripts/seed.mjs           # bulk-load seed JSON -> Supabase
supabase/migrations/       # schema
```

## Getting started
```bash
npm install
# Supabase URL + anon key are already wired in app.json -> expo.extra
npx expo start            # press 'a' for Android (use a tablet / landscape)
```

### Build a real Android app (APK/AAB)
```bash
npx expo install expo-dev-client
eas build -p android --profile preview     # needs an Expo account
```

## Continuous release (GitHub Actions → signed APK)
`.github/workflows/release-apk.yml` builds a **real, signed release APK** (never
debug, no AAB) on every push and publishes it as a GitHub Release.

- **Smart versioning** — `versionName` is `major.minor` from `app.json` plus the
  CI run number as the patch (e.g. `1.0.42`); `versionCode` is the run number,
  so it always increases.
- **Signing** — set these repo secrets for stable, upgradeable signing
  (Settings → Secrets and variables → Actions):
  - `ANDROID_KEYSTORE_BASE64` — `base64 -w0 your.keystore`
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`

  Create a keystore once:
  ```bash
  keytool -genkeypair -v -keystore gauss.keystore -alias gauss \
    -keyalg RSA -keysize 2048 -validity 10000
  base64 -w0 gauss.keystore   # paste into ANDROID_KEYSTORE_BASE64
  ```
  Without secrets the workflow still produces a genuine release APK, but signs it
  with an ephemeral key each run (not upgrade-compatible across builds).

## Database
Schema lives in `supabase/migrations/0001_gauss_init.sql` and is already
applied to the Supabase project. Three tables:
- `gauss_questions` — the bank (subject, category, difficulty, text/LaTeX,
  4 options, correct index, classic solution, smart shortcut)
- `gauss_exams_history` — one row per finished exam (score, timing, config)
- `gauss_user_history` — one row per attempt (correct/wrong/skipped, time)

## Adding questions
1. Drop JSON files into `data/seed/` (shape in `JULES_DATASET_GUIDE.md`).
2. `SUPABASE_SERVICE_ROLE_KEY=... npm run seed`

Bulk generation is delegated to **Google Jules** using the contract in
`data/seed/JULES_DATASET_GUIDE.md`.

## Security notes
- The **anon key** in `app.json` is public by design (RLS-protected) — safe.
- The **service role key** and any API tokens must live only in `.env`
  (gitignored) — never commit them.
