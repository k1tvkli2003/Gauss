import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/state/gauss_controller.dart';

class _Probe extends StatelessWidget {
  const _Probe(this.builds);
  final List<int> builds;

  @override
  Widget build(BuildContext context) {
    GaussScope.of(context);
    builds.add(builds.length);
    return const SizedBox();
  }
}

void main() {
  testWidgets('a hidden surface defers controller rebuilds until shown', (
    tester,
  ) async {
    final database = GaussDatabase(NativeDatabase.memory());
    final controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
    final builds = <int>[];
    var visible = true;
    late StateSetter setVisible;

    await tester.pumpWidget(
      GaussScope(
        controller: controller,
        child: StatefulBuilder(
          builder: (context, setState) {
            setVisible = setState;
            return TickerMode(
              enabled: visible,
              child: GaussVisibilityGate(child: _Probe(builds)),
            );
          },
        ),
      ),
    );
    expect(builds, hasLength(1));

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    controller.notifyListeners();
    await tester.pump();
    expect(builds, hasLength(2), reason: 'visible surfaces stay live');

    setVisible(() => visible = false);
    await tester.pump();
    final hiddenBaseline = builds.length;
    for (var i = 0; i < 5; i++) {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      controller.notifyListeners();
      await tester.pump();
    }
    expect(builds, hasLength(hiddenBaseline), reason: 'no offstage rebuilds');

    setVisible(() => visible = true);
    await tester.pump();
    expect(
      builds.length,
      hiddenBaseline + 1,
      reason: 'one catch-up rebuild when the surface returns',
    );

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await tester.runAsync(database.close);
  });
}
