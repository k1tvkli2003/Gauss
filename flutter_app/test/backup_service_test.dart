import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/backup_service.dart';

void main() {
  late Directory root;
  late BackupService service;
  late File database;

  setUp(() {
    root = Directory.systemTemp.createTempSync('gauss-vault-test');
    service = BackupService(overrideRoot: root);
    database = File(
      '${root.path}${Platform.pathSeparator}${BackupService.databaseFileName}',
    )..writeAsStringSync('original-progress');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('a backup captures the store and lists newest first', () async {
    final first = await service.createBackup(now: DateTime(2026, 7, 19, 9));
    database.writeAsStringSync('later-progress');
    final second = await service.createBackup(now: DateTime(2026, 7, 19, 10));

    expect(first.file.readAsStringSync(), 'original-progress');
    expect(second.file.readAsStringSync(), 'later-progress');
    expect(second.sizeBytes, greaterThan(0));

    final listed = await service.listBackups();
    expect(listed, hasLength(2));
    expect(listed.first.savedAt.isAfter(listed.last.savedAt), isTrue);
  });

  test('backing up an absent store fails without creating a file', () async {
    database.deleteSync();
    await expectLater(
      service.createBackup,
      throwsA(isA<FileSystemException>()),
    );
    expect(await service.listBackups(), isEmpty);
  });

  test('a staged restore only applies on the next cold start', () async {
    final saved = await service.createBackup(now: DateTime(2026, 7, 19, 9));
    database.writeAsStringSync('progress-made-since');

    await service.stageRestore(saved);
    expect(await service.hasPendingRestore(), isTrue);
    // Nothing changes while the app is running: the live store is untouched
    // until the swap happens before the database is opened.
    expect(database.readAsStringSync(), 'progress-made-since');

    expect(await service.applyPendingRestore(), isTrue);
    expect(database.readAsStringSync(), 'original-progress');
    expect(await service.hasPendingRestore(), isFalse);

    // The replaced store is kept, so a restore is itself recoverable.
    final listed = await service.listBackups();
    expect(
      listed.any(
        (entry) => entry.file.readAsStringSync() == 'progress-made-since',
      ),
      isTrue,
    );
  });

  test('a cancelled restore leaves the live store alone', () async {
    final saved = await service.createBackup(now: DateTime(2026, 7, 19, 9));
    database.writeAsStringSync('progress-made-since');
    await service.stageRestore(saved);

    await service.cancelPendingRestore();

    expect(await service.hasPendingRestore(), isFalse);
    expect(await service.applyPendingRestore(), isFalse);
    expect(database.readAsStringSync(), 'progress-made-since');
  });

  test('applying with nothing staged is a no-op', () async {
    expect(await service.applyPendingRestore(), isFalse);
    expect(database.readAsStringSync(), 'original-progress');
  });

  test(
    'unsupported startup never touches a platform file-system plugin',
    () async {
      final unsupported = BackupService(supportOverride: false);

      expect(unsupported.isSupported, isFalse);
      expect(await unsupported.applyPendingRestore(), isFalse);
      await expectLater(
        unsupported.listBackups(),
        throwsA(isA<UnsupportedError>()),
      );
    },
  );
}
