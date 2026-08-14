import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/feedback/feedback_controller.dart';
import 'package:gauss/feedback/feedback_exporter.dart';
import 'package:gauss/feedback/feedback_models.dart';
import 'package:gauss/feedback/feedback_repository.dart';
import 'package:gauss/feedback/feedback_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GaussDatabase database;
  late GaussFeedbackRepository repository;

  setUp(() {
    database = GaussDatabase(NativeDatabase.memory());
    repository = GaussFeedbackRepository(database);
  });

  tearDown(() => database.close());

  test(
    'account sync preserves exact question id, revision, and screenshot',
    () async {
      final target = _RecordingSyncTarget();
      final controller = GaussFeedbackController(
        repository,
        syncTarget: target,
        clock: () => DateTime.utc(2026, 8, 14, 12),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      await repository.addQuestionIssue(
        QuestionIssueReport(
          questionId: 'nardebam_math_1405_0042',
          questionRevision: 7,
          topicKey: 'sets',
          kind: QuestionIssueKind.solution,
          note: 'The final step needs another explanation.',
          sessionId: 'mission-42',
          missionIndex: 2,
          selectedChoiceIndex: 1,
          reportedAt: DateTime.utc(2026, 8, 14, 11, 58),
        ),
        screenshot: GaussFeedbackScreenshot(bytes: _onePixelPng, pixelRatio: 1),
      );

      await controller.syncPending();

      expect(target.entries, hasLength(1));
      expect(target.entries.single.questionId, 'nardebam_math_1405_0042');
      expect(target.entries.single.questionRevision, 7);
      expect(target.screenshots.single, _onePixelPng);
      expect(
        controller.entries.single.syncState,
        GaussFeedbackSyncState.synced,
      );
      expect(controller.entries.single.syncAttempts, 1);
      expect(controller.pendingCount, 0);
    },
  );

  test('failed upload remains local and retries idempotently', () async {
    final target = _RecordingSyncTarget(fail: true);
    final controller = GaussFeedbackController(
      repository,
      syncTarget: target,
      clock: () => DateTime.utc(2026, 8, 14, 12),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await repository.addEntry(
      id: 'fb_12345678_retry',
      kind: GaussFeedbackKind.error,
      route: '/map',
      note: 'Node spacing shifted.',
      createdAt: DateTime.utc(2026, 8, 14, 11),
    );

    await controller.syncPending();
    expect(controller.entries.single.syncState, GaussFeedbackSyncState.failed);
    expect(controller.entries.single.syncAttempts, 1);
    expect(controller.entries.single.note, 'Node spacing shifted.');

    target.fail = false;
    await controller.syncPending();
    expect(controller.entries.single.syncState, GaussFeedbackSyncState.synced);
    expect(controller.entries.single.syncAttempts, 2);
    expect(target.entries.last.id, 'fb_12345678_retry');
  });

  test(
    'private ZIP is redacted, revision-bound, and excludes account data',
    () async {
      await repository.addQuestionIssue(
        QuestionIssueReport(
          questionId: 'nardebam_physics_1405_0101',
          questionRevision: 9,
          topicKey: 'motion',
          kind: QuestionIssueKind.questionText,
          note: 'Authorization: Bearer not-a-real-export-token',
          sessionId: 'mission-export',
          missionIndex: 0,
          selectedChoiceIndex: null,
          reportedAt: DateTime.utc(2026, 8, 14, 12),
        ),
        screenshot: GaussFeedbackScreenshot(bytes: _onePixelPng, pixelRatio: 1),
      );
      final snapshot = await repository.createExportSnapshot();
      final bytes = GaussFeedbackExporter.buildArchive(
        snapshot,
        generatedAt: DateTime.utc(2026, 8, 14, 12, 30),
      );
      final archive = ZipDecoder().decodeBytes(bytes);
      final manifestBytes = archive
          .firstWhere((file) => file.name == 'manifest.json')
          .readBytes()!;
      final manifestText = utf8.decode(manifestBytes);
      final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
      final entry =
          (manifest['entries'] as List<dynamic>).single as Map<String, dynamic>;
      final screenshots = manifest['screenshots'] as Map<String, dynamic>;

      expect(entry['question_id'], 'nardebam_physics_1405_0101');
      expect(entry['question_revision'], 9);
      expect(entry['note'], contains('[REDACTED]'));
      expect(manifestText, isNot(contains('not-a-real-export-token')));
      expect(manifestText, isNot(contains('user_id')));
      expect(manifestText, isNot(contains('email')));
      expect(
        screenshots.values.single,
        containsPair('sha256', sha256.convert(_onePixelPng).toString()),
      );
      expect(
        archive.map((file) => file.name),
        contains('screenshots/${snapshot.entries.single.id}.png'),
      );
    },
  );

  test('Supabase payload is owner and release bound without credentials', () {
    final entry = GaussFeedbackEntry(
      id: 'fb_12345678_payload',
      kind: GaussFeedbackKind.questionIssue,
      route: '/mission/sets',
      note: 'Check this step.',
      questionId: 'nardebam_math_1405_0007',
      questionRevision: 4,
      topicKey: 'sets',
      questionIssueKind: 'solution',
      sessionId: 'mission-seven',
      missionIndex: 3,
      selectedChoiceIndex: 2,
      createdAt: DateTime.utc(2026, 8, 14),
      updatedAt: DateTime.utc(2026, 8, 14),
      syncState: GaussFeedbackSyncState.pending,
      syncAttempts: 0,
      hasScreenshot: true,
    );
    final row = SupabaseGaussFeedbackSyncTarget.remoteRow(
      entry,
      userId: '00000000-0000-4000-8000-000000000001',
      contentReleaseId: 'gauss-2026.08.14.1',
      screenshotPath:
          '00000000-0000-4000-8000-000000000001/fb_12345678_payload.png',
      screenshotSha256: List.filled(64, 'a').join(),
    );

    expect(row['question_revision'], 4);
    expect(row['content_release_id'], 'gauss-2026.08.14.1');
    expect(row.keys, isNot(contains('email')));
    expect(row.keys, isNot(contains('password')));
  });
}

final class _RecordingSyncTarget implements GaussFeedbackSyncTarget {
  _RecordingSyncTarget({this.fail = false});

  bool fail;
  final List<GaussFeedbackEntry> entries = [];
  final List<Uint8List> screenshots = [];

  @override
  Future<void> send(GaussFeedbackEntry entry, {Uint8List? screenshot}) async {
    entries.add(entry);
    if (screenshot != null) screenshots.add(Uint8List.fromList(screenshot));
    if (fail) throw const FormatException('offline fixture');
  }
}

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
