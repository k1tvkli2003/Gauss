/// One screened sub-division of a chapter ("unit"), e.g. "Venn diagrams".
class StudyUnit {
  const StudyUnit({
    required this.key,
    required this.topicKey,
    required this.label,
    required this.order,
    required this.questionIds,
  });

  final String key;
  final String topicKey;
  final String label;
  final int order;

  /// Source questions classified into this unit, in corpus order.
  final List<String> questionIds;

  bool get isMixed => key.endsWith('__mixed');
  int get questionCount => questionIds.length;
}

/// Part > Chapter > Unit view of the shipped corpus. It is a derived,
/// read-only classification: five-question lessons and their keys are not
/// affected by it.
class GaussSubtopicIndex {
  GaussSubtopicIndex._(this._byTopic, this._unitByQuestion);

  factory GaussSubtopicIndex.fromJson(Map<String, dynamic> json) {
    final rawUnits = (json['units'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final questionUnit = (json['question_unit'] as Map<String, dynamic>).map(
      (id, index) => MapEntry(id, index as int),
    );
    final idsByUnit = List<List<String>>.generate(rawUnits.length, (_) => []);
    for (final entry in questionUnit.entries) {
      idsByUnit[entry.value].add(entry.key);
    }
    final units = <StudyUnit>[
      for (var i = 0; i < rawUnits.length; i++)
        StudyUnit(
          key: rawUnits[i]['key'] as String,
          topicKey: rawUnits[i]['topic_key'] as String,
          label: rawUnits[i]['label'] as String,
          order: rawUnits[i]['order'] as int,
          questionIds: List.unmodifiable(idsByUnit[i]..sort()),
        ),
    ];
    final byTopic = <String, List<StudyUnit>>{};
    for (final unit in units) {
      byTopic.putIfAbsent(unit.topicKey, () => []).add(unit);
    }
    return GaussSubtopicIndex._(
      {for (final e in byTopic.entries) e.key: List.unmodifiable(e.value)},
      {for (final e in questionUnit.entries) e.key: units[e.value]},
    );
  }

  /// An index with no units, for callers that have not loaded the asset.
  GaussSubtopicIndex.empty() : _byTopic = const {}, _unitByQuestion = const {};

  final Map<String, List<StudyUnit>> _byTopic;
  final Map<String, StudyUnit> _unitByQuestion;

  List<StudyUnit> unitsOf(String topicKey) => _byTopic[topicKey] ?? const [];
  StudyUnit? unitOfQuestion(String questionId) => _unitByQuestion[questionId];
  int get unitCount =>
      _byTopic.values.fold(0, (sum, list) => sum + list.length);
}
