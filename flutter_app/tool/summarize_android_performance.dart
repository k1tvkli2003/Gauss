import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/summarize_android_performance.dart <evidence-directory>',
    );
    exitCode = 64;
    return;
  }

  final root = Directory(arguments.single).absolute;
  if (!root.existsSync()) {
    throw FileSystemException('Evidence directory does not exist.', root.path);
  }
  final runDirectories =
      root
          .listSync()
          .whereType<Directory>()
          .where(
            (directory) => File(
              '${directory.path}${Platform.pathSeparator}journeys.json',
            ).existsSync(),
          )
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  if (runDirectories.isEmpty) {
    throw StateError('No completed performance runs found in ${root.path}.');
  }

  final runs = <Map<String, dynamic>>[];
  for (final directory in runDirectories) {
    final journeys = _readJson(
      File('${directory.path}${Platform.pathSeparator}journeys.json'),
    );
    final runtime = _readJson(
      File('${directory.path}${Platform.pathSeparator}android-runtime.json'),
    );
    if (journeys['status'] != 'passed') {
      throw StateError('${directory.path} is not a passed run.');
    }
    runs.add(<String, dynamic>{
      'name': directory.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last,
      'journeys': journeys,
      'runtime': runtime,
    });
  }

  final environment = _readJson(
    File('${root.path}${Platform.pathSeparator}environment.json'),
  );
  final journeyNames = <String>{
    for (final run in runs)
      ...(run['journeys']['journeys'] as Map<String, dynamic>).keys,
  }.toList(growable: false)..sort();
  final journeySummary = <String, dynamic>{};

  for (final name in journeyNames) {
    final uiTimes = <num>[];
    final rasterTimes = <num>[];
    final wallClock = <num>[];
    final perRunMissedRatio = <num>[];
    for (final run in runs) {
      final report =
          (run['journeys']['journeys'] as Map<String, dynamic>)[name]
              as Map<String, dynamic>;
      final build = (report['frame_build_times'] as List).cast<num>();
      final raster = (report['frame_rasterizer_times'] as List).cast<num>();
      final budget = (run['journeys']['environment']['frame_budget_us'] as num)
          .toDouble();
      uiTimes.addAll(build);
      rasterTimes.addAll(raster);
      wallClock.add(report['wall_clock_millis'] as num);
      final paired = math.min(build.length, raster.length);
      var missed = 0;
      for (var index = 0; index < paired; index++) {
        if (math.max(build[index], raster[index]) > budget) missed += 1;
      }
      perRunMissedRatio.add(paired == 0 ? 0 : missed / paired);
    }
    uiTimes.sort();
    rasterTimes.sort();
    journeySummary[name] = <String, dynamic>{
      'run_count': runs.length,
      'ui_frame_count': uiTimes.length,
      'raster_frame_count': rasterTimes.length,
      'ui_millis': _percentileSummary(uiTimes, divisor: 1000),
      'raster_millis': _percentileSummary(rasterTimes, divisor: 1000),
      'wall_clock_millis': _distribution(wallClock),
      'dynamic_budget_missed_frame_ratio': _distribution(perRunMissedRatio),
    };
  }

  final controllerReady = <num>[
    for (final run in runs)
      run['journeys']['environment']['controller_ready_us'] as num,
  ];
  final firstFrame = <num>[
    for (final run in runs)
      run['journeys']['environment']['first_frame_us'] as num,
  ];
  final totalPss = <num>[
    for (final run in runs)
      if (run['runtime']['total_pss_kib'] case final num value) value,
  ];
  final output = <String, dynamic>{
    'schema_version': 1,
    'generated_at_utc': DateTime.now().toUtc().toIso8601String(),
    'git_revision': environment['git_revision'],
    'device': environment['device'],
    'build_mode': 'profile',
    'runs': runs.length,
    'startup_millis': <String, dynamic>{
      'controller_ready': _distribution(
        controllerReady.map((value) => value / 1000).toList(),
      ),
      'first_usable_map_frame': _distribution(
        firstFrame.map((value) => value / 1000).toList(),
      ),
    },
    'retained_total_pss_mib': totalPss.isEmpty
        ? null
        : _distribution(
            totalPss.map((value) => value / 1024).toList(growable: false),
          ),
    'journeys': journeySummary,
    'limitations': <String>[
      'Canonical Codex_API35 emulator evidence uses Android GPU emulation and is not a substitute for physical-device raster proof.',
      'Stylus input is synthesized through GestureBinding as PointerDeviceKind.stylus; Xiaomi Focus Pen hardware latency remains a physical-device gate.',
      'Timeline values are profile-mode Flutter engine measurements; wall-clock values include driver synchronization.',
    ],
  };
  final target = File('${root.path}${Platform.pathSeparator}aggregate.json');
  target.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));
}

Map<String, dynamic> _readJson(File file) {
  if (!file.existsSync()) {
    throw FileSystemException('Required evidence file is missing.', file.path);
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, dynamic> _percentileSummary(
  List<num> sortedValues, {
  required num divisor,
}) => <String, dynamic>{
  'p50': _percentile(sortedValues, .50) / divisor,
  'p95': _percentile(sortedValues, .95) / divisor,
  'p99': _percentile(sortedValues, .99) / divisor,
  'max': sortedValues.last / divisor,
};

Map<String, dynamic> _distribution(List<num> values) {
  final sorted = values.toList(growable: false)..sort();
  final mean = sorted.reduce((left, right) => left + right) / sorted.length;
  return <String, dynamic>{
    'min': sorted.first,
    'median': _percentile(sorted, .50),
    'mean': mean,
    'max': sorted.last,
  };
}

num _percentile(List<num> sortedValues, double percentile) {
  if (sortedValues.isEmpty) return 0;
  final index = (sortedValues.length * percentile).ceil() - 1;
  return sortedValues[index.clamp(0, sortedValues.length - 1)];
}
