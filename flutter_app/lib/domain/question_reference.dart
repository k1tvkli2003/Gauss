/// Returns a source-neutral, stable-enough label for user-facing diagnostics.
///
/// The immutable identifier remains stored in the outbox and database. Its
/// source namespace is intentionally never exposed in product chrome.
String questionDisplayReference(String questionId) {
  final numericParts = RegExp(
    r'\d+',
  ).allMatches(questionId).map((match) => match.group(0)!).toList();
  if (numericParts.length >= 2) {
    return 'Question ${numericParts[numericParts.length - 2]}-'
        '${numericParts.last}';
  }
  if (numericParts.isNotEmpty) return 'Question ${numericParts.last}';
  return 'Question context';
}
