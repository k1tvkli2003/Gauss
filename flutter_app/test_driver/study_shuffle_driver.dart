import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

/// Exercises only the isolated probe account, through real Study controls.
Future<void> main() async {
  final output = Platform.environment['GAUSS_STUDY_OUTPUT'];
  if (output == null) throw StateError('GAUSS_STUDY_OUTPUT is required');
  final directory = Directory(output)..createSync(recursive: true);
  final driver = await FlutterDriver.connect();
  const timeout = Duration(seconds: 45);
  try {
    final startup = Stopwatch()..start();
    while (true) {
      final ready = jsonDecode(await driver.requestData('ready')) as Map;
      if (ready['ready'] == true) break;
      if (startup.elapsed > timeout) throw StateError('First frame timed out');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await driver.runUnsynchronized(() async {
      await driver.waitFor(find.text('STUDY ROOM'), timeout: timeout);
      final before = jsonDecode(await driver.requestData('evidence')) as Map;
      if (before['fixture_reflections'] != 0 ||
          before['persisted_records'] != 0) {
        throw StateError('Shuffle probe requires a fresh, uncharted set');
      }
      final question = find.byValueKey(
        'study-ink-${before['first_question_id']}',
      );
      await driver.waitFor(question, timeout: timeout);
      final choice = find.bySemanticsLabel(RegExp(r'^Choice 1\.'));
      await driver.scrollIntoView(choice, alignment: .5, timeout: timeout);
      await driver.tap(choice, timeout: timeout);
      final selected = find.bySemanticsLabel(
        RegExp(r'Choice 1\..*Your private hypothesis\.'),
      );
      await driver.waitFor(selected, timeout: timeout);
      await File(
        '${directory.path}/shuffle-before.png',
      ).writeAsBytes(await driver.screenshot());
      await driver.tap(
        find.byValueKey('study-room-shuffle-action'),
        timeout: timeout,
      );
      await driver.waitFor(find.text('STUDY ROOM'), timeout: timeout);
      // Visit each slot through the real jump control until the original
      // source question is on screen. No probe handler mutates widget state.
      var located = false;
      for (var slot = 1; slot <= 5; slot++) {
        await driver.tap(find.byValueKey('study-room-jump-action'));
        await driver.tap(find.byValueKey('study-room-jump-question-$slot'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
        try {
          await driver.waitFor(question, timeout: const Duration(seconds: 1));
          await driver.waitFor(selected, timeout: const Duration(seconds: 1));
          located = true;
          break;
        } on DriverError {
          // Another slot is expected until the selected question is reached.
        }
      }
      if (!located) throw StateError('Shuffle lost the private hypothesis');
      await driver.scrollIntoView(selected, alignment: .5, timeout: timeout);
      final semanticsId = await driver.getSemanticsId(selected);
      await File(
        '${directory.path}/shuffle-after.png',
      ).writeAsBytes(await driver.screenshot());
      final after = jsonDecode(await driver.requestData('evidence')) as Map;
      if (after['persisted_records'] != 0 || after['encountered_slots'] != 0) {
        throw StateError('Shuffle must not chart or reward an unsaved answer');
      }
      await File('${directory.path}/result.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'status': 'passed',
          'captured_at': DateTime.now().toUtc().toIso8601String(),
          'before': before,
          'after': after,
          'selected_hypothesis_semantics_id': semanticsId,
          'scope': 'Android UI selection, shuffle, original question, no write',
        }),
      );
    });
  } finally {
    await driver.close();
  }
}
