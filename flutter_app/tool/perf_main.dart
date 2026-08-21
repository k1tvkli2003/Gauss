import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:go_router/go_router.dart';

import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/auth/gauss_account_session.dart';
import 'package:gauss/domain/study_curriculum.dart';

const _warmupFrames = 24;
const _reportWindow = 120;
final _harnessReport = <String, dynamic>{};

/// Profile-only Gauss entrypoint.
///
/// This target deliberately bypasses remote authentication and opens an
/// isolated, locally persisted performance account inside the
/// `com.gauss.app.profile` sandbox. It exercises the real app, corpus and
/// database paths without reading, replacing or clearing the owner's signed
/// package or account data.
Future<void> main() async {
  final startup = Stopwatch()..start();
  enableFlutterDriverExtension(handler: _handleDriverData);
  SemanticsBinding.instance.ensureSemantics();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  _installFrameReporter();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B1417),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Color(0xFF243337),
    ),
  );

  final session = await GaussAccountSession.open(
    'gauss-performance-harness-v1',
  );
  await session.controller.markTourSeen();
  final selectedTopic = session.controller.selectedTopic;
  final selectedSection = GaussStudyCurriculum.forSubject(
    selectedTopic.subject,
  ).firstWhere((section) => section.topicKeys.contains(selectedTopic.key));
  final selectedNode = GaussStudyCurriculum.nodesFor(
    selectedSection,
    session.controller.topics,
  ).firstWhere((node) => node.topic.key == selectedTopic.key);
  final controllerReadyMicros = startup.elapsedMicroseconds;
  _harnessReport['controller_ready_us'] = controllerReadyMicros;
  _harnessReport['selected_node_key'] = selectedNode.key;
  runApp(
    GaussApp(
      controller: session.controller,
      accountEmail: 'local-performance-harness',
      initialLocation: '/map',
    ),
  );
  SchedulerBinding.instance.addPostFrameCallback((_) {
    _harnessReport['first_frame_us'] = startup.elapsedMicroseconds;
    final message =
        'GAUSS_STARTUP_TIMING '
        'controller_ready_us=$controllerReadyMicros '
        'first_frame_us=${_harnessReport['first_frame_us']}';
    developer.log(message, name: 'gauss.performance');
    debugPrintSynchronously(message);
  });
}

Future<String> _handleDriverData(String? message) async {
  if (message == 'ready') {
    return jsonEncode(<String, dynamic>{
      'ready': _harnessReport['first_frame_us'] != null,
    });
  }
  if (message?.startsWith('stylus:') ?? false) {
    final payload = jsonDecode(message!.substring('stylus:'.length));
    if (payload case <String, dynamic>{
      'center_x': final num centerX,
      'center_y': final num centerY,
    }) {
      return _performStylusStroke(
        Offset(centerX.toDouble(), centerY.toDouble()),
      );
    }
    return jsonEncode(<String, dynamic>{'error': 'Invalid stylus payload.'});
  }
  if (message != 'environment') {
    return jsonEncode(<String, dynamic>{
      'error': 'Unsupported performance harness request.',
    });
  }
  final views = WidgetsBinding.instance.platformDispatcher.views;
  final view = views.isEmpty ? null : views.first;
  final refreshRate = view?.display.refreshRate ?? 60;
  return jsonEncode(<String, dynamic>{
    'os': Platform.operatingSystem,
    'os_version': Platform.operatingSystemVersion,
    'physical_width': view?.physicalSize.width,
    'physical_height': view?.physicalSize.height,
    'device_pixel_ratio': view?.devicePixelRatio,
    'refresh_rate_hz': refreshRate,
    'frame_budget_us': (Duration.microsecondsPerSecond / refreshRate).round(),
    'request_received_us': _harnessReport['first_frame_us'],
    ..._harnessReport,
  });
}

Future<String> _performStylusStroke(Offset center) async {
  const pointer = 701;
  const device = 701;
  const kind = PointerDeviceKind.stylus;
  final start = center + const Offset(-54, -16);
  GestureBinding.instance.handlePointerEvent(
    PointerAddedEvent(
      pointer: pointer,
      device: device,
      kind: kind,
      position: start,
    ),
  );
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(
      pointer: pointer,
      device: device,
      kind: kind,
      position: start,
      pressure: .72,
      pressureMin: 0,
      pressureMax: 1,
    ),
  );
  var previous = start;
  for (var step = 1; step <= 14; step++) {
    final position = start + Offset(step * 8, math.sin(step / 2) * 12);
    GestureBinding.instance.handlePointerEvent(
      PointerMoveEvent(
        timeStamp: Duration(milliseconds: step * 16),
        pointer: pointer,
        device: device,
        kind: kind,
        position: position,
        delta: position - previous,
        pressure: .72,
        pressureMin: 0,
        pressureMax: 1,
      ),
    );
    previous = position;
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(
      timeStamp: const Duration(milliseconds: 240),
      pointer: pointer,
      device: device,
      kind: kind,
      position: previous,
      pressureMin: 0,
      pressureMax: 1,
    ),
  );
  GestureBinding.instance.handlePointerEvent(
    PointerRemovedEvent(
      timeStamp: const Duration(milliseconds: 241),
      pointer: pointer,
      device: device,
      kind: kind,
      position: previous,
      pressureMin: 0,
      pressureMax: 1,
    ),
  );
  await SchedulerBinding.instance.endOfFrame;
  return jsonEncode(<String, dynamic>{
    'stylus': 'accepted',
    'points': 16,
    'pointer_kind': 'stylus',
  });
}

void _installFrameReporter() {
  final samples = <FrameTiming>[];
  var observedFrames = 0;
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      observedFrames += 1;
      if (observedFrames > _warmupFrames) samples.add(timing);
    }
    while (samples.length >= _reportWindow) {
      final window = samples.sublist(0, _reportWindow);
      samples.removeRange(0, _reportWindow);
      _report(window);
    }
  });
}

void _report(List<FrameTiming> frames) {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  final view = views.isEmpty ? null : views.first;
  final refreshRate = view?.display.refreshRate ?? 60;
  final frameBudgetMicros = (Duration.microsecondsPerSecond / refreshRate)
      .round();
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
            (frame) => math.max(
              frame.buildDuration.inMicroseconds,
              frame.rasterDuration.inMicroseconds,
            ),
          )
          .toList(growable: false)
        ..sort();
  final missed = worstLaneMicros
      .where((value) => value > frameBudgetMicros)
      .length;

  final message =
      'GAUSS_FRAME_TIMINGS '
      'frames=${frames.length} '
      'refresh_hz=${refreshRate.toStringAsFixed(2)} '
      'budget_us=$frameBudgetMicros '
      'ui_p50_us=${_percentile(uiMicros, .50)} '
      'ui_p95_us=${_percentile(uiMicros, .95)} '
      'ui_p99_us=${_percentile(uiMicros, .99)} '
      'raster_p50_us=${_percentile(rasterMicros, .50)} '
      'raster_p95_us=${_percentile(rasterMicros, .95)} '
      'raster_p99_us=${_percentile(rasterMicros, .99)} '
      'worst_lane_p95_us=${_percentile(worstLaneMicros, .95)} '
      'worst_lane_p99_us=${_percentile(worstLaneMicros, .99)} '
      'missed=$missed';
  developer.log(message, name: 'gauss.performance');
  debugPrintSynchronously(message);
}

int _percentile(List<int> sortedValues, double percentile) {
  final index = (sortedValues.length * percentile).ceil() - 1;
  return sortedValues[index.clamp(0, sortedValues.length - 1)];
}
