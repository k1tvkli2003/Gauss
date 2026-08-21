import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const _defaultTimeout = Duration(seconds: 30);

Future<void> main() async {
  final outputPath = Platform.environment['GAUSS_PERF_OUTPUT'];
  if (outputPath == null || outputPath.trim().isEmpty) {
    throw StateError('GAUSS_PERF_OUTPUT must name an isolated run directory.');
  }
  final outputDirectory = Directory(outputPath)..createSync(recursive: true);
  final driver = await FlutterDriver.connect(
    printCommunication: false,
    timeout: _defaultTimeout,
  );
  final report = <String, dynamic>{
    'captured_at_utc': DateTime.now().toUtc().toIso8601String(),
    'cache_state': Platform.environment['GAUSS_PERF_CACHE_STATE'],
    'journeys': <String, dynamic>{},
  };

  try {
    await _waitForHarnessReady(driver);
    await driver.runUnsynchronized(() async {
      final mapScroll = find.byValueKey('map-study-path-scroll');
      await driver.waitFor(mapScroll, timeout: _defaultTimeout);
      final environment =
          jsonDecode(
                await driver.requestData(
                  'environment',
                  timeout: _defaultTimeout,
                ),
              )
              as Map<String, dynamic>;
      report['environment'] = environment;
      await File(
        '${outputDirectory.path}${Platform.pathSeparator}map.png',
      ).writeAsBytes(await driver.screenshot());
      report['semantics'] = <String, dynamic>{
        'map_mission_action': await _semanticsIdOrNull(
          driver,
          find.byValueKey('map-study-dock-action'),
        ),
        'selected_map_node': await _semanticsIdOrNull(
          driver,
          find.byValueKey('map-node-${environment['selected_node_key']}'),
        ),
      };

      (report['journeys']
          as Map<String, dynamic>)['map_scroll'] = await _captureJourney(
        driver,
        outputDirectory,
        'map_scroll',
        () async {
          for (var cycle = 0; cycle < 4; cycle++) {
            final delta = cycle.isEven ? -620.0 : 620.0;
            for (var step = 0; step < 6; step++) {
              await driver.scroll(
                mapScroll,
                0,
                delta,
                const Duration(milliseconds: 760),
                frequency: 60,
                timeout: _defaultTimeout,
              );
              await Future<void>.delayed(const Duration(milliseconds: 120));
            }
          }
          await driver.tap(
            find.byValueKey('map-node-${environment['selected_node_key']}'),
            timeout: _defaultTimeout,
          );
        },
      );

      (report['journeys']
          as Map<String, dynamic>)['map_to_mission'] = await _captureJourney(
        driver,
        outputDirectory,
        'map_to_mission',
        () async {
          await driver.tap(
            find.byValueKey('map-study-dock-action'),
            timeout: _defaultTimeout,
          );
          await driver.waitFor(
            find.byValueKey('mission-question-scroll'),
            timeout: _defaultTimeout,
          );
          await Future<void>.delayed(const Duration(milliseconds: 450));
        },
      );
      await File(
        '${outputDirectory.path}${Platform.pathSeparator}mission.png',
      ).writeAsBytes(await driver.screenshot());

      final revealChoices = find.byValueKey('mission-reveal-choices-action');
      try {
        await driver.waitFor(
          revealChoices,
          timeout: const Duration(seconds: 2),
        );
        await driver.tap(revealChoices, timeout: _defaultTimeout);
        await Future<void>.delayed(const Duration(milliseconds: 260));
      } on DriverError {
        // Certified questions already expose their choices.
      }

      final writingSpace = find.byValueKey('question-manuscript-writing-space');
      await driver.scrollIntoView(
        writingSpace,
        alignment: 0.5,
        timeout: _defaultTimeout,
      );
      final writingCenter = await driver.getCenter(
        writingSpace,
        timeout: _defaultTimeout,
      );
      (report['journeys']
          as Map<
            String,
            dynamic
          >)['mission_stylus_ink'] = await _captureJourney(
        driver,
        outputDirectory,
        'mission_stylus_ink',
        () async {
          final response = jsonDecode(
            await driver.requestData(
              'stylus:${jsonEncode(<String, dynamic>{'center_x': writingCenter.dx, 'center_y': writingCenter.dy})}',
              timeout: _defaultTimeout,
            ),
          );
          if (response case <String, dynamic>{'stylus': 'accepted'}) {
            await driver.waitFor(
              find.byValueKey('mission-ink-controls'),
              timeout: _defaultTimeout,
            );
            return;
          }
          throw StateError('Stylus stroke was not accepted: $response');
        },
      );
      (report['semantics'] as Map<String, dynamic>)['mission_choice'] =
          await _semanticsIdOrNull(driver, find.byValueKey('mission-choice-0'));
      (report['semantics'] as Map<String, dynamic>)['mission_ink_controls'] =
          await _semanticsIdOrNull(
            driver,
            find.byValueKey('mission-ink-controls'),
          );

      (report['journeys'] as Map<String, dynamic>)['mission_touch_answer'] =
          await _captureJourney(
            driver,
            outputDirectory,
            'mission_touch_answer',
            () async {
              await driver.scroll(
                writingSpace,
                118,
                24,
                const Duration(milliseconds: 520),
                frequency: 60,
                timeout: _defaultTimeout,
              );

              final questionScroll = find.byValueKey('mission-question-scroll');
              await driver.scroll(
                questionScroll,
                0,
                -430,
                const Duration(milliseconds: 700),
                frequency: 60,
                timeout: _defaultTimeout,
              );
              final choice = find.byValueKey('mission-choice-0');
              await driver.waitFor(choice, timeout: _defaultTimeout);
              await driver.scrollIntoView(
                choice,
                alignment: 0.5,
                timeout: _defaultTimeout,
              );
              await driver.tap(choice, timeout: _defaultTimeout);
              await Future<void>.delayed(const Duration(milliseconds: 180));
              await driver.tap(
                find.byValueKey('mission-primary-action'),
                timeout: _defaultTimeout,
              );
              await Future<void>.delayed(const Duration(milliseconds: 520));
              await driver.waitFor(
                find.byValueKey('mission-ink-controls'),
                timeout: _defaultTimeout,
              );
            },
          );

      (report['journeys']
          as Map<String, dynamic>)['mission_to_map'] = await _captureJourney(
        driver,
        outputDirectory,
        'mission_to_map',
        () async {
          await driver.tap(
            find.byValueKey('mission-close-action'),
            timeout: _defaultTimeout,
          );
          final leave = find.text('Leave');
          await driver.waitFor(leave, timeout: _defaultTimeout);
          await driver.tap(leave, timeout: _defaultTimeout);
          await driver.waitFor(
            find.byValueKey('map-study-path-scroll'),
            timeout: _defaultTimeout,
          );
          await Future<void>.delayed(const Duration(milliseconds: 450));
        },
      );
    }, timeout: _defaultTimeout);
    report['status'] = 'passed';
  } catch (error, stackTrace) {
    report['status'] = 'failed';
    report['error'] = error.toString();
    report['stack_trace'] = stackTrace.toString();
    rethrow;
  } finally {
    final reportFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}journeys.json',
    );
    reportFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    await driver.close();
  }
}

Future<int?> _semanticsIdOrNull(
  FlutterDriver driver,
  SerializableFinder finder,
) async {
  try {
    return await driver.getSemanticsId(finder, timeout: _defaultTimeout);
  } on DriverError {
    return null;
  }
}

Future<void> _waitForHarnessReady(FlutterDriver driver) async {
  final deadline = DateTime.now().add(_defaultTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final response = jsonDecode(
      await driver.requestData('ready', timeout: _defaultTimeout),
    );
    if (response case <String, dynamic>{'ready': true}) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  throw TimeoutException('Gauss did not reach its first usable frame.');
}

Future<Map<String, dynamic>> _captureJourney(
  FlutterDriver driver,
  Directory outputDirectory,
  String name,
  Future<void> Function() action,
) async {
  final wallClock = Stopwatch()..start();
  final timeline = await driver.traceAction(action);
  wallClock.stop();
  final summary = TimelineSummary.summarize(timeline);
  await summary.writeTimelineToFile(
    name,
    destinationDirectory: outputDirectory.path,
    pretty: true,
  );
  return <String, dynamic>{
    ...summary.summaryJson,
    '95th_percentile_frame_build_time_millis': summary
        .computePercentileFrameBuildTimeMillis(95),
    '95th_percentile_frame_rasterizer_time_millis': summary
        .computePercentileFrameRasterizerTimeMillis(95),
    'wall_clock_millis': wallClock.elapsedMilliseconds,
  };
}
