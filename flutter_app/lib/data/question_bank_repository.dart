import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/question_certification.dart';
import '../domain/study_curriculum.dart';

const _expectedQuestionCount = 3672;
const _expectedTopicShardCount = 29;
const _requiredSourceBank = 'nardebam';
const _certifiedRuntimeAsset =
    'assets/curriculum/certified_question_runtime_v1.json';

class DatasetIntegrityException implements Exception {
  const DatasetIntegrityException(this.message);
  final String message;

  @override
  String toString() => 'DatasetIntegrityException: $message';
}

class QuestionBankRepository {
  QuestionBankRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, List<Question>> _cache = {};
  late final List<TopicDescriptor> topics;
  late final int declaredTotal;
  late final int declaredMissionReadyTotal;
  late final CertifiedQuestionRuntime certificationRuntime;
  late final GaussStudyPlan studyPlan;
  Future<void>? _initializing;
  var _initialized = false;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Parse and validate into locals before publishing the late-final state.
      // A retry after a transient asset or validation failure must never try to
      // assign a partially initialized `late final` field a second time.
      final raw = await _bundle.loadString('assets/question_bank/index.json');
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final rawCertification = await _bundle.loadString(_certifiedRuntimeAsset);
      final parsedCertification = CertifiedQuestionRuntime.fromJson(
        jsonDecode(rawCertification) as Map<String, dynamic>,
      );
      final rawPlan = await _bundle.loadString(
        'assets/curriculum/five_question_plan_v1.json',
      );
      final parsedPlan = GaussStudyPlan.fromJson(
        jsonDecode(rawPlan) as Map<String, dynamic>,
      );
      final parsedTotal = root['total'] as int;
      final parsedTopics = (root['topics'] as List<dynamic>)
          .map((item) {
            final json = item as Map<String, dynamic>;
            return TopicDescriptor.fromJson(
              json,
              missionReadyCount:
                  parsedCertification.topicMissionReadyCounts[json['topic_key']
                      as String] ??
                  0,
            );
          })
          .toList(growable: false);
      final indexedTotal = parsedTopics.fold<int>(
        0,
        (sum, topic) => sum + topic.questionCount,
      );
      if (parsedTotal != _expectedQuestionCount ||
          indexedTotal != parsedTotal) {
        throw DatasetIntegrityException(
          'Expected $_expectedQuestionCount preserved source questions; index declares $parsedTotal and shards total $indexedTotal.',
        );
      }
      if (parsedTopics.length != _expectedTopicShardCount) {
        throw DatasetIntegrityException(
          'Expected $_expectedTopicShardCount topic shards; found ${parsedTopics.length}.',
        );
      }
      if (parsedCertification.sourceQuestionCount != parsedTotal) {
        throw DatasetIntegrityException(
          'Certification binds ${parsedCertification.sourceQuestionCount} source questions; expected $parsedTotal.',
        );
      }
      final topicKeys = parsedTopics.map((topic) => topic.key).toSet();
      if (parsedCertification.topicMissionReadyCounts.length !=
              parsedTopics.length ||
          !topicKeys.containsAll(
            parsedCertification.topicMissionReadyCounts.keys,
          )) {
        throw const DatasetIntegrityException(
          'Certification topic registry does not match the question index.',
        );
      }
      final missionReadyTotal = parsedTopics.fold<int>(
        0,
        (sum, topic) => sum + topic.missionReadyCount,
      );
      if (missionReadyTotal != parsedCertification.missionReadyCount) {
        throw DatasetIntegrityException(
          'Certification declares ${parsedCertification.missionReadyCount} scored questions; topic counts declare $missionReadyTotal.',
        );
      }
      if (parsedPlan.sourceQuestionCount != parsedTotal) {
        throw DatasetIntegrityException(
          'Five-question plan covers ${parsedPlan.sourceQuestionCount} source questions; expected $parsedTotal.',
        );
      }
      for (final topic in parsedTopics) {
        final topicPlan = parsedPlan.topic(topic.key);
        if (topicPlan.sourceQuestionCount != topic.questionCount) {
          throw DatasetIntegrityException(
            '${topic.key} plans ${topicPlan.sourceQuestionCount} source questions; expected ${topic.questionCount}.',
          );
        }
      }

      studyPlan = parsedPlan;
      declaredTotal = parsedTotal;
      declaredMissionReadyTotal = missionReadyTotal;
      certificationRuntime = parsedCertification;
      topics = parsedTopics;
      _initialized = true;
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  TopicDescriptor topicByKey(String key) =>
      topics.firstWhere((topic) => topic.key == key);

  /// Whether a shard has already been decoded into the in-memory cache.
  /// Exposed so tests can assert that lookups stay narrow.
  @visibleForTesting
  bool isTopicLoaded(String key) => _cache.containsKey(key);

  Future<List<Question>> loadTopic(String key) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    final topic = topicByKey(key);
    final raw = await _bundle.loadString(topic.assetPath);
    final questions = (jsonDecode(raw) as List<dynamic>)
        .map((item) {
          final sourceRow = item as Map<String, dynamic>;
          final id = sourceRow['id'] as String?;
          final certification = certificationRuntime.questionsById[id];
          try {
            final effectiveRow =
                certification?.bindAndApply(sourceRow) ?? sourceRow;
            return Question.fromJson(
              effectiveRow,
              certification: certification,
            );
          } on FormatException catch (error) {
            throw DatasetIntegrityException(
              '${id ?? 'unknown question'} certification binding failed: ${error.message}',
            );
          }
        })
        .toList(growable: false);
    if (questions.length != topic.questionCount) {
      throw DatasetIntegrityException(
        '${topic.key} declares ${topic.questionCount} questions but contains ${questions.length}.',
      );
    }
    if (questions.any((question) => question.topicKey != topic.key)) {
      throw DatasetIntegrityException(
        '${topic.key} contains a foreign topic key.',
      );
    }
    if (questions.any(
      (question) => question.sourceBank != _requiredSourceBank,
    )) {
      throw DatasetIntegrityException(
        '${topic.key} contains a question outside the preserved source archive.',
      );
    }
    final missionReadyCount = questions
        .where((question) => question.missionReady)
        .length;
    if (missionReadyCount != topic.missionReadyCount) {
      throw DatasetIntegrityException(
        '${topic.key} declares ${topic.missionReadyCount} mission-ready questions but binds $missionReadyCount.',
      );
    }
    final plannedIds = studyPlan
        .topic(key)
        .sessions
        .expand((session) => session.slots)
        .where((slot) => slot.kind == StudySlotKind.primary)
        .map((slot) => slot.questionId)
        .toSet();
    final sourceIds = questions.map((question) => question.id).toSet();
    if (plannedIds.length != questions.length ||
        !plannedIds.containsAll(sourceIds) ||
        !sourceIds.containsAll(plannedIds)) {
      throw DatasetIntegrityException(
        '$key five-question plan does not preserve its immutable source ids.',
      );
    }
    _cache[key] = questions;
    return questions;
  }

  StudySessionPlan studySession(String topicKey, int offset) =>
      studyPlan.session(topicKey, offset);

  StudySessionSlot primaryStudySlot(String questionId) =>
      studyPlan.primarySlot(questionId);

  /// True only when all five rows carry current hash-bound certifications.
  bool isStudySessionMissionReady(String topicKey, {required int offset}) {
    final session = studySession(topicKey, offset);
    return session.slots.length == GaussStudyCurriculum.batchSize &&
        session.slots.every(
          (slot) =>
              certificationRuntime.questionsById.containsKey(slot.questionId),
        );
  }

  /// Whether one authored Map node can open as a private five-question lesson.
  ///
  /// Scientific certification stays strict in [isStudySessionMissionReady],
  /// but no longer acts as a runtime access gate. Initialization already proves
  /// that the generated plan covers every source row exactly once as a primary
  /// slot and fills remainders with explicit mastery-review slots.
  bool isStudySessionPlayable(String topicKey, {required int offset}) {
    final session = studySession(topicKey, offset);
    return session.slots.length == GaussStudyCurriculum.batchSize;
  }

  Future<List<Question>> loadStudySession(
    String topicKey, {
    required int offset,
  }) async {
    final session = studySession(topicKey, offset);
    final byId = {
      for (final question in await loadTopic(topicKey)) question.id: question,
    };
    final questions = <Question>[];
    for (final slot in session.slots) {
      final question = byId[slot.questionId];
      if (question == null) {
        throw DatasetIntegrityException(
          '${session.key} references missing source question ${slot.questionId}.',
        );
      }
      questions.add(question);
    }
    return List.unmodifiable(questions);
  }

  /// Loads one exact authored Map node as a private scored mission.
  ///
  /// Membership and order come from the immutable five-question study plan;
  /// no rows are substituted, discarded, or hidden because certification is
  /// pending. The source answer key is used provisionally until a later repair
  /// produces stronger hash-bound evidence.
  Future<List<Question>> createStudySessionMission(
    String topicKey, {
    required int offset,
  }) async {
    final questions = await loadStudySession(topicKey, offset: offset);
    if (questions.length != GaussStudyCurriculum.batchSize ||
        questions.any((question) => !question.runtimeUsable)) {
      throw DatasetIntegrityException(
        '$topicKey:$offset is not a structurally usable five-question plan.',
      );
    }
    return questions;
  }

  Future<List<Question>> createMission(
    String topicKey, {
    int count = GaussStudyCurriculum.batchSize,
    int? seed,
    Set<Difficulty> difficulties = const {},
    Set<String> sourceBanks = const {},
  }) async {
    final questions = List<Question>.of(
      (await loadTopic(topicKey)).where(
        (question) =>
            question.runtimeUsable &&
            (difficulties.isEmpty ||
                difficulties.contains(question.difficulty)) &&
            (sourceBanks.isEmpty || sourceBanks.contains(question.sourceBank)),
      ),
    );
    questions.shuffle(Random(seed ?? DateTime.now().microsecondsSinceEpoch));
    return questions.take(min(count, questions.length)).toList(growable: false);
  }

  /// Source items without a scientific certification.
  ///
  /// Kept as an audit/study query for backwards-compatible shelves. These rows
  /// are still runtime-usable and may enter the owner's private missions.
  Future<List<Question>> archiveQuestions(String topicKey) async =>
      (await loadTopic(
        topicKey,
      )).where((question) => !question.missionReady).toList(growable: false);

  /// Resolves questions by id, preserving the order of [ids].
  ///
  /// [topicByQuestionId] lets a caller that already knows where its questions
  /// live (study records store the topic) open only those shards. Without
  /// hints this must scan the whole library, which costs one decode per
  /// shard — measurably slow for a single id in a late shard.
  Future<List<Question>> questionsByIds(
    List<String> ids, {
    Map<String, String>? topicByQuestionId,
  }) async {
    if (ids.isEmpty) return const [];
    final wanted = ids.toSet();
    final found = <String, Question>{};

    final hintedTopics = <String>{};
    if (topicByQuestionId != null) {
      for (final id in wanted) {
        final topicKey = topicByQuestionId[id];
        if (topicKey != null) hintedTopics.add(topicKey);
      }
      for (final topicKey in hintedTopics) {
        // A stale hint (a topic that no longer exists) simply yields nothing
        // and falls through to the full scan below.
        if (!topics.any((topic) => topic.key == topicKey)) continue;
        for (final question in await loadTopic(topicKey)) {
          if (wanted.contains(question.id)) found[question.id] = question;
        }
      }
      if (found.length == wanted.length) {
        return ids.map((id) => found[id]).whereType<Question>().toList();
      }
    }

    for (final topic in topics) {
      if (hintedTopics.contains(topic.key)) continue;
      for (final question in await loadTopic(topic.key)) {
        if (wanted.contains(question.id)) found[question.id] = question;
      }
      if (found.length == wanted.length) break;
    }
    return ids.map((id) => found[id]).whereType<Question>().toList();
  }

  Future<void> validateAllShards() async {
    final ids = <String>{};
    var total = 0;
    var missionReadyTotal = 0;
    for (final topic in topics) {
      final questions = await loadTopic(topic.key);
      total += questions.length;
      final missionReady = questions
          .where((question) => question.missionReady)
          .length;
      missionReadyTotal += missionReady;
      if (missionReady != topic.missionReadyCount) {
        throw DatasetIntegrityException(
          '${topic.key} declares ${topic.missionReadyCount} mission-ready questions but contains $missionReady.',
        );
      }
      for (final question in questions) {
        if (!ids.add(question.id)) {
          throw DatasetIntegrityException(
            'Duplicate question id ${question.id}.',
          );
        }
        if (question.options.length != 4 ||
            question.correctChoiceIndex < 0 ||
            question.correctChoiceIndex > 3) {
          throw DatasetIntegrityException(
            '${question.id} violates the four-choice answer contract.',
          );
        }
        if (question.sourceBank != _requiredSourceBank) {
          throw DatasetIntegrityException(
            '${question.id} is not a preserved source item.',
          );
        }
        if (!question.runtimeUsable) {
          throw DatasetIntegrityException(
            '${question.id} is not structurally usable at runtime.',
          );
        }
      }
    }
    if (total != declaredTotal || ids.length != declaredTotal) {
      throw DatasetIntegrityException(
        'Loaded $total rows and ${ids.length} unique ids; expected $declaredTotal.',
      );
    }
    if (missionReadyTotal != declaredMissionReadyTotal) {
      throw DatasetIntegrityException(
        'Expected $declaredMissionReadyTotal scored questions; found $missionReadyTotal.',
      );
    }
  }
}
