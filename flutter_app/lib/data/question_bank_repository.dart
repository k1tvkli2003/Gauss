import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../domain/models.dart';

const _expectedQuestionCount = 3672;
const _expectedTopicShardCount = 29;
const _expectedMissionReadyQuestionCount = 0;
const _requiredSourceBank = 'nardebam';

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

  Future<void> initialize() async {
    final raw = await _bundle.loadString('assets/question_bank/index.json');
    final root = jsonDecode(raw) as Map<String, dynamic>;
    declaredTotal = root['total'] as int;
    topics = (root['topics'] as List<dynamic>)
        .map((item) {
          final json = item as Map<String, dynamic>;
          return TopicDescriptor.fromJson(
            json,
            missionReadyCount: _expectedMissionReadyQuestionCount,
          );
        })
        .toList(growable: false);
    final indexedTotal = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.questionCount,
    );
    if (declaredTotal != _expectedQuestionCount ||
        indexedTotal != declaredTotal) {
      throw DatasetIntegrityException(
        'Expected $_expectedQuestionCount preserved source questions; index declares $declaredTotal and shards total $indexedTotal.',
      );
    }
    if (topics.length != _expectedTopicShardCount) {
      throw DatasetIntegrityException(
        'Expected $_expectedTopicShardCount topic shards; found ${topics.length}.',
      );
    }
    final missionReadyTotal = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.missionReadyCount,
    );
    if (missionReadyTotal != _expectedMissionReadyQuestionCount) {
      throw DatasetIntegrityException(
        'Expected $_expectedMissionReadyQuestionCount scored questions; contract declares $missionReadyTotal.',
      );
    }
  }

  TopicDescriptor topicByKey(String key) =>
      topics.firstWhere((topic) => topic.key == key);

  Future<List<Question>> loadTopic(String key) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    final topic = topicByKey(key);
    final raw = await _bundle.loadString(topic.assetPath);
    final questions = (jsonDecode(raw) as List<dynamic>)
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
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
    if (questions.any((question) => question.missionReady)) {
      throw DatasetIntegrityException(
        '${topic.key} contains a scored question in the preserved source archive.',
      );
    }
    _cache[key] = questions;
    return questions;
  }

  Future<List<Question>> createMission(
    String topicKey, {
    int count = 10,
    int? seed,
    Set<Difficulty> difficulties = const {},
    Set<String> sourceBanks = const {},
  }) async {
    final questions = List<Question>.of(
      (await loadTopic(topicKey)).where(
        (question) =>
            question.missionReady &&
            (difficulties.isEmpty ||
                difficulties.contains(question.difficulty)) &&
            (sourceBanks.isEmpty || sourceBanks.contains(question.sourceBank)),
      ),
    );
    questions.shuffle(Random(seed ?? DateTime.now().microsecondsSinceEpoch));
    return questions.take(min(count, questions.length)).toList(growable: false);
  }

  /// The preserved, quarantined half of a chapter: source items whose
  /// answer/solution mapping is unverified. Read-only surfaces may present
  /// them with explicit provenance labels; they never enter scored missions.
  Future<List<Question>> archiveQuestions(String topicKey) async =>
      (await loadTopic(
        topicKey,
      )).where((question) => !question.missionReady).toList(growable: false);

  Future<List<Question>> questionsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final wanted = ids.toSet();
    final found = <String, Question>{};
    for (final topic in topics) {
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
      }
    }
    if (total != declaredTotal || ids.length != declaredTotal) {
      throw DatasetIntegrityException(
        'Loaded $total rows and ${ids.length} unique ids; expected $declaredTotal.',
      );
    }
    if (missionReadyTotal != _expectedMissionReadyQuestionCount) {
      throw DatasetIntegrityException(
        'Expected $_expectedMissionReadyQuestionCount scored questions; found $missionReadyTotal.',
      );
    }
  }
}
