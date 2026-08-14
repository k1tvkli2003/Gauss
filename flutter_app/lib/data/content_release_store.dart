import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gaussContentChannel = 'android-stable';
const _contentRootName = 'gauss_content_v1';
const _releaseIdPattern = r'^[a-z0-9][a-z0-9._-]{2,79}$';
const _questionIdPattern = r'^nardebam_(math|physics)_[0-9]{4}_[0-9]{4}$';
const _sha256Pattern = r'^[0-9a-f]{64}$';
const _requiredArtifactKinds = <String>{
  'question_index',
  'five_question_plan',
  'certification_runtime',
  'media_manifest',
};

enum GaussContentSource { bundled, cached, downloaded }

final class GaussContentSnapshot {
  const GaussContentSnapshot({
    required this.bundle,
    required this.source,
    this.releaseId,
    this.corpusSha256,
    this.requiredBuild,
    this.refreshError,
  });

  final AssetBundle bundle;
  final GaussContentSource source;
  final String? releaseId;
  final String? corpusSha256;
  final int? requiredBuild;
  final Object? refreshError;

  bool get isRemote => releaseId != null;

  GaussContentSnapshot withRefreshError(Object error) => GaussContentSnapshot(
    bundle: bundle,
    source: source,
    releaseId: releaseId,
    corpusSha256: corpusSha256,
    requiredBuild: requiredBuild,
    refreshError: error,
  );

  GaussContentSnapshot requiringBuild(int value) => GaussContentSnapshot(
    bundle: bundle,
    source: source,
    releaseId: releaseId,
    corpusSha256: corpusSha256,
    requiredBuild: value,
    refreshError: refreshError,
  );
}

final class GaussRemoteRelease {
  const GaussRemoteRelease({
    required this.id,
    required this.schemaVersion,
    required this.corpusSha256,
    required this.questionCount,
    required this.topicCount,
    required this.minimumAppBuild,
  });

  final String id;
  final int schemaVersion;
  final String corpusSha256;
  final int questionCount;
  final int topicCount;
  final int minimumAppBuild;
}

final class GaussRemoteArtifact {
  const GaussRemoteArtifact({
    required this.kind,
    required this.sha256,
    required this.payload,
  });

  final String kind;
  final String sha256;
  final Map<String, dynamic> payload;
}

final class GaussRemoteQuestionRevision {
  const GaussRemoteQuestionRevision({
    required this.ordinal,
    required this.questionId,
    required this.revision,
    required this.subject,
    required this.topicKey,
    required this.difficulty,
    required this.contentSha256,
    required this.payload,
  });

  final int ordinal;
  final String questionId;
  final int revision;
  final String subject;
  final String topicKey;
  final String difficulty;
  final String contentSha256;
  final Map<String, dynamic> payload;
}

abstract interface class GaussContentApi {
  Future<GaussRemoteRelease?> latestRelease(String channel);

  Future<List<GaussRemoteArtifact>> artifacts(String releaseId);

  Future<List<GaussRemoteQuestionRevision>> questionPage(
    String releaseId, {
    required int from,
    required int to,
  });
}

final class SupabaseGaussContentApi implements GaussContentApi {
  SupabaseGaussContentApi(
    this._client, {
    this.requestTimeout = const Duration(seconds: 20),
  });

  final SupabaseClient _client;
  final Duration requestTimeout;

  @override
  Future<GaussRemoteRelease?> latestRelease(String channel) async {
    final channelRow = await _client
        .from('gauss_content_channels')
        .select('release_id')
        .eq('channel', channel)
        .maybeSingle()
        .timeout(requestTimeout);
    if (channelRow == null) return null;
    final releaseId = channelRow['release_id'];
    if (releaseId is! String) {
      throw const FormatException('Content channel has no release id.');
    }
    final row = await _client
        .from('gauss_content_releases')
        .select(
          'id,schema_version,corpus_sha256,question_count,topic_count,minimum_app_build',
        )
        .eq('id', releaseId)
        .eq('state', 'published')
        .single()
        .timeout(requestTimeout);
    return GaussRemoteRelease(
      id: _requiredString(row, 'id'),
      schemaVersion: _requiredInt(row, 'schema_version'),
      corpusSha256: _requiredHash(row, 'corpus_sha256'),
      questionCount: _requiredInt(row, 'question_count'),
      topicCount: _requiredInt(row, 'topic_count'),
      minimumAppBuild: _requiredInt(row, 'minimum_app_build'),
    );
  }

  @override
  Future<List<GaussRemoteArtifact>> artifacts(String releaseId) async {
    final rows = await _client
        .from('gauss_content_artifacts')
        .select('kind,sha256,payload')
        .eq('release_id', releaseId)
        .order('kind')
        .timeout(requestTimeout);
    return rows
        .map((raw) {
          final row = Map<String, dynamic>.from(raw);
          return GaussRemoteArtifact(
            kind: _requiredString(row, 'kind'),
            sha256: _requiredHash(row, 'sha256'),
            payload: _requiredMap(row, 'payload'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<GaussRemoteQuestionRevision>> questionPage(
    String releaseId, {
    required int from,
    required int to,
  }) async {
    final rows = await _client
        .rpc(
          'gauss_release_payload',
          params: <String, Object?>{
            'p_release_id': releaseId,
            'p_offset': from,
            'p_limit': to - from + 1,
          },
        )
        .timeout(requestTimeout);
    if (rows is! List<dynamic>) {
      throw const FormatException('Release payload RPC returned no row list.');
    }
    return rows
        .map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Release payload contains a non-object.',
            );
          }
          final row = Map<String, dynamic>.from(raw);
          return GaussRemoteQuestionRevision(
            ordinal: _requiredInt(row, 'ordinal'),
            questionId: _requiredString(row, 'question_id'),
            revision: _requiredInt(row, 'revision'),
            subject: _requiredString(row, 'subject'),
            topicKey: _requiredString(row, 'topic_key'),
            difficulty: _requiredString(row, 'difficulty'),
            contentSha256: _requiredHash(row, 'content_sha256'),
            payload: _requiredMap(row, 'payload'),
          );
        })
        .toList(growable: false);
  }
}

typedef GaussContentRootProvider = Future<Directory> Function();
typedef GaussContentPhase = void Function(String message);

/// Downloads a complete release into a staging directory, validates every
/// hash and identity, then atomically flips a tiny active pointer.
///
/// A network error, an incompatible build, a malformed row, or a process death
/// can never replace the last verified snapshot. The bundled corpus remains the
/// final offline fallback when no verified remote release exists yet.
final class GaussContentReleaseStore {
  GaussContentReleaseStore({
    required this._api,
    required this.appBuild,
    AssetBundle? fallbackBundle,
    GaussContentRootProvider? rootProvider,
    this.channel = gaussContentChannel,
  }) : _fallback = fallbackBundle ?? rootBundle,
       _rootProvider = rootProvider ?? _defaultRoot;

  final GaussContentApi _api;
  final AssetBundle _fallback;
  final GaussContentRootProvider _rootProvider;
  final int appBuild;
  final String channel;

  static Future<Directory> _defaultRoot() async {
    final support = await getApplicationSupportDirectory();
    return Directory(_join(support.path, _contentRootName));
  }

  Future<GaussContentSnapshot> open({GaussContentPhase? onPhase}) async {
    final root = await _rootProvider();
    await root.create(recursive: true);
    final active = await _loadActive(root) ?? _bundledSnapshot();
    try {
      onPhase?.call('Checking the question atlas…');
      final release = await _api.latestRelease(channel);
      if (release == null) return active;
      _validateReleaseHeader(release);
      if (release.minimumAppBuild > appBuild) {
        return active.requiringBuild(release.minimumAppBuild);
      }
      if (active.releaseId == release.id &&
          active.corpusSha256 == release.corpusSha256) {
        return active;
      }
      onPhase?.call('Verifying ${release.questionCount} questions…');
      return await _downloadAndActivate(root, release);
    } catch (error) {
      return active.withRefreshError(error);
    }
  }

  GaussContentSnapshot _bundledSnapshot() => GaussContentSnapshot(
    bundle: _fallback,
    source: GaussContentSource.bundled,
  );

  Future<GaussContentSnapshot?> _loadActive(Directory root) async {
    for (final name in const ['active.json', 'active.previous.json']) {
      final pointer = File(_join(root.path, name));
      if (!await pointer.exists()) continue;
      try {
        final json = jsonDecode(await pointer.readAsString());
        if (json is! Map<String, dynamic>) continue;
        final releaseId = _requiredString(json, 'release_id');
        final corpusHash = _requiredHash(json, 'corpus_sha256');
        final manifestHash = _requiredHash(json, 'manifest_sha256');
        final directory = Directory(
          _join(root.path, 'releases', _safeReleaseId(releaseId)),
        );
        await _verifyReleaseDirectory(
          directory,
          releaseId: releaseId,
          corpusSha256: corpusHash,
          manifestSha256: manifestHash,
        );
        return GaussContentSnapshot(
          bundle: _DirectoryAssetBundle(directory, _fallback),
          source: GaussContentSource.cached,
          releaseId: releaseId,
          corpusSha256: corpusHash,
        );
      } catch (_) {
        // Preserve invalid evidence on disk and try the previous pointer. A
        // corrupt cache must never turn into a destructive cleanup path.
      }
    }
    return null;
  }

  Future<GaussContentSnapshot> _downloadAndActivate(
    Directory root,
    GaussRemoteRelease release,
  ) async {
    final releaseId = _safeReleaseId(release.id);
    final artifacts = await _api.artifacts(releaseId);
    final artifactsByKind = <String, GaussRemoteArtifact>{};
    for (final artifact in artifacts) {
      if (!_requiredArtifactKinds.contains(artifact.kind) ||
          artifactsByKind.putIfAbsent(artifact.kind, () => artifact) !=
              artifact) {
        throw const FormatException('Release artifact registry is invalid.');
      }
      if (canonicalContentSha256(artifact.payload) != artifact.sha256) {
        throw FormatException('${artifact.kind} failed its artifact hash.');
      }
    }
    if (!setEquals(artifactsByKind.keys.toSet(), _requiredArtifactKinds)) {
      throw const FormatException('Release is missing a required artifact.');
    }

    final revisions = <GaussRemoteQuestionRevision>[];
    const pageSize = 500;
    for (var from = 0; from < release.questionCount; from += pageSize) {
      final to = (from + pageSize - 1).clamp(0, release.questionCount - 1);
      final page = await _api.questionPage(releaseId, from: from, to: to);
      if (page.length != to - from + 1) {
        throw const FormatException('Release question page is incomplete.');
      }
      revisions.addAll(page);
    }
    _validateRevisions(release, revisions);
    final artifactHashes = {
      for (final entry in artifactsByKind.entries)
        entry.key: entry.value.sha256,
    };
    final corpusHash = computeContentCorpusSha256(
      artifactHashes: artifactHashes,
      revisions: revisions,
    );
    if (corpusHash != release.corpusSha256) {
      throw const FormatException('Release corpus hash does not reconcile.');
    }

    final staging = Directory(
      _join(
        root.path,
        'staging-$releaseId-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await staging.create(recursive: true);
    try {
      final fileHashes = await _writeReleaseFiles(
        staging,
        release: release,
        artifacts: artifactsByKind,
        revisions: revisions,
      );
      final manifest = <String, dynamic>{
        'schema_version': 1,
        'release_id': releaseId,
        'corpus_sha256': release.corpusSha256,
        'question_count': release.questionCount,
        'topic_count': release.topicCount,
        'minimum_app_build': release.minimumAppBuild,
        'artifact_hashes': artifactHashes,
        'file_hashes': fileHashes,
      };
      final manifestBytes = utf8.encode(canonicalContentJson(manifest));
      final manifestFile = File(_join(staging.path, 'release.json'));
      await manifestFile.writeAsBytes(manifestBytes, flush: true);
      final manifestHash = sha256.convert(manifestBytes).toString();
      await _verifyReleaseDirectory(
        staging,
        releaseId: releaseId,
        corpusSha256: release.corpusSha256,
        manifestSha256: manifestHash,
      );

      final releasesRoot = Directory(_join(root.path, 'releases'));
      await releasesRoot.create(recursive: true);
      final target = Directory(_join(releasesRoot.path, releaseId));
      if (await target.exists()) {
        try {
          await _verifyReleaseDirectory(
            target,
            releaseId: releaseId,
            corpusSha256: release.corpusSha256,
            manifestSha256: manifestHash,
          );
          await staging.delete(recursive: true);
        } catch (_) {
          final rejected = Directory(
            '${target.path}.rejected-${DateTime.now().microsecondsSinceEpoch}',
          );
          await target.rename(rejected.path);
          await staging.rename(target.path);
        }
      } else {
        await staging.rename(target.path);
      }
      await _activatePointer(
        root,
        releaseId: releaseId,
        corpusSha256: release.corpusSha256,
        manifestSha256: manifestHash,
      );
      return GaussContentSnapshot(
        bundle: _DirectoryAssetBundle(target, _fallback),
        source: GaussContentSource.downloaded,
        releaseId: releaseId,
        corpusSha256: release.corpusSha256,
      );
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  Future<Map<String, String>> _writeReleaseFiles(
    Directory staging, {
    required GaussRemoteRelease release,
    required Map<String, GaussRemoteArtifact> artifacts,
    required List<GaussRemoteQuestionRevision> revisions,
  }) async {
    final indexArtifact = artifacts['question_index']!.payload;
    final index = _requiredMap(indexArtifact, 'index');
    final topicIdsRaw = _requiredMap(indexArtifact, 'topic_question_ids');
    final topicsRaw = index['topics'];
    if (index['schema_version'] != 2 ||
        index['total'] != release.questionCount ||
        topicsRaw is! List<dynamic> ||
        topicsRaw.length != release.topicCount) {
      throw const FormatException('Remote question index is incompatible.');
    }
    final byId = {
      for (final revision in revisions) revision.questionId: revision,
    };
    final usedIds = <String>{};
    final fileHashes = <String, String>{};
    fileHashes['assets/question_bank/index.json'] = await _writeJson(
      staging,
      'assets/question_bank/index.json',
      index,
    );
    for (final rawTopic in topicsRaw) {
      if (rawTopic is! Map) {
        throw const FormatException('Remote index contains a bad topic.');
      }
      final topic = Map<String, dynamic>.from(rawTopic);
      final topicKey = _requiredString(topic, 'topic_key');
      final relativePath = _requiredString(topic, 'file');
      final count = _requiredInt(topic, 'count');
      final idsRaw = topicIdsRaw[topicKey];
      if (idsRaw is! List<dynamic> ||
          idsRaw.length != count ||
          idsRaw.any((id) => id is! String)) {
        throw FormatException('$topicKey has an invalid question-id order.');
      }
      final rows = <Map<String, dynamic>>[];
      for (final id in idsRaw.cast<String>()) {
        final revision = byId[id];
        if (revision == null ||
            revision.topicKey != topicKey ||
            !usedIds.add(id)) {
          throw FormatException('$topicKey cannot bind question $id.');
        }
        rows.add(<String, dynamic>{
          ...revision.payload,
          // Runtime-only delivery metadata. The immutable database payload
          // and its content hash stay untouched; this binds feedback and
          // progress diagnostics to the exact served revision.
          '_gauss_revision': revision.revision,
        });
      }
      final logicalPath = 'assets/${_safeLogicalPath(relativePath)}';
      fileHashes[logicalPath] = await _writeJson(staging, logicalPath, rows);
    }
    if (usedIds.length != release.questionCount ||
        usedIds.length != byId.length) {
      throw const FormatException('Remote topic membership is incomplete.');
    }
    fileHashes['assets/curriculum/certified_question_runtime_v1.json'] =
        await _writeJson(
          staging,
          'assets/curriculum/certified_question_runtime_v1.json',
          artifacts['certification_runtime']!.payload,
        );
    fileHashes['assets/curriculum/five_question_plan_v1.json'] =
        await _writeJson(
          staging,
          'assets/curriculum/five_question_plan_v1.json',
          artifacts['five_question_plan']!.payload,
        );
    return fileHashes;
  }

  Future<String> _writeJson(
    Directory root,
    String logicalPath,
    Object value,
  ) async {
    final safePath = _safeLogicalPath(logicalPath);
    final file = File(_joinAll([root.path, ...safePath.split('/')]));
    await file.parent.create(recursive: true);
    final bytes = utf8.encode(jsonEncode(value));
    await file.writeAsBytes(bytes, flush: true);
    return sha256.convert(bytes).toString();
  }

  Future<void> _verifyReleaseDirectory(
    Directory directory, {
    required String releaseId,
    required String corpusSha256,
    required String manifestSha256,
  }) async {
    if (!await directory.exists()) {
      throw const FileSystemException('Content release directory is missing.');
    }
    final manifestFile = File(_join(directory.path, 'release.json'));
    final manifestBytes = await manifestFile.readAsBytes();
    if (sha256.convert(manifestBytes).toString() != manifestSha256) {
      throw const FormatException('Local content manifest hash failed.');
    }
    final raw = jsonDecode(utf8.decode(manifestBytes));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Local content manifest is malformed.');
    }
    if (raw['schema_version'] != 1 ||
        raw['release_id'] != releaseId ||
        raw['corpus_sha256'] != corpusSha256) {
      throw const FormatException('Local content manifest identity drifted.');
    }
    final fileHashes = _requiredMap(raw, 'file_hashes');
    if (fileHashes.isEmpty) {
      throw const FormatException('Local content manifest has no files.');
    }
    for (final entry in fileHashes.entries) {
      final expected = entry.value;
      if (expected is! String || !RegExp(_sha256Pattern).hasMatch(expected)) {
        throw const FormatException('Local content file hash is malformed.');
      }
      final file = File(
        _joinAll([directory.path, ..._safeLogicalPath(entry.key).split('/')]),
      );
      final bytes = await file.readAsBytes();
      if (sha256.convert(bytes).toString() != expected) {
        throw FormatException('${entry.key} failed its local content hash.');
      }
    }
  }

  Future<void> _activatePointer(
    Directory root, {
    required String releaseId,
    required String corpusSha256,
    required String manifestSha256,
  }) async {
    final active = File(_join(root.path, 'active.json'));
    final previous = File(_join(root.path, 'active.previous.json'));
    final next = File(_join(root.path, 'active.next.json'));
    await next.writeAsString(
      canonicalContentJson(<String, dynamic>{
        'schema_version': 1,
        'release_id': releaseId,
        'corpus_sha256': corpusSha256,
        'manifest_sha256': manifestSha256,
      }),
      flush: true,
    );
    if (await previous.exists()) await previous.delete();
    if (await active.exists()) await active.rename(previous.path);
    await next.rename(active.path);
    if (await previous.exists()) await previous.delete();
  }

  void _validateReleaseHeader(GaussRemoteRelease release) {
    _safeReleaseId(release.id);
    if (release.schemaVersion != 1 ||
        !RegExp(_sha256Pattern).hasMatch(release.corpusSha256) ||
        release.questionCount < 1 ||
        release.topicCount < 1 ||
        release.minimumAppBuild < 1) {
      throw const FormatException('Remote release header is invalid.');
    }
  }

  void _validateRevisions(
    GaussRemoteRelease release,
    List<GaussRemoteQuestionRevision> revisions,
  ) {
    if (revisions.length != release.questionCount) {
      throw const FormatException('Remote release question count drifted.');
    }
    final ids = <String>{};
    for (var index = 0; index < revisions.length; index++) {
      final row = revisions[index];
      final payload = row.payload;
      if (row.ordinal != index ||
          row.revision < 1 ||
          !RegExp(_questionIdPattern).hasMatch(row.questionId) ||
          !ids.add(row.questionId) ||
          (row.subject != 'math' && row.subject != 'physics') ||
          payload['id'] != row.questionId ||
          payload['subject'] != row.subject ||
          payload['topic_key'] != row.topicKey ||
          payload['difficulty'] != row.difficulty ||
          payload['source_bank'] != 'nardebam' ||
          canonicalContentSha256(payload) != row.contentSha256) {
        throw FormatException('${row.questionId} failed release binding.');
      }
      final options = payload['options'];
      if (payload['stem'] is! List<dynamic> ||
          (payload['stem'] as List<dynamic>).isEmpty ||
          options is! List<dynamic> ||
          options.length != 4 ||
          options.any((option) => option is! List || option.isEmpty) ||
          payload['solution'] is! List<dynamic> ||
          (payload['solution'] as List<dynamic>).isEmpty ||
          payload['correct_option_index'] is! int ||
          (payload['correct_option_index'] as int) < 1 ||
          (payload['correct_option_index'] as int) > 4) {
        throw FormatException('${row.questionId} is structurally unusable.');
      }
    }
  }
}

String computeContentCorpusSha256({
  required Map<String, String> artifactHashes,
  required List<GaussRemoteQuestionRevision> revisions,
}) {
  final lines = <String>['gauss-content-v1'];
  final kinds = artifactHashes.keys.toList()..sort();
  for (final kind in kinds) {
    lines.add('artifact:$kind:${artifactHashes[kind]}');
  }
  for (final row in revisions) {
    lines.add(
      'question:${row.ordinal}:${row.questionId}:${row.revision}:${row.contentSha256}',
    );
  }
  return sha256.convert(utf8.encode(lines.join('\n'))).toString();
}

String canonicalContentSha256(Object? value) =>
    sha256.convert(utf8.encode(canonicalContentJson(value))).toString();

String canonicalContentJson(Object? value) {
  if (value is List<dynamic>) {
    return '[${value.map(canonicalContentJson).join(',')}]';
  }
  if (value is Map) {
    final keys = value.keys.map((key) => key as String).toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${canonicalContentJson(value[key])}').join(',')}}';
  }
  if (value is num) {
    if (!value.isFinite) throw const FormatException('Non-finite JSON number.');
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
  }
  return jsonEncode(value);
}

final class _DirectoryAssetBundle extends CachingAssetBundle {
  _DirectoryAssetBundle(this._root, this._fallback);

  final Directory _root;
  final AssetBundle _fallback;

  @override
  Future<ByteData> load(String key) async {
    try {
      final logicalPath = _safeLogicalPath(key);
      final file = File(_joinAll([_root.path, ...logicalPath.split('/')]));
      if (await file.exists()) {
        return ByteData.sublistView(await file.readAsBytes());
      }
    } on FormatException {
      // Invalid dynamic paths never touch the filesystem; let the immutable
      // Flutter bundle decide whether a legitimate key exists.
    }
    return _fallback.load(key);
  }
}

String _safeReleaseId(String value) {
  if (!RegExp(_releaseIdPattern).hasMatch(value)) {
    throw const FormatException('Unsafe content release id.');
  }
  return value;
}

String _safeLogicalPath(String value) {
  final normalized = value.replaceAll('\\', '/');
  final segments = normalized.split('/');
  if (normalized.isEmpty ||
      normalized.startsWith('/') ||
      segments.any((part) => part.isEmpty || part == '.' || part == '..') ||
      segments.any((part) => part.contains(':'))) {
    throw const FormatException('Unsafe content asset path.');
  }
  return normalized;
}

String _join(String first, [String? second, String? third, String? fourth]) {
  final parts = <String>[first, ?second, ?third, ?fourth];
  return parts.join(Platform.pathSeparator);
}

String _joinAll(Iterable<String> parts) => parts.join(Platform.pathSeparator);

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing content field: $key.');
  }
  return value;
}

String _requiredHash(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  if (!RegExp(_sha256Pattern).hasMatch(value)) {
    throw FormatException('Invalid content hash: $key.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Invalid content integer: $key.');
  return value;
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('Invalid content object: $key.');
  return Map<String, dynamic>.from(value);
}
