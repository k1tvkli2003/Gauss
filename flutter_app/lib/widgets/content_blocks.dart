import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';

/// One text or TeX run from a mixed Persian/mathematics content block.
///
/// The source corpus stays immutable. Any delimiter repair or TeX
/// normalization represented here is a view-only compatibility layer.
@immutable
class MathContentSegment {
  const MathContentSegment.text(this.value)
    : isMath = false,
      display = false,
      source = value;

  const MathContentSegment.math({
    required this.value,
    required this.source,
    required this.display,
  }) : isMath = true;

  final String value;
  final String source;
  final bool isMath;
  final bool display;
}

/// Parses `$...$` and `$$...$$` without mutating the bundled source string.
///
/// A handful of preserved source explanations have a missing closing dollar
/// before a newline. When the whole block is unbalanced, the repair is scoped
/// to odd lines so later Persian prose cannot be swallowed by a TeX widget.
@visibleForTesting
List<MathContentSegment> parseMathContent(String source) {
  final input = _repairUnbalancedDollarLines(source);
  final segments = <MathContentSegment>[];
  final text = StringBuffer();

  void flushText() {
    if (text.isEmpty) return;
    segments.add(MathContentSegment.text(text.toString()));
    text.clear();
  }

  var index = 0;
  while (index < input.length) {
    if (input[index] == r'\' &&
        index + 1 < input.length &&
        input[index + 1] == r'$') {
      text.write(r'$');
      index += 2;
      continue;
    }
    if (input[index] != r'$') {
      text.write(input[index]);
      index++;
      continue;
    }

    final display = index + 1 < input.length && input[index + 1] == r'$';
    final delimiter = display ? r'$$' : r'$';
    final contentStart = index + delimiter.length;
    final close = _findClosingDelimiter(input, contentStart, delimiter);
    if (close < 0) {
      text.write(delimiter);
      index = contentStart;
      continue;
    }

    final raw = input.substring(contentStart, close);
    if (raw.trim().isEmpty) {
      text.write(input.substring(index, close + delimiter.length));
    } else {
      flushText();
      segments.add(
        MathContentSegment.math(
          value: normalizeMathTex(raw),
          source: raw,
          display: display,
        ),
      );
    }
    index = close + delimiter.length;
  }
  flushText();
  return segments;
}

int _findClosingDelimiter(String input, int start, String delimiter) {
  var braceDepth = 0;
  for (var index = start; index <= input.length - delimiter.length; index++) {
    if (input[index] == r'\') {
      index++;
      continue;
    }
    if (input[index] == '{') {
      braceDepth++;
      continue;
    }
    if (input[index] == '}') {
      if (braceDepth > 0) braceDepth--;
      continue;
    }
    // Some preserved explanations contain `$P$` inside `\text{...}` while
    // the whole expression is already delimited by `$...$`. Those nested
    // dollars are extraction noise, not the end of the outer expression.
    if (braceDepth > 0) continue;
    if (!input.startsWith(delimiter, index)) continue;
    if (delimiter == r'$') {
      final touchesAnotherDollar =
          (index > 0 && input[index - 1] == r'$') ||
          (index + 1 < input.length && input[index + 1] == r'$');
      if (touchesAnotherDollar) continue;
    }
    return index;
  }
  return -1;
}

String _repairUnbalancedDollarLines(String source) {
  if (_unescapedDollarCount(source).isEven) return source;
  return source
      .split('\n')
      .map((line) => _unescapedDollarCount(line).isOdd ? '$line\$' : line)
      .join('\n');
}

int _unescapedDollarCount(String source) {
  var count = 0;
  for (var index = 0; index < source.length; index++) {
    if (source[index] != r'$') continue;
    var precedingSlashes = 0;
    for (
      var cursor = index - 1;
      cursor >= 0 && source[cursor] == r'\';
      cursor--
    ) {
      precedingSlashes++;
    }
    if (precedingSlashes.isEven) count++;
  }
  return count;
}

/// Normalizes extraction artifacts only inside TeX runs.
///
/// Persian prose and the JSON corpus are deliberately untouched. TeX number
/// tokens use ASCII digits for predictable parser metrics while the surrounding
/// Persian UI keeps its original glyphs.
@visibleForTesting
String normalizeMathTex(String source) {
  const digitMap = <String, String>{
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
  };
  final normalized = StringBuffer();
  for (final rune in source.runes) {
    final character = String.fromCharCode(rune);
    normalized.write(digitMap[character] ?? character);
  }
  var value = normalized
      .toString()
      // A single JSON backslash before `frac`/`bar` was decoded as the
      // corresponding control character in 57 preserved source runs.
      .replaceAll('\u000crac', r'\frac')
      .replaceAll('\u0008ar', r'\bar')
      .replaceAll(r'\fracrac', r'\frac')
      .replaceAll(r'\timesimes', r'\times')
      .replaceAll('−', '-')
      .replaceAll('٫', '.')
      .replaceAll('٪', r'\%');
  value = value.replaceAllMapped(
    RegExp(r'\\frac\(([^()]*)\)'),
    (match) => '${r'\frac{'}${match.group(1)}}',
  );
  value = value.replaceAllMapped(
    RegExp(r'\\\\\[([A-Za-z\\-])'),
    (match) => '\\\\{}[${match.group(1)}',
  );
  value = value.replaceAllMapped(RegExp(r'\\text\{([^{}]*)\}'), (match) {
    final body = match.group(1)!;
    final hasMathCommand = body.contains(r'\');
    final hasPersian = RegExp(r'[\u0600-\u06ff]').hasMatch(body);
    return hasMathCommand && !hasPersian
        ? '${r'\mathrm{'}${body.trim()}}'
        : match.group(0)!;
  });
  return _removeNestedMathDollars(value).trim();
}

String _removeNestedMathDollars(String source) {
  final result = StringBuffer();
  for (var index = 0; index < source.length; index++) {
    if (source[index] != r'$') {
      result.write(source[index]);
      continue;
    }
    var precedingSlashes = 0;
    for (
      var before = index - 1;
      before >= 0 && source[before] == r'\';
      before--
    ) {
      precedingSlashes++;
    }
    if (precedingSlashes.isOdd) result.write(source[index]);
  }
  return result.toString();
}

class ContentBlocksView extends StatelessWidget {
  const ContentBlocksView({
    required this.blocks,
    this.textStyle,
    this.textColor,
    this.compact = false,
    super.key,
  });

  final List<ContentBlock> blocks;
  final TextStyle? textStyle;
  final Color? textColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks)
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 4 : 12),
            child: switch (block) {
              TextBlock(:final text) => _MixedMathText(
                text: text,
                style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
                color: textColor,
              ),
              ImageBlock(:final asset, :final alt, :final aspectRatio) =>
                _AssetMedia(asset: asset, alt: alt, aspectRatio: aspectRatio),
            },
          ),
      ],
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: compact ? content : SelectionArea(child: content),
    );
  }
}

class _AssetMedia extends StatelessWidget {
  const _AssetMedia({
    required this.asset,
    required this.alt,
    required this.aspectRatio,
  });
  final String asset;
  final String alt;
  final double? aspectRatio;

  Widget _image(
    BuildContext context, {
    BoxFit fit = BoxFit.contain,
    bool fullscreen = false,
  }) => Image.asset(
    'assets/$asset',
    fit: fit,
    cacheWidth: fullscreen
        ? 2400
        : (MediaQuery.sizeOf(context).width *
                  MediaQuery.devicePixelRatioOf(context))
              .clamp(600, 1800)
              .round(),
    filterQuality: fullscreen ? FilterQuality.medium : FilterQuality.low,
    errorBuilder: (context, error, stackTrace) => Container(
      alignment: Alignment.center,
      color: GaussColors.ink,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          alt.isEmpty ? 'Image unavailable' : alt,
          textAlign: TextAlign.center,
          style: const TextStyle(color: GaussColors.muted),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    button: true,
    label: alt,
    hint: 'Open image viewer',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: GaussColors.ink,
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog.fullscreen(
              backgroundColor: GaussColors.voidBlack,
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        minScale: .5,
                        maxScale: 5,
                        child: Center(child: _image(context, fullscreen: true)),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close image viewer',
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: aspectRatio == null || aspectRatio! <= 0
                    ? 1.4
                    : 1 / aspectRatio!,
                child: _image(context),
              ),
              const Positioned(
                right: 8,
                bottom: 8,
                child: Icon(Icons.zoom_in, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MixedMathText extends StatelessWidget {
  const _MixedMathText({required this.text, this.style, this.color});
  final String text;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final segments = parseMathContent(text);
    if (segments.every((segment) => !segment.isMath)) {
      final resolvedStyle = style?.copyWith(color: color, height: 1.75);
      return Text(text, textAlign: TextAlign.start, style: resolvedStyle);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = <Widget>[];
        final inline = <Widget>[];

        Widget mathRun(MathContentSegment segment, int index) => Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            key: ValueKey(
              segment.display ? 'display-math-$index' : 'inline-math-$index',
            ),
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              segment.value,
              mathStyle: segment.display ? MathStyle.display : MathStyle.text,
              textStyle: style?.copyWith(color: color, height: 1.25),
              onErrorFallback: (error) => Text(
                segment.source,
                textDirection: TextDirection.ltr,
                style: style?.copyWith(color: color, height: 1.45),
              ),
            ),
          ),
        );

        void flushInline() {
          if (inline.isEmpty) return;
          rows.add(
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 3,
                runSpacing: 7,
                children: List<Widget>.of(inline),
              ),
            ),
          );
          inline.clear();
        }

        for (var index = 0; index < segments.length; index++) {
          final segment = segments[index];
          if (segment.value.isEmpty) continue;
          if (segment.isMath && segment.display) {
            flushInline();
            rows.add(
              SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: constraints.hasBoundedWidth
                        ? BoxConstraints(maxWidth: constraints.maxWidth)
                        : const BoxConstraints(),
                    child: mathRun(segment, index),
                  ),
                ),
              ),
            );
          } else if (segment.isMath) {
            inline.add(mathRun(segment, index));
          } else {
            inline.add(
              Text(
                segment.value,
                textAlign: TextAlign.start,
                textDirection: TextDirection.rtl,
                style: style?.copyWith(color: color, height: 1.7),
              ),
            );
          }
        }
        flushInline();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 7,
          children: rows,
        );
      },
    );
  }
}
