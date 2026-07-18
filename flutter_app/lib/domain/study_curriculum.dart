import 'dart:math' as math;

import 'models.dart';

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
  String get setLabel => 'Set ${partIndex + 1} of $partCount';
}

abstract final class GaussStudyCurriculum {
  static const batchSize = 20;

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
        final count = math.min(batchSize, topic.questionCount - offset);
        nodes.add(
          StudyPathNode(
            key: '${topic.key}:$offset:$batchSize',
            topic: topic,
            offset: offset,
            questionCount: count,
            partIndex: part,
            partCount: partCount,
          ),
        );
      }
    }
    return List.unmodifiable(nodes);
  }
}
