import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../data/backup_service.dart';
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
  });

  final String userId;
  final String storageKey;
  final GaussDatabase database;
  final GaussController controller;
  bool _disposed = false;

  static String storageKeyFor(String userId) => sha256
      .convert(utf8.encode('gauss-account-v1:$userId'))
      .toString()
      .substring(0, 24);

  static Future<GaussAccountSession> open(
    String userId, {
    @visibleForTesting GaussDatabase? databaseOverride,
    @visibleForTesting QuestionBankRepository? questionBankOverride,
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
    final controller = GaussController(
      questionBankOverride ?? QuestionBankRepository(),
      ProgressRepository(database),
      backups: backups,
    );
    final session = GaussAccountSession._(
      userId: userId,
      storageKey: storageKey,
      database: database,
      controller: controller,
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
