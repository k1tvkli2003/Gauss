import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

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
      await driver.waitFor(
        find.byValueKey('study-ink-${before['last_question_id']}'),
        timeout: timeout,
      );
      await File(
        '${directory.path}/study-before.png',
      ).writeAsBytes(await driver.screenshot());
      final reveal = find.byValueKey('study-room-reveal-source-action');
      await driver.scrollIntoView(reveal, alignment: .5, timeout: timeout);
      await driver.tap(reveal, timeout: timeout);
      final reflect = find.text('Concept feels clear');
      await driver.scrollIntoView(reflect, alignment: .5, timeout: timeout);
      await driver.tap(reflect, timeout: timeout);
      await driver.waitFor(
        find.text('Continue next session'),
        timeout: timeout,
      );
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final recapScreenshot = await driver.screenshot();
      await File(
        '${directory.path}/study-recap.png',
      ).writeAsBytes(recapScreenshot);
      await driver.tap(find.text('Continue next session'), timeout: timeout);
      final next = find.byValueKey('study-ink-${before['next_question_id']}');
      await driver.waitFor(next, timeout: timeout);
      await driver.waitFor(find.text('1 / 5'), timeout: timeout);
      final semanticsId = await driver.getSemanticsId(next, timeout: timeout);
      final after = jsonDecode(await driver.requestData('evidence')) as Map;
      if (after['persisted_records'] != 5 || after['encountered_slots'] != 5) {
        throw StateError('Study completion was not persisted: $after');
      }
      final nextScreenshot = await driver.screenshot();
      await File(
        '${directory.path}/study-next.png',
      ).writeAsBytes(nextScreenshot);
      await File('${directory.path}/result.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'status': 'passed',
          'captured_at': DateTime.now().toUtc().toIso8601String(),
          'before': before,
          'after': after,
          'next_question_semantics_id': semanticsId,
          'screenshot_changed_after_continuation': !recapScreenshot
              .asMap()
              .entries
              .every((entry) => entry.value == nextScreenshot[entry.key]),
          'scope': 'Four seeded reflections; fifth UI save, recap, next set',
        }),
      );
    });
  } finally {
    await driver.close();
  }
}
