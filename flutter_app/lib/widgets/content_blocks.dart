import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';

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

  Widget _image({BoxFit fit = BoxFit.contain}) => Image.asset(
    'assets/$asset',
    fit: fit,
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
                        child: Center(child: _image()),
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
                child: _image(),
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
    final normalized = text.replaceAll(r'$$', r'$');
    final pieces = normalized.split(r'$');
    if (pieces.length == 1) {
      final resolvedStyle = style?.copyWith(color: color, height: 1.75);
      return Text(text, textAlign: TextAlign.start, style: resolvedStyle);
    }
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 3,
      runSpacing: 7,
      children: [
        for (var index = 0; index < pieces.length; index++)
          if (pieces[index].isNotEmpty)
            index.isEven
                ? Text(
                    pieces[index],
                    style: style?.copyWith(color: color, height: 1.7),
                  )
                : Directionality(
                    textDirection: TextDirection.ltr,
                    child: Math.tex(
                      pieces[index],
                      mathStyle: MathStyle.text,
                      textStyle: style?.copyWith(color: color),
                      onErrorFallback: (error) => Text(
                        pieces[index],
                        style: style?.copyWith(color: color),
                      ),
                    ),
                  ),
      ],
    );
  }
}
