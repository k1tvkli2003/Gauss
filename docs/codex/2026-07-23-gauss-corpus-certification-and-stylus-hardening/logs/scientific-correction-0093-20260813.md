# Scientific correction 0093

This log binds the source-preserving scientific-correction lane for
`nardebam_math_1405_0093`. The immutable question JSON and source PDFs remain
unchanged. A derived runtime solution closes the omitted domain argument and
maps the stale extracted key from option 2 to the printed and independently
derived option 4.

## Fresh render verification

The derived solution, immutable options, corrected effective option, and exact
domain proof were rebound through `QuestionCertification` and rendered at
320dp with 200% text. The test also asserts that the effective solution uses
ASCII learning numerals and raises no Flutter exception.

- `flutter test --reporter compact test/scientific_correction_render_test.dart test/repaired_decimal_render_test.dart test/source_repair_render_test.dart`
  passed 4/4;
- focused `flutter analyze` over the certification boundary and all three
  repair render tests reported no issues;
- the decimal regression now explicitly expects presentation-boundary `2.5`
  and `13.5`, and rejects Persian/Arabic numeral glyphs;
- immutable source JSON and source PDFs were not changed.
