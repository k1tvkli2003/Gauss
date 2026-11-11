import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/features/insights/insights_screen.dart';
import 'package:gauss/features/map/map_screen.dart';
import 'package:gauss/features/mission/mission_screen.dart';
import 'package:gauss/features/study/study_hub_screen.dart';
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

  testWidgets('Map Study and Insights switch with a quiet fade-through', (
    tester,
  ) async {
    await _pumpGauss(tester, controller);

    expect(find.byType(MapScreen), findsOneWidget);
    expect(_routeOf(tester, find.byType(MapScreen)), '/map');

    await tester.tap(_compactDestination('Study'));
    await tester.pump();

    expect(find.byType(StudyHubScreen), findsOneWidget);
    expect(_routeOf(tester, find.byType(StudyHubScreen)), '/study');
    expect(_branchFade(tester).opacity.value, closeTo(0, .001));
    expect(
      _branchFade(tester).child,
      isNot(isA<SlideTransition>()),
      reason: 'peer destinations fade; they do not travel',
    );

    await tester.pump(const Duration(milliseconds: 110));
    expect(_branchFade(tester).opacity.value, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_branchFade(tester).opacity.value, 1);

    await tester.tap(_compactDestination('Insights'));
    await tester.pump();
    expect(find.byType(InsightsScreen), findsOneWidget);
    expect(_routeOf(tester, find.byType(InsightsScreen)), '/insights');
    expect(_branchFade(tester).opacity.value, closeTo(0, .001));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(_compactDestination('Map'));
    await tester.pump();
    expect(find.byType(MapScreen), findsOneWidget);
    expect(_routeOf(tester, find.byType(MapScreen)), '/map');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'detail push fades in after a short delay and fades out on back',
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
      expect(_spatialFade(tester).opacity.value, closeTo(0, .001));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        _spatialFade(tester).opacity.value,
        closeTo(0, .001),
        reason: 'the incoming page waits 60ms before fading in',
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(_spatialFade(tester).opacity.value, inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_spatialFade(tester).opacity.value, 1);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 70));
      expect(_spatialFade(tester).opacity.value, inExclusiveRange(0, 1));

      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byType(StudyHubScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(StudyHubScreen)), '/study');
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
      expect(find.byType(StudyHubScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(StudyHubScreen)), '/study');
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
      expect(find.byType(StudyHubScreen), findsOneWidget);
      expect(_routeOf(tester, find.byType(StudyHubScreen)), '/study');
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
    expect(_branchFade(tester).opacity.value, lessThan(1));

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('gauss-branch-route-motion')),
      findsNothing,
    );
    expect(find.byType(StudyHubScreen), findsOneWidget);
    expect(_routeOf(tester, find.byType(StudyHubScreen)), '/study');

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pump();
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

FadeTransition _spatialFade(WidgetTester tester) =>
    tester.widget<FadeTransition>(
      find.byKey(const ValueKey('gauss-spatial-route-motion')),
    );
