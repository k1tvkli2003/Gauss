import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../domain/models.dart';

const _missionReadyCounts = <String, int>{
  'sets': 26,
  'patterns_sequences': 34,
  'quadratic_equations_functions': 34,
  'rational_inequalities_sign': 89,
  'radicals_algebraic_expressions': 60,
  'absolute_value_floor': 0,
  'functions': 231,
  'trigonometry': 240,
  'limits_continuity': 186,
  'derivatives': 101,
  'derivative_applications': 60,
  'exponential_logarithmic': 60,
  'analytic_geometry': 121,
  'visual_thinking_conics': 257,
  'combinatorics': 65,
  'probability': 159,
  'geometry': 60,
  'statistics': 152,
  'physics_measurement': 60,
  'physical_properties_matter': 122,
  'temperature_heat': 248,
  'work_energy_power': 66,
  'electrostatics': 127,
  'current_electricity': 128,
  'magnetism_induction': 251,
  'one_dimensional_motion': 186,
  'dynamics': 187,
  'oscillation_waves': 246,
  'atomic_nuclear': 125,
};

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
          final key = json['topic_key'] as String;
          final missionReadyCount = _missionReadyCounts[key];
          if (missionReadyCount == null) {
            throw DatasetIntegrityException(
              'Topic $key has no mission-readiness contract.',
            );
          }
          return TopicDescriptor.fromJson(
            json,
            missionReadyCount: missionReadyCount,
          );
        })
        .toList(growable: false);
    final indexedTotal = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.questionCount,
    );
    if (declaredTotal != 7353 || indexedTotal != declaredTotal) {
      throw DatasetIntegrityException(
        'Expected 7,353 questions; index declares $declaredTotal and shards total $indexedTotal.',
      );
    }
    if (topics.length != 29) {
      throw DatasetIntegrityException(
        'Expected 29 topic shards; found ${topics.length}.',
      );
    }
    final missionReadyTotal = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.missionReadyCount,
    );
    if (missionReadyTotal != 3681) {
      throw DatasetIntegrityException(
        'Expected 3,681 mission-ready questions; contract declares $missionReadyTotal.',
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
      }
    }
    if (total != declaredTotal || ids.length != declaredTotal) {
      throw DatasetIntegrityException(
        'Loaded $total rows and ${ids.length} unique ids; expected $declaredTotal.',
      );
    }
    if (missionReadyTotal != 3681) {
      throw DatasetIntegrityException(
        'Expected 3,681 mission-ready questions; found $missionReadyTotal.',
      );
    }
  }
}
