import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gauss/domain/models.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:gauss/ui/tokens/gauss_tokens.dart';

/// The ImageGen-directed, production-cleaned Gauss wordmark. Use this instead
/// of live text wherever the product name acts as identity rather than copy.
class GaussWordmark extends StatelessWidget {
  const GaussWordmark({
    this.width = 132,
    this.semanticLabel = 'Gauss',
    super.key,
  });

  final double width;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/visual/brand/gauss_wordmark.png',
      width: width,
      fit: BoxFit.contain,
      cacheWidth: (width * 4).round(),
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: semanticLabel == null,
      semanticLabel: semanticLabel,
    );
    return image;
  }
}

/// The Gauss mark: a tapered gold G fused with the theorem star and a lapis center.
class TheoremStarMark extends StatelessWidget {
  const TheoremStarMark({
    this.size = 40,
    this.monochrome = false,
    this.darkInk = false,
    this.semanticLabel,
    super.key,
  });

  final double size;
  final bool monochrome;
  final bool darkInk;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          isComplex: true,
          willChange: false,
          painter: _TheoremStarPainter(
            monochrome: monochrome,
            darkInk: darkInk,
          ),
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(image: true, label: semanticLabel, child: mark);
  }
}

class _TheoremStarPainter extends CustomPainter {
  const _TheoremStarPainter({required this.monochrome, required this.darkInk});

  final bool monochrome;
  final bool darkInk;

  // Geometry in the 512 grid of assets/visual/brand/theorem_star.svg.
  static final Path _glyph = Path()
    ..moveTo(371, 142)
    ..cubicTo(339, 109, 299, 88, 256, 88)
    ..cubicTo(163.2, 88, 88, 163.2, 88, 256)
    ..cubicTo(88, 348.8, 163.2, 424, 256, 424)
    ..cubicTo(348.8, 424, 424, 348.8, 424, 256)
    ..quadraticBezierTo(424, 247, 415, 247)
    ..lineTo(282, 247)
    ..lineTo(282, 265)
    ..lineTo(399.7, 265)
    ..cubicTo(395, 340, 333, 400, 256, 400)
    ..cubicTo(176.5, 400, 112, 335.5, 112, 256)
    ..cubicTo(112, 176.5, 176.5, 112, 256, 112)
    ..cubicTo(299, 112, 338, 124, 371, 142)
    ..close();
  static final Path _star = Path()
    ..moveTo(256, 134)
    ..cubicTo(251, 180, 248, 211, 241, 239)
    ..cubicTo(210, 246, 180, 251, 134, 256)
    ..cubicTo(180, 261, 210, 266, 241, 273)
    ..cubicTo(248, 301, 251, 332, 256, 378)
    ..cubicTo(261, 332, 264, 301, 271, 273)
    ..cubicTo(310, 266, 361, 265, 414, 265)
    ..lineTo(414, 247)
    ..cubicTo(361, 247, 310, 246, 271, 239)
    ..cubicTo(264, 211, 261, 180, 256, 134)
    ..close();

  static const _gold = [
    Color(0xFFF6DDA0),
    Color(0xFFE9BF65),
    Color(0xFFC9983F),
    Color(0xFFEDC776),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);
    final flat = darkInk ? GaussColors.parchmentInk : null;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = flat ?? GaussColors.brassLight;
    if (flat == null) {
      fill.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _gold,
        stops: [0, .32, .65, 1],
      ).createShader(const Rect.fromLTWH(88, 88, 336, 336));
    }
    canvas.drawPath(_glyph, fill);
    canvas.drawCircle(
      const Offset(256, 256),
      82,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..shader = fill.shader
        ..color = fill.color,
    );
    canvas.drawPath(_star, fill);
    canvas.drawCircle(const Offset(256, 256), 24, fill);
    final center = darkInk
        ? GaussColors.parchment
        : monochrome
        ? GaussColors.deepInk
        : const Color(0xFF101D3F);
    canvas.drawCircle(const Offset(256, 256), 17, Paint()..color = center);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TheoremStarPainter oldDelegate) =>
      oldDelegate.monochrome != monochrome || oldDelegate.darkInk != darkInk;
}

enum GaussDestinationGlyph { map, practice, insights }

class GaussNavGlyph extends StatelessWidget {
  const GaussNavGlyph({
    required this.glyph,
    required this.selected,
    this.size = 25,
    super.key,
  });

  final GaussDestinationGlyph glyph;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _GaussNavGlyphPainter(glyph: glyph, selected: selected),
      ),
    ),
  );
}

/// A compact geometric quill for the private scratchpad. Utility glyphs stay
/// live and semantic through their parent control, while avoiding a generic
/// platform icon that conflicts with the Gauss identity.
class GaussScratchGlyph extends StatelessWidget {
  const GaussScratchGlyph({this.size = 24, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _GaussScratchGlyphPainter(color: color ?? GaussColors.ivory),
      ),
    ),
  );
}

class _GaussScratchGlyphPainter extends CustomPainter {
  const _GaussScratchGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 3, 14, 18),
        const Radius.circular(2.5),
      ),
      line,
    );
    canvas.drawLine(const Offset(7, 8), const Offset(14, 8), line);
    canvas.drawLine(const Offset(7, 12), const Offset(11, 12), line);
    final quill = Path()
      ..moveTo(10, 18.5)
      ..cubicTo(13, 14, 16.4, 9.2, 21, 7)
      ..cubicTo(20.6, 11.8, 17.3, 15.6, 12.2, 17.7)
      ..close();
    canvas.drawPath(quill, line..strokeWidth = 1.55);
    canvas.drawLine(const Offset(11, 18), const Offset(18.7, 9.2), line);
    canvas.drawCircle(
      const Offset(18.9, 9),
      1.15,
      Paint()..color = GaussColors.signal,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GaussScratchGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GaussNavGlyphPainter extends CustomPainter {
  const _GaussNavGlyphPainter({required this.glyph, required this.selected});

  final GaussDestinationGlyph glyph;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final color = selected ? GaussColors.brassLight : GaussColors.fog;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.8 : 1.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    switch (glyph) {
      case GaussDestinationGlyph.map:
        canvas.drawCircle(const Offset(12, 12), 7.2, paint);
        canvas.drawCircle(const Offset(12, 12), 3.1, paint);
        canvas.drawLine(const Offset(12, 2), const Offset(12, 5), paint);
        canvas.drawLine(const Offset(12, 19), const Offset(12, 22), paint);
        canvas.drawLine(const Offset(2, 12), const Offset(5, 12), paint);
        canvas.drawLine(const Offset(19, 12), const Offset(22, 12), paint);
        canvas.drawCircle(
          const Offset(16.8, 7.2),
          1.45,
          Paint()..color = color,
        );
      case GaussDestinationGlyph.practice:
        final left = Path()
          ..moveTo(3.5, 5)
          ..quadraticBezierTo(8.2, 3.7, 11.5, 7)
          ..lineTo(11.5, 20)
          ..quadraticBezierTo(8.2, 17.1, 3.5, 18.4)
          ..close();
        final right = Path()
          ..moveTo(20.5, 5)
          ..quadraticBezierTo(15.8, 3.7, 12.5, 7)
          ..lineTo(12.5, 20)
          ..quadraticBezierTo(15.8, 17.1, 20.5, 18.4)
          ..close();
        canvas.drawPath(left, paint);
        canvas.drawPath(right, paint);
        canvas.drawLine(const Offset(7, 9), const Offset(9.5, 9.5), paint);
        canvas.drawLine(const Offset(17, 9), const Offset(14.5, 9.5), paint);
      case GaussDestinationGlyph.insights:
        canvas.drawLine(const Offset(4, 20), const Offset(21, 20), paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 12, 3, 6),
            const Radius.circular(1),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(10.5, 8, 3, 10),
            const Radius.circular(1),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(16, 4, 3, 14),
            const Radius.circular(1),
          ),
          paint,
        );
        if (selected) {
          canvas.drawCircle(
            const Offset(18.6, 4.2),
            1.4,
            Paint()..color = GaussColors.signal,
          );
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GaussNavGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.selected != selected;
}

class TopicGlyph extends StatelessWidget {
  const TopicGlyph({
    required this.topicKey,
    this.color = GaussColors.ivory,
    this.size = 34,
    super.key,
  });

  final String topicKey;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _TopicGlyphPainter(keyName: topicKey, color: color),
      ),
    ),
  );
}

class _TopicGlyphPainter extends CustomPainter {
  const _TopicGlyphPainter({required this.keyName, required this.color});

  final String keyName;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.8
      ..color = color;

    if (keyName.contains('geometry') || keyName.contains('conics')) {
      canvas.drawPath(
        Path()
          ..moveTo(4, 25)
          ..lineTo(16, 5)
          ..lineTo(28, 25)
          ..close(),
        p,
      );
      canvas.drawCircle(const Offset(16, 17.5), 3.2, p);
    } else if (keyName.contains('function') ||
        keyName.contains('derivative') ||
        keyName.contains('limit')) {
      canvas.drawLine(const Offset(5, 26), const Offset(5, 6), p);
      canvas.drawLine(const Offset(4, 25), const Offset(28, 25), p);
      canvas.drawPath(
        Path()
          ..moveTo(7, 22)
          ..cubicTo(12, 23, 11, 8, 17, 10)
          ..cubicTo(21, 11, 21, 19, 27, 6),
        p..strokeWidth = 2.2,
      );
    } else if (keyName.contains('probability') ||
        keyName.contains('statistics') ||
        keyName.contains('combinatorics')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 6, 20, 20),
          const Radius.circular(4),
        ),
        p,
      );
      for (final point in const [
        Offset(11, 11),
        Offset(21, 11),
        Offset(16, 16),
        Offset(11, 21),
        Offset(21, 21),
      ]) {
        canvas.drawCircle(point, 1.25, Paint()..color = color);
      }
    } else if (keyName.contains('electric') ||
        keyName.contains('energy') ||
        keyName.contains('heat')) {
      canvas.drawPath(
        Path()
          ..moveTo(18, 3)
          ..lineTo(8, 18)
          ..lineTo(15, 18)
          ..lineTo(13, 29)
          ..lineTo(25, 13)
          ..lineTo(18, 13)
          ..close(),
        p,
      );
    } else if (keyName.contains('wave') ||
        keyName.contains('motion') ||
        keyName.contains('dynamic')) {
      canvas.drawLine(const Offset(3, 16), const Offset(29, 16), p);
      canvas.drawPath(
        Path()
          ..moveTo(3, 16)
          ..cubicTo(7, 3, 11, 3, 15, 16)
          ..cubicTo(19, 29, 23, 29, 29, 16),
        p..strokeWidth = 2.2,
      );
    } else if (keyName.contains('atomic') ||
        keyName.contains('magnet') ||
        keyName.contains('matter')) {
      canvas.drawCircle(const Offset(16, 16), 2.4, Paint()..color = color);
      for (var i = 0; i < 3; i++) {
        canvas.save();
        canvas.translate(16, 16);
        canvas.rotate(i * math.pi / 3);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 25, height: 9),
          p,
        );
        canvas.restore();
      }
    } else if (keyName.contains('trigonometry')) {
      canvas.drawCircle(const Offset(16, 16), 11, p);
      canvas.drawLine(const Offset(16, 16), const Offset(25, 10), p);
      canvas.drawArc(
        const Rect.fromLTWH(11, 11, 10, 10),
        -math.pi / 3,
        math.pi / 3,
        false,
        p,
      );
    } else {
      canvas.drawCircle(const Offset(16, 16), 11, p);
      canvas.drawPath(
        Path()
          ..moveTo(8, 11)
          ..lineTo(24, 11)
          ..moveTo(8, 16)
          ..lineTo(20, 16)
          ..moveTo(8, 21)
          ..lineTo(24, 21),
        p,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TopicGlyphPainter oldDelegate) =>
      oldDelegate.keyName != keyName || oldDelegate.color != color;
}

/// The one subject mark used everywhere: summation for Mathematics, the
/// atom for Physics. The lightning bolt is reserved for XP.
class SubjectGlyph extends StatelessWidget {
  const SubjectGlyph({
    required this.subject,
    required this.color,
    this.size = GaussIconSizes.standard,
    super.key,
  });

  final Subject subject;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => subject == Subject.math
      ? Icon(Icons.functions_rounded, color: color, size: size)
      : TopicGlyph(topicKey: 'atomic_nuclear', color: color, size: size + 1);
}

/// Shared raster providers. One provider per picture means one decoded
/// bitmap in the image cache, however many surfaces show it. (Each distinct
/// `cacheWidth` used to be its own cache entry, so the same 941px backdrop was
/// decoded up to six times.)
abstract final class GaussImages {
  static const atmosphere = AssetImage(
    'assets/visual/map/orrery_atmosphere_portrait.png',
  );
}
