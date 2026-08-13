import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/screens/insights_screen.dart';
import 'package:gauss/screens/map_screen.dart';
import 'package:gauss/screens/mission_screen.dart';
import 'package:gauss/screens/practice_screen.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GaussDatabase database;
  late GaussController controller;

  setUpAll(() {
    database = GaussDatabase(NativeDatabase.memory());
    controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
  });

  tearDownAll(() async {
    controller.dispose();
    await database.close();
  });

  testWidgets(
    'Map Study and Insights keep route identity with directional peer motion',
    (tester) async {
      await _pumpGauss(tester, controller);

      expect(find.byType(MapScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(MapScreen)), '/map');

      await tester.tap(_compactDestination('Study'));
      await tester.pump();

      expect(find.byType(PracticeScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(PracticeScreen)), '/study');
      var slide = _branchSlide(tester);
      var fade = _branchFade(tester);
      expect(slide.position.value.dx, closeTo(.034, .001));
      expect(slide.position.value.dy, 0);
      expect(fade.opacity.value, closeTo(.9, .001));

      await tester.pump(const Duration(milliseconds: 140));
      slide = _branchSlide(tester);
      expect(slide.position.value.dx, inExclusiveRange(0, .034));
      await tester.pump(const Duration(milliseconds: 180));
      expect(_branchSlide(tester).position.value, Offset.zero);
      expect(_branchFade(tester).opacity.value, 1);

      await tester.tap(_compactDestination('Insights'));
      await tester.pump();
      expect(find.byType(InsightsScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(InsightsScreen)), '/insights');
      expect(_branchSlide(tester).position.value.dx, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(_compactDestination('Map'));
      await tester.pump();
      expect(find.byType(MapScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(MapScreen)), '/map');
      expect(_branchSlide(tester).position.value.dx, lessThan(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'detail push rises into depth and back settles toward its source',
    (tester) async {
      await _pumpGauss(tester, controller);
      await tester.tap(_compactDestination('Study'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const ValueKey('study-primary-continue')).hitTestable(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(MissionScreen), findsOneWidget);
      expect(
        _routeOf(tester, find.byType(MissionScreen)),
        startsWith('/mission/'),
      );
      var routeFade = _spatialFade(tester);
      var routeSlide = _spatialSlide(tester);
      var routeScale = _spatialScale(tester);
      expect(routeFade.opacity.value, closeTo(0, .001));
      expect(routeSlide.position.value.dy, closeTo(.024, .001));
      expect(routeScale.scale.value, closeTo(.99, .001));

      await tester.pump(const Duration(milliseconds: 170));
      routeSlide = _spatialSlide(tester);
      expect(routeSlide.position.value.dy, inExclusiveRange(0, .024));
      await tester.pump(const Duration(milliseconds: 190));
      expect(_spatialSlide(tester).position.value, Offset.zero);
      expect(_spatialScale(tester).scale.value, 1);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      routeFade = _spatialFade(tester);
      routeSlide = _spatialSlide(tester);
      routeScale = _spatialScale(tester);
      expect(routeFade.opacity.value, inExclusiveRange(0, 1));
      expect(routeSlide.position.value.dy, inExclusiveRange(0, .024));
      expect(routeScale.scale.value, inExclusiveRange(.99, 1));

      await tester.pump(const Duration(milliseconds: 140));
      expect(find.byType(PracticeScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(PracticeScreen)), '/study');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'system disabled animations makes peer detail and back navigation immediate',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await _pumpGauss(tester, controller);
      expect(
        find.byKey(const ValueKey('gauss-branch-route-motion')),
        findsNothing,
      );

      await tester.tap(_compactDestination('Study'));
      await tester.pump();
      expect(find.byType(PracticeScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(PracticeScreen)), '/study');
      expect(
        find.byKey(const ValueKey('gauss-branch-route-motion')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('study-primary-continue')));
      await tester.pump();
      expect(find.byType(MissionScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('gauss-spatial-route-motion')),
        findsNothing,
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(PracticeScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(PracticeScreen)), '/study');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a reduced-motion change settles an active route entrance', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpGauss(tester, controller);

    await tester.tap(_compactDestination('Study'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('gauss-branch-route-motion')),
      findsOneWidget,
    );
    expect(_branchSlide(tester).position.value.dx, greaterThan(0));

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('gauss-branch-route-motion')),
      findsNothing,
    );
    expect(find.byType(PracticeScreen), findsOneWidget);
    expect(_routeOf(tester, find.byType(PracticeScreen)), '/study');

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pump();
    expect(_branchSlide(tester).position.value, Offset.zero);
    expect(_branchFade(tester).opacity.value, 1);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpGauss(WidgetTester tester, GaussController controller) async {
  await tester.binding.setSurfaceSize(const Size(411, 891));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  if (!controller.ready) await tester.runAsync(controller.initialize);
  if (controller.needsTour) await controller.markTourSeen();
  await tester.pumpWidget(GaussApp(controller: controller));
  await tester.pump();
}

Finder _compactDestination(String label) =>
    find.byKey(ValueKey('gauss-nav-${label.toLowerCase()}'));

String _routeOf(WidgetTester tester, Finder screen) =>
    GoRouterState.of(tester.element(screen)).uri.path;

FadeTransition _branchFade(WidgetTester tester) =>
    tester.widget<FadeTransition>(
      find.byKey(const ValueKey('gauss-branch-route-motion')),
    );

SlideTransition _branchSlide(WidgetTester tester) =>
    tester.widget<SlideTransition>(
      find
          .descendant(
            of: find.byKey(const ValueKey('gauss-branch-route-motion')),
            matching: find.byType(SlideTransition),
          )
          .first,
    );

FadeTransition _spatialFade(WidgetTester tester) =>
    tester.widget<FadeTransition>(
      find.byKey(const ValueKey('gauss-spatial-route-motion')),
    );

SlideTransition _spatialSlide(WidgetTester tester) =>
    tester.widget<SlideTransition>(
      find
          .descendant(
            of: find.byKey(const ValueKey('gauss-spatial-route-motion')),
            matching: find.byType(SlideTransition),
          )
          .first,
    );

ScaleTransition _spatialScale(WidgetTester tester) =>
    tester.widget<ScaleTransition>(
      find
          .descendant(
            of: find.byKey(const ValueKey('gauss-spatial-route-motion')),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
