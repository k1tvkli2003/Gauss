import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/content_release_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late _MemoryBundle fallback;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('gauss-content-store-');
    fallback = _MemoryBundle({
      'assets/question_bank/index.json': utf8.encode('{"bundled":true}'),
    });
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a complete release activates atomically and reopens offline', () async {
    final fixture = _fixture('gauss-test-1');
    final online = GaussContentReleaseStore(
      api: fixture.api,
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    );

    final downloaded = await online.open();

    expect(downloaded.source, GaussContentSource.downloaded);
    expect(downloaded.releaseId, fixture.release.id);
    expect(downloaded.refreshError, isNull);
    final remoteIndex =
        jsonDecode(
              await downloaded.bundle.loadString(
                'assets/question_bank/index.json',
              ),
            )
            as Map<String, dynamic>;
    expect(remoteIndex['total'], 2);
    final remoteQuestions =
        jsonDecode(
              await downloaded.bundle.loadString(
                'assets/question_bank/topics/math_sets.json',
              ),
            )
            as List<dynamic>;
    expect(
      remoteQuestions.map(
        (row) => (row as Map<String, dynamic>)['_gauss_revision'],
      ),
      everyElement(1),
    );
    expect(await File('${root.path}/active.json').exists(), isTrue);

    final offline = GaussContentReleaseStore(
      api: _ThrowingApi(),
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    );
    final reopened = await offline.open();

    expect(reopened.source, GaussContentSource.cached);
    expect(reopened.releaseId, fixture.release.id);
    expect(reopened.refreshError, isNotNull);
    expect(
      jsonDecode(
        await reopened.bundle.loadString('assets/question_bank/index.json'),
      ),
      containsPair('total', 2),
    );
  });

  test('a corrupt newer release cannot replace the active snapshot', () async {
    final first = _fixture('gauss-test-1');
    final store = GaussContentReleaseStore(
      api: first.api,
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    );
    expect((await store.open()).releaseId, 'gauss-test-1');
    final pointerBefore = await File('${root.path}/active.json').readAsString();

    final second = _fixture('gauss-test-2', corruptQuestionHash: true);
    final rejected = await GaussContentReleaseStore(
      api: second.api,
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    ).open();

    expect(rejected.releaseId, 'gauss-test-1');
    expect(rejected.source, GaussContentSource.cached);
    expect(rejected.refreshError, isNotNull);
    expect(
      await File('${root.path}/active.json').readAsString(),
      pointerBefore,
    );
  });

  test('a release requiring a newer app keeps the verified cache', () async {
    final first = _fixture('gauss-test-1');
    await GaussContentReleaseStore(
      api: first.api,
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    ).open();
    final future = _fixture('gauss-test-2', minimumAppBuild: 120);

    final result = await GaussContentReleaseStore(
      api: future.api,
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    ).open();

    expect(result.releaseId, 'gauss-test-1');
    expect(result.requiredBuild, 120);
    expect(result.refreshError, isNull);
  });

  test('unsafe remote asset paths fail closed to the bundled corpus', () async {
    final fixture = _fixture('gauss-test-unsafe', unsafePath: true);

    final result = await GaussContentReleaseStore(
      api: fixture.api,
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    ).open();

    expect(result.source, GaussContentSource.bundled);
    expect(result.releaseId, isNull);
    expect(result.refreshError, isNotNull);
    expect(
      await result.bundle.loadString('assets/question_bank/index.json'),
      '{"bundled":true}',
    );
  });

  test(
    'first remote activation reuses matching bundled question payloads',
    () async {
      final fixture = _fixture('gauss-test-1');
      final byKind = {
        for (final artifact in fixture.api.releaseArtifacts)
          artifact.kind: artifact.payload,
      };
      final indexArtifact = byKind['question_index']!;
      final bundled = _MemoryBundle({
        'assets/question_bank/index.json': utf8.encode(
          jsonEncode(indexArtifact['index']),
        ),
        'assets/question_bank/topics/math_sets.json': utf8.encode(
          jsonEncode(
            fixture.api.revisions
                .map((revision) => revision.payload)
                .toList(growable: false),
          ),
        ),
        'assets/curriculum/five_question_plan_v1.json': utf8.encode(
          jsonEncode(byKind['five_question_plan']),
        ),
        'assets/curriculum/certified_question_runtime_v1.json': utf8.encode(
          jsonEncode(byKind['certification_runtime']),
        ),
      });
      final deltaApi = _FakeDeltaApi(
        fixture.release,
        fixture.api.releaseArtifacts,
        fixture.api.revisions,
      );

      final result = await GaussContentReleaseStore(
        api: deltaApi,
        appBuild: 90,
        fallbackBundle: bundled,
        rootProvider: () async => root,
      ).open();

      expect(result.releaseId, fixture.release.id);
      expect(result.transferStats?.reusedQuestions, 2);
      expect(result.transferStats?.downloadedQuestions, 0);
      expect(result.transferStats?.reusedArtifacts, 3);
      expect(result.transferStats?.downloadedArtifacts, 1);
      expect(deltaApi.requestedQuestionBatches, isEmpty);
      expect(deltaApi.requestedArtifactBatches, [
        ['media_manifest'],
      ]);
    },
  );

  test(
    'manifest delta reuses verified artifacts and downloads only a changed question',
    () async {
      final first = _fixture('gauss-test-1');
      await GaussContentReleaseStore(
        api: first.api,
        appBuild: 90,
        fallbackBundle: fallback,
        rootProvider: () async => root,
      ).open();
      final second = _fixture(
        'gauss-test-2',
        secondStem: 'Second question revised',
        secondRevision: 2,
      );
      final deltaApi = _FakeDeltaApi(
        second.release,
        second.api.releaseArtifacts,
        second.api.revisions,
      );

      final result = await GaussContentReleaseStore(
        api: deltaApi,
        appBuild: 90,
        fallbackBundle: fallback,
        rootProvider: () async => root,
      ).open();

      expect(result.releaseId, 'gauss-test-2');
      expect(result.source, GaussContentSource.downloaded);
      expect(result.refreshError, isNull);
      expect(result.transferStats?.usedManifestDelta, isTrue);
      expect(result.transferStats?.artifactManifestRows, 4);
      expect(result.transferStats?.reusedArtifacts, 4);
      expect(result.transferStats?.downloadedArtifacts, 0);
      expect(result.transferStats?.questionManifestRows, 2);
      expect(result.transferStats?.reusedQuestions, 1);
      expect(result.transferStats?.downloadedQuestions, 1);
      expect(deltaApi.requestedArtifactBatches, isEmpty);
      expect(deltaApi.requestedQuestionBatches, [
        ['nardebam_math_1405_0002'],
      ]);
      expect(deltaApi.legacyQuestionPageCalls, 0);
      final questions =
          jsonDecode(
                await result.bundle.loadString(
                  'assets/question_bank/topics/math_sets.json',
                ),
              )
              as List<dynamic>;
      expect((questions[0] as Map<String, dynamic>)['_gauss_revision'], 1);
      expect((questions[1] as Map<String, dynamic>)['_gauss_revision'], 2);
    },
  );

  test('an incomplete delta batch keeps the old active pointer', () async {
    final first = _fixture('gauss-test-1');
    await GaussContentReleaseStore(
      api: first.api,
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    ).open();
    final pointerBefore = await File('${root.path}/active.json').readAsString();
    final second = _fixture(
      'gauss-test-2',
      secondStem: 'Second question revised',
      secondRevision: 2,
    );
    final deltaApi = _FakeDeltaApi(
      second.release,
      second.api.releaseArtifacts,
      second.api.revisions,
      omitLastQuestionPayload: true,
    );

    final result = await GaussContentReleaseStore(
      api: deltaApi,
      appBuild: 90,
      fallbackBundle: fallback,
      rootProvider: () async => root,
    ).open();

    expect(result.releaseId, 'gauss-test-1');
    expect(result.source, GaussContentSource.cached);
    expect(result.refreshError, isA<FormatException>());
    expect(deltaApi.legacyQuestionPageCalls, 0);
    expect(
      await File('${root.path}/active.json').readAsString(),
      pointerBefore,
    );
  });

  test(
    'a not-yet-deployed delta RPC falls back to the verified legacy page',
    () async {
      final first = _fixture('gauss-test-1');
      await GaussContentReleaseStore(
        api: first.api,
        appBuild: 90,
        fallbackBundle: fallback,
        rootProvider: () async => root,
      ).open();
      final second = _fixture(
        'gauss-test-2',
        secondStem: 'Second question revised',
        secondRevision: 2,
      );
      final deltaApi = _FakeDeltaApi(
        second.release,
        second.api.releaseArtifacts,
        second.api.revisions,
        questionManifestUnavailable: true,
      );

      final result = await GaussContentReleaseStore(
        api: deltaApi,
        appBuild: 90,
        fallbackBundle: fallback,
        rootProvider: () async => root,
      ).open();

      expect(result.releaseId, 'gauss-test-2');
      expect(result.refreshError, isNull);
      expect(result.transferStats?.reusedArtifacts, 4);
      expect(result.transferStats?.downloadedQuestions, 2);
      expect(deltaApi.legacyQuestionPageCalls, 1);
    },
  );

  test('published release receipt matches the exact local corpus', () {
    final repo = _findRepositoryRoot();
    final flutterAssets = Directory(
      _joinParts([repo.path, 'flutter_app', 'assets']),
    );
    final index = _readJsonMap(
      File(_joinParts([flutterAssets.path, 'question_bank', 'index.json'])),
    );
    final topics = (index['topics']! as List<dynamic>)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList(growable: false);
    final topicQuestionIds = <String, List<String>>{};
    final revisions = <GaussRemoteQuestionRevision>[];

    for (final topic in topics) {
      final topicKey = topic['topic_key']! as String;
      final subject = topic['subject']! as String;
      final relativePath = topic['file']! as String;
      final rows = _readJsonList(
        File(_joinParts([flutterAssets.path, ...relativePath.split('/')])),
      );
      final ids = <String>[];
      for (final raw in rows) {
        final payload = Map<String, dynamic>.from(raw as Map);
        final questionId = payload['id']! as String;
        ids.add(questionId);
        revisions.add(
          GaussRemoteQuestionRevision(
            ordinal: revisions.length,
            questionId: questionId,
            revision: 1,
            subject: subject,
            topicKey: topicKey,
            difficulty: payload['difficulty']! as String,
            contentSha256: canonicalContentSha256(payload),
            payload: payload,
          ),
        );
      }
      topicQuestionIds[topicKey] = ids;
    }

    final certification = _readJsonMap(
      File(
        _joinParts([
          flutterAssets.path,
          'curriculum',
          'certified_question_runtime_v1.json',
        ]),
      ),
    );
    final fiveQuestionPlan = _readJsonMap(
      File(
        _joinParts([
          flutterAssets.path,
          'curriculum',
          'five_question_plan_v1.json',
        ]),
      ),
    );
    final mediaEntries = File(
      _joinParts([
        repo.path,
        'data',
        'certification',
        'v1',
        'media-manifest.jsonl',
      ]),
    ).readAsLinesSync()..removeWhere((line) => line.trim().isEmpty);
    final media =
        mediaEntries
            .map((line) => Map<String, dynamic>.from(jsonDecode(line) as Map))
            .toList(growable: false)
          ..sort(
            (first, second) => (first['asset']! as String).compareTo(
              second['asset']! as String,
            ),
          );
    final artifactPayloads = <String, Map<String, dynamic>>{
      'question_index': {
        'schema_version': 1,
        'index': index,
        'topic_question_ids': topicQuestionIds,
      },
      'five_question_plan': fiveQuestionPlan,
      'certification_runtime': certification,
      'media_manifest': {'schema_version': 1, 'entries': media},
    };
    final artifactHashes = {
      for (final entry in artifactPayloads.entries)
        entry.key: canonicalContentSha256(entry.value),
    };
    final receipt = _readJsonMap(
      File(
        _joinParts([
          repo.path,
          'data',
          'content-releases',
          'gauss-2026.08.14.1.json',
        ]),
      ),
    );

    expect(revisions, hasLength(receipt['question_count']! as int));
    expect(topics, hasLength(receipt['topic_count']! as int));
    expect(artifactHashes, equals(receipt['artifact_sha256']));
    expect(
      computeContentCorpusSha256(
        artifactHashes: artifactHashes,
        revisions: revisions,
      ),
      receipt['corpus_sha256'],
    );
  });

  test('a one-question manifest delta stays below fifteen percent', () {
    final budget = _realCorpusTransferBudget(_findRepositoryRoot());

    expect(budget.questionCount, 3672);
    expect(
      budget.deltaBytes,
      lessThan(budget.fullBytes * 0.15),
      reason:
          'Uncompressed RPC-equivalent bytes: full=${budget.fullBytes}, '
          'one-question delta=${budget.deltaBytes}.',
    );
  });
}

Directory _findRepositoryRoot() {
  var cursor = Directory.current.absolute;
  while (true) {
    if (File(
      _joinParts([cursor.path, 'flutter_app', 'pubspec.yaml']),
    ).existsSync()) {
      return cursor;
    }
    if (File(_joinParts([cursor.path, 'pubspec.yaml'])).existsSync() &&
        Directory(
          _joinParts([cursor.path, 'assets', 'question_bank']),
        ).existsSync()) {
      return cursor.parent;
    }
    final parent = cursor.parent;
    if (parent.path == cursor.path) {
      throw StateError('Cannot locate the Gauss repository root.');
    }
    cursor = parent;
  }
}

Map<String, dynamic> _readJsonMap(File file) =>
    Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);

List<dynamic> _readJsonList(File file) =>
    List<dynamic>.from(jsonDecode(file.readAsStringSync()) as List);

String _joinParts(Iterable<String> parts) => parts.join(Platform.pathSeparator);

({int questionCount, int fullBytes, int deltaBytes}) _realCorpusTransferBudget(
  Directory repo,
) {
  final assets = Directory(_joinParts([repo.path, 'flutter_app', 'assets']));
  final index = _readJsonMap(
    File(_joinParts([assets.path, 'question_bank', 'index.json'])),
  );
  final topics = (index['topics']! as List<dynamic>)
      .map((raw) => Map<String, dynamic>.from(raw as Map))
      .toList(growable: false);
  final topicQuestionIds = <String, List<String>>{};
  final fullQuestionRows = <Map<String, dynamic>>[];
  final manifestRows = <Map<String, dynamic>>[];
  for (final topic in topics) {
    final topicKey = topic['topic_key']! as String;
    final subject = topic['subject']! as String;
    final relativePath = topic['file']! as String;
    final questions = _readJsonList(
      File(_joinParts([assets.path, ...relativePath.split('/')])),
    );
    final ids = <String>[];
    for (final raw in questions) {
      final payload = Map<String, dynamic>.from(raw as Map);
      final questionId = payload['id']! as String;
      final descriptor = <String, dynamic>{
        'ordinal': manifestRows.length,
        'question_id': questionId,
        'revision': 1,
        'subject': subject,
        'topic_key': topicKey,
        'difficulty': payload['difficulty'],
        'content_sha256': canonicalContentSha256(payload),
      };
      ids.add(questionId);
      manifestRows.add(descriptor);
      fullQuestionRows.add(<String, dynamic>{
        ...descriptor,
        'payload': payload,
      });
    }
    topicQuestionIds[topicKey] = ids;
  }
  final mediaEntries =
      File(
            _joinParts([
              repo.path,
              'data',
              'certification',
              'v1',
              'media-manifest.jsonl',
            ]),
          )
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .map((line) {
            return Map<String, dynamic>.from(jsonDecode(line) as Map);
          })
          .toList(growable: false)
        ..sort(
          (first, second) =>
              (first['asset']! as String).compareTo(second['asset']! as String),
        );
  final artifactPayloads = <String, Map<String, dynamic>>{
    'question_index': {
      'schema_version': 1,
      'index': index,
      'topic_question_ids': topicQuestionIds,
    },
    'five_question_plan': _readJsonMap(
      File(
        _joinParts([assets.path, 'curriculum', 'five_question_plan_v1.json']),
      ),
    ),
    'certification_runtime': _readJsonMap(
      File(
        _joinParts([
          assets.path,
          'curriculum',
          'certified_question_runtime_v1.json',
        ]),
      ),
    ),
    'media_manifest': {'schema_version': 1, 'entries': mediaEntries},
  };
  final sortedKinds = artifactPayloads.keys.toList()..sort();
  final fullArtifactRows = [
    for (final kind in sortedKinds)
      {
        'kind': kind,
        'sha256': canonicalContentSha256(artifactPayloads[kind]!),
        'payload': artifactPayloads[kind],
      },
  ];
  final artifactManifestRows = [
    for (final row in fullArtifactRows)
      {'kind': row['kind'], 'sha256': row['sha256']},
  ];
  final largestQuestion = fullQuestionRows.reduce(
    (first, second) =>
        _jsonByteCount(first) >= _jsonByteCount(second) ? first : second,
  );
  final fullBytes =
      _jsonByteCount(fullQuestionRows) + _jsonByteCount(fullArtifactRows);
  final deltaBytes =
      _jsonByteCount(manifestRows) +
      _jsonByteCount(artifactManifestRows) +
      _jsonByteCount(<Object>[largestQuestion]);
  return (
    questionCount: fullQuestionRows.length,
    fullBytes: fullBytes,
    deltaBytes: deltaBytes,
  );
}

int _jsonByteCount(Object value) => utf8.encode(jsonEncode(value)).length;

final class _Fixture {
  const _Fixture(this.release, this.api);

  final GaussRemoteRelease release;
  final _FakeApi api;
}

_Fixture _fixture(
  String releaseId, {
  int minimumAppBuild = 90,
  bool corruptQuestionHash = false,
  bool unsafePath = false,
  String secondStem = 'Second question',
  int secondRevision = 1,
}) {
  final questions = [
    _question('nardebam_math_1405_0001', 'First question'),
    _question('nardebam_math_1405_0002', secondStem),
  ];
  final index = <String, dynamic>{
    'schema_version': 2,
    'total': 2,
    'topics': [
      {
        'subject': 'math',
        'topic_key': 'sets',
        'label': 'Sets',
        'order': 1,
        'file': unsafePath
            ? '../outside.json'
            : 'question_bank/topics/math_sets.json',
        'count': 2,
      },
    ],
  };
  final artifactPayloads = <String, Map<String, dynamic>>{
    'question_index': {
      'schema_version': 1,
      'index': index,
      'topic_question_ids': {
        'sets': questions.map((row) => row['id']).toList(),
      },
    },
    'five_question_plan': {'schema_version': 1, 'source_question_count': 2},
    'certification_runtime': {'schema_version': 1, 'source_question_count': 2},
    'media_manifest': {'schema_version': 1, 'entries': <Object>[]},
  };
  final artifacts = artifactPayloads.entries
      .map(
        (entry) => GaussRemoteArtifact(
          kind: entry.key,
          sha256: canonicalContentSha256(entry.value),
          payload: entry.value,
        ),
      )
      .toList(growable: false);
  final revisions = <GaussRemoteQuestionRevision>[];
  for (var index = 0; index < questions.length; index++) {
    final payload = questions[index];
    final digest = canonicalContentSha256(payload);
    revisions.add(
      GaussRemoteQuestionRevision(
        ordinal: index,
        questionId: payload['id']! as String,
        revision: index == 1 ? secondRevision : 1,
        subject: 'math',
        topicKey: 'sets',
        difficulty: 'easy',
        contentSha256: corruptQuestionHash && index == 1
            ? List.filled(64, '0').join()
            : digest,
        payload: payload,
      ),
    );
  }
  final artifactHashes = {
    for (final artifact in artifacts) artifact.kind: artifact.sha256,
  };
  final release = GaussRemoteRelease(
    id: releaseId,
    schemaVersion: 1,
    corpusSha256: computeContentCorpusSha256(
      artifactHashes: artifactHashes,
      revisions: revisions,
    ),
    questionCount: 2,
    topicCount: 1,
    minimumAppBuild: minimumAppBuild,
  );
  return _Fixture(release, _FakeApi(release, artifacts, revisions));
}

Map<String, dynamic> _question(String id, String stem) => {
  'id': id,
  'subject': 'math',
  'topic_key': 'sets',
  'difficulty': 'easy',
  'source_bank': 'nardebam',
  'correct_option_index': 1,
  'stem': [
    {'type': 'text', 'text': stem},
  ],
  'options': [
    [
      {'type': 'text', 'text': 'A'},
    ],
    [
      {'type': 'text', 'text': 'B'},
    ],
    [
      {'type': 'text', 'text': 'C'},
    ],
    [
      {'type': 'text', 'text': 'D'},
    ],
  ],
  'solution': [
    {'type': 'text', 'text': 'A is correct.'},
  ],
};

final class _FakeApi implements GaussContentApi {
  const _FakeApi(this.release, this.releaseArtifacts, this.revisions);

  final GaussRemoteRelease release;
  final List<GaussRemoteArtifact> releaseArtifacts;
  final List<GaussRemoteQuestionRevision> revisions;

  @override
  Future<List<GaussRemoteArtifact>> artifacts(String releaseId) async =>
      releaseArtifacts;

  @override
  Future<GaussRemoteRelease?> latestRelease(String channel) async => release;

  @override
  Future<List<GaussRemoteQuestionRevision>> questionPage(
    String releaseId, {
    required int from,
    required int to,
  }) async => revisions.sublist(from, to + 1);
}

final class _FakeDeltaApi implements GaussDeltaContentApi {
  _FakeDeltaApi(
    this.release,
    this.releaseArtifacts,
    this.revisions, {
    this.omitLastQuestionPayload = false,
    this.questionManifestUnavailable = false,
  });

  final GaussRemoteRelease release;
  final List<GaussRemoteArtifact> releaseArtifacts;
  final List<GaussRemoteQuestionRevision> revisions;
  final bool omitLastQuestionPayload;
  final bool questionManifestUnavailable;
  final List<List<String>> requestedArtifactBatches = <List<String>>[];
  final List<List<String>> requestedQuestionBatches = <List<String>>[];
  int legacyQuestionPageCalls = 0;

  @override
  Future<List<GaussRemoteArtifactDescriptor>> artifactManifest(
    String releaseId,
  ) async => releaseArtifacts
      .map(
        (artifact) => GaussRemoteArtifactDescriptor(
          kind: artifact.kind,
          sha256: artifact.sha256,
        ),
      )
      .toList(growable: false);

  @override
  Future<List<GaussRemoteArtifact>> artifactBatch(
    String releaseId,
    List<String> kinds,
  ) async {
    requestedArtifactBatches.add(List<String>.from(kinds));
    final byKind = {
      for (final artifact in releaseArtifacts) artifact.kind: artifact,
    };
    return kinds.map((kind) => byKind[kind]!).toList(growable: false);
  }

  @override
  Future<List<GaussRemoteArtifact>> artifacts(String releaseId) async =>
      releaseArtifacts;

  @override
  Future<GaussRemoteRelease?> latestRelease(String channel) async => release;

  @override
  Future<List<GaussRemoteQuestionRevision>> questionBatch(
    String releaseId,
    List<GaussRemoteQuestionDescriptor> descriptors,
  ) async {
    requestedQuestionBatches.add(
      descriptors
          .map((descriptor) => descriptor.questionId)
          .toList(growable: false),
    );
    final byIdentity = {
      for (final revision in revisions)
        '${revision.questionId}:${revision.revision}': revision,
    };
    final result = descriptors
        .map(
          (descriptor) =>
              byIdentity['${descriptor.questionId}:${descriptor.revision}']!,
        )
        .toList(growable: true);
    if (omitLastQuestionPayload && result.isNotEmpty) result.removeLast();
    return result;
  }

  @override
  Future<List<GaussRemoteQuestionDescriptor>> questionManifestPage(
    String releaseId, {
    required int from,
    required int to,
  }) async {
    if (questionManifestUnavailable) {
      throw const PostgrestException(
        message: 'Function is not present in the schema cache.',
        code: 'PGRST202',
      );
    }
    return revisions
        .sublist(from, to + 1)
        .map(
          (revision) => GaussRemoteQuestionDescriptor(
            ordinal: revision.ordinal,
            questionId: revision.questionId,
            revision: revision.revision,
            subject: revision.subject,
            topicKey: revision.topicKey,
            difficulty: revision.difficulty,
            contentSha256: revision.contentSha256,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<GaussRemoteQuestionRevision>> questionPage(
    String releaseId, {
    required int from,
    required int to,
  }) async {
    legacyQuestionPageCalls += 1;
    return revisions.sublist(from, to + 1);
  }
}

final class _ThrowingApi implements GaussContentApi {
  @override
  Future<List<GaussRemoteArtifact>> artifacts(String releaseId) =>
      throw SocketException('offline');

  @override
  Future<GaussRemoteRelease?> latestRelease(String channel) =>
      throw SocketException('offline');

  @override
  Future<List<GaussRemoteQuestionRevision>> questionPage(
    String releaseId, {
    required int from,
    required int to,
  }) => throw SocketException('offline');
}

final class _MemoryBundle extends CachingAssetBundle {
  _MemoryBundle(Map<String, List<int>> assets)
    : _assets = assets.map(
        (key, value) => MapEntry(key, Uint8List.fromList(value)),
      );

  final Map<String, Uint8List> _assets;

  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) throw StateError('Missing test asset $key');
    return ByteData.sublistView(value);
  }
}
