import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'feedback_exporter.dart';
import 'feedback_models.dart';
import 'feedback_repository.dart';
import 'feedback_sync.dart';

class GaussFeedbackController extends ChangeNotifier {
  GaussFeedbackController(
    this.repository, {
    GaussFeedbackSyncTarget? syncTarget,
    GaussFeedbackExporter? exporter,
    DateTime Function()? clock,
    Random? random,
  }) : // Keep the public constructor label readable while the target stays private.
       // ignore: prefer_initializing_formals
       _syncTarget = syncTarget,
       _exporter = exporter ?? GaussFeedbackExporter(repository: repository),
       _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final GaussFeedbackRepository repository;
  final GaussFeedbackSyncTarget? _syncTarget;
  final GaussFeedbackExporter _exporter;
  final DateTime Function() _clock;
  final Random _random;

  bool _initialized = false;
  bool _enabled = false;
  bool _busy = false;
  bool _syncing = false;
  bool _disposed = false;
  Object? _lastError;
  List<GaussFeedbackEntry> _entries = const [];

  bool get initialized => _initialized;
  bool get enabled => _enabled;
  bool get busy => _busy;
  bool get syncing => _syncing;
  bool get remoteEnabled => _syncTarget != null;
  Object? get lastError => _lastError;
  List<GaussFeedbackEntry> get entries => List.unmodifiable(_entries);
  int get entryCount => _entries.length;
  int get pendingCount => _entries
      .where((entry) => entry.syncState != GaussFeedbackSyncState.synced)
      .length;

  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    try {
      await repository.initialize();
      await repository.recoverInterruptedSync(_clock().toUtc());
      _enabled = await repository.readCaptureEnabled();
      _entries = await repository.readEntries();
      _lastError = null;
    } catch (error) {
      _lastError = error;
      _enabled = false;
      _entries = const [];
    }
    _initialized = true;
    _notifySafely();
    _scheduleSync();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    try {
      _entries = await repository.readEntries();
      _lastError = null;
    } catch (error) {
      _lastError = error;
    }
    _notifySafely();
    _scheduleSync();
  }

  Future<void> setEnabled(bool enabled) => _run(() async {
    await repository.writeCaptureEnabled(enabled);
    _enabled = enabled;
  });

  Future<GaussFeedbackEntry> addEntry({
    required String route,
    required String note,
    required GaussFeedbackKind kind,
    GaussFeedbackScreenshot? screenshot,
  }) async {
    final entry = await _run(() async {
      final now = _clock().toUtc();
      final saved = await repository.addEntry(
        id: _nextId(now),
        kind: kind,
        route: route,
        note: note,
        createdAt: now,
        screenshot: screenshot,
      );
      _entries = await repository.readEntries();
      return saved;
    });
    _scheduleSync();
    return entry;
  }

  Future<Uint8List?> readScreenshot(GaussFeedbackEntry entry) =>
      repository.readScreenshot(entry);

  Future<void> deleteEntry(GaussFeedbackEntry entry) => _run(() async {
    if (_syncing) throw StateError('Wait for feedback sync to finish.');
    await repository.deleteEntry(entry);
    _entries = await repository.readEntries();
  });

  Future<void> clearAll() => _run(() async {
    if (_syncing) throw StateError('Wait for feedback sync to finish.');
    await repository.clearAll();
    _entries = const [];
  });

  Future<GaussFeedbackExportResult> export() => _run(() async {
    if (_syncing) throw StateError('Wait for feedback sync to finish.');
    return _exporter.export();
  });

  Future<void> syncPending() async {
    final target = _syncTarget;
    if (target == null || _syncing || _disposed) return;
    _syncing = true;
    _notifySafely();
    final attempted = <String>{};
    try {
      while (!_disposed) {
        final candidates = (await repository.readSyncCandidates())
            .where((entry) => attempted.add(entry.id))
            .toList(growable: false);
        if (candidates.isEmpty) break;
        for (final entry in candidates) {
          if (_disposed) return;
          try {
            await repository.markSyncing(entry, updatedAt: _clock().toUtc());
            final screenshot = await repository.readScreenshot(entry);
            if (entry.hasScreenshot && screenshot == null) {
              throw const FormatException(
                'The local screenshot is unreadable.',
              );
            }
            await target.send(entry, screenshot: screenshot);
            await repository.markSynced(entry.id, updatedAt: _clock().toUtc());
          } catch (_) {
            await repository.markFailed(
              entry.id,
              updatedAt: _clock().toUtc(),
              message:
                  'Private upload is unavailable. The report remains safely on this device.',
            );
          }
        }
      }
      _entries = await repository.readEntries();
    } finally {
      _syncing = false;
      _notifySafely();
    }
  }

  void _scheduleSync() {
    if (_syncTarget == null || _syncing || _disposed) return;
    unawaited(syncPending());
  }

  Future<T> _run<T>(Future<T> Function() operation) async {
    if (_disposed) throw StateError('Feedback controller is disposed.');
    if (_busy) throw StateError('Feedback capture is already busy.');
    _busy = true;
    _lastError = null;
    _notifySafely();
    try {
      return await operation();
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _busy = false;
      _notifySafely();
    }
  }

  String _nextId(DateTime now) {
    final entropy = List.generate(
      3,
      (_) => _random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();
    return 'fb_${now.microsecondsSinceEpoch}_$entropy';
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
