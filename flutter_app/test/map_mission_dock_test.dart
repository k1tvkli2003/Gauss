import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/screens/map_screen.dart';
import 'package:gauss/state/gauss_controller.dart';

Finder _assetImage(String assetName) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == assetName,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the compact map dock distinguishes the current study set from a selected set',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final database = GaussDatabase(NativeDatabase.memory());
      final controller = GaussController(
        QuestionBankRepository(),
        ProgressRepository(database),
      );
      addTearDown(() async {
        controller.dispose();
        await database.close();
      });
      await tester.binding.setSurfaceSize(const Size(411, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(controller.initialize);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          home: GaussScope(
            controller: controller,
            child: const Scaffold(body: MapScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('CURRENT MISSION'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^CURRENT MISSION\.')),
        findsOneWidget,
      );
      expect(
        _assetImage('assets/visual/mascot/mira_thinking.png'),
        findsNothing,
        reason:
            'distant landmark art must not compete with the first map frame',
      );
      await tester.tap(find.byKey(const ValueKey('map-node-sets:5:5')));
      await tester.pumpAndSettle();

      expect(find.text('SELECTED LESSON'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^SELECTED LESSON\.')),
        findsOneWidget,
      );

      final routeScroll = find.byKey(const ValueKey('map-study-path-scroll'));
      final scrollable = find.descendant(
        of: routeScroll,
        matching: find.byType(Scrollable),
      );
      await tester.drag(routeScroll, const Offset(0, -320));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );

      await tester.tap(find.byKey(const ValueKey('map-subject-physics')));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        0,
        reason: 'a new subject must start at the beginning of its route',
      );
      expect(
        find.bySemanticsLabel(RegExp('Physics study path')),
        findsOneWidget,
      );

      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
