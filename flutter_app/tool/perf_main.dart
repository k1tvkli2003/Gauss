import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:gauss/main.dart' as gauss;

const _warmupFrames = 12;
const _reportStep = 30;
const _frameBudgetMicros = 16667;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final samples = <FrameTiming>[];
  var observedFrames = 0;
  var nextReport = _reportStep;

  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      observedFrames += 1;
      if (observedFrames > _warmupFrames) {
        samples.add(timing);
      }
    }

    while (samples.length >= nextReport) {
      _report(samples.take(nextReport).toList(growable: false));
      nextReport += _reportStep;
    }
  });

  await gauss.main();
}

void _report(List<FrameTiming> frames) {
  final uiMicros =
      frames
          .map((frame) => frame.buildDuration.inMicroseconds)
          .toList(growable: false)
        ..sort();
  final rasterMicros =
      frames
          .map((frame) => frame.rasterDuration.inMicroseconds)
          .toList(growable: false)
        ..sort();
  final worstLaneMicros =
      frames
          .map(
            (frame) =>
                frame.buildDuration.inMicroseconds >
                    frame.rasterDuration.inMicroseconds
                ? frame.buildDuration.inMicroseconds
                : frame.rasterDuration.inMicroseconds,
          )
          .toList(growable: false)
        ..sort();

  final slowUi = uiMicros.where((value) => value > _frameBudgetMicros).length;
  final slowRaster = rasterMicros
      .where((value) => value > _frameBudgetMicros)
      .length;

  final message =
      'GAUSS_FRAME_TIMINGS '
      'frames=${frames.length} '
      'ui_p50_us=${_percentile(uiMicros, 0.50)} '
      'ui_p95_us=${_percentile(uiMicros, 0.95)} '
      'ui_p99_us=${_percentile(uiMicros, 0.99)} '
      'raster_p50_us=${_percentile(rasterMicros, 0.50)} '
      'raster_p95_us=${_percentile(rasterMicros, 0.95)} '
      'raster_p99_us=${_percentile(rasterMicros, 0.99)} '
      'worst_lane_p95_us=${_percentile(worstLaneMicros, 0.95)} '
      'slow_ui=$slowUi slow_raster=$slowRaster';
  developer.log(message, name: 'gauss.performance');
  debugPrintSynchronously(message);
}

int _percentile(List<int> sortedValues, double percentile) {
  final index = (sortedValues.length * percentile).ceil() - 1;
  return sortedValues[index.clamp(0, sortedValues.length - 1)];
}
