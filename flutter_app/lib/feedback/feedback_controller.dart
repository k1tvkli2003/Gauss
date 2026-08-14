import 'dart:math';
import 'package:flutter/foundation.dart';

import 'feedback_models.dart';
import 'feedback_repository.dart';

class GaussFeedbackController extends ChangeNotifier {
  GaussFeedbackController(
    this.repository, {
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final GaussFeedbackRepository repository;
  final DateTime Function() _clock;
  final Random _random;

  bool _initialized = false;
  bool _enabled = false;
  bool _busy = false;
  bool _disposed = false;
  Object? _lastError;
  List<GaussFeedbackEntry> _entries = const [];

  bool get initialized => _initialized;
  bool get enabled => _enabled;
  bool get busy => _busy;
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
  }) => _run(() async {
    final now = _clock().toUtc();
    final entry = await repository.addEntry(
      id: _nextId(now),
      kind: kind,
      route: route,
      note: note,
      createdAt: now,
      screenshot: screenshot,
    );
    _entries = await repository.readEntries();
    return entry;
  });

  Future<Uint8List?> readScreenshot(GaussFeedbackEntry entry) =>
      repository.readScreenshot(entry);

  Future<void> deleteEntry(GaussFeedbackEntry entry) => _run(() async {
    await repository.deleteEntry(entry);
    _entries = await repository.readEntries();
  });

  Future<void> clearAll() => _run(() async {
    await repository.clearAll();
    _entries = const [];
  });

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
