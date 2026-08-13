import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/widgets/content_blocks.dart';

const _repair1248 =
    'پاسخ موجود متعلق به سؤال دیگری است. '
    r'بزرگ‌ترین طول بازهٔ نزولی $2-(-\frac12)=\frac52=۲٫۵$ است. '
    'مقدار باید ۲٫۵ خوانده و رندر شود، نه کسر دوپنجم.';

const _repair1429 =
    r"برای $t\ge0$ داریم $C'(t)=\frac{81-6t^3}{(27+t^3)^2}$. "
    r'بیشینه در $t^3=\frac{27}{2}=۱۳٫۵$ رخ می‌دهد. '
    'مقدار باید ۱۳٫۵ خوانده و رندر شود، نه کسر سیزده‌پنجم.';

void main() {
  test('repaired locale decimals enter TeX as decimal numbers', () {
    final firstMath = parseMathContent(
      _repair1248,
    ).where((segment) => segment.isMath).map((segment) => segment.value);
    final secondMath = parseMathContent(
      _repair1429,
    ).where((segment) => segment.isMath).map((segment) => segment.value);

    expect(firstMath, contains(r'2-(-\frac12)=\frac52=2.5'));
    expect(secondMath, contains(r't^3=\frac{27}{2}=13.5'));
    expect(firstMath.any((value) => value.contains('2/5')), isFalse);
    expect(secondMath.any((value) => value.contains('13/5')), isFalse);
  });

  testWidgets(
    'repaired decimals render at narrow Android width and 200% text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 780),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey('decimal-render-boundary'),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Semantics(
                        key: ValueKey('repair-1248-render'),
                        label: 'Question 1248 repaired decimal 2.5',
                        child: ContentBlocksView(
                          blocks: [TextBlock(_repair1248)],
                        ),
                      ),
                      SizedBox(height: 24),
                      Semantics(
                        key: ValueKey('repair-1429-render'),
                        label: 'Question 1429 repaired decimal 13.5',
                        child: ContentBlocksView(
                          blocks: [TextBlock(_repair1429)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mathWidgets = tester.widgetList<Math>(find.byType(Math)).toList();
      expect(mathWidgets, hasLength(4));
      expect(mathWidgets.every((widget) => widget.parseError == null), isTrue);
      expect(find.textContaining('مقدار باید 2.5'), findsOneWidget);
      expect(find.textContaining('مقدار باید 13.5'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              RegExp(
                r'[\u06f0-\u06f9\u0660-\u0669]',
              ).hasMatch(widget.data ?? ''),
        ),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget.key.toString().contains('math-error-'),
        ),
        findsNothing,
      );

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('decimal-render-boundary')),
      );
      final image = await boundary.toImage(pixelRatio: 1);
      expect(image.width, 360);
      expect(image.height, 780);
      image.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
