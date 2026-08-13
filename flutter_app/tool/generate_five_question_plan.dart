import 'dart:convert';
import 'dart:io';

const _batchSize = 5;
const _planVersion = 'screened-taxonomy-five-question-v1';

Future<void> main(List<String> arguments) async {
  final root = Directory.current.path.endsWith('flutter_app')
      ? Directory.current.parent
      : Directory.current;
  final flutterRoot = Directory('${root.path}/flutter_app');
  final indexFile = File('${flutterRoot.path}/assets/question_bank/index.json');
  final manifestFile = File(
    '${root.path}/data/certification/v1/manifest.jsonl',
  );
  final outputFile = File(
    '${flutterRoot.path}/assets/curriculum/five_question_plan_v1.json',
  );

  final index =
      jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
  final topicIndex = <String, Map<String, dynamic>>{
    for (final raw in index['topics'] as List<dynamic>)
      (raw as Map<String, dynamic>)['topic_key'] as String: raw,
  };
  final recordsByTopic = <String, List<_PlanningRecord>>{};
  await for (final line
      in manifestFile
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    final row = jsonDecode(line) as Map<String, dynamic>;
    final taxonomy = row['taxonomy'] as Map<String, dynamic>;
    final difficulty = row['difficulty'] as Map<String, dynamic>;
    if (taxonomy['status'] != 'screened' ||
        difficulty['status'] != 'screened') {
      throw StateError(
        'Question ${row['question_id']} has no screened planning metadata.',
      );
    }
    final topicKey = taxonomy['topic_key'] as String;
    if (!topicIndex.containsKey(topicKey)) {
      throw StateError('Manifest references unknown topic $topicKey.');
    }
    final proposedSubtopic =
        taxonomy['proposed_subtopic'] as Map<String, dynamic>?;
    final primaryConcepts = _strings(taxonomy['proposed_concept_tags']);
    final secondaryConcepts = _strings(taxonomy['proposed_secondary_concepts']);
    final concepts = {...primaryConcepts, ...secondaryConcepts}.toList()
      ..sort();
    final prerequisites = _strings(taxonomy['proposed_prerequisites'])..sort();
    final subtopic = (proposedSubtopic?['key'] as String?)?.trim();
    final record = _PlanningRecord(
      questionId: row['question_id'] as String,
      topicKey: topicKey,
      subtopicKey: subtopic?.isNotEmpty == true
          ? subtopic!
          : concepts.isNotEmpty
          ? concepts.first
          : topicKey,
      concepts: concepts,
      prerequisites: prerequisites,
      difficulty: difficulty['screened'] as String,
    );
    recordsByTopic.putIfAbsent(topicKey, () => []).add(record);
  }

  final topics = <Map<String, dynamic>>[];
  final allPrimaryIds = <String>{};
  var totalSlots = 0;
  var reviewSlots = 0;
  for (final topicEntry in index['topics'] as List<dynamic>) {
    final topic = topicEntry as Map<String, dynamic>;
    final topicKey = topic['topic_key'] as String;
    final expectedCount = topic['count'] as int;
    final records = recordsByTopic[topicKey] ?? const <_PlanningRecord>[];
    if (records.length != expectedCount) {
      throw StateError(
        '$topicKey has ${records.length} screened records; expected $expectedCount.',
      );
    }
    final sourceIds = await _sourceIds(flutterRoot, topic);
    final plannedIds = records.map((record) => record.questionId).toSet();
    if (sourceIds.length != expectedCount ||
        !sourceIds.containsAll(plannedIds) ||
        !plannedIds.containsAll(sourceIds)) {
      throw StateError('$topicKey plan does not match its immutable shard.');
    }

    final ordered = _conceptualOrder(records);
    final sessions = <Map<String, dynamic>>[];
    final primarySessionByQuestion = <String, String>{};
    for (var start = 0; start < ordered.length; start += _batchSize) {
      final sessionIndex = start ~/ _batchSize;
      final key = '$topicKey:${sessionIndex * _batchSize}:$_batchSize';
      final primary = ordered.skip(start).take(_batchSize).toList();
      final slots = <Map<String, dynamic>>[];
      for (final record in primary) {
        if (!allPrimaryIds.add(record.questionId)) {
          throw StateError('Duplicate source question ${record.questionId}.');
        }
        primarySessionByQuestion[record.questionId] = key;
        slots.add(
          _slotJson(
            record,
            id: '$key#${slots.length}',
            kind: 'primary',
            primarySessionKey: key,
          ),
        );
      }
      if (slots.length < _batchSize) {
        final candidates = ordered.take(start).toList();
        final reviews = _selectMasteryReviews(
          candidates,
          primary,
          count: _batchSize - slots.length,
        );
        for (final record in reviews) {
          slots.add(
            _slotJson(
              record,
              id: '$key#${slots.length}',
              kind: 'mastery_review',
              primarySessionKey: primarySessionByQuestion[record.questionId]!,
            ),
          );
          reviewSlots += 1;
        }
      }
      if (slots.length != _batchSize) {
        throw StateError('$key does not contain exactly $_batchSize slots.');
      }
      sessions.add({
        'key': key,
        'topic_key': topicKey,
        'index': sessionIndex,
        'slots': slots,
      });
      totalSlots += slots.length;
    }
    topics.add({
      'topic_key': topicKey,
      'source_question_count': expectedCount,
      'sessions': sessions,
    });
  }

  final declaredCount = index['total'] as int;
  if (allPrimaryIds.length != declaredCount) {
    throw StateError(
      'Plan covers ${allPrimaryIds.length} source questions; expected $declaredCount.',
    );
  }
  final output = <String, dynamic>{
    'schema_version': 1,
    'plan_version': _planVersion,
    'source_question_count': declaredCount,
    'slot_count': totalSlots,
    'mastery_review_slot_count': reviewSlots,
    'derivation': {
      'source': 'data/certification/v1/manifest.jsonl',
      'grouping': [
        'screened_subtopic',
        'screened_concepts',
        'screened_prerequisites',
        'screened_difficulty',
      ],
      'remainder_policy': 'explicit_mastery_review',
    },
    'topics': topics,
  };
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(jsonEncode(output));
  stdout.writeln(
    'Wrote ${outputFile.path}: $declaredCount primary questions, '
    '$reviewSlots mastery-review slots, $totalSlots total slots.',
  );
}

List<String> _strings(dynamic value) => value is List<dynamic>
    ? value.whereType<String>().where((item) => item.isNotEmpty).toList()
    : <String>[];

Future<Set<String>> _sourceIds(
  Directory flutterRoot,
  Map<String, dynamic> topic,
) async {
  final file = File('${flutterRoot.path}/assets/${topic['file']}');
  final rows = jsonDecode(await file.readAsString()) as List<dynamic>;
  return rows
      .map((row) => (row as Map<String, dynamic>)['id'] as String)
      .toSet();
}

List<_PlanningRecord> _conceptualOrder(List<_PlanningRecord> records) {
  final clusters = <String, List<_PlanningRecord>>{};
  for (final record in records) {
    clusters.putIfAbsent(record.subtopicKey, () => []).add(record);
  }
  final orderedClusters = clusters.entries.toList()
    ..sort((left, right) {
      final leftDifficulty = left.value
          .map((record) => record.difficultyRank)
          .reduce((a, b) => a < b ? a : b);
      final rightDifficulty = right.value
          .map((record) => record.difficultyRank)
          .reduce((a, b) => a < b ? a : b);
      final difficulty = leftDifficulty.compareTo(rightDifficulty);
      if (difficulty != 0) return difficulty;
      final leftPrerequisites = left.value
          .map((record) => record.prerequisites.length)
          .reduce((a, b) => a < b ? a : b);
      final rightPrerequisites = right.value
          .map((record) => record.prerequisites.length)
          .reduce((a, b) => a < b ? a : b);
      final prerequisite = leftPrerequisites.compareTo(rightPrerequisites);
      if (prerequisite != 0) return prerequisite;
      return left.key.compareTo(right.key);
    });
  return [
    for (final cluster in orderedClusters)
      ...(cluster.value..sort(_withinClusterCompare)),
  ];
}

int _withinClusterCompare(_PlanningRecord left, _PlanningRecord right) {
  final prerequisites = left.prerequisites.length.compareTo(
    right.prerequisites.length,
  );
  if (prerequisites != 0) return prerequisites;
  final prerequisiteSignature = left.prerequisites
      .join('|')
      .compareTo(right.prerequisites.join('|'));
  if (prerequisiteSignature != 0) return prerequisiteSignature;
  final difficulty = left.difficultyRank.compareTo(right.difficultyRank);
  if (difficulty != 0) return difficulty;
  final concepts = left.concepts.join('|').compareTo(right.concepts.join('|'));
  if (concepts != 0) return concepts;
  return left.questionId.compareTo(right.questionId);
}

List<_PlanningRecord> _selectMasteryReviews(
  List<_PlanningRecord> candidates,
  List<_PlanningRecord> remainder, {
  required int count,
}) {
  if (candidates.length < count || remainder.isEmpty) {
    throw StateError('A remainder cannot be filled with distinct reviews.');
  }
  final ranked = candidates.toList()
    ..sort((left, right) {
      final score = _reviewScore(
        right,
        remainder,
      ).compareTo(_reviewScore(left, remainder));
      if (score != 0) return score;
      final difficulty = left.difficultyRank.compareTo(right.difficultyRank);
      if (difficulty != 0) return difficulty;
      return left.questionId.compareTo(right.questionId);
    });
  return ranked.take(count).toList(growable: false);
}

int _reviewScore(_PlanningRecord candidate, List<_PlanningRecord> targets) {
  var best = -100000;
  for (final target in targets) {
    final sharedConcepts = candidate.concepts.toSet().intersection(
      target.concepts.toSet(),
    );
    final sharedPrerequisites = candidate.prerequisites.toSet().intersection(
      target.prerequisites.toSet(),
    );
    final reinforcesPrerequisite = candidate.concepts.toSet().intersection(
      target.prerequisites.toSet(),
    );
    final score =
        (candidate.subtopicKey == target.subtopicKey ? 100 : 0) +
        sharedConcepts.length * 20 +
        sharedPrerequisites.length * 10 +
        reinforcesPrerequisite.length * 8 -
        (candidate.difficultyRank - target.difficultyRank).abs() * 4;
    if (score > best) best = score;
  }
  return best;
}

Map<String, dynamic> _slotJson(
  _PlanningRecord record, {
  required String id,
  required String kind,
  required String primarySessionKey,
}) => {
  'id': id,
  'question_id': record.questionId,
  'kind': kind,
  'primary_session_key': primarySessionKey,
  'profile': {
    'subtopic_key': record.subtopicKey,
    'concepts': record.concepts,
    'prerequisites': record.prerequisites,
    'difficulty': record.difficulty,
  },
};

class _PlanningRecord {
  const _PlanningRecord({
    required this.questionId,
    required this.topicKey,
    required this.subtopicKey,
    required this.concepts,
    required this.prerequisites,
    required this.difficulty,
  });

  final String questionId;
  final String topicKey;
  final String subtopicKey;
  final List<String> concepts;
  final List<String> prerequisites;
  final String difficulty;

  int get difficultyRank => switch (difficulty) {
    'above_average' => 0,
    'hard' => 1,
    'very_hard' => 2,
    'olympiad' => 3,
    _ => throw StateError('Unsupported screened difficulty $difficulty.'),
  };
}
