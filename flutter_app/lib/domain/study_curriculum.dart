import 'models.dart';

enum StudySlotKind {
  primary('primary'),
  masteryReview('mastery_review'),
  curated('curated');

  const StudySlotKind(this.key);
  final String key;

  static StudySlotKind fromKey(String value) =>
      StudySlotKind.values.firstWhere((item) => item.key == value);
}

/// Screened learning metadata used to keep sessions conceptually coherent.
///
/// These values are derived from the immutable certification manifest. They
/// describe ordering only and never promote a quarantined source answer into
/// scored content.
class StudyQuestionProfile {
  const StudyQuestionProfile({
    required this.subtopicKey,
    required this.concepts,
    required this.prerequisites,
    required this.difficulty,
  });

  final String subtopicKey;
  final List<String> concepts;
  final List<String> prerequisites;
  final Difficulty difficulty;

  factory StudyQuestionProfile.fromJson(Map<String, dynamic> json) =>
      StudyQuestionProfile(
        subtopicKey: json['subtopic_key'] as String,
        concepts: List<String>.unmodifiable(
          (json['concepts'] as List<dynamic>).cast<String>(),
        ),
        prerequisites: List<String>.unmodifiable(
          (json['prerequisites'] as List<dynamic>).cast<String>(),
        ),
        difficulty: Difficulty.fromKey(json['difficulty'] as String),
      );
}

/// One persisted encounter target inside a five-question micro-lesson.
class StudySessionSlot {
  const StudySessionSlot({
    required this.id,
    required this.sessionKey,
    required this.questionId,
    required this.kind,
    required this.profile,
    required this.primarySessionKey,
  });

  final String id;
  final String sessionKey;
  final String questionId;
  final StudySlotKind kind;
  final StudyQuestionProfile profile;

  /// Canonical home of the immutable source question. A mastery-review slot
  /// points back to an earlier primary slot rather than moving its reflection.
  final String primarySessionKey;

  bool get isPlanned => kind != StudySlotKind.curated;
  bool get isMasteryReview => kind == StudySlotKind.masteryReview;

  factory StudySessionSlot.fromJson(
    Map<String, dynamic> json, {
    required String sessionKey,
  }) => StudySessionSlot(
    id: json['id'] as String,
    sessionKey: sessionKey,
    questionId: json['question_id'] as String,
    kind: StudySlotKind.fromKey(json['kind'] as String),
    profile: StudyQuestionProfile.fromJson(
      json['profile'] as Map<String, dynamic>,
    ),
    primarySessionKey: (json['primary_session_key'] as String?) ?? sessionKey,
  );

  factory StudySessionSlot.curated({
    required String shelfKey,
    required String questionId,
    required int index,
  }) => StudySessionSlot(
    id: '$shelfKey:$index:$questionId',
    sessionKey: shelfKey,
    questionId: questionId,
    kind: StudySlotKind.curated,
    profile: const StudyQuestionProfile(
      subtopicKey: 'curated',
      concepts: [],
      prerequisites: [],
      difficulty: Difficulty.aboveAverage,
    ),
    primarySessionKey: shelfKey,
  );
}

class StudySessionPlan {
  const StudySessionPlan({
    required this.key,
    required this.topicKey,
    required this.index,
    required this.slots,
  });

  final String key;
  final String topicKey;
  final int index;
  final List<StudySessionSlot> slots;

  int get primaryCount =>
      slots.where((slot) => slot.kind == StudySlotKind.primary).length;
  bool get isMasteryMix =>
      slots.any((slot) => slot.kind == StudySlotKind.masteryReview);

  /// A short, deterministic description of what this five-question set
  /// actually practises. Map nodes use screened concept metadata instead of
  /// exposing implementation copy such as "Session 3 of 10".
  String get displayLabel => _studySetDisplayLabel(slots);

  factory StudySessionPlan.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String;
    return StudySessionPlan(
      key: key,
      topicKey: json['topic_key'] as String,
      index: json['index'] as int,
      slots: List<StudySessionSlot>.unmodifiable(
        (json['slots'] as List<dynamic>).map(
          (slot) => StudySessionSlot.fromJson(
            slot as Map<String, dynamic>,
            sessionKey: key,
          ),
        ),
      ),
    );
  }
}

const _studyLabelStopConcepts = <String>{
  'algebraic_manipulation',
  'circuit_analysis',
  'counterexample',
  'equation_solving',
  'mathematical_reasoning',
  'physics',
  'problem_solving',
  'quantitative_reasoning',
};

const _studyLabelCommonTokens = <String>{
  'equation',
  'equations',
  'function',
  'functions',
  'math',
  'physics',
  'set',
  'sets',
};

String _studySetDisplayLabel(List<StudySessionSlot> slots) {
  final counts = <String, int>{};
  final firstSeen = <String, int>{};
  var sequence = 0;
  for (final slot in slots) {
    for (final concept in slot.profile.concepts) {
      if (concept.isEmpty || _studyLabelStopConcepts.contains(concept)) {
        continue;
      }
      firstSeen.putIfAbsent(concept, () => sequence++);
      counts.update(concept, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final ranked = counts.keys.toList(growable: false)
    ..sort((left, right) {
      final byFrequency = counts[right]!.compareTo(counts[left]!);
      if (byFrequency != 0) return byFrequency;
      return firstSeen[left]!.compareTo(firstSeen[right]!);
    });
  if (ranked.isEmpty) {
    return _humanizeStudyTaxonomy(
      slots.isEmpty ? 'guided_practice' : slots.first.profile.subtopicKey,
    );
  }

  final first = ranked.first;
  final firstTokens = first
      .split('_')
      .where((token) => !_studyLabelCommonTokens.contains(token))
      .toSet();
  String? second;
  for (final candidate in ranked.skip(1)) {
    final candidateTokens = candidate
        .split('_')
        .where((token) => !_studyLabelCommonTokens.contains(token))
        .toSet();
    if (firstTokens.intersection(candidateTokens).length <= 1) {
      second = candidate;
      break;
    }
  }
  second ??= ranked.length > 1 ? ranked[1] : null;
  final firstLabel = _humanizeStudyTaxonomy(first);
  if (second == null) return firstLabel;
  return _joinStudyConceptLabels(firstLabel, _humanizeStudyTaxonomy(second));
}

String _humanizeStudyTaxonomy(String value) {
  const acronyms = <String, String>{
    'ac': 'AC',
    'dc': 'DC',
    'emf': 'EMF',
    'iv': 'IV',
    'kcl': 'KCL',
    'kvl': 'KVL',
    'led': 'LED',
    'rms': 'RMS',
  };
  const connectors = <String>{
    'and',
    'at',
    'by',
    'for',
    'from',
    'in',
    'of',
    'on',
    'to',
    'under',
    'via',
    'with',
  };
  final words = value.split('_').where((word) => word.isNotEmpty).toList();
  return [
    for (var index = 0; index < words.length; index++)
      if (acronyms.containsKey(words[index]))
        acronyms[words[index]]!
      else if (index > 0 && connectors.contains(words[index]))
        words[index]
      else
        '${words[index][0].toUpperCase()}${words[index].substring(1)}',
  ].join(' ');
}

String _joinStudyConceptLabels(String first, String second) {
  final firstWords = first.split(' ');
  final secondWords = second.split(' ');
  if (firstWords.first == secondWords.first &&
      firstWords.length > 1 &&
      secondWords.length > 1) {
    return '${firstWords.first} ${firstWords.skip(1).join(' ')} & '
        '${secondWords.skip(1).join(' ')}';
  }
  if (firstWords.last == secondWords.last &&
      firstWords.length > 1 &&
      secondWords.length > 1) {
    return '${firstWords.take(firstWords.length - 1).join(' ')} & '
        '${secondWords.take(secondWords.length - 1).join(' ')} '
        '${firstWords.last}';
  }
  return '$first & $second';
}

class StudyTopicPlan {
  const StudyTopicPlan({
    required this.topicKey,
    required this.sourceQuestionCount,
    required this.sessions,
  });

  final String topicKey;
  final int sourceQuestionCount;
  final List<StudySessionPlan> sessions;

  int get slotCount => sessions.length * GaussStudyCurriculum.batchSize;
}

/// Immutable, generated runtime view over the screened taxonomy manifest.
class GaussStudyPlan {
  GaussStudyPlan._({
    required this.version,
    required this.sourceQuestionCount,
    required Map<String, StudyTopicPlan> byTopic,
  }) : _byTopic = Map.unmodifiable(byTopic),
       _primarySlots = Map.unmodifiable({
         for (final topic in byTopic.values)
           for (final session in topic.sessions)
             for (final slot in session.slots)
               if (slot.kind == StudySlotKind.primary) slot.questionId: slot,
       });

  final String version;
  final int sourceQuestionCount;
  final Map<String, StudyTopicPlan> _byTopic;
  final Map<String, StudySessionSlot> _primarySlots;

  Iterable<StudyTopicPlan> get topics => _byTopic.values;

  StudyTopicPlan topic(String topicKey) {
    final plan = _byTopic[topicKey];
    if (plan == null) throw StateError('Study plan is missing $topicKey.');
    return plan;
  }

  StudySessionPlan session(String topicKey, int offset) {
    final topicPlan = topic(topicKey);
    if (offset < 0 || offset % GaussStudyCurriculum.batchSize != 0) {
      throw ArgumentError.value(
        offset,
        'offset',
        'must address a five-question session boundary',
      );
    }
    final index = offset ~/ GaussStudyCurriculum.batchSize;
    if (index >= topicPlan.sessions.length) {
      throw RangeError.index(index, topicPlan.sessions, 'sessionIndex');
    }
    return topicPlan.sessions[index];
  }

  StudySessionSlot primarySlot(String questionId) {
    final slot = maybePrimarySlot(questionId);
    if (slot == null) {
      throw StateError('Study plan is missing source question $questionId.');
    }
    return slot;
  }

  StudySessionSlot? maybePrimarySlot(String questionId) =>
      _primarySlots[questionId];

  factory GaussStudyPlan.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 1) {
      throw const FormatException('Unsupported five-question plan schema.');
    }
    final byTopic = <String, StudyTopicPlan>{};
    final slotIds = <String>{};
    final primaryIds = <String>{};
    for (final rawTopic in json['topics'] as List<dynamic>) {
      final topicJson = rawTopic as Map<String, dynamic>;
      final topicKey = topicJson['topic_key'] as String;
      final sessions = List<StudySessionPlan>.unmodifiable(
        (topicJson['sessions'] as List<dynamic>).map(
          (item) => StudySessionPlan.fromJson(item as Map<String, dynamic>),
        ),
      );
      for (var index = 0; index < sessions.length; index++) {
        final session = sessions[index];
        final expectedKey =
            '$topicKey:${index * GaussStudyCurriculum.batchSize}:${GaussStudyCurriculum.batchSize}';
        if (session.topicKey != topicKey ||
            session.index != index ||
            session.key != expectedKey ||
            session.slots.length != GaussStudyCurriculum.batchSize) {
          throw FormatException('Invalid five-question session $expectedKey.');
        }
        for (final slot in session.slots) {
          if (!slotIds.add(slot.id)) {
            throw FormatException('Duplicate study slot ${slot.id}.');
          }
          if (slot.kind == StudySlotKind.primary &&
              !primaryIds.add(slot.questionId)) {
            throw FormatException(
              'Duplicate primary question ${slot.questionId}.',
            );
          }
        }
      }
      final sourceCount = topicJson['source_question_count'] as int;
      final topicPrimaryCount = sessions.fold<int>(
        0,
        (total, session) => total + session.primaryCount,
      );
      if (topicPrimaryCount != sourceCount) {
        throw FormatException(
          '$topicKey plans $topicPrimaryCount primary questions, expected $sourceCount.',
        );
      }
      if (byTopic.containsKey(topicKey)) {
        throw FormatException('Duplicate study topic $topicKey.');
      }
      byTopic[topicKey] = StudyTopicPlan(
        topicKey: topicKey,
        sourceQuestionCount: sourceCount,
        sessions: sessions,
      );
    }
    final declaredCount = json['source_question_count'] as int;
    if (primaryIds.length != declaredCount) {
      throw FormatException(
        'Study plan covers ${primaryIds.length} primary questions, expected $declaredCount.',
      );
    }
    for (final topic in byTopic.values) {
      for (final session in topic.sessions) {
        for (final slot in session.slots) {
          if (!primaryIds.contains(slot.questionId)) {
            throw FormatException(
              'Review slot ${slot.id} has no primary source question.',
            );
          }
          if (slot.isMasteryReview &&
              !topic.sessions.any(
                (candidate) => candidate.key == slot.primarySessionKey,
              )) {
            throw FormatException(
              'Review slot ${slot.id} has no primary session.',
            );
          }
        }
      }
    }
    return GaussStudyPlan._(
      version: json['plan_version'] as String,
      sourceQuestionCount: declaredCount,
      byTopic: byTopic,
    );
  }
}

/// The product-authored navigation hierarchy over the immutable source bank.
///
/// It changes presentation only: source questions remain in their original
/// topic shards and are sliced into stable, non-overlapping study sets.
class StudySectionDefinition {
  const StudySectionDefinition({
    required this.id,
    required this.subject,
    required this.title,
    required this.subtitle,
    required this.topicKeys,
  });

  final String id;
  final Subject subject;
  final String title;
  final String subtitle;
  final List<String> topicKeys;
}

class StudyPathNode {
  const StudyPathNode({
    required this.key,
    required this.topic,
    required this.offset,
    required this.questionCount,
    required this.partIndex,
    required this.partCount,
  });

  final String key;
  final TopicDescriptor topic;
  final int offset;
  final int questionCount;
  final int partIndex;
  final int partCount;

  bool get beginsUnit => partIndex == 0;
  String get setLabel => 'Session ${partIndex + 1} of $partCount';
}

abstract final class GaussStudyCurriculum {
  static const batchSize = 5;

  static const sections = <StudySectionDefinition>[
    StudySectionDefinition(
      id: 'math_algebraic_foundations',
      subject: Subject.math,
      title: 'Algebraic foundations',
      subtitle: 'Sets, patterns, expressions, absolute value, and signs',
      topicKeys: [
        'sets',
        'patterns_sequences',
        'radicals_algebraic_expressions',
        'absolute_value_floor',
        'rational_inequalities_sign',
      ],
    ),
    StudySectionDefinition(
      id: 'math_functions_equations',
      subject: Subject.math,
      title: 'Functions and equations',
      subtitle: 'Quadratics, function behavior, exponentials, and logarithms',
      topicKeys: [
        'quadratic_equations_functions',
        'functions',
        'exponential_logarithmic',
      ],
    ),
    StudySectionDefinition(
      id: 'math_calculus',
      subject: Subject.math,
      title: 'Calculus',
      subtitle: 'Limits, derivatives, and the geometry of change',
      topicKeys: [
        'limits_continuity',
        'derivatives',
        'derivative_applications',
      ],
    ),
    StudySectionDefinition(
      id: 'math_geometry_trigonometry',
      subject: Subject.math,
      title: 'Geometry and trigonometry',
      subtitle: 'Angles, coordinates, conics, and geometric reasoning',
      topicKeys: [
        'trigonometry',
        'analytic_geometry',
        'visual_thinking_conics',
        'geometry',
      ],
    ),
    StudySectionDefinition(
      id: 'math_discrete_data',
      subject: Subject.math,
      title: 'Discrete mathematics and data',
      subtitle: 'Counting, uncertainty, and statistical evidence',
      topicKeys: ['combinatorics', 'probability', 'statistics'],
    ),
    StudySectionDefinition(
      id: 'physics_matter_measurement',
      subject: Subject.physics,
      title: 'Matter and measurement',
      subtitle: 'Measurement, material behavior, temperature, and heat',
      topicKeys: [
        'physics_measurement',
        'physical_properties_matter',
        'temperature_heat',
      ],
    ),
    StudySectionDefinition(
      id: 'physics_mechanics',
      subject: Subject.physics,
      title: 'Mechanics',
      subtitle: 'Motion, forces, work, energy, and power',
      topicKeys: ['one_dimensional_motion', 'dynamics', 'work_energy_power'],
    ),
    StudySectionDefinition(
      id: 'physics_fields_circuits',
      subject: Subject.physics,
      title: 'Fields and circuits',
      subtitle: 'Charge, current, magnetism, and induction',
      topicKeys: [
        'electrostatics',
        'current_electricity',
        'magnetism_induction',
      ],
    ),
    StudySectionDefinition(
      id: 'physics_waves_modern',
      subject: Subject.physics,
      title: 'Waves and modern physics',
      subtitle: 'Oscillation, wave behavior, atoms, and nuclei',
      topicKeys: ['oscillation_waves', 'atomic_nuclear'],
    ),
  ];

  static List<StudySectionDefinition> forSubject(Subject subject) => sections
      .where((section) => section.subject == subject)
      .toList(growable: false);

  static List<StudyPathNode> nodesFor(
    StudySectionDefinition section,
    Iterable<TopicDescriptor> topics,
  ) {
    final byKey = {for (final topic in topics) topic.key: topic};
    final nodes = <StudyPathNode>[];
    for (final topicKey in section.topicKeys) {
      final topic = byKey[topicKey];
      if (topic == null) {
        throw StateError('${section.id} references missing topic $topicKey.');
      }
      final partCount = (topic.questionCount / batchSize).ceil();
      for (var part = 0; part < partCount; part++) {
        final offset = part * batchSize;
        nodes.add(
          StudyPathNode(
            key: '${topic.key}:$offset:$batchSize',
            topic: topic,
            offset: offset,
            // Every learnable node is exactly one five-slot session. The
            // generated plan fills a topic remainder with explicit mastery
            // reviews while preserving each source question once as primary.
            questionCount: batchSize,
            partIndex: part,
            partCount: partCount,
          ),
        );
      }
    }
    return List.unmodifiable(nodes);
  }
}
