import 'gamification_catalog.dart';

enum Subject {
  math('math', 'ریاضی'),
  physics('physics', 'فیزیک');

  const Subject(this.key, this.label);
  final String key;
  final String label;

  static Subject fromKey(String value) =>
      Subject.values.firstWhere((item) => item.key == value);
}

enum Difficulty {
  aboveAverage('above_average', 'بالاتر از متوسط'),
  hard('hard', 'سخت'),
  veryHard('very_hard', 'خیلی سخت'),
  olympiad('olympiad', 'المپیادی');

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

  int get preservedArchiveCount => questionCount - missionReadyCount;

  factory TopicDescriptor.fromJson(
    Map<String, dynamic> json, {
    required int missionReadyCount,
  }) => TopicDescriptor(
    subject: Subject.fromKey(json['subject'] as String),
    key: json['topic_key'] as String,
    label: json['label'] as String,
    order: json['order'] as int,
    assetPath: 'assets/${json['file'] as String}',
    questionCount: json['count'] as int,
    missionReadyCount: missionReadyCount,
  );
}

class Question {
  const Question({
    required this.id,
    required this.subject,
    required this.topicKey,
    required this.difficulty,
    required this.stem,
    required this.options,
    required this.sourceCorrectOptionIndex,
    required this.solution,
    required this.shortcut,
    required this.sourceBank,
    required this.trust,
    required this.solutionVerified,
  });

  final String id;
  final Subject subject;
  final String topicKey;
  final Difficulty difficulty;
  final List<ContentBlock> stem;
  final List<List<ContentBlock>> options;

  /// Immutable source contract: JSON answer keys are 1...4.
  final int sourceCorrectOptionIndex;
  final List<ContentBlock> solution;
  final List<ContentBlock>? shortcut;
  final String sourceBank;

  /// The source corpus is immutable, but not every imported item has a
  /// trustworthy question, answer-key, and solution mapping. Unverified items
  /// stay bundled for preservation and never enter scored missions.
  final QuestionTrust trust;
  final bool solutionVerified;

  bool get missionReady => trust.canScore;

  /// Flutter selection contract: choice indexes are 0...3.
  int get correctChoiceIndex => sourceCorrectOptionIndex - 1;

  factory Question.fromJson(Map<String, dynamic> json) {
    final sourceIndex = json['correct_option_index'] as int;
    final rawOptions = json['options'] as List<dynamic>;
    final sourceBank = json['source_bank'] as String?;
    if (sourceBank == null || sourceBank.isEmpty) {
      throw FormatException('Question ${json['id']} has no source bank.');
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
    return Question(
      id: json['id'] as String,
      subject: Subject.fromKey(json['subject'] as String),
      topicKey: json['topic_key'] as String,
      difficulty: Difficulty.fromKey(json['difficulty'] as String),
      stem: _blocks(json['stem']),
      options: rawOptions
          .map((option) => _blocks(option))
          .toList(growable: false),
      sourceCorrectOptionIndex: sourceIndex,
      solution: solution,
      shortcut: json['smart_shortcut'] == null
          ? null
          : _blocks(json['smart_shortcut']),
      sourceBank: sourceBank,
      trust: isUnverifiedSourceMapping
          ? QuestionTrust.preservedArchive
          : QuestionTrust.missionReady,
      solutionVerified:
          !isUnverifiedSourceMapping &&
          _solutionAnswerMatches(solution, sourceIndex),
    );
  }

  static bool _solutionAnswerMatches(
    List<ContentBlock> solution,
    int sourceIndex,
  ) {
    final text = solution
        .whereType<TextBlock>()
        .map((block) => block.text)
        .join(' ')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4');
    final matches = RegExp(
      r'(?:گزینه|option)\s*([1-4])',
      caseSensitive: false,
    ).allMatches(text);
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
    required this.records,
    required this.initialIndex,
    required this.revisitOnly,
  });

  final String key;
  final List<Question> questions;
  final Map<String, StudyRecord> records;
  final int initialIndex;
  final bool revisitOnly;
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
    required this.xpEarned,
    required this.totalXp,
    required this.levelBefore,
    required this.levelAfter,
  });

  final StudyRecord record;
  final List<RewardLine> lines;
  final bool setCompleted;
  final bool unitCompleted;
  final int xpEarned;
  final int totalXp;
  final int levelBefore;
  final int levelAfter;

  bool get leveledUp => levelAfter > levelBefore;
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
    required this.reason,
    required this.amount,
    required this.category,
  });

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
  });

  final int totalXp;
  final int todayXp;
  final int level;
  final double levelProgress;
  final int streak;
  final DailyQuest quest;
  final List<AchievementSnapshot> achievements;
}
