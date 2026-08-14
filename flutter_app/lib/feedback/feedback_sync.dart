import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'feedback_models.dart';

abstract interface class GaussFeedbackSyncTarget {
  Future<void> send(GaussFeedbackEntry entry, {Uint8List? screenshot});
}

/// Account-bound Supabase delivery for the local-first feedback outbox.
///
/// The publishable client is intentionally used here: table and Storage RLS
/// remain the authority. A service-role credential never enters the APK.
final class SupabaseGaussFeedbackSyncTarget implements GaussFeedbackSyncTarget {
  SupabaseGaussFeedbackSyncTarget({
    required SupabaseClient client,
    required this.userId,
    this.contentReleaseId,
    this.requestTimeout = const Duration(seconds: 20),
  }) : // Keep the public constructor label stable while the client stays private.
       // ignore: prefer_initializing_formals
       _client = client;

  static const bucket = 'gauss-feedback-private';

  final SupabaseClient _client;
  final String userId;
  final String? contentReleaseId;
  final Duration requestTimeout;

  @override
  Future<void> send(GaussFeedbackEntry entry, {Uint8List? screenshot}) async {
    if (_client.auth.currentUser?.id != userId) {
      throw StateError('The feedback account session changed.');
    }
    if (entry.hasScreenshot != (screenshot != null)) {
      throw const FormatException('Feedback screenshot binding is incomplete.');
    }

    String? screenshotPath;
    String? screenshotSha256;
    if (screenshot != null) {
      screenshotPath = '$userId/${entry.id}.png';
      screenshotSha256 = sha256.convert(screenshot).toString();
      await _client.storage
          .from(bucket)
          .uploadBinary(
            screenshotPath,
            screenshot,
            fileOptions: const FileOptions(
              cacheControl: '0',
              contentType: 'image/png',
              upsert: true,
            ),
          )
          .timeout(requestTimeout);
    }

    await _client
        .from('gauss_feedback_reports')
        .upsert(
          remoteRow(
            entry,
            userId: userId,
            contentReleaseId: contentReleaseId,
            screenshotPath: screenshotPath,
            screenshotSha256: screenshotSha256,
          ),
          onConflict: 'user_id,id',
        )
        .timeout(requestTimeout);
  }

  static Map<String, Object?> remoteRow(
    GaussFeedbackEntry entry, {
    required String userId,
    required String? contentReleaseId,
    required String? screenshotPath,
    required String? screenshotSha256,
  }) => <String, Object?>{
    'user_id': userId,
    'id': entry.id,
    'kind': entry.kind.name,
    'route': entry.route,
    'note': entry.note,
    'question_id': entry.questionId,
    'question_revision': entry.questionRevision,
    'topic_key': entry.topicKey,
    'issue_kind': entry.questionIssueKind,
    'session_id': entry.sessionId,
    'mission_index': entry.missionIndex,
    'selected_choice_index': entry.selectedChoiceIndex,
    'content_release_id': contentReleaseId,
    'screenshot_path': screenshotPath,
    'screenshot_sha256': screenshotSha256,
    'client_created_at': entry.createdAt.toUtc().toIso8601String(),
  };
}
