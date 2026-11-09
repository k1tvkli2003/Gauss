import 'package:flutter/foundation.dart';

enum GaussFeedbackKind {
  error('Error'),
  suggestion('Suggestion'),
  criticism('Criticism'),
  note('Note'),
  questionIssue('Question issue');

  const GaussFeedbackKind(this.label);
  final String label;

  static GaussFeedbackKind fromKey(String value) =>
      GaussFeedbackKind.values.firstWhere(
        (candidate) => candidate.name == value,
        orElse: () => GaussFeedbackKind.note,
      );
}

enum GaussFeedbackSyncState {
  pending,
  syncing,
  synced,
  failed;

  static GaussFeedbackSyncState fromKey(String value) =>
      GaussFeedbackSyncState.values.firstWhere(
        (candidate) => candidate.name == value,
        orElse: () => GaussFeedbackSyncState.pending,
      );
}

@immutable
class GaussFeedbackEntry {
  const GaussFeedbackEntry({
    required this.id,
    required this.kind,
    required this.route,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.syncAttempts,
    required this.hasScreenshot,
    this.questionId,
    this.questionRevision,
    this.topicKey,
    this.questionIssueKind,
    this.sessionId,
    this.missionIndex,
    this.selectedChoiceIndex,
    this.screenshotWidthPx,
    this.screenshotHeightPx,
    this.screenshotByteLength,
    this.screenshotPixelRatio,
    this.lastSyncError,
    this.legacy = false,
  });

  final String id;
  final GaussFeedbackKind kind;
  final String route;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GaussFeedbackSyncState syncState;
  final int syncAttempts;
  final bool hasScreenshot;
  final String? questionId;
  final int? questionRevision;
  final String? topicKey;
  final String? questionIssueKind;
  final String? sessionId;
  final int? missionIndex;
  final int? selectedChoiceIndex;
  final int? screenshotWidthPx;
  final int? screenshotHeightPx;
  final int? screenshotByteLength;
  final double? screenshotPixelRatio;
  final String? lastSyncError;

  /// A pre-outbox question report retained through the additive migration.
  final bool legacy;
}

@immutable
class GaussFeedbackScreenshot {
  const GaussFeedbackScreenshot({
    required this.bytes,
    required this.pixelRatio,
  });

  final Uint8List bytes;
  final double pixelRatio;
}

@immutable
class GaussFeedbackExportSnapshot {
  const GaussFeedbackExportSnapshot({
    required this.entries,
    required this.screenshots,
  });

  final List<GaussFeedbackEntry> entries;
  final Map<String, Uint8List> screenshots;
}
