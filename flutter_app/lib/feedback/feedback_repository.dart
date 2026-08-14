import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../data/local/gauss_database.dart';
import '../domain/models.dart';
import 'feedback_models.dart';
import 'feedback_redactor.dart';

class GaussFeedbackRepository {
  GaussFeedbackRepository(this.database);

  final GaussDatabase database;

  static const captureEnabledFlag = 'feedback_capture_enabled_v1';
  static const _legacyQuestionPrefix = 'question_issue_v1:';
  static const maxEntryCount = 250;
  static const maxNoteCharacters = 4000;
  static const maxRouteCharacters = 500;
  static const maxScreenshotBytes = 8 * 1024 * 1024;
  static const maxScreenshotDimensionPx = 8192;
  static const maxScreenshotPixelRatio = 2.5;
  static const maxPendingScreenshotBytes = 96 * 1024 * 1024;

  Future<void> initialize() => database.customSelect('SELECT 1').getSingle();

  Future<bool> readCaptureEnabled() async {
    final row = await (database.select(
      database.appFlags,
    )..where((item) => item.key.equals(captureEnabledFlag))).getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> writeCaptureEnabled(bool enabled) => database
      .into(database.appFlags)
      .insertOnConflictUpdate(
        AppFlagsCompanion.insert(
          key: captureEnabledFlag,
          value: enabled ? 'true' : 'false',
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<List<GaussFeedbackEntry>> readEntries() async {
    final query = database.selectOnly(database.feedbackOutboxEntries)
      ..addColumns([
        database.feedbackOutboxEntries.id,
        database.feedbackOutboxEntries.kind,
        database.feedbackOutboxEntries.route,
        database.feedbackOutboxEntries.note,
        database.feedbackOutboxEntries.questionId,
        database.feedbackOutboxEntries.questionRevision,
        database.feedbackOutboxEntries.topicKey,
        database.feedbackOutboxEntries.questionIssueKind,
        database.feedbackOutboxEntries.sessionId,
        database.feedbackOutboxEntries.missionIndex,
        database.feedbackOutboxEntries.selectedChoiceIndex,
        database.feedbackOutboxEntries.screenshotWidthPx,
        database.feedbackOutboxEntries.screenshotHeightPx,
        database.feedbackOutboxEntries.screenshotByteLength,
        database.feedbackOutboxEntries.screenshotPixelRatio,
        database.feedbackOutboxEntries.syncState,
        database.feedbackOutboxEntries.syncAttempts,
        database.feedbackOutboxEntries.lastSyncError,
        database.feedbackOutboxEntries.createdAt,
        database.feedbackOutboxEntries.updatedAt,
      ])
      ..orderBy([OrderingTerm.desc(database.feedbackOutboxEntries.createdAt)]);
    final entries = (await query.get()).map(_entryFromTypedResult).toList();

    final legacyRows = await (database.select(
      database.appFlags,
    )..where((row) => row.key.like('$_legacyQuestionPrefix%'))).get();
    final seen = entries.map((entry) => entry.id).toSet();
    for (final row in legacyRows) {
      try {
        final decoded = jsonDecode(row.value);
        if (decoded is! Map<String, dynamic>) continue;
        final report = QuestionIssueReport.fromJson(decoded);
        if (!seen.add(report.id)) continue;
        entries.add(
          GaussFeedbackEntry(
            id: row.key.substring(_legacyQuestionPrefix.length),
            kind: GaussFeedbackKind.questionIssue,
            route: '/mission/${report.topicKey}',
            note: GaussFeedbackRedactor.redactAndLimit(
              report.note,
              maxNoteCharacters,
            ),
            questionId: report.questionId,
            topicKey: report.topicKey,
            questionIssueKind: report.kind.key,
            sessionId: report.sessionId,
            missionIndex: report.missionIndex,
            selectedChoiceIndex: report.selectedChoiceIndex,
            createdAt: report.reportedAt.toUtc(),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              row.updatedAt,
              isUtc: true,
            ),
            syncState: GaussFeedbackSyncState.pending,
            syncAttempts: 0,
            hasScreenshot: false,
            legacy: true,
          ),
        );
      } catch (_) {
        // A malformed optional legacy signal must not block the usable queue.
      }
    }
    entries.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(entries);
  }

  Future<GaussFeedbackEntry> addEntry({
    required String id,
    required GaussFeedbackKind kind,
    required String route,
    required String note,
    required DateTime createdAt,
    GaussFeedbackScreenshot? screenshot,
  }) async {
    if (!RegExp(r'^fb_[a-zA-Z0-9_-]{8,120}$').hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'Use a portable feedback id.');
    }
    final normalizedNote = GaussFeedbackRedactor.redactAndLimit(
      note.trim(),
      maxNoteCharacters,
    );
    if (normalizedNote.isEmpty && screenshot == null) {
      throw ArgumentError('A note or screenshot is required.');
    }
    final normalizedRoute = GaussFeedbackRedactor.redactAndLimit(
      route.trim().isEmpty ? 'Unknown' : route.trim(),
      maxRouteCharacters,
    );
    final metadata = screenshot == null ? null : _validatePng(screenshot);
    await _ensureCapacity(screenshot?.bytes.lengthInBytes ?? 0);
    final now = createdAt.toUtc().millisecondsSinceEpoch;
    await database
        .into(database.feedbackOutboxEntries)
        .insert(
          FeedbackOutboxEntriesCompanion.insert(
            id: id,
            kind: kind.name,
            route: normalizedRoute,
            note: normalizedNote,
            screenshotPng: Value(screenshot?.bytes),
            screenshotWidthPx: Value(metadata?.width),
            screenshotHeightPx: Value(metadata?.height),
            screenshotByteLength: Value(screenshot?.bytes.lengthInBytes),
            screenshotPixelRatio: Value(screenshot?.pixelRatio),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await readEntries()).firstWhere((entry) => entry.id == id);
  }

  Future<GaussFeedbackEntry> addQuestionIssue(
    QuestionIssueReport report, {
    GaussFeedbackScreenshot? screenshot,
  }) async {
    final metadata = screenshot == null ? null : _validatePng(screenshot);
    await _ensureCapacity(screenshot?.bytes.lengthInBytes ?? 0);
    final note = GaussFeedbackRedactor.redactAndLimit(
      report.note.trim(),
      maxNoteCharacters,
    );
    final safeQuestion = report.questionId.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final id =
        'fb_${report.reportedAt.toUtc().microsecondsSinceEpoch}_question_'
        '${safeQuestion.length <= 64 ? safeQuestion : safeQuestion.substring(0, 64)}';
    final createdAt = report.reportedAt.toUtc().millisecondsSinceEpoch;
    await database
        .into(database.feedbackOutboxEntries)
        .insert(
          FeedbackOutboxEntriesCompanion.insert(
            id: id,
            kind: GaussFeedbackKind.questionIssue.name,
            route: '/mission/${report.topicKey}',
            note: note,
            questionId: Value(report.questionId),
            topicKey: Value(report.topicKey),
            questionIssueKind: Value(report.kind.key),
            sessionId: Value(report.sessionId),
            missionIndex: Value(report.missionIndex),
            selectedChoiceIndex: Value(report.selectedChoiceIndex),
            screenshotPng: Value(screenshot?.bytes),
            screenshotWidthPx: Value(metadata?.width),
            screenshotHeightPx: Value(metadata?.height),
            screenshotByteLength: Value(screenshot?.bytes.lengthInBytes),
            screenshotPixelRatio: Value(screenshot?.pixelRatio),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    return (await readEntries()).firstWhere((entry) => entry.id == id);
  }

  Future<void> _ensureCapacity(int newScreenshotBytes) async {
    final current = await readEntries();
    if (current.where((entry) => !entry.legacy).length >= maxEntryCount) {
      throw StateError(
        'The local feedback outbox is full. Review or remove an entry first.',
      );
    }
    final bytesInQueue = current.fold<int>(
      0,
      (sum, entry) => sum + (entry.screenshotByteLength ?? 0),
    );
    if (bytesInQueue + newScreenshotBytes > maxPendingScreenshotBytes) {
      throw StateError(
        'The local screenshot allowance is full. Review or remove an entry first.',
      );
    }
  }

  Future<Uint8List?> readScreenshot(GaussFeedbackEntry entry) async {
    if (!entry.hasScreenshot || entry.legacy) return null;
    final query = database.selectOnly(database.feedbackOutboxEntries)
      ..addColumns([database.feedbackOutboxEntries.screenshotPng])
      ..where(database.feedbackOutboxEntries.id.equals(entry.id));
    final row = await query.getSingleOrNull();
    final bytes = row?.read(database.feedbackOutboxEntries.screenshotPng);
    if (bytes == null) return null;
    try {
      _validatePng(
        GaussFeedbackScreenshot(
          bytes: bytes,
          pixelRatio: entry.screenshotPixelRatio ?? 1,
        ),
      );
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteEntry(GaussFeedbackEntry entry) async {
    if (entry.legacy) {
      await (database.delete(database.appFlags)..where(
            (row) => row.key.equals('$_legacyQuestionPrefix${entry.id}'),
          ))
          .go();
      return;
    }
    await (database.delete(
      database.feedbackOutboxEntries,
    )..where((row) => row.id.equals(entry.id))).go();
  }

  Future<void> clearAll() => database.transaction(() async {
    await database.delete(database.feedbackOutboxEntries).go();
    await (database.delete(
      database.appFlags,
    )..where((row) => row.key.like('$_legacyQuestionPrefix%'))).go();
  });

  GaussFeedbackEntry _entryFromTypedResult(TypedResult row) {
    final table = database.feedbackOutboxEntries;
    final screenshotLength = row.read(table.screenshotByteLength);
    return GaussFeedbackEntry(
      id: row.read(table.id)!,
      kind: GaussFeedbackKind.fromKey(row.read(table.kind)!),
      route: row.read(table.route)!,
      note: row.read(table.note)!,
      questionId: row.read(table.questionId),
      questionRevision: row.read(table.questionRevision),
      topicKey: row.read(table.topicKey),
      questionIssueKind: row.read(table.questionIssueKind),
      sessionId: row.read(table.sessionId),
      missionIndex: row.read(table.missionIndex),
      selectedChoiceIndex: row.read(table.selectedChoiceIndex),
      screenshotWidthPx: row.read(table.screenshotWidthPx),
      screenshotHeightPx: row.read(table.screenshotHeightPx),
      screenshotByteLength: screenshotLength,
      screenshotPixelRatio: row.read(table.screenshotPixelRatio),
      syncState: GaussFeedbackSyncState.fromKey(row.read(table.syncState)!),
      syncAttempts: row.read(table.syncAttempts)!,
      lastSyncError: row.read(table.lastSyncError),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read(table.createdAt)!,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read(table.updatedAt)!,
        isUtc: true,
      ),
      hasScreenshot: screenshotLength != null && screenshotLength > 0,
    );
  }

  _PngMetadata _validatePng(GaussFeedbackScreenshot screenshot) {
    if (!screenshot.pixelRatio.isFinite ||
        screenshot.pixelRatio < 1 ||
        screenshot.pixelRatio > maxScreenshotPixelRatio) {
      throw ArgumentError.value(
        screenshot.pixelRatio,
        'screenshot.pixelRatio',
        'Pixel ratio is outside the capture range.',
      );
    }
    final bytes = screenshot.bytes;
    if (bytes.lengthInBytes > maxScreenshotBytes) {
      throw ArgumentError('Screenshot exceeds the byte limit.');
    }
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.lengthInBytes < 45) {
      throw const FormatException('PNG is incomplete.');
    }
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        throw const FormatException('Screenshot is not a PNG.');
      }
    }
    final data = ByteData.sublistView(bytes);
    var offset = 8;
    var width = 0;
    var height = 0;
    var sawHeader = false;
    var sawEnd = false;
    var imageBytes = 0;
    while (offset < bytes.lengthInBytes) {
      if (bytes.lengthInBytes - offset < 12) {
        throw const FormatException('PNG chunk is truncated.');
      }
      final length = data.getUint32(offset);
      if (length > bytes.lengthInBytes - offset - 12) {
        throw const FormatException('PNG chunk data is truncated.');
      }
      final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      final expectedCrc = data.getUint32(offset + 8 + length);
      if (_pngCrc(bytes, offset + 4, length + 4) != expectedCrc) {
        throw FormatException('PNG $type checksum is invalid.');
      }
      if (!sawHeader) {
        if (type != 'IHDR' || length != 13) {
          throw const FormatException('PNG must begin with IHDR.');
        }
        width = data.getUint32(offset + 8);
        height = data.getUint32(offset + 12);
        if (width <= 0 ||
            height <= 0 ||
            width > maxScreenshotDimensionPx ||
            height > maxScreenshotDimensionPx) {
          throw const FormatException('PNG dimensions are invalid.');
        }
        sawHeader = true;
      } else if (type == 'IHDR') {
        throw const FormatException('PNG contains multiple headers.');
      }
      if (type == 'IDAT') imageBytes += length;
      offset += 12 + length;
      if (type == 'IEND') {
        if (length != 0 || offset != bytes.lengthInBytes) {
          throw const FormatException('PNG ending is invalid.');
        }
        sawEnd = true;
        break;
      }
    }
    if (!sawHeader || !sawEnd || imageBytes == 0) {
      throw const FormatException('PNG is missing required chunks.');
    }
    return _PngMetadata(width: width, height: height);
  }

  int _pngCrc(Uint8List bytes, int start, int length) {
    var crc = 0xffffffff;
    for (var index = start; index < start + length; index++) {
      crc ^= bytes[index];
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}

class _PngMetadata {
  const _PngMetadata({required this.width, required this.height});
  final int width;
  final int height;
}
