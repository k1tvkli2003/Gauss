import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A saved copy of the local progress database.
class BackupEntry {
  const BackupEntry({
    required this.file,
    required this.savedAt,
    required this.sizeBytes,
  });

  final File file;
  final DateTime savedAt;
  final int sizeBytes;

  String get name => file.uri.pathSegments.last;
}

/// Local-only backup of the progress store.
///
/// Everything stays on the device: copies land in the app's own external
/// files directory, which a file manager can reach without any permission
/// and which no other app can write to. Nothing is uploaded or shared.
///
/// Restore is deliberately deferred: replacing the database while Drift holds
/// it open risks corrupting live progress, so [stageRestore] parks the chosen
/// copy and [applyPendingRestore] swaps it in during the next cold start,
/// before the database is opened.
class BackupService {
  BackupService({this.overrideRoot, @visibleForTesting this.supportOverride});

  /// Test seam: keeps the vault inside a temporary directory so the suite
  /// never touches real device storage.
  @visibleForTesting
  final Directory? overrideRoot;

  @visibleForTesting
  final bool? supportOverride;

  /// Native Android can copy its SQLite file directly. A browser cannot reach
  /// that file-system surface, so the vault must stand down without invoking
  /// path_provider (which has no web implementation for this workflow).
  bool get isSupported => supportOverride ?? (overrideRoot != null || !kIsWeb);

  static const databaseFileName = 'gauss_flutter_v1.sqlite';
  static const _pendingRestoreName = 'pending_restore.sqlite';
  static const _backupPrefix = 'gauss-progress-';

  void _requireSupport() {
    if (!isSupported) {
      throw UnsupportedError(
        'The device vault is available in the native Android app.',
      );
    }
  }

  Future<Directory> _backupDirectory() async {
    _requireSupport();
    final root =
        overrideRoot ??
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}${Platform.pathSeparator}backups');
    if (!directory.existsSync()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _databaseFile() async {
    _requireSupport();
    final root = overrideRoot ?? await getApplicationDocumentsDirectory();
    return File('${root.path}${Platform.pathSeparator}$databaseFileName');
  }

  Future<File> _pendingRestoreFile() async {
    _requireSupport();
    final root = overrideRoot ?? await getApplicationDocumentsDirectory();
    return File('${root.path}${Platform.pathSeparator}$_pendingRestoreName');
  }

  static String _stamp(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}'
      '${at.month.toString().padLeft(2, '0')}'
      '${at.day.toString().padLeft(2, '0')}'
      '-'
      '${at.hour.toString().padLeft(2, '0')}'
      '${at.minute.toString().padLeft(2, '0')}'
      '${at.second.toString().padLeft(2, '0')}';

  /// Copies the current progress database into the backup folder.
  Future<BackupEntry> createBackup({DateTime? now}) async {
    final source = await _databaseFile();
    if (!source.existsSync()) {
      throw const FileSystemException(
        'There is no local progress store to back up yet.',
      );
    }
    final directory = await _backupDirectory();
    final at = now ?? DateTime.now();
    final target = File(
      '${directory.path}${Platform.pathSeparator}'
      '$_backupPrefix${_stamp(at)}.sqlite',
    );
    await source.copy(target.path);
    return BackupEntry(
      file: target,
      savedAt: at,
      sizeBytes: await target.length(),
    );
  }

  /// The moment a copy was taken, read from its own name. Filesystem
  /// timestamps are not trustworthy here — a copy may inherit the source's
  /// mtime — so the stamp written at creation is the authority.
  static DateTime? _stampFromName(String name) {
    final match = RegExp(
      r'(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})',
    ).firstMatch(name);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  }

  /// Every saved copy, newest first.
  Future<List<BackupEntry>> listBackups() async {
    final directory = await _backupDirectory();
    if (!directory.existsSync()) return const [];
    final entries = <BackupEntry>[];
    for (final entity in directory.listSync()) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.sqlite')) continue;
      final stat = entity.statSync();
      entries.add(
        BackupEntry(
          file: entity,
          savedAt:
              _stampFromName(entity.uri.pathSegments.last) ?? stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }
    entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return List.unmodifiable(entries);
  }

  /// Parks [backup] to replace the live database on the next cold start.
  Future<void> stageRestore(BackupEntry backup) async {
    if (!backup.file.existsSync()) {
      throw const FileSystemException('That backup file is no longer there.');
    }
    await backup.file.copy((await _pendingRestoreFile()).path);
  }

  Future<bool> hasPendingRestore() async =>
      (await _pendingRestoreFile()).existsSync();

  Future<void> cancelPendingRestore() async {
    final pending = await _pendingRestoreFile();
    if (pending.existsSync()) await pending.delete();
  }

  /// Swaps a staged copy into place. Call before the database is opened.
  ///
  /// The live database is copied aside first, so a failed swap still leaves a
  /// recoverable file behind. Returns true when a restore was applied.
  Future<bool> applyPendingRestore() async {
    // Browser startup must not touch path_provider or report a false runtime
    // error. Browser progress remains in its own local Drift store.
    if (!isSupported) return false;
    final pending = await _pendingRestoreFile();
    if (!pending.existsSync()) return false;
    final live = await _databaseFile();
    if (live.existsSync()) {
      final directory = await _backupDirectory();
      await live.copy(
        '${directory.path}${Platform.pathSeparator}'
        '${_backupPrefix}replaced-${_stamp(DateTime.now())}.sqlite',
      );
    }
    await pending.copy(live.path);
    await pending.delete();
    return true;
  }
}
