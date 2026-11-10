// End-to-end guard for the ONLINE path: the app downloads a content release,
// activates it into a real directory, and reads every question through that
// directory bundle. Offline it falls back to the bundled assets. A learner who
// is online must be able to enter every lesson exactly as an offline one can.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/content_release_store.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/state/gauss_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory scratch;
  setUp(() async {
    scratch = await Directory.systemTemp.createTemp('gauss-online-path-');
  });
  tearDown(() async {
    if (await scratch.exists()) await scratch.delete(recursive: true);
  });

  Future<List<String>> enterEveryLesson(QuestionBankRepository bank) async {
    final failures = <String>[];
    var entered = 0;
    for (final section in GaussStudyCurriculum.sections) {
      for (final node in GaussStudyCurriculum.nodesFor(section, bank.topics)) {
        try {
          final questions = await bank.createStudySessionMission(
            node.topic.key,
            offset: node.offset,
          );
          if (questions.length != GaussStudyCurriculum.batchSize) {
            failures.add('${node.key}: ${questions.length} questions');
          }
          entered++;
        } catch (error) {
          failures.add('${node.key}: $error');
        }
      }
    }
    expect(entered, greaterThan(300), reason: 'the whole route was walked');
    return failures;
  }

  test('every lesson opens from the bundled assets (offline path)', () async {
    final bank = QuestionBankRepository();
    await bank.initialize();
    expect(await enterEveryLesson(bank), isEmpty);
  });

  test('every lesson opens from a downloaded release (online path)', () async {
    final fixture = _realCorpusRelease();
    final snapshot = await GaussContentReleaseStore(
      api: fixture,
      appBuild: 1000,
      fallbackBundle: rootBundle,
      rootProvider: () async => scratch,
    ).open();

    expect(snapshot.refreshError, isNull, reason: '${snapshot.refreshError}');
    expect(snapshot.source, GaussContentSource.downloaded);

    final bank = QuestionBankRepository(bundle: snapshot.bundle);
    await bank.initialize();
    expect(await enterEveryLesson(bank), isEmpty);

    // Reopening later (offline, cached release) must behave the same.
    final cached = await GaussContentReleaseStore(
      api: _OfflineApi(),
      appBuild: 1000,
      fallbackBundle: rootBundle,
      rootProvider: () async => scratch,
    ).open();
    expect(cached.source, GaussContentSource.cached);
    final cachedBank = QuestionBankRepository(bundle: cached.bundle);
    await cachedBank.initialize();
    expect(await enterEveryLesson(cachedBank), isEmpty);
  });

  test('a release that cannot open lessons never becomes active', () async {
    final fixture = _realCorpusRelease();
    final snapshot = await GaussContentReleaseStore(
      api: fixture,
      appBuild: 1000,
      fallbackBundle: rootBundle,
      rootProvider: () async => scratch,
      verifyRelease: (bundle) async =>
          throw const FormatException('simulated unusable release'),
    ).open();

    expect(snapshot.source, GaussContentSource.bundled);
    expect(snapshot.releaseId, isNull);
    expect(snapshot.refreshError, isA<FormatException>());
    expect(File('${scratch.path}/active.json').existsSync(), isFalse);
    // The learner still enters lessons from the bundled library.
    final bank = QuestionBankRepository(bundle: snapshot.bundle);
    await bank.initialize();
    expect(
      await bank.createStudySessionMission('sets', offset: 0),
      hasLength(GaussStudyCurriculum.batchSize),
    );
  });

  test(
    'a release with an older lesson plan never replaces the bundled one',
    () async {
      final snapshot = await GaussContentReleaseStore(
        api: _realCorpusRelease(legacyPlan: true),
        appBuild: 1000,
        fallbackBundle: rootBundle,
        rootProvider: () async => scratch,
      ).open();

      expect(snapshot.source, GaussContentSource.bundled);
      expect(snapshot.releaseId, isNull);
      expect(
        '${snapshot.refreshError}',
        contains('older than the one bundled'),
      );
      expect(File('${scratch.path}/active.json').existsSync(), isFalse);
      final bank = QuestionBankRepository(bundle: snapshot.bundle);
      await bank.initialize();
      expect(bank.studyPlan.revision, greaterThanOrEqualTo(2));
    },
  );

  test('the real verifier accepts a healthy release', () async {
    final snapshot = await GaussContentReleaseStore(
      api: _realCorpusRelease(),
      appBuild: 1000,
      fallbackBundle: rootBundle,
      rootProvider: () async => scratch,
      verifyRelease: QuestionBankRepository.verifyBundle,
    ).open();
    expect(snapshot.refreshError, isNull, reason: '${snapshot.refreshError}');
    expect(snapshot.source, GaussContentSource.downloaded);
  });

  test('delivery revision survives certification binding', () async {
    final snapshot = await GaussContentReleaseStore(
      api: _realCorpusRelease(),
      appBuild: 1000,
      fallbackBundle: rootBundle,
      rootProvider: () async => scratch,
    ).open();
    final bank = QuestionBankRepository(bundle: snapshot.bundle);
    await bank.initialize();
    final questions = await bank.loadTopic('sets');
    expect(questions, isNotEmpty);
    expect(questions.every((question) => question.revision == 1), isTrue);
  });

  test('entering a lesson writes to a real on-disk database', () async {
    final fixture = _realCorpusRelease();
    final snapshot = await GaussContentReleaseStore(
      api: fixture,
      appBuild: 1000,
      fallbackBundle: rootBundle,
      rootProvider: () async => scratch,
    ).open();
    final database = GaussDatabase(
      NativeDatabase(File('${scratch.path}/progress.sqlite')),
    );
    addTearDown(database.close);
    final controller = GaussController(
      QuestionBankRepository(bundle: snapshot.bundle),
      ProgressRepository(database),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final node = GaussStudyCurriculum.nodesFor(
      GaussStudyCurriculum.sections.first,
      controller.topics,
    ).first;
    final questions = await controller.createStudySessionMission(
      node.topic.key,
      offset: node.offset,
    );
    await controller.startMission(
      sessionId: 'online-path-test',
      topicKey: node.topic.key,
      createdAt: DateTime.now(),
      questions: questions,
    );
    expect(await controller.loadResumableMission(), isNotNull);
  });
}

/// A release built from the exact bundled corpus, served by an in-memory API.
GaussContentApi _realCorpusRelease({bool legacyPlan = false}) {
  final assets = Directory('assets');
  Map<String, dynamic> readMap(String path) => Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map,
  );
  final index = readMap('assets/question_bank/index.json');
  final topics = (index['topics']! as List<dynamic>)
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList(growable: false);
  final topicIds = <String, List<String>>{};
  final revisions = <GaussRemoteQuestionRevision>[];
  for (final topic in topics) {
    final rows =
        jsonDecode(File('${assets.path}/${topic['file']}').readAsStringSync())
            as List<dynamic>;
    final ids = <String>[];
    for (final raw in rows) {
      final payload = Map<String, dynamic>.from(raw as Map);
      ids.add(payload['id']! as String);
      revisions.add(
        GaussRemoteQuestionRevision(
          ordinal: revisions.length,
          questionId: payload['id']! as String,
          revision: 1,
          subject: topic['subject']! as String,
          topicKey: topic['topic_key']! as String,
          difficulty: payload['difficulty']! as String,
          contentSha256: canonicalContentSha256(payload),
          payload: payload,
        ),
      );
    }
    topicIds[topic['topic_key']! as String] = ids;
  }
  final media =
      File('../data/certification/v1/media-manifest.jsonl')
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .map((line) => Map<String, dynamic>.from(jsonDecode(line) as Map))
          .toList()
        ..sort(
          (a, b) => (a['asset']! as String).compareTo(b['asset']! as String),
        );
  final payloads = <String, Map<String, dynamic>>{
    'question_index': {
      'schema_version': 1,
      'index': index,
      'topic_question_ids': topicIds,
    },
    'five_question_plan': legacyPlan
        // The plan as an older published release carries it: no revision.
        ? (readMap('assets/curriculum/five_question_plan_v1.json')
            ..remove('plan_revision'))
        : readMap('assets/curriculum/five_question_plan_v1.json'),
    'certification_runtime': readMap(
      'assets/curriculum/certified_question_runtime_v1.json',
    ),
    'media_manifest': {'schema_version': 1, 'entries': media},
  };
  final artifacts = [
    for (final entry in payloads.entries)
      GaussRemoteArtifact(
        kind: entry.key,
        sha256: canonicalContentSha256(entry.value),
        payload: entry.value,
      ),
  ];
  final release = GaussRemoteRelease(
    id: 'gauss-online-path-test',
    schemaVersion: 1,
    corpusSha256: computeContentCorpusSha256(
      artifactHashes: {for (final a in artifacts) a.kind: a.sha256},
      revisions: revisions,
    ),
    questionCount: revisions.length,
    topicCount: topics.length,
    minimumAppBuild: 1,
  );
  return _MemoryApi(release, artifacts, revisions);
}

final class _MemoryApi implements GaussContentApi {
  const _MemoryApi(this.release, this.artifactRows, this.revisions);
  final GaussRemoteRelease release;
  final List<GaussRemoteArtifact> artifactRows;
  final List<GaussRemoteQuestionRevision> revisions;

  @override
  Future<List<GaussRemoteArtifact>> artifacts(String releaseId) async =>
      artifactRows;

  @override
  Future<GaussRemoteRelease?> latestRelease(String channel) async => release;

  @override
  Future<List<GaussRemoteQuestionRevision>> questionPage(
    String releaseId, {
    required int from,
    required int to,
  }) async => revisions.sublist(from, to + 1);
}

final class _OfflineApi implements GaussContentApi {
  @override
  Future<List<GaussRemoteArtifact>> artifacts(String releaseId) =>
      throw const SocketException('offline');

  @override
  Future<GaussRemoteRelease?> latestRelease(String channel) =>
      throw const SocketException('offline');

  @override
  Future<List<GaussRemoteQuestionRevision>> questionPage(
    String releaseId, {
    required int from,
    required int to,
  }) => throw const SocketException('offline');
}
