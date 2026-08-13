# Flutter corpus render gate — 2026-08-10

## Runtime

- Flutter `3.44.0` stable, framework revision `559ffa3f75`
- Dart `3.12.0`
- Windows host

## Exact command

```powershell
cd C:\Users\K1\Desktop\Projects\Gauss\flutter_app
flutter test test/content_rendering_test.dart test/corpus_media_asset_test.dart
```

## Captured result

```text
00:00 +0: loading C:/Users/K1/Desktop/Projects/Gauss/flutter_app/test/content_rendering_test.dart
00:00 +0: C:/Users/K1/Desktop/Projects/Gauss/flutter_app/test/content_rendering_test.dart: mixed Persian and TeX parsing preserves prose and repairs one line
00:00 +1: C:/Users/K1/Desktop/Projects/Gauss/flutter_app/test/content_rendering_test.dart: TeX normalization is view-only and deterministic
00:00 +2: C:/Users/K1/Desktop/Projects/Gauss/flutter_app/test/content_rendering_test.dart: every bundled question TeX segment parses without source mutation
00:01 +3: C:/Users/K1/Desktop/Projects/Gauss/flutter_app/test/corpus_media_asset_test.dart: every bundled question-media asset resolves and decodes through Flutter
00:01 +4: C:/Users/K1/Desktop/Projects/Gauss/flutter_app/test/corpus_media_asset_test.dart: every bundled question-media asset resolves and decodes through Flutter
00:25 +5: All tests passed!
```

## Assertions bound by the tests

- `3,672` canonical/runtime questions loaded through `QuestionBankRepository`.
- `22,032` text blocks traversed without source mutation.
- More than `37,000` extracted TeX segments parsed by the same parser used by `flutter_math_fork`.
- `3,410` unique question-media assets resolved through `rootBundle` and decoded by Flutter's image codec.
- A Persian/TeX composition rendered at phone width with `200%` text scaling without a Flutter exception.

This is a technical runtime receipt. Semantic image relevance, crop correctness,
source-PDF fidelity, answer correctness, and solution completeness remain
separate fail-closed gates.

## Revalidation after live-digit rendering changes — 2026-08-13

The render boundary now normalizes Persian and Arabic-Indic numerals to ASCII
`0`–`9` while preserving the immutable source records. Because that changed
`content_rendering_test.dart`, the original file-bound receipt became stale and
was not carried forward on trust. The complete gate was rerun with the same
command on Flutter `3.44.0` / Dart `3.12.0`; all `6` tests passed, including all
bundled media decode checks and the expanded live-digit/RTL rendering checks.
The receipt is regenerated from the current test-file hashes below rather than
editing a digest by hand.

## English chrome and ASCII learning numerals — 2026-08-13

The language boundary is now explicit and fail-closed:

- all product chrome is pinned to English/LTR even when the Android device
  locale is Persian;
- Persian is reserved for question, option, solution, shortcut, and
  question-image-description content;
- both Eastern Arabic and Persian digits, plus their decimal/group/percent
  separators, are normalized only at the effective rendering boundary to
  ASCII `0`–`9`, `.`, `,`, and `%`;
- the immutable source JSON and media were not rewritten;
- all `3,672` questions and more than `22,000` learning strings passed the
  live-text normalization audit;
- the current `49` mission-ready questions contain `0` embedded media assets.
  Future mission-ready media must carry a hash-bound `no_digits` or
  `ascii_only` receipt; absent evidence remains quarantined.

Additional verified command:

```powershell
flutter test test/english_chrome_contract_test.dart
```

Captured result: `5/5` passed. The wider Mission, manuscript, Focus Pen, and
question-contract group passed `42/42`; `android_experience_test.dart` passed
`24/24`; focused analyze reported no issues.
