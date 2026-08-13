/// Presentation policy for preserved learning content.
///
/// Gauss keeps the imported question corpus immutable. Question, answer,
/// solution, shortcut, and media-description prose may therefore remain in
/// its source language, while every rendered numeral uses the app's ASCII
/// convention. This transformation belongs at the effective/view boundary;
/// it must never be written back to source JSON or media.
const _learningNumeralMap = <String, String>{
  '۰': '0',
  '۱': '1',
  '۲': '2',
  '۳': '3',
  '۴': '4',
  '۵': '5',
  '۶': '6',
  '۷': '7',
  '۸': '8',
  '۹': '9',
  '٠': '0',
  '١': '1',
  '٢': '2',
  '٣': '3',
  '٤': '4',
  '٥': '5',
  '٦': '6',
  '٧': '7',
  '٨': '8',
  '٩': '9',
  '٫': '.',
  '٬': ',',
  '٪': '%',
};

/// Normalizes numeral glyphs without translating or rewriting source prose.
String normalizeLearningDigits(String source) {
  final normalized = StringBuffer();
  for (final rune in source.runes) {
    final character = String.fromCharCode(rune);
    normalized.write(_learningNumeralMap[character] ?? character);
  }
  return normalized.toString();
}
