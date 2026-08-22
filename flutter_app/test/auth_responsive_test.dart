import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/auth/gauss_auth_controller.dart';
import 'package:gauss/auth/gauss_auth_screen.dart';
import 'package:gauss/widgets/gauss_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;
  late GaussAuthController controller;

  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_test_only',
    );
    controller = GaussAuthController(client);
  });

  tearDown(() {
    controller.dispose();
    client.dispose();
  });

  for (final testCase
      in const <
        ({String name, Size size, double textScale, String compositionKey})
      >[
        (
          name: 'phone portrait',
          size: Size(320, 760),
          textScale: 1,
          compositionKey: 'auth-phone-portrait',
        ),
        (
          name: 'phone portrait at 200 percent text',
          size: Size(320, 760),
          textScale: 2,
          compositionKey: 'auth-phone-portrait',
        ),
        (
          name: 'tablet portrait',
          size: Size(800, 1280),
          textScale: 1,
          compositionKey: 'auth-tablet-portrait',
        ),
        (
          name: 'tablet portrait at 200 percent text',
          size: Size(800, 1280),
          textScale: 2,
          compositionKey: 'auth-tablet-portrait',
        ),
        (
          name: 'tablet landscape',
          size: Size(1280, 800),
          textScale: 1,
          compositionKey: 'auth-tablet-landscape',
        ),
        (
          name: 'tablet landscape at 200 percent text',
          size: Size(1280, 800),
          textScale: 2,
          compositionKey: 'auth-tablet-landscape',
        ),
      ]) {
    testWidgets('${testCase.name} owns an intentional safe composition', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(testCase.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _AuthHarness(controller: controller, textScale: testCase.textScale),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(ValueKey(testCase.compositionKey)), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Works offline after sign in'), findsOneWidget);
      final markRect = tester.getRect(
        find.byKey(const ValueKey('auth-theorem-mark')),
      );
      final wordmarkRect = tester.getRect(find.byType(GaussWordmark));
      expect(
        (markRect.center.dx - wordmarkRect.center.dx).abs(),
        lessThan(.1),
        reason: 'The transparent theorem mark and wordmark must share a center',
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.overflow == TextOverflow.ellipsis &&
              !const {
                'Email',
                'Password',
                'you@example.com',
              }.contains(widget.data),
        ),
        findsNothing,
      );
      for (final key in const [
        'auth-mode-signIn',
        'auth-mode-createAccount',
        'auth-email-field',
        'auth-password-field',
        'auth-password-visibility',
        'auth-submit-action',
      ]) {
        final finder = find.byKey(ValueKey(key));
        expect(finder, findsOneWidget, reason: '$key missing');
        await tester.ensureVisible(finder);
        await tester.pump(const Duration(milliseconds: 120));
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(testCase.size.width));
        expect(rect.bottom, lessThanOrEqualTo(testCase.size.height));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      if (testCase.textScale > 1.3) {
        expect(find.byKey(const ValueKey('auth-mode-stacked')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tablet landscape remains operable with the keyboard open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _AuthHarness(
        controller: controller,
        textScale: 2,
        viewInsets: const EdgeInsets.only(bottom: 320),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('auth-password-field')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('auth-tablet-landscape')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-submit-action')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('auth-submit-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _AuthHarness extends StatelessWidget {
  const _AuthHarness({
    required this.controller,
    required this.textScale,
    this.viewInsets = EdgeInsets.zero,
  });

  final GaussAuthController controller;
  final double textScale;
  final EdgeInsets viewInsets;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildGaussTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        viewInsets: viewInsets,
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: GaussAuthScreen(controller: controller),
  );
}
