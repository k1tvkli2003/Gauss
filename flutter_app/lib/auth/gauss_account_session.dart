import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/backup_service.dart';
import '../data/content_release_store.dart';
import '../data/local/gauss_database.dart';
import '../data/progress_repository.dart';
import '../data/question_bank_repository.dart';
import '../state/gauss_controller.dart';

/// Owns every account-scoped runtime object as one disposable boundary.
///
/// The database file is selected before Drift opens it. Switching accounts
/// therefore cannot reveal another account's progress even while offline.
class GaussAccountSession {
  GaussAccountSession._({
    required this.userId,
    required this.storageKey,
    required this.database,
    required this.controller,
    required this.contentSnapshot,
  });

  final String userId;
  final String storageKey;
  final GaussDatabase database;
  final GaussController controller;
  final GaussContentSnapshot? contentSnapshot;
  bool _disposed = false;

  static String storageKeyFor(String userId) => sha256
      .convert(utf8.encode('gauss-account-v1:$userId'))
      .toString()
      .substring(0, 24);

  static Future<GaussAccountSession> open(
    String userId, {
    @visibleForTesting GaussDatabase? databaseOverride,
    @visibleForTesting QuestionBankRepository? questionBankOverride,
    SupabaseClient? contentClient,
    int appBuild = 1,
    GaussContentPhase? onOpeningPhase,
  }) async {
    final storageKey = storageKeyFor(userId);
    final backups = BackupService(accountStorageKey: storageKey);
    if (databaseOverride == null) {
      // A staged restore belongs to this account only and must be swapped in
      // before its account database is opened.
      await backups.applyPendingRestore();
    }
    final database =
        databaseOverride ?? GaussDatabase.defaults(name: backups.databaseName);
    GaussContentSnapshot? contentSnapshot;
    final questionBank =
        questionBankOverride ??
        await (() async {
          if (contentClient == null) return QuestionBankRepository();
          contentSnapshot = await GaussContentReleaseStore(
            api: SupabaseGaussContentApi(contentClient),
            appBuild: appBuild,
          ).open(onPhase: onOpeningPhase);
          return QuestionBankRepository(bundle: contentSnapshot!.bundle);
        })();
    onOpeningPhase?.call('Opening your private orbit…');
    final controller = GaussController(
      questionBank,
      ProgressRepository(database),
      backups: backups,
    );
    final session = GaussAccountSession._(
      userId: userId,
      storageKey: storageKey,
      database: database,
      controller: controller,
      contentSnapshot: contentSnapshot,
    );
    try {
      await controller.initialize();
      return session;
    } catch (_) {
      await session.dispose();
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    controller.dispose();
    await database.close();
  }
}
