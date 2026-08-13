import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_design_system.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/screens/practice_screen.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GaussDatabase database;
  late GaussController controller;

  setUp(() async {
    database = GaussDatabase(NativeDatabase.memory());
    controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  testWidgets(
    'phone Study makes Current Study the single primary path into learning',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(411, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _StudyFixture(controller: controller);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pump();

      expect(
        find.byKey(const ValueKey('study-course-instrument')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('study-today')), findsOneWidget);
      expect(find.text('CURRENT STUDY'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('study-primary-continue')),
        findsOneWidget,
      );
      expect(find.text('NEXT 5'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('study-primary-continue')),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      final continueRect = tester.getRect(
        find.byKey(const ValueKey('study-primary-continue')),
      );
      expect(continueRect.height, greaterThanOrEqualTo(48));
      expect(continueRect.top, greaterThanOrEqualTo(0));
      expect(
        continueRect.bottom,
        lessThanOrEqualTo(724),
        reason: 'The primary action must stay above compact navigation.',
      );
      expect(
        find.byKey(const ValueKey('study-current-section-axis')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('study-course-instrument')))
            .height,
        lessThanOrEqualTo(86),
        reason: 'The course switch must stay a content-hugging rail.',
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('study-today'))).height,
        lessThanOrEqualTo(250),
        reason: 'Current Study must stay a compact mission console.',
      );

      final expected = GaussStudyCurriculum.nodesFor(
        GaussStudyCurriculum.forSubject(controller.selectedTopic.subject).first,
        controller.topics,
      ).first;
      expect(
        find.bySemanticsLabel(
          'Continue ${expected.topic.label}, Session ${expected.partIndex + 1} of ${expected.partCount}',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'course and chapter instruments keep independent exact center axes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(411, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _StudyFixture(controller: controller);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app());
      await tester.pump();

      final headerAxis = tester.getRect(
        find.byKey(const ValueKey('study-header-axis')),
      );
      final headerWordmark = tester.getRect(
        find.byKey(const ValueKey('study-centered-wordmark')),
      );
      final offlineTrack = tester.getRect(
        find.byKey(const ValueKey('study-offline-track')),
      );
      final scratchTrack = tester.getRect(
        find.byKey(const ValueKey('study-scratch-track')),
      );
      expect(headerWordmark.center.dx, closeTo(headerAxis.center.dx, .5));
      expect(offlineTrack.size, const Size.square(48));
      expect(scratchTrack.size, const Size.square(48));
      expect(
        headerAxis.center.dx - offlineTrack.center.dx,
        closeTo(scratchTrack.center.dx - headerAxis.center.dx, .5),
      );

      final course = find.byKey(const ValueKey('study-course-instrument'));
      final math = find.byKey(const ValueKey('study-subject-math'));
      final physics = find.byKey(const ValueKey('study-subject-physics'));
      final courseAxis = tester.getCenter(course).dx;
      final mathRect = tester.getRect(math);
      final physicsRect = tester.getRect(physics);
      expect(mathRect.width, closeTo(physicsRect.width, .5));
      expect(mathRect.height, closeTo(physicsRect.height, .5));
      expect(
        courseAxis - mathRect.center.dx,
        closeTo(physicsRect.center.dx - courseAxis, .5),
      );
      expect(
        tester
            .getCenter(find.byKey(const ValueKey('study-course-axis-label')))
            .dx,
        closeTo(courseAxis, .5),
      );
      expect(mathRect.height, greaterThanOrEqualTo(48));
      expect(physicsRect.height, greaterThanOrEqualTo(48));
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);

      final sectionAxis = find.byKey(
        const ValueKey('study-current-section-axis'),
      );
      final sectionAxisX = tester.getCenter(sectionAxis).dx;
      final sectionLabel = find.byKey(
        const ValueKey('study-current-section-label'),
      );
      final previous = find.byKey(const ValueKey('study-previous-section'));
      final next = find.byKey(const ValueKey('study-next-section'));
      final previousRect = tester.getRect(previous);
      final nextRect = tester.getRect(next);
      expect(tester.getCenter(sectionLabel).dx, closeTo(sectionAxisX, .5));
      expect(previousRect.size, nextRect.size);
      expect(previousRect.height, greaterThanOrEqualTo(48));
      expect(nextRect.height, greaterThanOrEqualTo(48));
      expect(
        sectionAxisX - previousRect.center.dx,
        closeTo(nextRect.center.dx - sectionAxisX, .5),
      );
      for (final surface in [
        find.byKey(const ValueKey('study-balanced-header')),
        course,
        find.byKey(const ValueKey('study-today')),
      ]) {
        expect(
          find.descendant(
            of: surface,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text && widget.overflow == TextOverflow.ellipsis,
            ),
          ),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'accessible phone gives chapter copy a full-width whole-word axis',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 711));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _StudyFixture(controller: controller);
      addTearDown(fixture.dispose);

      await tester.pumpWidget(fixture.app(textScale: 2, reducedMotion: true));
      await tester.pump();

      final course = find.byKey(const ValueKey('study-course-instrument'));
      final math = find.byKey(const ValueKey('study-subject-math'));
      final physics = find.byKey(const ValueKey('study-subject-physics'));
      final mathRect = tester.getRect(math);
      final physicsRect = tester.getRect(physics);
      expect(mathRect.center.dy, closeTo(physicsRect.center.dy, .5));
      expect(mathRect.overlaps(physicsRect), isFalse);
      expect(mathRect.height, greaterThanOrEqualTo(48));
      expect(physicsRect.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSize(course).height,
        lessThanOrEqualTo(112),
        reason:
            'At 200% the subject chooser must recompose into two compact '
            'orbits instead of two oversized stacked cards.',
      );
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);

      final axis = find.byKey(const ValueKey('study-current-section-axis'));
      final label = find.byKey(const ValueKey('study-current-section-label'));
      final title = find.byKey(const ValueKey('study-current-section-title'));
      expect(axis, findsOneWidget);
      expect(label, findsOneWidget);
      expect(title, findsOneWidget);
      expect(
        tester.getCenter(label).dx,
        closeTo(tester.getCenter(axis).dx, .5),
      );

      final titleRect = tester.getRect(title);
      final expectedTitle = GaussStudyCurriculum.forSubject(
        controller.selectedTopic.subject,
      ).first.title;
      for (final word in expectedTitle.split(' ')) {
        final wordFinder = find.descendant(
          of: title,
          matching: find.text(word),
        );
        expect(wordFinder, findsOneWidget);
        final wordText = tester.widget<Text>(wordFinder);
        expect(wordText.maxLines, 1);
        expect(wordText.softWrap, isFalse);
        final wordRect = tester.getRect(wordFinder);
        expect(wordRect.left, greaterThanOrEqualTo(titleRect.left - .5));
        expect(wordRect.right, lessThanOrEqualTo(titleRect.right + .5));
        expect(wordRect.top, greaterThanOrEqualTo(titleRect.top - .5));
        expect(wordRect.bottom, lessThanOrEqualTo(titleRect.bottom + .5));
      }

      expect(
        tester
            .getSize(find.byKey(const ValueKey('study-previous-section')))
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('study-next-section'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        find.byKey(const ValueKey('study-accessible-current-mission')),
        findsOneWidget,
      );
      final currentStudyRect = tester.getRect(
        find.byKey(const ValueKey('study-today')),
      );
      final continueRect = tester.getRect(
        find.byKey(const ValueKey('study-primary-continue')),
      );
      const compactContentBottom = 711 - GaussMetrics.compactChromeReserve;
      expect(
        currentStudyRect.bottom,
        lessThanOrEqualTo(compactContentBottom + .5),
        reason:
            'The complete Current Study instrument must clear the floating '
            'footer on the initial 320dp/200% frame.',
      );
      expect(continueRect.bottom, lessThanOrEqualTo(compactContentBottom + .5));
      final breathingRoom = find.byKey(
        const ValueKey('study-accessible-footer-breathing-room'),
        skipOffstage: false,
      );
      expect(breathingRoom, findsOneWidget);
      expect(tester.getSize(breathingRoom).height, 64);
      final library = find.text('Library', skipOffstage: false);
      expect(library, findsOneWidget);
      expect(
        tester.getRect(library).top,
        greaterThanOrEqualTo(compactContentBottom),
        reason:
            'The next section must enter as a complete block instead of '
            'leaving a clipped heading beside the floating footer.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('chapter controls change Current Study and keep five questions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(411, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _StudyFixture(controller: controller);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await tester.pump();

    final sections = GaussStudyCurriculum.forSubject(
      controller.selectedTopic.subject,
    );
    void expectCurrentSectionTitle(String title) {
      final titleFrame = find.byKey(
        const ValueKey('study-current-section-title'),
      );
      expect(titleFrame, findsOneWidget);
      for (final word in title.split(' ')) {
        expect(
          find.descendant(of: titleFrame, matching: find.text(word)),
          findsOneWidget,
        );
      }
    }

    expectCurrentSectionTitle(sections.first.title);

    await tester.tap(find.byKey(const ValueKey('study-next-section')));
    await tester.pump(const Duration(milliseconds: 240));
    expect(
      sections[1].topicKeys,
      contains(controller.selectedTopicKey),
      reason: 'The chapter instrument must update the shared learning context.',
    );
    expectCurrentSectionTitle(sections[1].title);
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('study-subject-math')))
          .properties
          .selected,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('study-primary-continue')));
    await tester.pumpAndSettle();
    expect(find.text('MISSION DESTINATION'), findsOneWidget);
    final uri = fixture.openedStudyUri!;
    expect(uri.pathSegments.first, 'mission');
    final offset = int.parse(uri.queryParameters['offset']!);
    final questions = await tester.runAsync(
      () => controller.createStudySessionMission(
        uri.pathSegments.last,
        offset: offset,
      ),
    );
    expect(questions, hasLength(GaussStudyCurriculum.batchSize));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Library keeps every tool and chapter one tap reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(411, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _StudyFixture(controller: controller);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('study-library-tools')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    for (final label in const [
      'Revisit orbit',
      'Gem shelf',
      'Scratchpad',
      'Path atlas',
    ]) {
      final tool = find.byKey(ValueKey('study-mode-$label'));
      expect(tool, findsOneWidget);
      expect(tester.getSize(tool).height, greaterThanOrEqualTo(48));
    }

    final sections = GaussStudyCurriculum.forSubject(
      controller.selectedTopic.subject,
    );
    final firstToggle = find.byKey(
      ValueKey('study-section-toggle-${sections.first.id}'),
    );
    await tester.scrollUntilVisible(
      firstToggle,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(firstToggle, findsOneWidget);
    expect(tester.widget<Semantics>(firstToggle).properties.expanded, isFalse);

    await tester.tap(firstToggle);
    await tester.pump(const Duration(milliseconds: 240));
    expect(tester.widget<Semantics>(firstToggle).properties.expanded, isTrue);
    expect(find.text(controller.topics.first.label), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Study adapts its Library tools for tablet and 200 percent text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _StudyFixture(controller: controller);
    addTearDown(fixture.dispose);

    await tester.binding.setSurfaceSize(const Size(800, 900));
    await tester.pumpWidget(fixture.app());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('study-library-tools')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final tools = [
      for (final label in const [
        'Revisit orbit',
        'Gem shelf',
        'Scratchpad',
        'Path atlas',
      ])
        tester.getCenter(find.byKey(ValueKey('study-mode-$label'))),
    ];
    expect(tools[1].dy, closeTo(tools[0].dy, 1));
    expect(tools[3].dy, closeTo(tools[2].dy, 1));
    expect(tools[2].dy, greaterThan(tools[0].dy + 40));

    await tester.pumpWidget(fixture.app(textScale: 2, reducedMotion: true));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('study-library-tools')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    final accessibleTabletTools = [
      for (final label in const [
        'Revisit orbit',
        'Gem shelf',
        'Scratchpad',
        'Path atlas',
      ])
        tester.getCenter(find.byKey(ValueKey('study-mode-$label'))),
    ];
    for (var index = 1; index < accessibleTabletTools.length; index++) {
      expect(
        accessibleTabletTools[index].dy,
        greaterThan(accessibleTabletTools[index - 1].dy + 40),
        reason: 'Accessible tablet tools must reflow instead of squeeze.',
      );
    }
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump();
    final lastSectionKey = ValueKey(
      'study-section-${GaussStudyCurriculum.forSubject(controller.selectedTopic.subject).last.id}',
    );
    await tester.scrollUntilVisible(
      find.byKey(lastSectionKey),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(lastSectionKey), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    final accessiblePhoneFixture = _StudyFixture(controller: controller);
    addTearDown(accessiblePhoneFixture.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 760));
    await tester.pumpWidget(
      accessiblePhoneFixture.app(textScale: 2, reducedMotion: true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    for (final subject in const ['math', 'physics']) {
      final switchTarget = find.byKey(ValueKey('study-subject-$subject'));
      expect(tester.getSize(switchTarget).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(switchTarget).width, greaterThanOrEqualTo(120));
    }
    expect(find.bySemanticsLabel('Mathematics'), findsOneWidget);
    expect(find.bySemanticsLabel('Physics'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('study-primary-continue')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('study-primary-continue')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(lastSectionKey),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(lastSectionKey), findsOneWidget);
    final lastChapter = GaussStudyCurriculum.forSubject(
      controller.selectedTopic.subject,
    ).last;
    final lastToggle = find.byKey(
      ValueKey('study-section-toggle-${lastChapter.id}'),
    );
    await tester.ensureVisible(lastToggle);
    await tester.pump();
    await tester.tap(lastToggle);
    await tester.pump();
    final lastTopic = controller.topics.firstWhere(
      (topic) => topic.key == lastChapter.topicKeys.last,
    );
    await tester.ensureVisible(find.text(lastTopic.label));
    await tester.pump();
    expect(find.text(lastTopic.label), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _StudyFixture {
  _StudyFixture({required this.controller}) {
    router = GoRouter(
      initialLocation: '/study',
      routes: [
        GoRoute(
          path: '/study',
          builder: (context, state) => const Scaffold(body: PracticeScreen()),
        ),
        GoRoute(
          path: '/mission/:topicKey',
          builder: (context, state) {
            openedStudyUri = state.uri;
            return const Scaffold(
              body: Center(child: Text('MISSION DESTINATION')),
            );
          },
        ),
        for (final path in const ['/study/revisit', '/study/gems', '/map'])
          GoRoute(
            path: path,
            builder: (context, state) =>
                Scaffold(body: Center(child: Text(path))),
          ),
      ],
    );
  }

  final GaussController controller;
  late final GoRouter router;
  Uri? openedStudyUri;

  Widget app({double textScale = 1, bool reducedMotion = false}) =>
      MaterialApp.router(
        theme: buildGaussTheme(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: GaussScope(controller: controller, child: child!),
        ),
      );

  void dispose() => router.dispose();
}
