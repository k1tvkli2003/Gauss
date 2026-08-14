import 'gamification_catalog.dart';
import 'learning_content_policy.dart';
import 'question_certification.dart';

enum Subject {
  math('math', 'Mathematics'),
  physics('physics', 'Physics');

  const Subject(this.key, this.label);
  final String key;
  final String label;

  static Subject fromKey(String value) =>
      Subject.values.firstWhere((item) => item.key == value);
}

enum Difficulty {
  aboveAverage('above_average', 'Above average'),
  hard('hard', 'Hard'),
  veryHard('very_hard', 'Very hard'),
  olympiad('olympiad', 'Olympiad');

  const Difficulty(this.key, this.label);
  final String key;
  final String label;

  static Difficulty fromKey(String value) =>
      Difficulty.values.firstWhere((item) => item.key == value);

  static Difficulty? tryFromKey(String value) {
    for (final item in Difficulty.values) {
      if (item.key == value) return item;
    }
    return null;
  }
}

enum QuestionTrust {
  missionReady,
  preservedArchive;

  /// Scientific-certification status only.
  ///
  /// The private runtime may still present and score a structurally valid
  /// source item under the owner's provisional-use policy. Keeping this flag
  /// strict preserves the audit trail without turning it into an access gate.
  bool get canScore => this == QuestionTrust.missionReady;
}

/// A learner-authored reflection over a preserved source item.
///
/// Neither value claims that the imported answer is correct. The distinction
/// only drives the private study queue: [clear] removes an item from revisit,
/// while [revisit] keeps it close for another pass.
enum StudyReflection {
  clear('clear'),
  revisit('revisit'),

  /// A question worth returning to for its idea, not its difficulty: a
  /// keepsake shelf the learner curates deliberately.
  gem('gem');

  const StudyReflection(this.key);
  final String key;

  /// Gems are settled concepts too — only [revisit] asks for another pass.
  bool get needsAnotherPass => this == StudyReflection.revisit;

  static StudyReflection fromKey(String value) =>
      StudyReflection.values.firstWhere((item) => item.key == value);
}

sealed class ContentBlock {
  const ContentBlock();

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'image') {
      return ImageBlock(
        asset: json['asset'] as String,
        alt: (json['alt'] as String?) ?? '',
        aspectRatio: (json['aspect_ratio'] as num?)?.toDouble(),
      );
    }
    return TextBlock((json['text'] as String?) ?? '');
  }
}

final class TextBlock extends ContentBlock {
  const TextBlock(this.text);
  final String text;
}

final class ImageBlock extends ContentBlock {
  const ImageBlock({required this.asset, required this.alt, this.aspectRatio});
  final String asset;
  final String alt;
  final double? aspectRatio;
}

class TopicDescriptor {
  const TopicDescriptor({
    required this.subject,
    required this.key,
    required this.label,
    required this.order,
    required this.assetPath,
    required this.questionCount,
    required this.missionReadyCount,
  });

  final Subject subject;
  final String key;
  final String label;
  final int order;
  final String assetPath;
  final int questionCount;
  final int missionReadyCount;

  static const _englishLabels = <String, String>{
    'sets': 'Sets',
    'patterns_sequences': 'Patterns & Sequences',
    'quadratic_equations_functions': 'Quadratics',
    'rational_inequalities_sign': 'Rational Inequalities',
    'radicals_algebraic_expressions': 'Radicals & Expressions',
    'absolute_value_floor': 'Absolute Value & Floor',
    'functions': 'Functions',
    'trigonometry': 'Trigonometry',
    'limits_continuity': 'Limits & Continuity',
    'derivatives': 'Derivatives',
    'derivative_applications': 'Derivative Applications',
    'exponential_logarithmic': 'Exponential & Logarithmic',
    'analytic_geometry': 'Analytic Geometry',
    'visual_thinking_conics': 'Visual Thinking & Conics',
    'combinatorics': 'Combinatorics',
    'probability': 'Probability',
    'geometry': 'Geometry',
    'statistics': 'Statistics',
    'physics_measurement': 'Physics & Measurement',
    'physical_properties_matter': 'Properties of Matter',
    'work_energy_power': 'Work, Energy & Power',
    'temperature_heat': 'Temperature & Heat',
    'electrostatics': 'Electrostatics',
    'current_electricity': 'Current Electricity',
    'magnetism_induction': 'Magnetism & Induction',
    'one_dimensional_motion': 'One-Dimensional Motion',
    'dynamics': 'Dynamics',
    'oscillation_waves': 'Oscillations & Waves',
    'atomic_nuclear': 'Atomic & Nuclear Physics',
  };

  int get preservedArchiveCount => questionCount - missionReadyCount;

  factory TopicDescriptor.fromJson(
    Map<String, dynamic> json, {
    required int missionReadyCount,
  }) => TopicDescriptor(
    subject: Subject.fromKey(json['subject'] as String),
    key: json['topic_key'] as String,
    label:
        _englishLabels[json['topic_key'] as String] ??
        (json['topic_key'] as String)
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' '),
    order: json['order'] as int,
    assetPath: 'assets/${json['file'] as String}',
    questionCount: json['count'] as int,
    missionReadyCount: missionReadyCount,
  );
}

class Question {
  const Question({
    required this.id,
    this.revision = 1,
    required this.subject,
    required this.topicKey,
    required this.difficulty,
    required this.stem,
    required this.options,
    required this.sourceCorrectOptionIndex,
    required this.effectiveCorrectOptionIndex,
    required this.solution,
    required this.shortcut,
    required this.sourceBank,
    required this.trust,
    required this.solutionVerified,
    this.certification,
  });

  final String id;

  /// Monotonic content revision for this stable question identity.
  ///
  /// Bundled source rows predate remote delivery and are revision 1. A
  /// downloaded release injects its reviewed database revision at the cache
  /// boundary without rewriting the immutable source corpus.
  final int revision;
  final Subject subject;
  final String topicKey;
  final Difficulty difficulty;
  final List<ContentBlock> stem;
  final List<List<ContentBlock>> options;

  /// Immutable source contract: JSON answer keys are 1...4.
  final int sourceCorrectOptionIndex;

  /// Certified answer mapping after a source-faithful derived repair. This is
  /// also 1...4 and never overwrites [sourceCorrectOptionIndex].
  final int effectiveCorrectOptionIndex;
  final List<ContentBlock> solution;
  final List<ContentBlock>? shortcut;
  final String sourceBank;

  /// The source corpus is immutable, but not every imported item has a
  /// trustworthy question, answer-key, and solution mapping. Unverified items
  /// stay bundled for preservation and never enter scored missions.
  final QuestionTrust trust;
  final bool solutionVerified;
  final QuestionCertification? certification;

  /// Every successfully parsed source row is available for private practice.
  ///
  /// Certification remains visible through [missionReady]; it no longer
  /// decides whether the owner can open the question. The repository validates
  /// this structural contract across all 3,672 rows during corpus checks.
  bool get runtimeUsable =>
      stem.isNotEmpty &&
      options.length == 4 &&
      options.every((option) => option.isNotEmpty) &&
      correctChoiceIndex >= 0 &&
      correctChoiceIndex < options.length &&
      solution.isNotEmpty;

  bool get missionReady => trust.canScore;

  /// Flutter selection contract: choice indexes are 0...3.
  int get correctChoiceIndex => effectiveCorrectOptionIndex - 1;

  factory Question.fromJson(
    Map<String, dynamic> json, {
    QuestionCertification? certification,
  }) {
    final sourceIndex = json['correct_option_index'] as int;
    final revision = json['_gauss_revision'] as int? ?? 1;
    final effectiveIndex = certification?.effectiveOptionIndex ?? sourceIndex;
    final rawOptions = json['options'] as List<dynamic>;
    final sourceBank = json['source_bank'] as String?;
    if (sourceBank == null || sourceBank.isEmpty) {
      throw FormatException('Question ${json['id']} has no source bank.');
    }
    if (revision < 1) {
      throw FormatException('Question ${json['id']} has an invalid revision.');
    }
    final provenance = json['provenance'] as Map<String, dynamic>?;
    final solution = _blocks(json['solution']);
    final isUnverifiedSourceMapping =
        sourceBank == 'nardebam' &&
        provenance?['kind'] == 'source' &&
        provenance?['solution_origin'] == 'source';
    if (sourceIndex < 1 || sourceIndex > rawOptions.length) {
      throw FormatException(
        'Question ${json['id']} has invalid 1-based answer $sourceIndex.',
      );
    }
    if (effectiveIndex < 1 || effectiveIndex > rawOptions.length) {
      throw FormatException(
        'Question ${json['id']} has invalid certified answer $effectiveIndex.',
      );
    }
    if (certification != null &&
        (certification.questionId != json['id'] ||
            certification.subjectKey != json['subject'] ||
            certification.topicKey != json['topic_key'] ||
            certification.sourceOptionIndex != sourceIndex)) {
      throw FormatException(
        'Question ${json['id']} does not match its certification identity.',
      );
    }
    return Question(
      id: json['id'] as String,
      revision: revision,
      subject: Subject.fromKey(json['subject'] as String),
      topicKey: json['topic_key'] as String,
      difficulty: Difficulty.fromKey(
        certification?.reviewedDifficultyKey ?? json['difficulty'] as String,
      ),
      stem: _blocks(json['stem']),
      options: rawOptions
          .map((option) => _blocks(option))
          .toList(growable: false),
      sourceCorrectOptionIndex: sourceIndex,
      effectiveCorrectOptionIndex: effectiveIndex,
      solution: solution,
      shortcut: json['smart_shortcut'] == null
          ? null
          : _blocks(json['smart_shortcut']),
      sourceBank: sourceBank,
      trust: certification != null
          ? QuestionTrust.missionReady
          : isUnverifiedSourceMapping
          ? QuestionTrust.preservedArchive
          : QuestionTrust.missionReady,
      solutionVerified:
          certification?.solutionVerified ??
          (!isUnverifiedSourceMapping &&
              _solutionAnswerMatches(solution, effectiveIndex)),
      certification: certification,
    );
  }

  static bool _solutionAnswerMatches(
    List<ContentBlock> solution,
    int sourceIndex,
  ) {
    final text = solution
        .whereType<TextBlock>()
        .map((block) => block.text)
        .join(' ');
    final normalizedText = normalizeLearningDigits(text);
    final matches = RegExp(
      r'(?:گزینه|option)\s*([1-4])',
      caseSensitive: false,
    ).allMatches(normalizedText);
    if (matches.isEmpty) return true;
    return int.parse(matches.last.group(1)!) == sourceIndex;
  }

  static List<ContentBlock> _blocks(dynamic value) => (value as List<dynamic>)
      .map((item) => ContentBlock.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
}

class StudyRecord {
  const StudyRecord({
    required this.questionId,
    required this.topicKey,
    required this.shelfKey,
    required this.hypothesisChoiceIndex,
    required this.hypothesisMatched,
    required this.reflection,
    required this.firstReflectedAt,
    required this.updatedAt,
  });

  final String questionId;
  final String topicKey;
  final String shelfKey;

  /// The learner's private pre-reveal hypothesis.
  final int? hypothesisChoiceIndex;

  /// Whether that hypothesis agreed with the source-claimed key. Recorded as
  /// a private alignment note; the source is unverified, so it is never a
  /// score and never gates a reward.
  final bool? hypothesisMatched;
  final StudyReflection reflection;
  final DateTime firstReflectedAt;
  final DateTime updatedAt;
}

class StudyTopicSnapshot {
  const StudyTopicSnapshot({
    required this.reflected,
    required this.clear,
    required this.revisit,
    this.gem = 0,
  });

  const StudyTopicSnapshot.empty()
    : reflected = 0,
      clear = 0,
      revisit = 0,
      gem = 0;

  final int reflected;
  final int clear;
  final int revisit;
  final int gem;
}

class StudySummary {
  const StudySummary({
    required this.totalReflected,
    required this.clearCount,
    required this.revisitCount,
    required this.touchedTopics,
    required this.byTopic,
    required this.byShelf,
    required this.heatmap,
    this.gemCount = 0,
    this.hypothesisCount = 0,
    this.hypothesisMatchedCount = 0,
  });

  const StudySummary.empty()
    : totalReflected = 0,
      clearCount = 0,
      revisitCount = 0,
      touchedTopics = 0,
      byTopic = const {},
      byShelf = const {},
      heatmap = const {},
      gemCount = 0,
      hypothesisCount = 0,
      hypothesisMatchedCount = 0;

  final int totalReflected;
  final int clearCount;
  final int revisitCount;
  final int touchedTopics;

  /// Questions kept on the gem shelf for their idea.
  final int gemCount;

  /// Reflections that carried a pre-reveal hypothesis, and how many of those
  /// agreed with the (unverified) source key.
  final int hypothesisCount;
  final int hypothesisMatchedCount;
  final Map<String, StudyTopicSnapshot> byTopic;
  final Map<String, StudyTopicSnapshot> byShelf;

  /// Unique first reflections per local calendar day. This is a calm activity
  /// record, not a streak and not a farmable repeat counter.
  final Map<String, int> heatmap;

  StudyTopicSnapshot topic(String key) =>
      byTopic[key] ?? const StudyTopicSnapshot.empty();

  StudyTopicSnapshot shelf(String key) =>
      byShelf[key] ?? const StudyTopicSnapshot.empty();
}

class StudyShelf {
  const StudyShelf({
    required this.key,
    required this.questions,
    required this.slots,
    required this.records,
    required this.encounteredSlotIds,
    required this.initialIndex,
    required this.revisitOnly,
  });

  final String key;
  final List<Question> questions;
  final List<StudyShelfSlot> slots;
  final Map<String, StudyRecord> records;
  final Set<String> encounteredSlotIds;
  final int initialIndex;
  final bool revisitOnly;

  bool isEncounteredAt(int index) =>
      !slots[index].planned || encounteredSlotIds.contains(slots[index].id);
}

class StudyShelfSlot {
  const StudyShelfSlot({
    required this.id,
    required this.questionId,
    required this.kind,
    required this.primaryShelfKey,
    required this.planned,
  });

  final String id;
  final String questionId;
  final String kind;
  final String primaryShelfKey;
  final bool planned;
}

/// What a saved reflection produced: the persisted record plus any rewards
/// the idempotent ledger granted for the act of studying. Rewards celebrate
/// effort and pacing — they never claim the unverified source is correct.
class StudyReflectionOutcome {
  const StudyReflectionOutcome({
    required this.record,
    required this.lines,
    required this.setCompleted,
    required this.unitCompleted,
    required this.dailyQuestCompleted,
    required this.xpEarned,
    required this.totalXp,
    required this.levelBefore,
    required this.levelAfter,
  });

  final StudyRecord record;
  final List<RewardLine> lines;
  final bool setCompleted;
  final bool unitCompleted;

  /// True only when this write created today's quest-completion ledger event.
  /// It is a study milestone, not a claim that an unverified source answer was
  /// mathematically correct.
  final bool dailyQuestCompleted;
  final int xpEarned;
  final int totalXp;
  final int levelBefore;
  final int levelAfter;

  bool get leveledUp => levelAfter > levelBefore;
}

/// Private, offline issue categories for owner-reported corpus repairs.
enum QuestionIssueKind {
  questionText('question_text', 'Question text'),
  options('options', 'Answer choices'),
  answerKey('answer_key', 'Answer key'),
  solution('solution', 'Solution'),
  image('image', 'Image or diagram'),
  other('other', 'Something else');

  const QuestionIssueKind(this.key, this.label);
  final String key;
  final String label;

  static QuestionIssueKind fromKey(String value) =>
      QuestionIssueKind.values.firstWhere((item) => item.key == value);
}

/// One local-only repair signal attached to an immutable source question.
///
/// Reports never rewrite or hide corpus rows. They preserve the exact runtime
/// context needed for a later repair pass while the question stays playable.
class QuestionIssueReport {
  const QuestionIssueReport({
    required this.questionId,
    this.questionRevision = 1,
    required this.topicKey,
    required this.kind,
    required this.note,
    required this.sessionId,
    required this.missionIndex,
    required this.selectedChoiceIndex,
    required this.reportedAt,
  });

  final String questionId;
  final int questionRevision;
  final String topicKey;
  final QuestionIssueKind kind;
  final String note;
  final String sessionId;
  final int missionIndex;
  final int? selectedChoiceIndex;
  final DateTime reportedAt;

  String get id => '$questionId:${reportedAt.microsecondsSinceEpoch}';

  Map<String, Object?> toJson() => {
    'schema_version': 2,
    'question_id': questionId,
    'question_revision': questionRevision,
    'topic_key': topicKey,
    'kind': kind.key,
    'note': note,
    'session_id': sessionId,
    'mission_index': missionIndex,
    'selected_choice_index': selectedChoiceIndex,
    'reported_at': reportedAt.toIso8601String(),
  };

  factory QuestionIssueReport.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schema_version'];
    if (schemaVersion != 1 && schemaVersion != 2) {
      throw const FormatException('Unsupported question issue schema.');
    }
    final questionId = json['question_id'];
    final questionRevision = schemaVersion == 1 ? 1 : json['question_revision'];
    final topicKey = json['topic_key'];
    final kind = json['kind'];
    final note = json['note'];
    final sessionId = json['session_id'];
    final missionIndex = json['mission_index'];
    final selectedChoiceIndex = json['selected_choice_index'];
    final reportedAt = DateTime.tryParse(json['reported_at'] as String? ?? '');
    if (questionId is! String ||
        questionId.isEmpty ||
        questionRevision is! int ||
        questionRevision < 1 ||
        topicKey is! String ||
        topicKey.isEmpty ||
        kind is! String ||
        note is! String ||
        sessionId is! String ||
        sessionId.isEmpty ||
        missionIndex is! int ||
        missionIndex < 0 ||
        (selectedChoiceIndex != null && selectedChoiceIndex is! int) ||
        reportedAt == null) {
      throw const FormatException('Malformed question issue report.');
    }
    return QuestionIssueReport(
      questionId: questionId,
      questionRevision: questionRevision,
      topicKey: topicKey,
      kind: QuestionIssueKind.fromKey(kind),
      note: note,
      sessionId: sessionId,
      missionIndex: missionIndex,
      selectedChoiceIndex: selectedChoiceIndex as int?,
      reportedAt: reportedAt,
    );
  }
}

class AttemptRecord {
  const AttemptRecord({
    required this.sessionId,
    required this.missionIndex,
    required this.questionId,
    required this.subject,
    required this.topicKey,
    required this.selectedChoiceIndex,
    required this.correct,
    required this.elapsedSeconds,
    required this.at,
    this.examId,
    this.finalized = false,
    this.errorTag,
  });

  final String sessionId;
  final int missionIndex;
  final String questionId;
  final Subject subject;
  final String topicKey;
  final int? selectedChoiceIndex;
  final bool correct;
  final int elapsedSeconds;
  final DateTime at;
  final int? examId;
  final bool finalized;

  /// Self-reported reason for a miss (see [MissReason]); null when untagged.
  final String? errorTag;

  bool get skipped => selectedChoiceIndex == null;

  AttemptRecord copyWith({int? examId, bool? finalized, String? errorTag}) =>
      AttemptRecord(
        sessionId: sessionId,
        missionIndex: missionIndex,
        questionId: questionId,
        subject: subject,
        topicKey: topicKey,
        selectedChoiceIndex: selectedChoiceIndex,
        correct: correct,
        elapsedSeconds: elapsedSeconds,
        at: at,
        examId: examId ?? this.examId,
        finalized: finalized ?? this.finalized,
        errorTag: errorTag ?? this.errorTag,
      );
}

class ActiveMissionRecord {
  const ActiveMissionRecord({
    required this.sessionId,
    required this.subject,
    required this.topicKey,
    required this.createdAt,
    required this.questionIds,
    required this.attempts,
  });

  final String sessionId;
  final Subject subject;
  final String topicKey;
  final DateTime createdAt;
  final List<String> questionIds;
  final List<AttemptRecord> attempts;
}

class ResumableMission {
  const ResumableMission({
    required this.sessionId,
    required this.subject,
    required this.topicKey,
    required this.createdAt,
    required this.questions,
    required this.attempts,
  });

  final String sessionId;
  final Subject subject;
  final String topicKey;
  final DateTime createdAt;
  final List<Question> questions;
  final List<AttemptRecord> attempts;

  int get answeredCount => attempts.length;

  int get resumeIndex {
    if (questions.isEmpty) return 0;
    final answered = attempts.map((attempt) => attempt.missionIndex).toSet();
    for (var index = 0; index < questions.length; index++) {
      if (!answered.contains(index)) return index;
    }
    return questions.length - 1;
  }

  AttemptRecord? get resumeAttempt {
    final index = resumeIndex;
    for (final attempt in attempts) {
      if (attempt.missionIndex == index) return attempt;
    }
    return null;
  }
}

class RewardLine {
  const RewardLine({
    required this.eventId,
    required this.ruleVersion,
    required this.reason,
    required this.amount,
    required this.category,
  });

  /// Stable identity of the authoritative event that produced this line.
  /// Presentation code may acknowledge it, but must never grant it again.
  final String eventId;
  final int ruleVersion;
  final String reason;
  final int amount;
  final String category;
}

class MissionCompletion {
  const MissionCompletion({
    required this.examId,
    required this.xpEarned,
    required this.totalXp,
    required this.levelBefore,
    required this.levelAfter,
    required this.lines,
  });

  final int examId;
  final int xpEarned;
  final int totalXp;
  final int levelBefore;
  final int levelAfter;
  final List<RewardLine> lines;
}

class RecentExamSummary {
  const RecentExamSummary({
    required this.id,
    required this.subject,
    required this.topicKey,
    required this.totalQuestions,
    required this.correctCount,
    required this.scorePercentage,
    required this.completedAt,
  });

  final int id;
  final Subject subject;
  final String? topicKey;
  final int totalQuestions;
  final int correctCount;
  final double scorePercentage;
  final DateTime completedAt;
}

class TopicInsight {
  const TopicInsight({
    required this.topicKey,
    required this.subject,
    required this.total,
    required this.correct,
    required this.accuracy,
    required this.averageSeconds,
  });

  final String topicKey;
  final Subject subject;
  final int total;
  final int correct;
  final double accuracy;
  final double averageSeconds;
}

class DistractorInsight {
  const DistractorInsight({
    required this.topicKey,
    required this.subject,
    required this.choiceIndex,
    required this.count,
  });

  final String topicKey;
  final Subject subject;
  final int choiceIndex;
  final int count;
}

/// The fixed vocabulary of self-reported miss reasons.
enum MissReason {
  careless('careless', 'Careless slip'),
  gap('gap', 'Knowledge gap'),
  misread('misread', 'Misread it'),
  time('time', 'Ran out of time');

  const MissReason(this.key, this.label);
  final String key;
  final String label;

  static MissReason? tryFromKey(String? value) {
    for (final item in MissReason.values) {
      if (item.key == value) return item;
    }
    return null;
  }
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.totalAnswered,
    required this.totalCorrect,
    required this.accuracy,
    required this.averageSeconds,
    required this.weakTopics,
    required this.distractors,
    required this.heatmap,
    required this.streak,
    this.errorBreakdown = const {},
  });

  final int totalAnswered;
  final int totalCorrect;
  final double accuracy;
  final double averageSeconds;
  final List<TopicInsight> weakTopics;
  final List<DistractorInsight> distractors;
  final Map<String, int> heatmap;
  final int streak;

  /// Finalized wrong answers grouped by self-reported [MissReason] key.
  final Map<String, int> errorBreakdown;
}

class DailyQuest {
  const DailyQuest({
    required this.title,
    required this.progress,
    required this.target,
    required this.rewardXp,
    required this.completed,
  });

  final String title;
  final int progress;
  final int target;
  final int rewardXp;
  final bool completed;
}

class GamificationSummary {
  const GamificationSummary({
    required this.totalXp,
    required this.todayXp,
    required this.level,
    required this.levelProgress,
    required this.streak,
    required this.quest,
    required this.achievements,
    this.effectiveDayKey = '',
    this.clockAdjusted = false,
    this.streakGraceUsed = false,
  });

  final int totalXp;
  final int todayXp;
  final int level;
  final double levelProgress;
  final int streak;
  final DailyQuest quest;
  final List<AchievementSnapshot> achievements;

  /// Calendar window used by the reward engine. It can intentionally differ
  /// from the wall clock after a backwards clock change so daily rewards and
  /// caps cannot be reopened.
  final String effectiveDayKey;
  final bool clockAdjusted;

  /// True when the current private rhythm bridges one missed calendar day.
  /// No currency, purchase, or social mechanic is attached to this grace.
  final bool streakGraceUsed;
}
