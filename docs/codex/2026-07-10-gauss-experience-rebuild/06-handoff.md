# Handoff

## Outcome

The requested autonomous rebuild is complete. `flutter_app/` is a release-building, local-first Flutter/Dart replacement for Android and web. It preserves the full corpus and media, protects scoring from untrusted archived rows, and implements the selected Orrery map, practice/review, mission, recovery, recap, rewards, and insights journeys.

## Done

- Full additive Flutter implementation, source-preserving trust boundary, offline persistence, private gamification, responsive/accessibility polish, analyzer/tests, Android/web release builds, archive/signature verification, and browser runtime QA.

## Remaining

- No required project work remains. A physical Android launch and private production certificate are optional environment-dependent release steps.

## Verification

- All available proof is recorded in `05-verification.md`: 27 tests, zero analyzer issues, web and four Android release artifacts, exact source-to-artifact parity, valid signatures, compact/expanded browser journeys, semantic inspection, and zero final runtime warnings/errors.

## Primary Artifacts

- Flutter source: `flutter_app/`
- Universal APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- ABI-specific APKs: `flutter_app/build/app/outputs/flutter-apk/app-*-release.apk`
- Web bundle: `flutter_app/build/web/`
- Dataset policy: `dataset-integrity-policy.md`
- Gamification contract: `gamification-catalog-v1.md`
- Full verification: `05-verification.md`

## Run and Build

From `flutter_app/`:

```powershell
flutter run -d chrome
flutter build web --release --no-pub
flutter build apk --release --no-pub
flutter build apk --release --split-per-abi --no-pub
flutter test --no-pub
flutter analyze --no-pub
```

For personal Android sideloading, use the arm64 split on a typical modern phone or the universal APK when architecture is unknown. Store/private production distribution requires a release keystore via the existing `GAUSS_KEYSTORE_PATH`, `GAUSS_KEYSTORE_PASSWORD`, `GAUSS_KEY_ALIAS`, and `GAUSS_KEY_PASSWORD` inputs.

## Data Safety Rules

- Do not rewrite, normalize in place, delete, or regenerate protected question/media source trees.
- Do not make `preservedArchive` questions scorable without a new independently validated answer/solution source.
- Do not display the 71 quarantined Gauss explanations until their explicit option-number statements are reconciled.
- Keep the immutable event ledger as the source of truth for XP, quest claims, and achievement metrics.
- Preserve stable question IDs and the typed answer-index adapter.

## Rollback

The Kotlin/Compose project and its dirty user-owned worktree remain intact. The Flutter implementation is additive, so rollback consists of continuing to build the legacy project; no source corpus or migration was destructively transformed.

## Verification Boundary Details

All available static, unit, release, archive, signature, responsive browser, semantics, and runtime-log gates passed. The only unexecuted native gate is a physical Android launch because no device was connected.
