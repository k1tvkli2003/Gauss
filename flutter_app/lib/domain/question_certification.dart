import 'dart:convert';

import 'package:crypto/crypto.dart';

const _sha256Pattern = r'^[a-f0-9]{64}$';
const _allowedPatchFields = <String>{
  'stem',
  'options',
  'solution',
  'smart_shortcut',
};

/// Build-generated, fail-closed admission contract for verified source items.
///
/// The immutable source row remains the authority. A certification can only
/// make it mission-ready when its hash binds the exact bundled row. Future
/// source-faithful repairs are carried as a narrow derived patch and receive a
/// second hash after application; the source JSON itself is never rewritten.
final class QuestionCertification {
  QuestionCertification._({
    required this.questionId,
    required this.subjectKey,
    required this.topicKey,
    required this.sectionId,
    required this.subtopicKey,
    required this.conceptTags,
    required this.prerequisites,
    required this.reviewedDifficultyKey,
    required this.sourceSha256,
    required this.runtimeRecordSha256,
    required this.effectiveRecordSha256,
    required this.sourceOptionIndex,
    required this.effectiveOptionIndex,
    required this.solutionVerified,
    required this.renderReceiptId,
    required this.sourceFidelityReceiptId,
    required this.contentPatch,
  });

  final String questionId;
  final String subjectKey;
  final String topicKey;
  final String sectionId;
  final String subtopicKey;
  final List<String> conceptTags;
  final List<String> prerequisites;
  final String reviewedDifficultyKey;
  final String sourceSha256;
  final String runtimeRecordSha256;
  final String effectiveRecordSha256;
  final int sourceOptionIndex;
  final int effectiveOptionIndex;
  final bool solutionVerified;
  final String renderReceiptId;
  final String sourceFidelityReceiptId;
  final Map<String, dynamic>? contentPatch;

  factory QuestionCertification.fromJson(Map<String, dynamic> json) {
    final questionId = _requiredString(json, 'question_id');
    final sourceOptionIndex = json['source_option_index'];
    final effectiveOptionIndex = json['effective_option_index'];
    if (sourceOptionIndex is! int ||
        sourceOptionIndex < 1 ||
        sourceOptionIndex > 4) {
      throw FormatException('$questionId has an invalid source option index.');
    }
    if (effectiveOptionIndex is! int ||
        effectiveOptionIndex < 1 ||
        effectiveOptionIndex > 4) {
      throw FormatException(
        '$questionId has an invalid effective option index.',
      );
    }
    final runtimeHash = _requiredHash(json, 'runtime_record_sha256');
    final effectiveHash = _requiredHash(json, 'effective_record_sha256');
    final rawPatch = json['content_patch'];
    Map<String, dynamic>? patch;
    if (rawPatch != null) {
      if (rawPatch is! Map<String, dynamic>) {
        throw FormatException('$questionId has a malformed content patch.');
      }
      final forbidden = rawPatch.keys
          .where((key) => !_allowedPatchFields.contains(key))
          .toList(growable: false);
      if (forbidden.isNotEmpty || rawPatch.isEmpty) {
        throw FormatException(
          '$questionId has forbidden or empty content-patch fields.',
        );
      }
      patch = Map<String, dynamic>.unmodifiable(rawPatch);
    } else if (runtimeHash != effectiveHash) {
      throw FormatException(
        '$questionId changes its effective hash without a content patch.',
      );
    }
    if (json['solution_verified'] != true) {
      throw FormatException(
        '$questionId is admitted without a verified solution.',
      );
    }
    return QuestionCertification._(
      questionId: questionId,
      subjectKey: _requiredString(json, 'subject'),
      topicKey: _requiredString(json, 'topic_key'),
      sectionId: _requiredString(json, 'section_id'),
      subtopicKey: _requiredString(json, 'subtopic_key'),
      conceptTags: _stringList(json, 'concept_tags'),
      prerequisites: _stringList(json, 'prerequisites'),
      reviewedDifficultyKey: _requiredString(json, 'reviewed_difficulty'),
      sourceSha256: _requiredHash(json, 'source_sha256'),
      runtimeRecordSha256: runtimeHash,
      effectiveRecordSha256: effectiveHash,
      sourceOptionIndex: sourceOptionIndex,
      effectiveOptionIndex: effectiveOptionIndex,
      solutionVerified: true,
      renderReceiptId: _requiredString(json, 'render_receipt_id'),
      sourceFidelityReceiptId: _requiredString(
        json,
        'source_fidelity_receipt_id',
      ),
      contentPatch: patch,
    );
  }

  /// Returns a detached effective row after both pre- and post-patch bindings
  /// pass. Any stale source row or stale repair therefore remains quarantined.
  Map<String, dynamic> bindAndApply(Map<String, dynamic> sourceRow) {
    if (sourceRow['id'] != questionId ||
        sourceRow['subject'] != subjectKey ||
        sourceRow['topic_key'] != topicKey ||
        sourceRow['correct_option_index'] != sourceOptionIndex) {
      throw FormatException('$questionId certification identity drift.');
    }
    if (canonicalJsonSha256(sourceRow) != runtimeRecordSha256) {
      throw FormatException(
        '$questionId source hash does not match certification.',
      );
    }
    final effectiveRow = Map<String, dynamic>.of(sourceRow);
    if (contentPatch case final patch?) {
      effectiveRow.addAll(patch);
    }
    if (canonicalJsonSha256(effectiveRow) != effectiveRecordSha256) {
      throw FormatException(
        '$questionId effective content hash does not match.',
      );
    }
    return effectiveRow;
  }
}

final class CertifiedQuestionRuntime {
  CertifiedQuestionRuntime._({
    required this.sourceQuestionCount,
    required this.missionReadyCount,
    required this.sourceSetSha256,
    required this.manifestFileSha256,
    required this.contractSha256,
    required this.topicMissionReadyCounts,
    required this.questionsById,
  });

  final int sourceQuestionCount;
  final int missionReadyCount;
  final String sourceSetSha256;
  final String manifestFileSha256;
  final String contractSha256;
  final Map<String, int> topicMissionReadyCounts;
  final Map<String, QuestionCertification> questionsById;

  factory CertifiedQuestionRuntime.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 1) {
      throw const FormatException('Unsupported certified runtime schema.');
    }
    final declaredContractHash = _requiredHash(json, 'contract_sha256');
    final payload = Map<String, dynamic>.of(json)..remove('contract_sha256');
    if (canonicalJsonSha256(payload) != declaredContractHash) {
      throw const FormatException('Certified runtime contract hash mismatch.');
    }
    final sourceQuestionCount = json['source_question_count'];
    final missionReadyCount = json['mission_ready_count'];
    if (sourceQuestionCount is! int || sourceQuestionCount < 1) {
      throw const FormatException('Invalid certified source question count.');
    }
    if (missionReadyCount is! int || missionReadyCount < 0) {
      throw const FormatException('Invalid mission-ready count.');
    }
    final rawTopicCounts = json['topic_mission_ready_counts'];
    if (rawTopicCounts is! Map<String, dynamic>) {
      throw const FormatException('Certified runtime has no topic counts.');
    }
    final topicCounts = <String, int>{};
    for (final entry in rawTopicCounts.entries) {
      if (entry.value is! int || (entry.value as int) < 0) {
        throw FormatException('${entry.key} has an invalid certified count.');
      }
      topicCounts[entry.key] = entry.value as int;
    }
    final rawQuestions = json['questions'];
    if (rawQuestions is! List<dynamic>) {
      throw const FormatException('Certified runtime has no question list.');
    }
    final byId = <String, QuestionCertification>{};
    for (final raw in rawQuestions) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Malformed certified question entry.');
      }
      final certification = QuestionCertification.fromJson(raw);
      if (byId.putIfAbsent(certification.questionId, () => certification) !=
          certification) {
        throw FormatException(
          'Duplicate certified question ${certification.questionId}.',
        );
      }
    }
    final topicTotal = topicCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (byId.length != missionReadyCount || topicTotal != missionReadyCount) {
      throw const FormatException(
        'Certified runtime count reconciliation failed.',
      );
    }
    final actualTopicCounts = <String, int>{};
    for (final certification in byId.values) {
      actualTopicCounts.update(
        certification.topicKey,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    for (final entry in topicCounts.entries) {
      if ((actualTopicCounts[entry.key] ?? 0) != entry.value) {
        throw FormatException(
          '${entry.key} certified entries do not match its count.',
        );
      }
    }
    if (actualTopicCounts.keys.any((key) => !topicCounts.containsKey(key))) {
      throw const FormatException(
        'Certified question references an unknown topic.',
      );
    }
    return CertifiedQuestionRuntime._(
      sourceQuestionCount: sourceQuestionCount,
      missionReadyCount: missionReadyCount,
      sourceSetSha256: _requiredHash(json, 'source_set_sha256'),
      manifestFileSha256: _requiredHash(json, 'manifest_file_sha256'),
      contractSha256: declaredContractHash,
      topicMissionReadyCounts: Map.unmodifiable(topicCounts),
      questionsById: Map.unmodifiable(byId),
    );
  }
}

String canonicalJsonSha256(Object? value) =>
    sha256.convert(utf8.encode(_canonicalJson(value))).toString();

String _canonicalJson(Object? value) {
  if (value is List<dynamic>) {
    return '[${value.map(_canonicalJson).join(',')}]';
  }
  if (value is Map) {
    final keys = value.keys.map((key) => key as String).toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
  }
  if (value is num) {
    if (!value.isFinite) throw const FormatException('Non-finite JSON number.');
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
  }
  return jsonEncode(value);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or empty $key.');
  }
  return value;
}

String _requiredHash(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key);
  if (!RegExp(_sha256Pattern).hasMatch(value)) {
    throw FormatException('$key is not a SHA-256 digest.');
  }
  return value;
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List<dynamic> || value.any((item) => item is! String)) {
    throw FormatException('$key is not a string list.');
  }
  return List<String>.unmodifiable(value.cast<String>());
}
