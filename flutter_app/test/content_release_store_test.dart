import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/content_release_store.dart';

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
}) {
  final questions = [
    _question('nardebam_math_1405_0001', 'First question'),
    _question('nardebam_math_1405_0002', 'Second question'),
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
        revision: 1,
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
