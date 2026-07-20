// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gauss_database.dart';

// ignore_for_file: type=lint
class $ExamsTable extends Exams with TableInfo<$ExamsTable, ExamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicKeyMeta = const VerificationMeta(
    'topicKey',
  );
  @override
  late final GeneratedColumn<String> topicKey = GeneratedColumn<String>(
    'topic_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wrongCountMeta = const VerificationMeta(
    'wrongCount',
  );
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
    'wrong_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skippedCountMeta = const VerificationMeta(
    'skippedCount',
  );
  @override
  late final GeneratedColumn<int> skippedCount = GeneratedColumn<int>(
    'skipped_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scorePercentageMeta = const VerificationMeta(
    'scorePercentage',
  );
  @override
  late final GeneratedColumn<double> scorePercentage = GeneratedColumn<double>(
    'score_percentage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    subject,
    topicKey,
    totalQuestions,
    correctCount,
    wrongCount,
    skippedCount,
    scorePercentage,
    durationSeconds,
    status,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exams';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('topic_key')) {
      context.handle(
        _topicKeyMeta,
        topicKey.isAcceptableOrUnknown(data['topic_key']!, _topicKeyMeta),
      );
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
        _wrongCountMeta,
        wrongCount.isAcceptableOrUnknown(data['wrong_count']!, _wrongCountMeta),
      );
    }
    if (data.containsKey('skipped_count')) {
      context.handle(
        _skippedCountMeta,
        skippedCount.isAcceptableOrUnknown(
          data['skipped_count']!,
          _skippedCountMeta,
        ),
      );
    }
    if (data.containsKey('score_percentage')) {
      context.handle(
        _scorePercentageMeta,
        scorePercentage.isAcceptableOrUnknown(
          data['score_percentage']!,
          _scorePercentageMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      topicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_key'],
      ),
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      wrongCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_count'],
      )!,
      skippedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped_count'],
      )!,
      scorePercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score_percentage'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $ExamsTable createAlias(String alias) {
    return $ExamsTable(attachedDatabase, alias);
  }
}

class ExamRow extends DataClass implements Insertable<ExamRow> {
  final int id;
  final String sessionId;
  final String subject;
  final String? topicKey;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double scorePercentage;
  final int durationSeconds;
  final String status;
  final int createdAt;
  final int? completedAt;
  const ExamRow({
    required this.id,
    required this.sessionId,
    required this.subject,
    this.topicKey,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.scorePercentage,
    required this.durationSeconds,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['subject'] = Variable<String>(subject);
    if (!nullToAbsent || topicKey != null) {
      map['topic_key'] = Variable<String>(topicKey);
    }
    map['total_questions'] = Variable<int>(totalQuestions);
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    map['skipped_count'] = Variable<int>(skippedCount);
    map['score_percentage'] = Variable<double>(scorePercentage);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  ExamsCompanion toCompanion(bool nullToAbsent) {
    return ExamsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      subject: Value(subject),
      topicKey: topicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(topicKey),
      totalQuestions: Value(totalQuestions),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      skippedCount: Value(skippedCount),
      scorePercentage: Value(scorePercentage),
      durationSeconds: Value(durationSeconds),
      status: Value(status),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ExamRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      subject: serializer.fromJson<String>(json['subject']),
      topicKey: serializer.fromJson<String?>(json['topicKey']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      skippedCount: serializer.fromJson<int>(json['skippedCount']),
      scorePercentage: serializer.fromJson<double>(json['scorePercentage']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'subject': serializer.toJson<String>(subject),
      'topicKey': serializer.toJson<String?>(topicKey),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'skippedCount': serializer.toJson<int>(skippedCount),
      'scorePercentage': serializer.toJson<double>(scorePercentage),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  ExamRow copyWith({
    int? id,
    String? sessionId,
    String? subject,
    Value<String?> topicKey = const Value.absent(),
    int? totalQuestions,
    int? correctCount,
    int? wrongCount,
    int? skippedCount,
    double? scorePercentage,
    int? durationSeconds,
    String? status,
    int? createdAt,
    Value<int?> completedAt = const Value.absent(),
  }) => ExamRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    subject: subject ?? this.subject,
    topicKey: topicKey.present ? topicKey.value : this.topicKey,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
    skippedCount: skippedCount ?? this.skippedCount,
    scorePercentage: scorePercentage ?? this.scorePercentage,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  ExamRow copyWithCompanion(ExamsCompanion data) {
    return ExamRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      subject: data.subject.present ? data.subject.value : this.subject,
      topicKey: data.topicKey.present ? data.topicKey.value : this.topicKey,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount: data.wrongCount.present
          ? data.wrongCount.value
          : this.wrongCount,
      skippedCount: data.skippedCount.present
          ? data.skippedCount.value
          : this.skippedCount,
      scorePercentage: data.scorePercentage.present
          ? data.scorePercentage.value
          : this.scorePercentage,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('subject: $subject, ')
          ..write('topicKey: $topicKey, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('skippedCount: $skippedCount, ')
          ..write('scorePercentage: $scorePercentage, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    subject,
    topicKey,
    totalQuestions,
    correctCount,
    wrongCount,
    skippedCount,
    scorePercentage,
    durationSeconds,
    status,
    createdAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.subject == this.subject &&
          other.topicKey == this.topicKey &&
          other.totalQuestions == this.totalQuestions &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.skippedCount == this.skippedCount &&
          other.scorePercentage == this.scorePercentage &&
          other.durationSeconds == this.durationSeconds &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class ExamsCompanion extends UpdateCompanion<ExamRow> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<String> subject;
  final Value<String?> topicKey;
  final Value<int> totalQuestions;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<int> skippedCount;
  final Value<double> scorePercentage;
  final Value<int> durationSeconds;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  const ExamsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.subject = const Value.absent(),
    this.topicKey = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.skippedCount = const Value.absent(),
    this.scorePercentage = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  ExamsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required String subject,
    this.topicKey = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.skippedCount = const Value.absent(),
    this.scorePercentage = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    this.completedAt = const Value.absent(),
  }) : sessionId = Value(sessionId),
       subject = Value(subject),
       createdAt = Value(createdAt);
  static Insertable<ExamRow> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<String>? subject,
    Expression<String>? topicKey,
    Expression<int>? totalQuestions,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<int>? skippedCount,
    Expression<double>? scorePercentage,
    Expression<int>? durationSeconds,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (subject != null) 'subject': subject,
      if (topicKey != null) 'topic_key': topicKey,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (skippedCount != null) 'skipped_count': skippedCount,
      if (scorePercentage != null) 'score_percentage': scorePercentage,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  ExamsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<String>? subject,
    Value<String?>? topicKey,
    Value<int>? totalQuestions,
    Value<int>? correctCount,
    Value<int>? wrongCount,
    Value<int>? skippedCount,
    Value<double>? scorePercentage,
    Value<int>? durationSeconds,
    Value<String>? status,
    Value<int>? createdAt,
    Value<int?>? completedAt,
  }) {
    return ExamsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      subject: subject ?? this.subject,
      topicKey: topicKey ?? this.topicKey,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      skippedCount: skippedCount ?? this.skippedCount,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topicKey.present) {
      map['topic_key'] = Variable<String>(topicKey.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (skippedCount.present) {
      map['skipped_count'] = Variable<int>(skippedCount.value);
    }
    if (scorePercentage.present) {
      map['score_percentage'] = Variable<double>(scorePercentage.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('subject: $subject, ')
          ..write('topicKey: $topicKey, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('skippedCount: $skippedCount, ')
          ..write('scorePercentage: $scorePercentage, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts
    with TableInfo<$AttemptsTable, AttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<int> examId = GeneratedColumn<int>(
    'exam_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id)',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _missionIndexMeta = const VerificationMeta(
    'missionIndex',
  );
  @override
  late final GeneratedColumn<int> missionIndex = GeneratedColumn<int>(
    'mission_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicKeyMeta = const VerificationMeta(
    'topicKey',
  );
  @override
  late final GeneratedColumn<String> topicKey = GeneratedColumn<String>(
    'topic_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedChoiceIndexMeta =
      const VerificationMeta('selectedChoiceIndex');
  @override
  late final GeneratedColumn<int> selectedChoiceIndex = GeneratedColumn<int>(
    'selected_choice_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeTakenSecondsMeta = const VerificationMeta(
    'timeTakenSeconds',
  );
  @override
  late final GeneratedColumn<int> timeTakenSeconds = GeneratedColumn<int>(
    'time_taken_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solvedAtMeta = const VerificationMeta(
    'solvedAt',
  );
  @override
  late final GeneratedColumn<int> solvedAt = GeneratedColumn<int>(
    'solved_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorTagMeta = const VerificationMeta(
    'errorTag',
  );
  @override
  late final GeneratedColumn<String> errorTag = GeneratedColumn<String>(
    'error_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    examId,
    sessionId,
    missionIndex,
    questionId,
    subject,
    topicKey,
    status,
    selectedChoiceIndex,
    timeTakenSeconds,
    solvedAt,
    errorTag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('mission_index')) {
      context.handle(
        _missionIndexMeta,
        missionIndex.isAcceptableOrUnknown(
          data['mission_index']!,
          _missionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_missionIndexMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('topic_key')) {
      context.handle(
        _topicKeyMeta,
        topicKey.isAcceptableOrUnknown(data['topic_key']!, _topicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_topicKeyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('selected_choice_index')) {
      context.handle(
        _selectedChoiceIndexMeta,
        selectedChoiceIndex.isAcceptableOrUnknown(
          data['selected_choice_index']!,
          _selectedChoiceIndexMeta,
        ),
      );
    }
    if (data.containsKey('time_taken_seconds')) {
      context.handle(
        _timeTakenSecondsMeta,
        timeTakenSeconds.isAcceptableOrUnknown(
          data['time_taken_seconds']!,
          _timeTakenSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeTakenSecondsMeta);
    }
    if (data.containsKey('solved_at')) {
      context.handle(
        _solvedAtMeta,
        solvedAt.isAcceptableOrUnknown(data['solved_at']!, _solvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_solvedAtMeta);
    }
    if (data.containsKey('error_tag')) {
      context.handle(
        _errorTagMeta,
        errorTag.isAcceptableOrUnknown(data['error_tag']!, _errorTagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, questionId},
  ];
  @override
  AttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exam_id'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      missionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mission_index'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      topicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_key'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      selectedChoiceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selected_choice_index'],
      ),
      timeTakenSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_taken_seconds'],
      )!,
      solvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}solved_at'],
      )!,
      errorTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_tag'],
      ),
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class AttemptRow extends DataClass implements Insertable<AttemptRow> {
  final int id;
  final int? examId;
  final String sessionId;
  final int missionIndex;
  final String questionId;
  final String subject;
  final String topicKey;
  final String status;
  final int? selectedChoiceIndex;
  final int timeTakenSeconds;
  final int solvedAt;

  /// Self-reported reason for a wrong answer (careless, gap, misread, time).
  /// Nullable: tagging is optional and only offered on non-skipped misses.
  final String? errorTag;
  const AttemptRow({
    required this.id,
    this.examId,
    required this.sessionId,
    required this.missionIndex,
    required this.questionId,
    required this.subject,
    required this.topicKey,
    required this.status,
    this.selectedChoiceIndex,
    required this.timeTakenSeconds,
    required this.solvedAt,
    this.errorTag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || examId != null) {
      map['exam_id'] = Variable<int>(examId);
    }
    map['session_id'] = Variable<String>(sessionId);
    map['mission_index'] = Variable<int>(missionIndex);
    map['question_id'] = Variable<String>(questionId);
    map['subject'] = Variable<String>(subject);
    map['topic_key'] = Variable<String>(topicKey);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || selectedChoiceIndex != null) {
      map['selected_choice_index'] = Variable<int>(selectedChoiceIndex);
    }
    map['time_taken_seconds'] = Variable<int>(timeTakenSeconds);
    map['solved_at'] = Variable<int>(solvedAt);
    if (!nullToAbsent || errorTag != null) {
      map['error_tag'] = Variable<String>(errorTag);
    }
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      examId: examId == null && nullToAbsent
          ? const Value.absent()
          : Value(examId),
      sessionId: Value(sessionId),
      missionIndex: Value(missionIndex),
      questionId: Value(questionId),
      subject: Value(subject),
      topicKey: Value(topicKey),
      status: Value(status),
      selectedChoiceIndex: selectedChoiceIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedChoiceIndex),
      timeTakenSeconds: Value(timeTakenSeconds),
      solvedAt: Value(solvedAt),
      errorTag: errorTag == null && nullToAbsent
          ? const Value.absent()
          : Value(errorTag),
    );
  }

  factory AttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRow(
      id: serializer.fromJson<int>(json['id']),
      examId: serializer.fromJson<int?>(json['examId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      missionIndex: serializer.fromJson<int>(json['missionIndex']),
      questionId: serializer.fromJson<String>(json['questionId']),
      subject: serializer.fromJson<String>(json['subject']),
      topicKey: serializer.fromJson<String>(json['topicKey']),
      status: serializer.fromJson<String>(json['status']),
      selectedChoiceIndex: serializer.fromJson<int?>(
        json['selectedChoiceIndex'],
      ),
      timeTakenSeconds: serializer.fromJson<int>(json['timeTakenSeconds']),
      solvedAt: serializer.fromJson<int>(json['solvedAt']),
      errorTag: serializer.fromJson<String?>(json['errorTag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'examId': serializer.toJson<int?>(examId),
      'sessionId': serializer.toJson<String>(sessionId),
      'missionIndex': serializer.toJson<int>(missionIndex),
      'questionId': serializer.toJson<String>(questionId),
      'subject': serializer.toJson<String>(subject),
      'topicKey': serializer.toJson<String>(topicKey),
      'status': serializer.toJson<String>(status),
      'selectedChoiceIndex': serializer.toJson<int?>(selectedChoiceIndex),
      'timeTakenSeconds': serializer.toJson<int>(timeTakenSeconds),
      'solvedAt': serializer.toJson<int>(solvedAt),
      'errorTag': serializer.toJson<String?>(errorTag),
    };
  }

  AttemptRow copyWith({
    int? id,
    Value<int?> examId = const Value.absent(),
    String? sessionId,
    int? missionIndex,
    String? questionId,
    String? subject,
    String? topicKey,
    String? status,
    Value<int?> selectedChoiceIndex = const Value.absent(),
    int? timeTakenSeconds,
    int? solvedAt,
    Value<String?> errorTag = const Value.absent(),
  }) => AttemptRow(
    id: id ?? this.id,
    examId: examId.present ? examId.value : this.examId,
    sessionId: sessionId ?? this.sessionId,
    missionIndex: missionIndex ?? this.missionIndex,
    questionId: questionId ?? this.questionId,
    subject: subject ?? this.subject,
    topicKey: topicKey ?? this.topicKey,
    status: status ?? this.status,
    selectedChoiceIndex: selectedChoiceIndex.present
        ? selectedChoiceIndex.value
        : this.selectedChoiceIndex,
    timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
    solvedAt: solvedAt ?? this.solvedAt,
    errorTag: errorTag.present ? errorTag.value : this.errorTag,
  );
  AttemptRow copyWithCompanion(AttemptsCompanion data) {
    return AttemptRow(
      id: data.id.present ? data.id.value : this.id,
      examId: data.examId.present ? data.examId.value : this.examId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      missionIndex: data.missionIndex.present
          ? data.missionIndex.value
          : this.missionIndex,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      subject: data.subject.present ? data.subject.value : this.subject,
      topicKey: data.topicKey.present ? data.topicKey.value : this.topicKey,
      status: data.status.present ? data.status.value : this.status,
      selectedChoiceIndex: data.selectedChoiceIndex.present
          ? data.selectedChoiceIndex.value
          : this.selectedChoiceIndex,
      timeTakenSeconds: data.timeTakenSeconds.present
          ? data.timeTakenSeconds.value
          : this.timeTakenSeconds,
      solvedAt: data.solvedAt.present ? data.solvedAt.value : this.solvedAt,
      errorTag: data.errorTag.present ? data.errorTag.value : this.errorTag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRow(')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('sessionId: $sessionId, ')
          ..write('missionIndex: $missionIndex, ')
          ..write('questionId: $questionId, ')
          ..write('subject: $subject, ')
          ..write('topicKey: $topicKey, ')
          ..write('status: $status, ')
          ..write('selectedChoiceIndex: $selectedChoiceIndex, ')
          ..write('timeTakenSeconds: $timeTakenSeconds, ')
          ..write('solvedAt: $solvedAt, ')
          ..write('errorTag: $errorTag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    examId,
    sessionId,
    missionIndex,
    questionId,
    subject,
    topicKey,
    status,
    selectedChoiceIndex,
    timeTakenSeconds,
    solvedAt,
    errorTag,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRow &&
          other.id == this.id &&
          other.examId == this.examId &&
          other.sessionId == this.sessionId &&
          other.missionIndex == this.missionIndex &&
          other.questionId == this.questionId &&
          other.subject == this.subject &&
          other.topicKey == this.topicKey &&
          other.status == this.status &&
          other.selectedChoiceIndex == this.selectedChoiceIndex &&
          other.timeTakenSeconds == this.timeTakenSeconds &&
          other.solvedAt == this.solvedAt &&
          other.errorTag == this.errorTag);
}

class AttemptsCompanion extends UpdateCompanion<AttemptRow> {
  final Value<int> id;
  final Value<int?> examId;
  final Value<String> sessionId;
  final Value<int> missionIndex;
  final Value<String> questionId;
  final Value<String> subject;
  final Value<String> topicKey;
  final Value<String> status;
  final Value<int?> selectedChoiceIndex;
  final Value<int> timeTakenSeconds;
  final Value<int> solvedAt;
  final Value<String?> errorTag;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.examId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.missionIndex = const Value.absent(),
    this.questionId = const Value.absent(),
    this.subject = const Value.absent(),
    this.topicKey = const Value.absent(),
    this.status = const Value.absent(),
    this.selectedChoiceIndex = const Value.absent(),
    this.timeTakenSeconds = const Value.absent(),
    this.solvedAt = const Value.absent(),
    this.errorTag = const Value.absent(),
  });
  AttemptsCompanion.insert({
    this.id = const Value.absent(),
    this.examId = const Value.absent(),
    required String sessionId,
    required int missionIndex,
    required String questionId,
    required String subject,
    required String topicKey,
    required String status,
    this.selectedChoiceIndex = const Value.absent(),
    required int timeTakenSeconds,
    required int solvedAt,
    this.errorTag = const Value.absent(),
  }) : sessionId = Value(sessionId),
       missionIndex = Value(missionIndex),
       questionId = Value(questionId),
       subject = Value(subject),
       topicKey = Value(topicKey),
       status = Value(status),
       timeTakenSeconds = Value(timeTakenSeconds),
       solvedAt = Value(solvedAt);
  static Insertable<AttemptRow> custom({
    Expression<int>? id,
    Expression<int>? examId,
    Expression<String>? sessionId,
    Expression<int>? missionIndex,
    Expression<String>? questionId,
    Expression<String>? subject,
    Expression<String>? topicKey,
    Expression<String>? status,
    Expression<int>? selectedChoiceIndex,
    Expression<int>? timeTakenSeconds,
    Expression<int>? solvedAt,
    Expression<String>? errorTag,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (examId != null) 'exam_id': examId,
      if (sessionId != null) 'session_id': sessionId,
      if (missionIndex != null) 'mission_index': missionIndex,
      if (questionId != null) 'question_id': questionId,
      if (subject != null) 'subject': subject,
      if (topicKey != null) 'topic_key': topicKey,
      if (status != null) 'status': status,
      if (selectedChoiceIndex != null)
        'selected_choice_index': selectedChoiceIndex,
      if (timeTakenSeconds != null) 'time_taken_seconds': timeTakenSeconds,
      if (solvedAt != null) 'solved_at': solvedAt,
      if (errorTag != null) 'error_tag': errorTag,
    });
  }

  AttemptsCompanion copyWith({
    Value<int>? id,
    Value<int?>? examId,
    Value<String>? sessionId,
    Value<int>? missionIndex,
    Value<String>? questionId,
    Value<String>? subject,
    Value<String>? topicKey,
    Value<String>? status,
    Value<int?>? selectedChoiceIndex,
    Value<int>? timeTakenSeconds,
    Value<int>? solvedAt,
    Value<String?>? errorTag,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      sessionId: sessionId ?? this.sessionId,
      missionIndex: missionIndex ?? this.missionIndex,
      questionId: questionId ?? this.questionId,
      subject: subject ?? this.subject,
      topicKey: topicKey ?? this.topicKey,
      status: status ?? this.status,
      selectedChoiceIndex: selectedChoiceIndex ?? this.selectedChoiceIndex,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      solvedAt: solvedAt ?? this.solvedAt,
      errorTag: errorTag ?? this.errorTag,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<int>(examId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (missionIndex.present) {
      map['mission_index'] = Variable<int>(missionIndex.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topicKey.present) {
      map['topic_key'] = Variable<String>(topicKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (selectedChoiceIndex.present) {
      map['selected_choice_index'] = Variable<int>(selectedChoiceIndex.value);
    }
    if (timeTakenSeconds.present) {
      map['time_taken_seconds'] = Variable<int>(timeTakenSeconds.value);
    }
    if (solvedAt.present) {
      map['solved_at'] = Variable<int>(solvedAt.value);
    }
    if (errorTag.present) {
      map['error_tag'] = Variable<String>(errorTag.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('examId: $examId, ')
          ..write('sessionId: $sessionId, ')
          ..write('missionIndex: $missionIndex, ')
          ..write('questionId: $questionId, ')
          ..write('subject: $subject, ')
          ..write('topicKey: $topicKey, ')
          ..write('status: $status, ')
          ..write('selectedChoiceIndex: $selectedChoiceIndex, ')
          ..write('timeTakenSeconds: $timeTakenSeconds, ')
          ..write('solvedAt: $solvedAt, ')
          ..write('errorTag: $errorTag')
          ..write(')'))
        .toString();
  }
}

class $MissionQueueItemsTable extends MissionQueueItems
    with TableInfo<$MissionQueueItemsTable, MissionQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MissionQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<int> examId = GeneratedColumn<int>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [examId, position, questionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mission_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MissionQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId, position};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {examId, questionId},
  ];
  @override
  MissionQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MissionQueueRow(
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exam_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
    );
  }

  @override
  $MissionQueueItemsTable createAlias(String alias) {
    return $MissionQueueItemsTable(attachedDatabase, alias);
  }
}

class MissionQueueRow extends DataClass implements Insertable<MissionQueueRow> {
  final int examId;
  final int position;
  final String questionId;
  const MissionQueueRow({
    required this.examId,
    required this.position,
    required this.questionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exam_id'] = Variable<int>(examId);
    map['position'] = Variable<int>(position);
    map['question_id'] = Variable<String>(questionId);
    return map;
  }

  MissionQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return MissionQueueItemsCompanion(
      examId: Value(examId),
      position: Value(position),
      questionId: Value(questionId),
    );
  }

  factory MissionQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MissionQueueRow(
      examId: serializer.fromJson<int>(json['examId']),
      position: serializer.fromJson<int>(json['position']),
      questionId: serializer.fromJson<String>(json['questionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examId': serializer.toJson<int>(examId),
      'position': serializer.toJson<int>(position),
      'questionId': serializer.toJson<String>(questionId),
    };
  }

  MissionQueueRow copyWith({int? examId, int? position, String? questionId}) =>
      MissionQueueRow(
        examId: examId ?? this.examId,
        position: position ?? this.position,
        questionId: questionId ?? this.questionId,
      );
  MissionQueueRow copyWithCompanion(MissionQueueItemsCompanion data) {
    return MissionQueueRow(
      examId: data.examId.present ? data.examId.value : this.examId,
      position: data.position.present ? data.position.value : this.position,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MissionQueueRow(')
          ..write('examId: $examId, ')
          ..write('position: $position, ')
          ..write('questionId: $questionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(examId, position, questionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissionQueueRow &&
          other.examId == this.examId &&
          other.position == this.position &&
          other.questionId == this.questionId);
}

class MissionQueueItemsCompanion extends UpdateCompanion<MissionQueueRow> {
  final Value<int> examId;
  final Value<int> position;
  final Value<String> questionId;
  final Value<int> rowid;
  const MissionQueueItemsCompanion({
    this.examId = const Value.absent(),
    this.position = const Value.absent(),
    this.questionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MissionQueueItemsCompanion.insert({
    required int examId,
    required int position,
    required String questionId,
    this.rowid = const Value.absent(),
  }) : examId = Value(examId),
       position = Value(position),
       questionId = Value(questionId);
  static Insertable<MissionQueueRow> custom({
    Expression<int>? examId,
    Expression<int>? position,
    Expression<String>? questionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examId != null) 'exam_id': examId,
      if (position != null) 'position': position,
      if (questionId != null) 'question_id': questionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MissionQueueItemsCompanion copyWith({
    Value<int>? examId,
    Value<int>? position,
    Value<String>? questionId,
    Value<int>? rowid,
  }) {
    return MissionQueueItemsCompanion(
      examId: examId ?? this.examId,
      position: position ?? this.position,
      questionId: questionId ?? this.questionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examId.present) {
      map['exam_id'] = Variable<int>(examId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MissionQueueItemsCompanion(')
          ..write('examId: $examId, ')
          ..write('position: $position, ')
          ..write('questionId: $questionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SrsStatesTable extends SrsStates
    with TableInfo<$SrsStatesTable, SrsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _easeMeta = const VerificationMeta('ease');
  @override
  late final GeneratedColumn<double> ease = GeneratedColumn<double>(
    'ease',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    ease,
    intervalDays,
    reps,
    lapses,
    dueAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<SrsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('ease')) {
      context.handle(
        _easeMeta,
        ease.isAcceptableOrUnknown(data['ease']!, _easeMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  SrsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsRow(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      ease: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SrsStatesTable createAlias(String alias) {
    return $SrsStatesTable(attachedDatabase, alias);
  }
}

class SrsRow extends DataClass implements Insertable<SrsRow> {
  final String questionId;
  final double ease;
  final int intervalDays;
  final int reps;
  final int lapses;
  final int dueAt;
  final int updatedAt;
  const SrsRow({
    required this.questionId,
    required this.ease,
    required this.intervalDays,
    required this.reps,
    required this.lapses,
    required this.dueAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    map['ease'] = Variable<double>(ease);
    map['interval_days'] = Variable<int>(intervalDays);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['due_at'] = Variable<int>(dueAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SrsStatesCompanion toCompanion(bool nullToAbsent) {
    return SrsStatesCompanion(
      questionId: Value(questionId),
      ease: Value(ease),
      intervalDays: Value(intervalDays),
      reps: Value(reps),
      lapses: Value(lapses),
      dueAt: Value(dueAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SrsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsRow(
      questionId: serializer.fromJson<String>(json['questionId']),
      ease: serializer.fromJson<double>(json['ease']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'ease': serializer.toJson<double>(ease),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'dueAt': serializer.toJson<int>(dueAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SrsRow copyWith({
    String? questionId,
    double? ease,
    int? intervalDays,
    int? reps,
    int? lapses,
    int? dueAt,
    int? updatedAt,
  }) => SrsRow(
    questionId: questionId ?? this.questionId,
    ease: ease ?? this.ease,
    intervalDays: intervalDays ?? this.intervalDays,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    dueAt: dueAt ?? this.dueAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SrsRow copyWithCompanion(SrsStatesCompanion data) {
    return SrsRow(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      ease: data.ease.present ? data.ease.value : this.ease,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsRow(')
          ..write('questionId: $questionId, ')
          ..write('ease: $ease, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('dueAt: $dueAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questionId,
    ease,
    intervalDays,
    reps,
    lapses,
    dueAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsRow &&
          other.questionId == this.questionId &&
          other.ease == this.ease &&
          other.intervalDays == this.intervalDays &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.dueAt == this.dueAt &&
          other.updatedAt == this.updatedAt);
}

class SrsStatesCompanion extends UpdateCompanion<SrsRow> {
  final Value<String> questionId;
  final Value<double> ease;
  final Value<int> intervalDays;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> dueAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SrsStatesCompanion({
    this.questionId = const Value.absent(),
    this.ease = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SrsStatesCompanion.insert({
    required String questionId,
    this.ease = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    required int dueAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId),
       dueAt = Value(dueAt),
       updatedAt = Value(updatedAt);
  static Insertable<SrsRow> custom({
    Expression<String>? questionId,
    Expression<double>? ease,
    Expression<int>? intervalDays,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? dueAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (ease != null) 'ease': ease,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (dueAt != null) 'due_at': dueAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SrsStatesCompanion copyWith({
    Value<String>? questionId,
    Value<double>? ease,
    Value<int>? intervalDays,
    Value<int>? reps,
    Value<int>? lapses,
    Value<int>? dueAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SrsStatesCompanion(
      questionId: questionId ?? this.questionId,
      ease: ease ?? this.ease,
      intervalDays: intervalDays ?? this.intervalDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      dueAt: dueAt ?? this.dueAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (ease.present) {
      map['ease'] = Variable<double>(ease.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsStatesCompanion(')
          ..write('questionId: $questionId, ')
          ..write('ease: $ease, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('dueAt: $dueAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GamificationEventsTable extends GamificationEvents
    with TableInfo<$GamificationEventsTable, GamificationEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamificationEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicKeyMeta = const VerificationMeta(
    'topicKey',
  );
  @override
  late final GeneratedColumn<String> topicKey = GeneratedColumn<String>(
    'topic_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<int> examId = GeneratedColumn<int>(
    'exam_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id)',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionMeta = const VerificationMeta(
    'ruleVersion',
  );
  @override
  late final GeneratedColumn<int> ruleVersion = GeneratedColumn<int>(
    'rule_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    subject,
    topicKey,
    examId,
    questionId,
    dayKey,
    createdAt,
    ruleVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gamification_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<GamificationEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('topic_key')) {
      context.handle(
        _topicKeyMeta,
        topicKey.isAcceptableOrUnknown(data['topic_key']!, _topicKeyMeta),
      );
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('rule_version')) {
      context.handle(
        _ruleVersionMeta,
        ruleVersion.isAcceptableOrUnknown(
          data['rule_version']!,
          _ruleVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GamificationEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GamificationEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      topicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_key'],
      ),
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exam_id'],
      ),
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      ),
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      ruleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule_version'],
      )!,
    );
  }

  @override
  $GamificationEventsTable createAlias(String alias) {
    return $GamificationEventsTable(attachedDatabase, alias);
  }
}

class GamificationEventRow extends DataClass
    implements Insertable<GamificationEventRow> {
  final String id;
  final String type;
  final String? subject;
  final String? topicKey;
  final int? examId;
  final String? questionId;
  final String dayKey;
  final int createdAt;
  final int ruleVersion;
  const GamificationEventRow({
    required this.id,
    required this.type,
    this.subject,
    this.topicKey,
    this.examId,
    this.questionId,
    required this.dayKey,
    required this.createdAt,
    required this.ruleVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || topicKey != null) {
      map['topic_key'] = Variable<String>(topicKey);
    }
    if (!nullToAbsent || examId != null) {
      map['exam_id'] = Variable<int>(examId);
    }
    if (!nullToAbsent || questionId != null) {
      map['question_id'] = Variable<String>(questionId);
    }
    map['day_key'] = Variable<String>(dayKey);
    map['created_at'] = Variable<int>(createdAt);
    map['rule_version'] = Variable<int>(ruleVersion);
    return map;
  }

  GamificationEventsCompanion toCompanion(bool nullToAbsent) {
    return GamificationEventsCompanion(
      id: Value(id),
      type: Value(type),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      topicKey: topicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(topicKey),
      examId: examId == null && nullToAbsent
          ? const Value.absent()
          : Value(examId),
      questionId: questionId == null && nullToAbsent
          ? const Value.absent()
          : Value(questionId),
      dayKey: Value(dayKey),
      createdAt: Value(createdAt),
      ruleVersion: Value(ruleVersion),
    );
  }

  factory GamificationEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GamificationEventRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      subject: serializer.fromJson<String?>(json['subject']),
      topicKey: serializer.fromJson<String?>(json['topicKey']),
      examId: serializer.fromJson<int?>(json['examId']),
      questionId: serializer.fromJson<String?>(json['questionId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      ruleVersion: serializer.fromJson<int>(json['ruleVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'subject': serializer.toJson<String?>(subject),
      'topicKey': serializer.toJson<String?>(topicKey),
      'examId': serializer.toJson<int?>(examId),
      'questionId': serializer.toJson<String?>(questionId),
      'dayKey': serializer.toJson<String>(dayKey),
      'createdAt': serializer.toJson<int>(createdAt),
      'ruleVersion': serializer.toJson<int>(ruleVersion),
    };
  }

  GamificationEventRow copyWith({
    String? id,
    String? type,
    Value<String?> subject = const Value.absent(),
    Value<String?> topicKey = const Value.absent(),
    Value<int?> examId = const Value.absent(),
    Value<String?> questionId = const Value.absent(),
    String? dayKey,
    int? createdAt,
    int? ruleVersion,
  }) => GamificationEventRow(
    id: id ?? this.id,
    type: type ?? this.type,
    subject: subject.present ? subject.value : this.subject,
    topicKey: topicKey.present ? topicKey.value : this.topicKey,
    examId: examId.present ? examId.value : this.examId,
    questionId: questionId.present ? questionId.value : this.questionId,
    dayKey: dayKey ?? this.dayKey,
    createdAt: createdAt ?? this.createdAt,
    ruleVersion: ruleVersion ?? this.ruleVersion,
  );
  GamificationEventRow copyWithCompanion(GamificationEventsCompanion data) {
    return GamificationEventRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      subject: data.subject.present ? data.subject.value : this.subject,
      topicKey: data.topicKey.present ? data.topicKey.value : this.topicKey,
      examId: data.examId.present ? data.examId.value : this.examId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      ruleVersion: data.ruleVersion.present
          ? data.ruleVersion.value
          : this.ruleVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GamificationEventRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('subject: $subject, ')
          ..write('topicKey: $topicKey, ')
          ..write('examId: $examId, ')
          ..write('questionId: $questionId, ')
          ..write('dayKey: $dayKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('ruleVersion: $ruleVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    subject,
    topicKey,
    examId,
    questionId,
    dayKey,
    createdAt,
    ruleVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GamificationEventRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.subject == this.subject &&
          other.topicKey == this.topicKey &&
          other.examId == this.examId &&
          other.questionId == this.questionId &&
          other.dayKey == this.dayKey &&
          other.createdAt == this.createdAt &&
          other.ruleVersion == this.ruleVersion);
}

class GamificationEventsCompanion
    extends UpdateCompanion<GamificationEventRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String?> subject;
  final Value<String?> topicKey;
  final Value<int?> examId;
  final Value<String?> questionId;
  final Value<String> dayKey;
  final Value<int> createdAt;
  final Value<int> ruleVersion;
  final Value<int> rowid;
  const GamificationEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.subject = const Value.absent(),
    this.topicKey = const Value.absent(),
    this.examId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GamificationEventsCompanion.insert({
    required String id,
    required String type,
    this.subject = const Value.absent(),
    this.topicKey = const Value.absent(),
    this.examId = const Value.absent(),
    this.questionId = const Value.absent(),
    required String dayKey,
    required int createdAt,
    this.ruleVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       dayKey = Value(dayKey),
       createdAt = Value(createdAt);
  static Insertable<GamificationEventRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? subject,
    Expression<String>? topicKey,
    Expression<int>? examId,
    Expression<String>? questionId,
    Expression<String>? dayKey,
    Expression<int>? createdAt,
    Expression<int>? ruleVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (subject != null) 'subject': subject,
      if (topicKey != null) 'topic_key': topicKey,
      if (examId != null) 'exam_id': examId,
      if (questionId != null) 'question_id': questionId,
      if (dayKey != null) 'day_key': dayKey,
      if (createdAt != null) 'created_at': createdAt,
      if (ruleVersion != null) 'rule_version': ruleVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GamificationEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String?>? subject,
    Value<String?>? topicKey,
    Value<int?>? examId,
    Value<String?>? questionId,
    Value<String>? dayKey,
    Value<int>? createdAt,
    Value<int>? ruleVersion,
    Value<int>? rowid,
  }) {
    return GamificationEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      topicKey: topicKey ?? this.topicKey,
      examId: examId ?? this.examId,
      questionId: questionId ?? this.questionId,
      dayKey: dayKey ?? this.dayKey,
      createdAt: createdAt ?? this.createdAt,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topicKey.present) {
      map['topic_key'] = Variable<String>(topicKey.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<int>(examId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (ruleVersion.present) {
      map['rule_version'] = Variable<int>(ruleVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamificationEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('subject: $subject, ')
          ..write('topicKey: $topicKey, ')
          ..write('examId: $examId, ')
          ..write('questionId: $questionId, ')
          ..write('dayKey: $dayKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $XpTransactionsTable extends XpTransactions
    with TableInfo<$XpTransactionsTable, XpTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $XpTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES gamification_events (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    amount,
    category,
    reason,
    dayKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'xp_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<XpTransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  XpTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return XpTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $XpTransactionsTable createAlias(String alias) {
    return $XpTransactionsTable(attachedDatabase, alias);
  }
}

class XpTransactionRow extends DataClass
    implements Insertable<XpTransactionRow> {
  final String id;
  final String eventId;
  final int amount;
  final String category;
  final String reason;
  final String dayKey;
  final int createdAt;
  const XpTransactionRow({
    required this.id,
    required this.eventId,
    required this.amount,
    required this.category,
    required this.reason,
    required this.dayKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['amount'] = Variable<int>(amount);
    map['category'] = Variable<String>(category);
    map['reason'] = Variable<String>(reason);
    map['day_key'] = Variable<String>(dayKey);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  XpTransactionsCompanion toCompanion(bool nullToAbsent) {
    return XpTransactionsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      amount: Value(amount),
      category: Value(category),
      reason: Value(reason),
      dayKey: Value(dayKey),
      createdAt: Value(createdAt),
    );
  }

  factory XpTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return XpTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      amount: serializer.fromJson<int>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      reason: serializer.fromJson<String>(json['reason']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'amount': serializer.toJson<int>(amount),
      'category': serializer.toJson<String>(category),
      'reason': serializer.toJson<String>(reason),
      'dayKey': serializer.toJson<String>(dayKey),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  XpTransactionRow copyWith({
    String? id,
    String? eventId,
    int? amount,
    String? category,
    String? reason,
    String? dayKey,
    int? createdAt,
  }) => XpTransactionRow(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    reason: reason ?? this.reason,
    dayKey: dayKey ?? this.dayKey,
    createdAt: createdAt ?? this.createdAt,
  );
  XpTransactionRow copyWithCompanion(XpTransactionsCompanion data) {
    return XpTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      reason: data.reason.present ? data.reason.value : this.reason,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('XpTransactionRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('reason: $reason, ')
          ..write('dayKey: $dayKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventId, amount, category, reason, dayKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XpTransactionRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.reason == this.reason &&
          other.dayKey == this.dayKey &&
          other.createdAt == this.createdAt);
}

class XpTransactionsCompanion extends UpdateCompanion<XpTransactionRow> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<int> amount;
  final Value<String> category;
  final Value<String> reason;
  final Value<String> dayKey;
  final Value<int> createdAt;
  final Value<int> rowid;
  const XpTransactionsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.reason = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  XpTransactionsCompanion.insert({
    required String id,
    required String eventId,
    required int amount,
    required String category,
    required String reason,
    required String dayKey,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventId = Value(eventId),
       amount = Value(amount),
       category = Value(category),
       reason = Value(reason),
       dayKey = Value(dayKey),
       createdAt = Value(createdAt);
  static Insertable<XpTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<int>? amount,
    Expression<String>? category,
    Expression<String>? reason,
    Expression<String>? dayKey,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (reason != null) 'reason': reason,
      if (dayKey != null) 'day_key': dayKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  XpTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventId,
    Value<int>? amount,
    Value<String>? category,
    Value<String>? reason,
    Value<String>? dayKey,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return XpTransactionsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      reason: reason ?? this.reason,
      dayKey: dayKey ?? this.dayKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('XpTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('reason: $reason, ')
          ..write('dayKey: $dayKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestProgressTable extends QuestProgress
    with TableInfo<$QuestProgressTable, QuestProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questIdMeta = const VerificationMeta(
    'questId',
  );
  @override
  late final GeneratedColumn<String> questId = GeneratedColumn<String>(
    'quest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _rewardXpMeta = const VerificationMeta(
    'rewardXp',
  );
  @override
  late final GeneratedColumn<int> rewardXp = GeneratedColumn<int>(
    'reward_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    questId,
    dayKey,
    title,
    progress,
    target,
    completed,
    rewardXp,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quest_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('quest_id')) {
      context.handle(
        _questIdMeta,
        questId.isAcceptableOrUnknown(data['quest_id']!, _questIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('reward_xp')) {
      context.handle(
        _rewardXpMeta,
        rewardXp.isAcceptableOrUnknown(data['reward_xp']!, _rewardXpMeta),
      );
    } else if (isInserting) {
      context.missing(_rewardXpMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questId};
  @override
  QuestProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestProgressRow(
      questId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      rewardXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reward_xp'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuestProgressTable createAlias(String alias) {
    return $QuestProgressTable(attachedDatabase, alias);
  }
}

class QuestProgressRow extends DataClass
    implements Insertable<QuestProgressRow> {
  final String questId;
  final String dayKey;
  final String title;
  final int progress;
  final int target;
  final bool completed;
  final int rewardXp;
  final int updatedAt;
  const QuestProgressRow({
    required this.questId,
    required this.dayKey,
    required this.title,
    required this.progress,
    required this.target,
    required this.completed,
    required this.rewardXp,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['quest_id'] = Variable<String>(questId);
    map['day_key'] = Variable<String>(dayKey);
    map['title'] = Variable<String>(title);
    map['progress'] = Variable<int>(progress);
    map['target'] = Variable<int>(target);
    map['completed'] = Variable<bool>(completed);
    map['reward_xp'] = Variable<int>(rewardXp);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  QuestProgressCompanion toCompanion(bool nullToAbsent) {
    return QuestProgressCompanion(
      questId: Value(questId),
      dayKey: Value(dayKey),
      title: Value(title),
      progress: Value(progress),
      target: Value(target),
      completed: Value(completed),
      rewardXp: Value(rewardXp),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuestProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestProgressRow(
      questId: serializer.fromJson<String>(json['questId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      title: serializer.fromJson<String>(json['title']),
      progress: serializer.fromJson<int>(json['progress']),
      target: serializer.fromJson<int>(json['target']),
      completed: serializer.fromJson<bool>(json['completed']),
      rewardXp: serializer.fromJson<int>(json['rewardXp']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questId': serializer.toJson<String>(questId),
      'dayKey': serializer.toJson<String>(dayKey),
      'title': serializer.toJson<String>(title),
      'progress': serializer.toJson<int>(progress),
      'target': serializer.toJson<int>(target),
      'completed': serializer.toJson<bool>(completed),
      'rewardXp': serializer.toJson<int>(rewardXp),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  QuestProgressRow copyWith({
    String? questId,
    String? dayKey,
    String? title,
    int? progress,
    int? target,
    bool? completed,
    int? rewardXp,
    int? updatedAt,
  }) => QuestProgressRow(
    questId: questId ?? this.questId,
    dayKey: dayKey ?? this.dayKey,
    title: title ?? this.title,
    progress: progress ?? this.progress,
    target: target ?? this.target,
    completed: completed ?? this.completed,
    rewardXp: rewardXp ?? this.rewardXp,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuestProgressRow copyWithCompanion(QuestProgressCompanion data) {
    return QuestProgressRow(
      questId: data.questId.present ? data.questId.value : this.questId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      title: data.title.present ? data.title.value : this.title,
      progress: data.progress.present ? data.progress.value : this.progress,
      target: data.target.present ? data.target.value : this.target,
      completed: data.completed.present ? data.completed.value : this.completed,
      rewardXp: data.rewardXp.present ? data.rewardXp.value : this.rewardXp,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestProgressRow(')
          ..write('questId: $questId, ')
          ..write('dayKey: $dayKey, ')
          ..write('title: $title, ')
          ..write('progress: $progress, ')
          ..write('target: $target, ')
          ..write('completed: $completed, ')
          ..write('rewardXp: $rewardXp, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questId,
    dayKey,
    title,
    progress,
    target,
    completed,
    rewardXp,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestProgressRow &&
          other.questId == this.questId &&
          other.dayKey == this.dayKey &&
          other.title == this.title &&
          other.progress == this.progress &&
          other.target == this.target &&
          other.completed == this.completed &&
          other.rewardXp == this.rewardXp &&
          other.updatedAt == this.updatedAt);
}

class QuestProgressCompanion extends UpdateCompanion<QuestProgressRow> {
  final Value<String> questId;
  final Value<String> dayKey;
  final Value<String> title;
  final Value<int> progress;
  final Value<int> target;
  final Value<bool> completed;
  final Value<int> rewardXp;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const QuestProgressCompanion({
    this.questId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.title = const Value.absent(),
    this.progress = const Value.absent(),
    this.target = const Value.absent(),
    this.completed = const Value.absent(),
    this.rewardXp = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestProgressCompanion.insert({
    required String questId,
    required String dayKey,
    required String title,
    required int progress,
    required int target,
    required bool completed,
    required int rewardXp,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : questId = Value(questId),
       dayKey = Value(dayKey),
       title = Value(title),
       progress = Value(progress),
       target = Value(target),
       completed = Value(completed),
       rewardXp = Value(rewardXp),
       updatedAt = Value(updatedAt);
  static Insertable<QuestProgressRow> custom({
    Expression<String>? questId,
    Expression<String>? dayKey,
    Expression<String>? title,
    Expression<int>? progress,
    Expression<int>? target,
    Expression<bool>? completed,
    Expression<int>? rewardXp,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questId != null) 'quest_id': questId,
      if (dayKey != null) 'day_key': dayKey,
      if (title != null) 'title': title,
      if (progress != null) 'progress': progress,
      if (target != null) 'target': target,
      if (completed != null) 'completed': completed,
      if (rewardXp != null) 'reward_xp': rewardXp,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestProgressCompanion copyWith({
    Value<String>? questId,
    Value<String>? dayKey,
    Value<String>? title,
    Value<int>? progress,
    Value<int>? target,
    Value<bool>? completed,
    Value<int>? rewardXp,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuestProgressCompanion(
      questId: questId ?? this.questId,
      dayKey: dayKey ?? this.dayKey,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      completed: completed ?? this.completed,
      rewardXp: rewardXp ?? this.rewardXp,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questId.present) {
      map['quest_id'] = Variable<String>(questId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rewardXp.present) {
      map['reward_xp'] = Variable<int>(rewardXp.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestProgressCompanion(')
          ..write('questId: $questId, ')
          ..write('dayKey: $dayKey, ')
          ..write('title: $title, ')
          ..write('progress: $progress, ')
          ..write('target: $target, ')
          ..write('completed: $completed, ')
          ..write('rewardXp: $rewardXp, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementProgressTable extends AchievementProgress
    with TableInfo<$AchievementProgressTable, AchievementProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _achievementIdMeta = const VerificationMeta(
    'achievementId',
  );
  @override
  late final GeneratedColumn<String> achievementId = GeneratedColumn<String>(
    'achievement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentMeta = const VerificationMeta(
    'current',
  );
  @override
  late final GeneratedColumn<int> current = GeneratedColumn<int>(
    'current',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    achievementId,
    title,
    current,
    target,
    completedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievement_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<AchievementProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('achievement_id')) {
      context.handle(
        _achievementIdMeta,
        achievementId.isAcceptableOrUnknown(
          data['achievement_id']!,
          _achievementIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_achievementIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('current')) {
      context.handle(
        _currentMeta,
        current.isAcceptableOrUnknown(data['current']!, _currentMeta),
      );
    } else if (isInserting) {
      context.missing(_currentMeta);
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {achievementId};
  @override
  AchievementProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementProgressRow(
      achievementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}achievement_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      current: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AchievementProgressTable createAlias(String alias) {
    return $AchievementProgressTable(attachedDatabase, alias);
  }
}

class AchievementProgressRow extends DataClass
    implements Insertable<AchievementProgressRow> {
  final String achievementId;
  final String title;
  final int current;
  final int target;
  final int? completedAt;
  final int updatedAt;
  const AchievementProgressRow({
    required this.achievementId,
    required this.title,
    required this.current,
    required this.target,
    this.completedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['achievement_id'] = Variable<String>(achievementId);
    map['title'] = Variable<String>(title);
    map['current'] = Variable<int>(current);
    map['target'] = Variable<int>(target);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AchievementProgressCompanion toCompanion(bool nullToAbsent) {
    return AchievementProgressCompanion(
      achievementId: Value(achievementId),
      title: Value(title),
      current: Value(current),
      target: Value(target),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AchievementProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementProgressRow(
      achievementId: serializer.fromJson<String>(json['achievementId']),
      title: serializer.fromJson<String>(json['title']),
      current: serializer.fromJson<int>(json['current']),
      target: serializer.fromJson<int>(json['target']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'achievementId': serializer.toJson<String>(achievementId),
      'title': serializer.toJson<String>(title),
      'current': serializer.toJson<int>(current),
      'target': serializer.toJson<int>(target),
      'completedAt': serializer.toJson<int?>(completedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AchievementProgressRow copyWith({
    String? achievementId,
    String? title,
    int? current,
    int? target,
    Value<int?> completedAt = const Value.absent(),
    int? updatedAt,
  }) => AchievementProgressRow(
    achievementId: achievementId ?? this.achievementId,
    title: title ?? this.title,
    current: current ?? this.current,
    target: target ?? this.target,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AchievementProgressRow copyWithCompanion(AchievementProgressCompanion data) {
    return AchievementProgressRow(
      achievementId: data.achievementId.present
          ? data.achievementId.value
          : this.achievementId,
      title: data.title.present ? data.title.value : this.title,
      current: data.current.present ? data.current.value : this.current,
      target: data.target.present ? data.target.value : this.target,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementProgressRow(')
          ..write('achievementId: $achievementId, ')
          ..write('title: $title, ')
          ..write('current: $current, ')
          ..write('target: $target, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    achievementId,
    title,
    current,
    target,
    completedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementProgressRow &&
          other.achievementId == this.achievementId &&
          other.title == this.title &&
          other.current == this.current &&
          other.target == this.target &&
          other.completedAt == this.completedAt &&
          other.updatedAt == this.updatedAt);
}

class AchievementProgressCompanion
    extends UpdateCompanion<AchievementProgressRow> {
  final Value<String> achievementId;
  final Value<String> title;
  final Value<int> current;
  final Value<int> target;
  final Value<int?> completedAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AchievementProgressCompanion({
    this.achievementId = const Value.absent(),
    this.title = const Value.absent(),
    this.current = const Value.absent(),
    this.target = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementProgressCompanion.insert({
    required String achievementId,
    required String title,
    required int current,
    required int target,
    this.completedAt = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : achievementId = Value(achievementId),
       title = Value(title),
       current = Value(current),
       target = Value(target),
       updatedAt = Value(updatedAt);
  static Insertable<AchievementProgressRow> custom({
    Expression<String>? achievementId,
    Expression<String>? title,
    Expression<int>? current,
    Expression<int>? target,
    Expression<int>? completedAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (achievementId != null) 'achievement_id': achievementId,
      if (title != null) 'title': title,
      if (current != null) 'current': current,
      if (target != null) 'target': target,
      if (completedAt != null) 'completed_at': completedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementProgressCompanion copyWith({
    Value<String>? achievementId,
    Value<String>? title,
    Value<int>? current,
    Value<int>? target,
    Value<int?>? completedAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AchievementProgressCompanion(
      achievementId: achievementId ?? this.achievementId,
      title: title ?? this.title,
      current: current ?? this.current,
      target: target ?? this.target,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (achievementId.present) {
      map['achievement_id'] = Variable<String>(achievementId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (current.present) {
      map['current'] = Variable<int>(current.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementProgressCompanion(')
          ..write('achievementId: $achievementId, ')
          ..write('title: $title, ')
          ..write('current: $current, ')
          ..write('target: $target, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyRecordsTable extends StudyRecords
    with TableInfo<$StudyRecordsTable, StudyRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicKeyMeta = const VerificationMeta(
    'topicKey',
  );
  @override
  late final GeneratedColumn<String> topicKey = GeneratedColumn<String>(
    'topic_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shelfKeyMeta = const VerificationMeta(
    'shelfKey',
  );
  @override
  late final GeneratedColumn<String> shelfKey = GeneratedColumn<String>(
    'shelf_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hypothesisChoiceIndexMeta =
      const VerificationMeta('hypothesisChoiceIndex');
  @override
  late final GeneratedColumn<int> hypothesisChoiceIndex = GeneratedColumn<int>(
    'hypothesis_choice_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hypothesisMatchedMeta = const VerificationMeta(
    'hypothesisMatched',
  );
  @override
  late final GeneratedColumn<bool> hypothesisMatched = GeneratedColumn<bool>(
    'hypothesis_matched',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hypothesis_matched" IN (0, 1))',
    ),
  );
  static const VerificationMeta _reflectionMeta = const VerificationMeta(
    'reflection',
  );
  @override
  late final GeneratedColumn<String> reflection = GeneratedColumn<String>(
    'reflection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstReflectedAtMeta = const VerificationMeta(
    'firstReflectedAt',
  );
  @override
  late final GeneratedColumn<int> firstReflectedAt = GeneratedColumn<int>(
    'first_reflected_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    topicKey,
    shelfKey,
    hypothesisChoiceIndex,
    hypothesisMatched,
    reflection,
    firstReflectedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('topic_key')) {
      context.handle(
        _topicKeyMeta,
        topicKey.isAcceptableOrUnknown(data['topic_key']!, _topicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_topicKeyMeta);
    }
    if (data.containsKey('shelf_key')) {
      context.handle(
        _shelfKeyMeta,
        shelfKey.isAcceptableOrUnknown(data['shelf_key']!, _shelfKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_shelfKeyMeta);
    }
    if (data.containsKey('hypothesis_choice_index')) {
      context.handle(
        _hypothesisChoiceIndexMeta,
        hypothesisChoiceIndex.isAcceptableOrUnknown(
          data['hypothesis_choice_index']!,
          _hypothesisChoiceIndexMeta,
        ),
      );
    }
    if (data.containsKey('hypothesis_matched')) {
      context.handle(
        _hypothesisMatchedMeta,
        hypothesisMatched.isAcceptableOrUnknown(
          data['hypothesis_matched']!,
          _hypothesisMatchedMeta,
        ),
      );
    }
    if (data.containsKey('reflection')) {
      context.handle(
        _reflectionMeta,
        reflection.isAcceptableOrUnknown(data['reflection']!, _reflectionMeta),
      );
    } else if (isInserting) {
      context.missing(_reflectionMeta);
    }
    if (data.containsKey('first_reflected_at')) {
      context.handle(
        _firstReflectedAtMeta,
        firstReflectedAt.isAcceptableOrUnknown(
          data['first_reflected_at']!,
          _firstReflectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstReflectedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  StudyRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyRecordRow(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      topicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_key'],
      )!,
      shelfKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_key'],
      )!,
      hypothesisChoiceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hypothesis_choice_index'],
      ),
      hypothesisMatched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hypothesis_matched'],
      ),
      reflection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reflection'],
      )!,
      firstReflectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_reflected_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudyRecordsTable createAlias(String alias) {
    return $StudyRecordsTable(attachedDatabase, alias);
  }
}

class StudyRecordRow extends DataClass implements Insertable<StudyRecordRow> {
  final String questionId;
  final String topicKey;
  final String shelfKey;
  final int? hypothesisChoiceIndex;

  /// Whether the private hypothesis matched the source-claimed key. Recorded
  /// only as a personal alignment note — the source key is never verified, so
  /// this can never become a score.
  final bool? hypothesisMatched;
  final String reflection;
  final int firstReflectedAt;
  final int updatedAt;
  const StudyRecordRow({
    required this.questionId,
    required this.topicKey,
    required this.shelfKey,
    this.hypothesisChoiceIndex,
    this.hypothesisMatched,
    required this.reflection,
    required this.firstReflectedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    map['topic_key'] = Variable<String>(topicKey);
    map['shelf_key'] = Variable<String>(shelfKey);
    if (!nullToAbsent || hypothesisChoiceIndex != null) {
      map['hypothesis_choice_index'] = Variable<int>(hypothesisChoiceIndex);
    }
    if (!nullToAbsent || hypothesisMatched != null) {
      map['hypothesis_matched'] = Variable<bool>(hypothesisMatched);
    }
    map['reflection'] = Variable<String>(reflection);
    map['first_reflected_at'] = Variable<int>(firstReflectedAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  StudyRecordsCompanion toCompanion(bool nullToAbsent) {
    return StudyRecordsCompanion(
      questionId: Value(questionId),
      topicKey: Value(topicKey),
      shelfKey: Value(shelfKey),
      hypothesisChoiceIndex: hypothesisChoiceIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(hypothesisChoiceIndex),
      hypothesisMatched: hypothesisMatched == null && nullToAbsent
          ? const Value.absent()
          : Value(hypothesisMatched),
      reflection: Value(reflection),
      firstReflectedAt: Value(firstReflectedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudyRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyRecordRow(
      questionId: serializer.fromJson<String>(json['questionId']),
      topicKey: serializer.fromJson<String>(json['topicKey']),
      shelfKey: serializer.fromJson<String>(json['shelfKey']),
      hypothesisChoiceIndex: serializer.fromJson<int?>(
        json['hypothesisChoiceIndex'],
      ),
      hypothesisMatched: serializer.fromJson<bool?>(json['hypothesisMatched']),
      reflection: serializer.fromJson<String>(json['reflection']),
      firstReflectedAt: serializer.fromJson<int>(json['firstReflectedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'topicKey': serializer.toJson<String>(topicKey),
      'shelfKey': serializer.toJson<String>(shelfKey),
      'hypothesisChoiceIndex': serializer.toJson<int?>(hypothesisChoiceIndex),
      'hypothesisMatched': serializer.toJson<bool?>(hypothesisMatched),
      'reflection': serializer.toJson<String>(reflection),
      'firstReflectedAt': serializer.toJson<int>(firstReflectedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  StudyRecordRow copyWith({
    String? questionId,
    String? topicKey,
    String? shelfKey,
    Value<int?> hypothesisChoiceIndex = const Value.absent(),
    Value<bool?> hypothesisMatched = const Value.absent(),
    String? reflection,
    int? firstReflectedAt,
    int? updatedAt,
  }) => StudyRecordRow(
    questionId: questionId ?? this.questionId,
    topicKey: topicKey ?? this.topicKey,
    shelfKey: shelfKey ?? this.shelfKey,
    hypothesisChoiceIndex: hypothesisChoiceIndex.present
        ? hypothesisChoiceIndex.value
        : this.hypothesisChoiceIndex,
    hypothesisMatched: hypothesisMatched.present
        ? hypothesisMatched.value
        : this.hypothesisMatched,
    reflection: reflection ?? this.reflection,
    firstReflectedAt: firstReflectedAt ?? this.firstReflectedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudyRecordRow copyWithCompanion(StudyRecordsCompanion data) {
    return StudyRecordRow(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      topicKey: data.topicKey.present ? data.topicKey.value : this.topicKey,
      shelfKey: data.shelfKey.present ? data.shelfKey.value : this.shelfKey,
      hypothesisChoiceIndex: data.hypothesisChoiceIndex.present
          ? data.hypothesisChoiceIndex.value
          : this.hypothesisChoiceIndex,
      hypothesisMatched: data.hypothesisMatched.present
          ? data.hypothesisMatched.value
          : this.hypothesisMatched,
      reflection: data.reflection.present
          ? data.reflection.value
          : this.reflection,
      firstReflectedAt: data.firstReflectedAt.present
          ? data.firstReflectedAt.value
          : this.firstReflectedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyRecordRow(')
          ..write('questionId: $questionId, ')
          ..write('topicKey: $topicKey, ')
          ..write('shelfKey: $shelfKey, ')
          ..write('hypothesisChoiceIndex: $hypothesisChoiceIndex, ')
          ..write('hypothesisMatched: $hypothesisMatched, ')
          ..write('reflection: $reflection, ')
          ..write('firstReflectedAt: $firstReflectedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questionId,
    topicKey,
    shelfKey,
    hypothesisChoiceIndex,
    hypothesisMatched,
    reflection,
    firstReflectedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyRecordRow &&
          other.questionId == this.questionId &&
          other.topicKey == this.topicKey &&
          other.shelfKey == this.shelfKey &&
          other.hypothesisChoiceIndex == this.hypothesisChoiceIndex &&
          other.hypothesisMatched == this.hypothesisMatched &&
          other.reflection == this.reflection &&
          other.firstReflectedAt == this.firstReflectedAt &&
          other.updatedAt == this.updatedAt);
}

class StudyRecordsCompanion extends UpdateCompanion<StudyRecordRow> {
  final Value<String> questionId;
  final Value<String> topicKey;
  final Value<String> shelfKey;
  final Value<int?> hypothesisChoiceIndex;
  final Value<bool?> hypothesisMatched;
  final Value<String> reflection;
  final Value<int> firstReflectedAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const StudyRecordsCompanion({
    this.questionId = const Value.absent(),
    this.topicKey = const Value.absent(),
    this.shelfKey = const Value.absent(),
    this.hypothesisChoiceIndex = const Value.absent(),
    this.hypothesisMatched = const Value.absent(),
    this.reflection = const Value.absent(),
    this.firstReflectedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyRecordsCompanion.insert({
    required String questionId,
    required String topicKey,
    required String shelfKey,
    this.hypothesisChoiceIndex = const Value.absent(),
    this.hypothesisMatched = const Value.absent(),
    required String reflection,
    required int firstReflectedAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId),
       topicKey = Value(topicKey),
       shelfKey = Value(shelfKey),
       reflection = Value(reflection),
       firstReflectedAt = Value(firstReflectedAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudyRecordRow> custom({
    Expression<String>? questionId,
    Expression<String>? topicKey,
    Expression<String>? shelfKey,
    Expression<int>? hypothesisChoiceIndex,
    Expression<bool>? hypothesisMatched,
    Expression<String>? reflection,
    Expression<int>? firstReflectedAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (topicKey != null) 'topic_key': topicKey,
      if (shelfKey != null) 'shelf_key': shelfKey,
      if (hypothesisChoiceIndex != null)
        'hypothesis_choice_index': hypothesisChoiceIndex,
      if (hypothesisMatched != null) 'hypothesis_matched': hypothesisMatched,
      if (reflection != null) 'reflection': reflection,
      if (firstReflectedAt != null) 'first_reflected_at': firstReflectedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyRecordsCompanion copyWith({
    Value<String>? questionId,
    Value<String>? topicKey,
    Value<String>? shelfKey,
    Value<int?>? hypothesisChoiceIndex,
    Value<bool?>? hypothesisMatched,
    Value<String>? reflection,
    Value<int>? firstReflectedAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return StudyRecordsCompanion(
      questionId: questionId ?? this.questionId,
      topicKey: topicKey ?? this.topicKey,
      shelfKey: shelfKey ?? this.shelfKey,
      hypothesisChoiceIndex:
          hypothesisChoiceIndex ?? this.hypothesisChoiceIndex,
      hypothesisMatched: hypothesisMatched ?? this.hypothesisMatched,
      reflection: reflection ?? this.reflection,
      firstReflectedAt: firstReflectedAt ?? this.firstReflectedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (topicKey.present) {
      map['topic_key'] = Variable<String>(topicKey.value);
    }
    if (shelfKey.present) {
      map['shelf_key'] = Variable<String>(shelfKey.value);
    }
    if (hypothesisChoiceIndex.present) {
      map['hypothesis_choice_index'] = Variable<int>(
        hypothesisChoiceIndex.value,
      );
    }
    if (hypothesisMatched.present) {
      map['hypothesis_matched'] = Variable<bool>(hypothesisMatched.value);
    }
    if (reflection.present) {
      map['reflection'] = Variable<String>(reflection.value);
    }
    if (firstReflectedAt.present) {
      map['first_reflected_at'] = Variable<int>(firstReflectedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyRecordsCompanion(')
          ..write('questionId: $questionId, ')
          ..write('topicKey: $topicKey, ')
          ..write('shelfKey: $shelfKey, ')
          ..write('hypothesisChoiceIndex: $hypothesisChoiceIndex, ')
          ..write('hypothesisMatched: $hypothesisMatched, ')
          ..write('reflection: $reflection, ')
          ..write('firstReflectedAt: $firstReflectedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyPositionsTable extends StudyPositions
    with TableInfo<$StudyPositionsTable, StudyPositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shelfKeyMeta = const VerificationMeta(
    'shelfKey',
  );
  @override
  late final GeneratedColumn<String> shelfKey = GeneratedColumn<String>(
    'shelf_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    shelfKey,
    questionId,
    position,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyPositionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shelf_key')) {
      context.handle(
        _shelfKeyMeta,
        shelfKey.isAcceptableOrUnknown(data['shelf_key']!, _shelfKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_shelfKeyMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shelfKey};
  @override
  StudyPositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyPositionRow(
      shelfKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_key'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudyPositionsTable createAlias(String alias) {
    return $StudyPositionsTable(attachedDatabase, alias);
  }
}

class StudyPositionRow extends DataClass
    implements Insertable<StudyPositionRow> {
  final String shelfKey;
  final String questionId;
  final int position;
  final int updatedAt;
  const StudyPositionRow({
    required this.shelfKey,
    required this.questionId,
    required this.position,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shelf_key'] = Variable<String>(shelfKey);
    map['question_id'] = Variable<String>(questionId);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  StudyPositionsCompanion toCompanion(bool nullToAbsent) {
    return StudyPositionsCompanion(
      shelfKey: Value(shelfKey),
      questionId: Value(questionId),
      position: Value(position),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudyPositionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyPositionRow(
      shelfKey: serializer.fromJson<String>(json['shelfKey']),
      questionId: serializer.fromJson<String>(json['questionId']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shelfKey': serializer.toJson<String>(shelfKey),
      'questionId': serializer.toJson<String>(questionId),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  StudyPositionRow copyWith({
    String? shelfKey,
    String? questionId,
    int? position,
    int? updatedAt,
  }) => StudyPositionRow(
    shelfKey: shelfKey ?? this.shelfKey,
    questionId: questionId ?? this.questionId,
    position: position ?? this.position,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudyPositionRow copyWithCompanion(StudyPositionsCompanion data) {
    return StudyPositionRow(
      shelfKey: data.shelfKey.present ? data.shelfKey.value : this.shelfKey,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyPositionRow(')
          ..write('shelfKey: $shelfKey, ')
          ..write('questionId: $questionId, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shelfKey, questionId, position, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyPositionRow &&
          other.shelfKey == this.shelfKey &&
          other.questionId == this.questionId &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt);
}

class StudyPositionsCompanion extends UpdateCompanion<StudyPositionRow> {
  final Value<String> shelfKey;
  final Value<String> questionId;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const StudyPositionsCompanion({
    this.shelfKey = const Value.absent(),
    this.questionId = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyPositionsCompanion.insert({
    required String shelfKey,
    required String questionId,
    required int position,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : shelfKey = Value(shelfKey),
       questionId = Value(questionId),
       position = Value(position),
       updatedAt = Value(updatedAt);
  static Insertable<StudyPositionRow> custom({
    Expression<String>? shelfKey,
    Expression<String>? questionId,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shelfKey != null) 'shelf_key': shelfKey,
      if (questionId != null) 'question_id': questionId,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyPositionsCompanion copyWith({
    Value<String>? shelfKey,
    Value<String>? questionId,
    Value<int>? position,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return StudyPositionsCompanion(
      shelfKey: shelfKey ?? this.shelfKey,
      questionId: questionId ?? this.questionId,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shelfKey.present) {
      map['shelf_key'] = Variable<String>(shelfKey.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyPositionsCompanion(')
          ..write('shelfKey: $shelfKey, ')
          ..write('questionId: $questionId, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$GaussDatabase extends GeneratedDatabase {
  _$GaussDatabase(QueryExecutor e) : super(e);
  $GaussDatabaseManager get managers => $GaussDatabaseManager(this);
  late final $ExamsTable exams = $ExamsTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $MissionQueueItemsTable missionQueueItems =
      $MissionQueueItemsTable(this);
  late final $SrsStatesTable srsStates = $SrsStatesTable(this);
  late final $GamificationEventsTable gamificationEvents =
      $GamificationEventsTable(this);
  late final $XpTransactionsTable xpTransactions = $XpTransactionsTable(this);
  late final $QuestProgressTable questProgress = $QuestProgressTable(this);
  late final $AchievementProgressTable achievementProgress =
      $AchievementProgressTable(this);
  late final $StudyRecordsTable studyRecords = $StudyRecordsTable(this);
  late final $StudyPositionsTable studyPositions = $StudyPositionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exams,
    attempts,
    missionQueueItems,
    srsStates,
    gamificationEvents,
    xpTransactions,
    questProgress,
    achievementProgress,
    studyRecords,
    studyPositions,
  ];
}

typedef $$ExamsTableCreateCompanionBuilder =
    ExamsCompanion Function({
      Value<int> id,
      required String sessionId,
      required String subject,
      Value<String?> topicKey,
      Value<int> totalQuestions,
      Value<int> correctCount,
      Value<int> wrongCount,
      Value<int> skippedCount,
      Value<double> scorePercentage,
      Value<int> durationSeconds,
      Value<String> status,
      required int createdAt,
      Value<int?> completedAt,
    });
typedef $$ExamsTableUpdateCompanionBuilder =
    ExamsCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<String> subject,
      Value<String?> topicKey,
      Value<int> totalQuestions,
      Value<int> correctCount,
      Value<int> wrongCount,
      Value<int> skippedCount,
      Value<double> scorePercentage,
      Value<int> durationSeconds,
      Value<String> status,
      Value<int> createdAt,
      Value<int?> completedAt,
    });

final class $$ExamsTableReferences
    extends BaseReferences<_$GaussDatabase, $ExamsTable, ExamRow> {
  $$ExamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AttemptsTable, List<AttemptRow>>
  _attemptsRefsTable(_$GaussDatabase db) => MultiTypedResultKey.fromTable(
    db.attempts,
    aliasName: 'exams__id__attempts__exam_id',
  );

  $$AttemptsTableProcessedTableManager get attemptsRefs {
    final manager = $$AttemptsTableTableManager(
      $_db,
      $_db.attempts,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attemptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MissionQueueItemsTable, List<MissionQueueRow>>
  _missionQueueItemsRefsTable(_$GaussDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.missionQueueItems,
        aliasName: 'exams__id__mission_queue_items__exam_id',
      );

  $$MissionQueueItemsTableProcessedTableManager get missionQueueItemsRefs {
    final manager = $$MissionQueueItemsTableTableManager(
      $_db,
      $_db.missionQueueItems,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _missionQueueItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $GamificationEventsTable,
    List<GamificationEventRow>
  >
  _gamificationEventsRefsTable(_$GaussDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.gamificationEvents,
        aliasName: 'exams__id__gamification_events__exam_id',
      );

  $$GamificationEventsTableProcessedTableManager get gamificationEventsRefs {
    final manager = $$GamificationEventsTableTableManager(
      $_db,
      $_db.gamificationEvents,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _gamificationEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExamsTableFilterComposer
    extends Composer<_$GaussDatabase, $ExamsTable> {
  $$ExamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicKey => $composableBuilder(
    column: $table.topicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skippedCount => $composableBuilder(
    column: $table.skippedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scorePercentage => $composableBuilder(
    column: $table.scorePercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> attemptsRefs(
    Expression<bool> Function($$AttemptsTableFilterComposer f) f,
  ) {
    final $$AttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableFilterComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> missionQueueItemsRefs(
    Expression<bool> Function($$MissionQueueItemsTableFilterComposer f) f,
  ) {
    final $$MissionQueueItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.missionQueueItems,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MissionQueueItemsTableFilterComposer(
            $db: $db,
            $table: $db.missionQueueItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gamificationEventsRefs(
    Expression<bool> Function($$GamificationEventsTableFilterComposer f) f,
  ) {
    final $$GamificationEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gamificationEvents,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamificationEventsTableFilterComposer(
            $db: $db,
            $table: $db.gamificationEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExamsTableOrderingComposer
    extends Composer<_$GaussDatabase, $ExamsTable> {
  $$ExamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicKey => $composableBuilder(
    column: $table.topicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skippedCount => $composableBuilder(
    column: $table.skippedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scorePercentage => $composableBuilder(
    column: $table.scorePercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExamsTableAnnotationComposer
    extends Composer<_$GaussDatabase, $ExamsTable> {
  $$ExamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topicKey =>
      $composableBuilder(column: $table.topicKey, builder: (column) => column);

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skippedCount => $composableBuilder(
    column: $table.skippedCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scorePercentage => $composableBuilder(
    column: $table.scorePercentage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  Expression<T> attemptsRefs<T extends Object>(
    Expression<T> Function($$AttemptsTableAnnotationComposer a) f,
  ) {
    final $$AttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> missionQueueItemsRefs<T extends Object>(
    Expression<T> Function($$MissionQueueItemsTableAnnotationComposer a) f,
  ) {
    final $$MissionQueueItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.missionQueueItems,
          getReferencedColumn: (t) => t.examId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MissionQueueItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.missionQueueItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> gamificationEventsRefs<T extends Object>(
    Expression<T> Function($$GamificationEventsTableAnnotationComposer a) f,
  ) {
    final $$GamificationEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.gamificationEvents,
          getReferencedColumn: (t) => t.examId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GamificationEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.gamificationEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExamsTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $ExamsTable,
          ExamRow,
          $$ExamsTableFilterComposer,
          $$ExamsTableOrderingComposer,
          $$ExamsTableAnnotationComposer,
          $$ExamsTableCreateCompanionBuilder,
          $$ExamsTableUpdateCompanionBuilder,
          (ExamRow, $$ExamsTableReferences),
          ExamRow,
          PrefetchHooks Function({
            bool attemptsRefs,
            bool missionQueueItemsRefs,
            bool gamificationEventsRefs,
          })
        > {
  $$ExamsTableTableManager(_$GaussDatabase db, $ExamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String?> topicKey = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<int> skippedCount = const Value.absent(),
                Value<double> scorePercentage = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
              }) => ExamsCompanion(
                id: id,
                sessionId: sessionId,
                subject: subject,
                topicKey: topicKey,
                totalQuestions: totalQuestions,
                correctCount: correctCount,
                wrongCount: wrongCount,
                skippedCount: skippedCount,
                scorePercentage: scorePercentage,
                durationSeconds: durationSeconds,
                status: status,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required String subject,
                Value<String?> topicKey = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<int> skippedCount = const Value.absent(),
                Value<double> scorePercentage = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> status = const Value.absent(),
                required int createdAt,
                Value<int?> completedAt = const Value.absent(),
              }) => ExamsCompanion.insert(
                id: id,
                sessionId: sessionId,
                subject: subject,
                topicKey: topicKey,
                totalQuestions: totalQuestions,
                correctCount: correctCount,
                wrongCount: wrongCount,
                skippedCount: skippedCount,
                scorePercentage: scorePercentage,
                durationSeconds: durationSeconds,
                status: status,
                createdAt: createdAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ExamsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                attemptsRefs = false,
                missionQueueItemsRefs = false,
                gamificationEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attemptsRefs) db.attempts,
                    if (missionQueueItemsRefs) db.missionQueueItems,
                    if (gamificationEventsRefs) db.gamificationEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attemptsRefs)
                        await $_getPrefetchedData<
                          ExamRow,
                          $ExamsTable,
                          AttemptRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._attemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).attemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (missionQueueItemsRefs)
                        await $_getPrefetchedData<
                          ExamRow,
                          $ExamsTable,
                          MissionQueueRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._missionQueueItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).missionQueueItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gamificationEventsRefs)
                        await $_getPrefetchedData<
                          ExamRow,
                          $ExamsTable,
                          GamificationEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._gamificationEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).gamificationEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExamsTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $ExamsTable,
      ExamRow,
      $$ExamsTableFilterComposer,
      $$ExamsTableOrderingComposer,
      $$ExamsTableAnnotationComposer,
      $$ExamsTableCreateCompanionBuilder,
      $$ExamsTableUpdateCompanionBuilder,
      (ExamRow, $$ExamsTableReferences),
      ExamRow,
      PrefetchHooks Function({
        bool attemptsRefs,
        bool missionQueueItemsRefs,
        bool gamificationEventsRefs,
      })
    >;
typedef $$AttemptsTableCreateCompanionBuilder =
    AttemptsCompanion Function({
      Value<int> id,
      Value<int?> examId,
      required String sessionId,
      required int missionIndex,
      required String questionId,
      required String subject,
      required String topicKey,
      required String status,
      Value<int?> selectedChoiceIndex,
      required int timeTakenSeconds,
      required int solvedAt,
      Value<String?> errorTag,
    });
typedef $$AttemptsTableUpdateCompanionBuilder =
    AttemptsCompanion Function({
      Value<int> id,
      Value<int?> examId,
      Value<String> sessionId,
      Value<int> missionIndex,
      Value<String> questionId,
      Value<String> subject,
      Value<String> topicKey,
      Value<String> status,
      Value<int?> selectedChoiceIndex,
      Value<int> timeTakenSeconds,
      Value<int> solvedAt,
      Value<String?> errorTag,
    });

final class $$AttemptsTableReferences
    extends BaseReferences<_$GaussDatabase, $AttemptsTable, AttemptRow> {
  $$AttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExamsTable _examIdTable(_$GaussDatabase db) =>
      db.exams.createAlias('attempts__exam_id__exams__id');

  $$ExamsTableProcessedTableManager? get examId {
    final $_column = $_itemColumn<int>('exam_id');
    if ($_column == null) return null;
    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttemptsTableFilterComposer
    extends Composer<_$GaussDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missionIndex => $composableBuilder(
    column: $table.missionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicKey => $composableBuilder(
    column: $table.topicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get selectedChoiceIndex => $composableBuilder(
    column: $table.selectedChoiceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeTakenSeconds => $composableBuilder(
    column: $table.timeTakenSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get solvedAt => $composableBuilder(
    column: $table.solvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorTag => $composableBuilder(
    column: $table.errorTag,
    builder: (column) => ColumnFilters(column),
  );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$GaussDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missionIndex => $composableBuilder(
    column: $table.missionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicKey => $composableBuilder(
    column: $table.topicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get selectedChoiceIndex => $composableBuilder(
    column: $table.selectedChoiceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeTakenSeconds => $composableBuilder(
    column: $table.timeTakenSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get solvedAt => $composableBuilder(
    column: $table.solvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorTag => $composableBuilder(
    column: $table.errorTag,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$GaussDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get missionIndex => $composableBuilder(
    column: $table.missionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topicKey =>
      $composableBuilder(column: $table.topicKey, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get selectedChoiceIndex => $composableBuilder(
    column: $table.selectedChoiceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeTakenSeconds => $composableBuilder(
    column: $table.timeTakenSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get solvedAt =>
      $composableBuilder(column: $table.solvedAt, builder: (column) => column);

  GeneratedColumn<String> get errorTag =>
      $composableBuilder(column: $table.errorTag, builder: (column) => column);

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $AttemptsTable,
          AttemptRow,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (AttemptRow, $$AttemptsTableReferences),
          AttemptRow,
          PrefetchHooks Function({bool examId})
        > {
  $$AttemptsTableTableManager(_$GaussDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> examId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> missionIndex = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> topicKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> selectedChoiceIndex = const Value.absent(),
                Value<int> timeTakenSeconds = const Value.absent(),
                Value<int> solvedAt = const Value.absent(),
                Value<String?> errorTag = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                examId: examId,
                sessionId: sessionId,
                missionIndex: missionIndex,
                questionId: questionId,
                subject: subject,
                topicKey: topicKey,
                status: status,
                selectedChoiceIndex: selectedChoiceIndex,
                timeTakenSeconds: timeTakenSeconds,
                solvedAt: solvedAt,
                errorTag: errorTag,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> examId = const Value.absent(),
                required String sessionId,
                required int missionIndex,
                required String questionId,
                required String subject,
                required String topicKey,
                required String status,
                Value<int?> selectedChoiceIndex = const Value.absent(),
                required int timeTakenSeconds,
                required int solvedAt,
                Value<String?> errorTag = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                examId: examId,
                sessionId: sessionId,
                missionIndex: missionIndex,
                questionId: questionId,
                subject: subject,
                topicKey: topicKey,
                status: status,
                selectedChoiceIndex: selectedChoiceIndex,
                timeTakenSeconds: timeTakenSeconds,
                solvedAt: solvedAt,
                errorTag: errorTag,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({examId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (examId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.examId,
                                referencedTable: $$AttemptsTableReferences
                                    ._examIdTable(db),
                                referencedColumn: $$AttemptsTableReferences
                                    ._examIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $AttemptsTable,
      AttemptRow,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (AttemptRow, $$AttemptsTableReferences),
      AttemptRow,
      PrefetchHooks Function({bool examId})
    >;
typedef $$MissionQueueItemsTableCreateCompanionBuilder =
    MissionQueueItemsCompanion Function({
      required int examId,
      required int position,
      required String questionId,
      Value<int> rowid,
    });
typedef $$MissionQueueItemsTableUpdateCompanionBuilder =
    MissionQueueItemsCompanion Function({
      Value<int> examId,
      Value<int> position,
      Value<String> questionId,
      Value<int> rowid,
    });

final class $$MissionQueueItemsTableReferences
    extends
        BaseReferences<
          _$GaussDatabase,
          $MissionQueueItemsTable,
          MissionQueueRow
        > {
  $$MissionQueueItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExamsTable _examIdTable(_$GaussDatabase db) =>
      db.exams.createAlias('mission_queue_items__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<int>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MissionQueueItemsTableFilterComposer
    extends Composer<_$GaussDatabase, $MissionQueueItemsTable> {
  $$MissionQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MissionQueueItemsTableOrderingComposer
    extends Composer<_$GaussDatabase, $MissionQueueItemsTable> {
  $$MissionQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MissionQueueItemsTableAnnotationComposer
    extends Composer<_$GaussDatabase, $MissionQueueItemsTable> {
  $$MissionQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MissionQueueItemsTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $MissionQueueItemsTable,
          MissionQueueRow,
          $$MissionQueueItemsTableFilterComposer,
          $$MissionQueueItemsTableOrderingComposer,
          $$MissionQueueItemsTableAnnotationComposer,
          $$MissionQueueItemsTableCreateCompanionBuilder,
          $$MissionQueueItemsTableUpdateCompanionBuilder,
          (MissionQueueRow, $$MissionQueueItemsTableReferences),
          MissionQueueRow,
          PrefetchHooks Function({bool examId})
        > {
  $$MissionQueueItemsTableTableManager(
    _$GaussDatabase db,
    $MissionQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MissionQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MissionQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MissionQueueItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> examId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MissionQueueItemsCompanion(
                examId: examId,
                position: position,
                questionId: questionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int examId,
                required int position,
                required String questionId,
                Value<int> rowid = const Value.absent(),
              }) => MissionQueueItemsCompanion.insert(
                examId: examId,
                position: position,
                questionId: questionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MissionQueueItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({examId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (examId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.examId,
                                referencedTable:
                                    $$MissionQueueItemsTableReferences
                                        ._examIdTable(db),
                                referencedColumn:
                                    $$MissionQueueItemsTableReferences
                                        ._examIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MissionQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $MissionQueueItemsTable,
      MissionQueueRow,
      $$MissionQueueItemsTableFilterComposer,
      $$MissionQueueItemsTableOrderingComposer,
      $$MissionQueueItemsTableAnnotationComposer,
      $$MissionQueueItemsTableCreateCompanionBuilder,
      $$MissionQueueItemsTableUpdateCompanionBuilder,
      (MissionQueueRow, $$MissionQueueItemsTableReferences),
      MissionQueueRow,
      PrefetchHooks Function({bool examId})
    >;
typedef $$SrsStatesTableCreateCompanionBuilder =
    SrsStatesCompanion Function({
      required String questionId,
      Value<double> ease,
      Value<int> intervalDays,
      Value<int> reps,
      Value<int> lapses,
      required int dueAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$SrsStatesTableUpdateCompanionBuilder =
    SrsStatesCompanion Function({
      Value<String> questionId,
      Value<double> ease,
      Value<int> intervalDays,
      Value<int> reps,
      Value<int> lapses,
      Value<int> dueAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$SrsStatesTableFilterComposer
    extends Composer<_$GaussDatabase, $SrsStatesTable> {
  $$SrsStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SrsStatesTableOrderingComposer
    extends Composer<_$GaussDatabase, $SrsStatesTable> {
  $$SrsStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ease => $composableBuilder(
    column: $table.ease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SrsStatesTableAnnotationComposer
    extends Composer<_$GaussDatabase, $SrsStatesTable> {
  $$SrsStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SrsStatesTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $SrsStatesTable,
          SrsRow,
          $$SrsStatesTableFilterComposer,
          $$SrsStatesTableOrderingComposer,
          $$SrsStatesTableAnnotationComposer,
          $$SrsStatesTableCreateCompanionBuilder,
          $$SrsStatesTableUpdateCompanionBuilder,
          (SrsRow, BaseReferences<_$GaussDatabase, $SrsStatesTable, SrsRow>),
          SrsRow,
          PrefetchHooks Function()
        > {
  $$SrsStatesTableTableManager(_$GaussDatabase db, $SrsStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SrsStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SrsStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SrsStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SrsStatesCompanion(
                questionId: questionId,
                ease: ease,
                intervalDays: intervalDays,
                reps: reps,
                lapses: lapses,
                dueAt: dueAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                Value<double> ease = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                required int dueAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SrsStatesCompanion.insert(
                questionId: questionId,
                ease: ease,
                intervalDays: intervalDays,
                reps: reps,
                lapses: lapses,
                dueAt: dueAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SrsStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $SrsStatesTable,
      SrsRow,
      $$SrsStatesTableFilterComposer,
      $$SrsStatesTableOrderingComposer,
      $$SrsStatesTableAnnotationComposer,
      $$SrsStatesTableCreateCompanionBuilder,
      $$SrsStatesTableUpdateCompanionBuilder,
      (SrsRow, BaseReferences<_$GaussDatabase, $SrsStatesTable, SrsRow>),
      SrsRow,
      PrefetchHooks Function()
    >;
typedef $$GamificationEventsTableCreateCompanionBuilder =
    GamificationEventsCompanion Function({
      required String id,
      required String type,
      Value<String?> subject,
      Value<String?> topicKey,
      Value<int?> examId,
      Value<String?> questionId,
      required String dayKey,
      required int createdAt,
      Value<int> ruleVersion,
      Value<int> rowid,
    });
typedef $$GamificationEventsTableUpdateCompanionBuilder =
    GamificationEventsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String?> subject,
      Value<String?> topicKey,
      Value<int?> examId,
      Value<String?> questionId,
      Value<String> dayKey,
      Value<int> createdAt,
      Value<int> ruleVersion,
      Value<int> rowid,
    });

final class $$GamificationEventsTableReferences
    extends
        BaseReferences<
          _$GaussDatabase,
          $GamificationEventsTable,
          GamificationEventRow
        > {
  $$GamificationEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExamsTable _examIdTable(_$GaussDatabase db) =>
      db.exams.createAlias('gamification_events__exam_id__exams__id');

  $$ExamsTableProcessedTableManager? get examId {
    final $_column = $_itemColumn<int>('exam_id');
    if ($_column == null) return null;
    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$XpTransactionsTable, List<XpTransactionRow>>
  _xpTransactionsRefsTable(_$GaussDatabase db) => MultiTypedResultKey.fromTable(
    db.xpTransactions,
    aliasName: 'gamification_events__id__xp_transactions__event_id',
  );

  $$XpTransactionsTableProcessedTableManager get xpTransactionsRefs {
    final manager = $$XpTransactionsTableTableManager(
      $_db,
      $_db.xpTransactions,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_xpTransactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GamificationEventsTableFilterComposer
    extends Composer<_$GaussDatabase, $GamificationEventsTable> {
  $$GamificationEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicKey => $composableBuilder(
    column: $table.topicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> xpTransactionsRefs(
    Expression<bool> Function($$XpTransactionsTableFilterComposer f) f,
  ) {
    final $$XpTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.xpTransactions,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$XpTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.xpTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamificationEventsTableOrderingComposer
    extends Composer<_$GaussDatabase, $GamificationEventsTable> {
  $$GamificationEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicKey => $composableBuilder(
    column: $table.topicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GamificationEventsTableAnnotationComposer
    extends Composer<_$GaussDatabase, $GamificationEventsTable> {
  $$GamificationEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topicKey =>
      $composableBuilder(column: $table.topicKey, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => column,
  );

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> xpTransactionsRefs<T extends Object>(
    Expression<T> Function($$XpTransactionsTableAnnotationComposer a) f,
  ) {
    final $$XpTransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.xpTransactions,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$XpTransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.xpTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamificationEventsTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $GamificationEventsTable,
          GamificationEventRow,
          $$GamificationEventsTableFilterComposer,
          $$GamificationEventsTableOrderingComposer,
          $$GamificationEventsTableAnnotationComposer,
          $$GamificationEventsTableCreateCompanionBuilder,
          $$GamificationEventsTableUpdateCompanionBuilder,
          (GamificationEventRow, $$GamificationEventsTableReferences),
          GamificationEventRow,
          PrefetchHooks Function({bool examId, bool xpTransactionsRefs})
        > {
  $$GamificationEventsTableTableManager(
    _$GaussDatabase db,
    $GamificationEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamificationEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamificationEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamificationEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> topicKey = const Value.absent(),
                Value<int?> examId = const Value.absent(),
                Value<String?> questionId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> ruleVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamificationEventsCompanion(
                id: id,
                type: type,
                subject: subject,
                topicKey: topicKey,
                examId: examId,
                questionId: questionId,
                dayKey: dayKey,
                createdAt: createdAt,
                ruleVersion: ruleVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                Value<String?> subject = const Value.absent(),
                Value<String?> topicKey = const Value.absent(),
                Value<int?> examId = const Value.absent(),
                Value<String?> questionId = const Value.absent(),
                required String dayKey,
                required int createdAt,
                Value<int> ruleVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamificationEventsCompanion.insert(
                id: id,
                type: type,
                subject: subject,
                topicKey: topicKey,
                examId: examId,
                questionId: questionId,
                dayKey: dayKey,
                createdAt: createdAt,
                ruleVersion: ruleVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GamificationEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({examId = false, xpTransactionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (xpTransactionsRefs) db.xpTransactions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (examId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.examId,
                                    referencedTable:
                                        $$GamificationEventsTableReferences
                                            ._examIdTable(db),
                                    referencedColumn:
                                        $$GamificationEventsTableReferences
                                            ._examIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (xpTransactionsRefs)
                        await $_getPrefetchedData<
                          GamificationEventRow,
                          $GamificationEventsTable,
                          XpTransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $$GamificationEventsTableReferences
                              ._xpTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamificationEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).xpTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GamificationEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $GamificationEventsTable,
      GamificationEventRow,
      $$GamificationEventsTableFilterComposer,
      $$GamificationEventsTableOrderingComposer,
      $$GamificationEventsTableAnnotationComposer,
      $$GamificationEventsTableCreateCompanionBuilder,
      $$GamificationEventsTableUpdateCompanionBuilder,
      (GamificationEventRow, $$GamificationEventsTableReferences),
      GamificationEventRow,
      PrefetchHooks Function({bool examId, bool xpTransactionsRefs})
    >;
typedef $$XpTransactionsTableCreateCompanionBuilder =
    XpTransactionsCompanion Function({
      required String id,
      required String eventId,
      required int amount,
      required String category,
      required String reason,
      required String dayKey,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$XpTransactionsTableUpdateCompanionBuilder =
    XpTransactionsCompanion Function({
      Value<String> id,
      Value<String> eventId,
      Value<int> amount,
      Value<String> category,
      Value<String> reason,
      Value<String> dayKey,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$XpTransactionsTableReferences
    extends
        BaseReferences<
          _$GaussDatabase,
          $XpTransactionsTable,
          XpTransactionRow
        > {
  $$XpTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamificationEventsTable _eventIdTable(_$GaussDatabase db) => db
      .gamificationEvents
      .createAlias('xp_transactions__event_id__gamification_events__id');

  $$GamificationEventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$GamificationEventsTableTableManager(
      $_db,
      $_db.gamificationEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$XpTransactionsTableFilterComposer
    extends Composer<_$GaussDatabase, $XpTransactionsTable> {
  $$XpTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamificationEventsTableFilterComposer get eventId {
    final $$GamificationEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.gamificationEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamificationEventsTableFilterComposer(
            $db: $db,
            $table: $db.gamificationEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$XpTransactionsTableOrderingComposer
    extends Composer<_$GaussDatabase, $XpTransactionsTable> {
  $$XpTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamificationEventsTableOrderingComposer get eventId {
    final $$GamificationEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.gamificationEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamificationEventsTableOrderingComposer(
            $db: $db,
            $table: $db.gamificationEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$XpTransactionsTableAnnotationComposer
    extends Composer<_$GaussDatabase, $XpTransactionsTable> {
  $$XpTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GamificationEventsTableAnnotationComposer get eventId {
    final $$GamificationEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.eventId,
          referencedTable: $db.gamificationEvents,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GamificationEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.gamificationEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$XpTransactionsTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $XpTransactionsTable,
          XpTransactionRow,
          $$XpTransactionsTableFilterComposer,
          $$XpTransactionsTableOrderingComposer,
          $$XpTransactionsTableAnnotationComposer,
          $$XpTransactionsTableCreateCompanionBuilder,
          $$XpTransactionsTableUpdateCompanionBuilder,
          (XpTransactionRow, $$XpTransactionsTableReferences),
          XpTransactionRow,
          PrefetchHooks Function({bool eventId})
        > {
  $$XpTransactionsTableTableManager(
    _$GaussDatabase db,
    $XpTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$XpTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$XpTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$XpTransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => XpTransactionsCompanion(
                id: id,
                eventId: eventId,
                amount: amount,
                category: category,
                reason: reason,
                dayKey: dayKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventId,
                required int amount,
                required String category,
                required String reason,
                required String dayKey,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => XpTransactionsCompanion.insert(
                id: id,
                eventId: eventId,
                amount: amount,
                category: category,
                reason: reason,
                dayKey: dayKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$XpTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (eventId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.eventId,
                                referencedTable: $$XpTransactionsTableReferences
                                    ._eventIdTable(db),
                                referencedColumn:
                                    $$XpTransactionsTableReferences
                                        ._eventIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$XpTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $XpTransactionsTable,
      XpTransactionRow,
      $$XpTransactionsTableFilterComposer,
      $$XpTransactionsTableOrderingComposer,
      $$XpTransactionsTableAnnotationComposer,
      $$XpTransactionsTableCreateCompanionBuilder,
      $$XpTransactionsTableUpdateCompanionBuilder,
      (XpTransactionRow, $$XpTransactionsTableReferences),
      XpTransactionRow,
      PrefetchHooks Function({bool eventId})
    >;
typedef $$QuestProgressTableCreateCompanionBuilder =
    QuestProgressCompanion Function({
      required String questId,
      required String dayKey,
      required String title,
      required int progress,
      required int target,
      required bool completed,
      required int rewardXp,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$QuestProgressTableUpdateCompanionBuilder =
    QuestProgressCompanion Function({
      Value<String> questId,
      Value<String> dayKey,
      Value<String> title,
      Value<int> progress,
      Value<int> target,
      Value<bool> completed,
      Value<int> rewardXp,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$QuestProgressTableFilterComposer
    extends Composer<_$GaussDatabase, $QuestProgressTable> {
  $$QuestProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questId => $composableBuilder(
    column: $table.questId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rewardXp => $composableBuilder(
    column: $table.rewardXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestProgressTableOrderingComposer
    extends Composer<_$GaussDatabase, $QuestProgressTable> {
  $$QuestProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questId => $composableBuilder(
    column: $table.questId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rewardXp => $composableBuilder(
    column: $table.rewardXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestProgressTableAnnotationComposer
    extends Composer<_$GaussDatabase, $QuestProgressTable> {
  $$QuestProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questId =>
      $composableBuilder(column: $table.questId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get rewardXp =>
      $composableBuilder(column: $table.rewardXp, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuestProgressTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $QuestProgressTable,
          QuestProgressRow,
          $$QuestProgressTableFilterComposer,
          $$QuestProgressTableOrderingComposer,
          $$QuestProgressTableAnnotationComposer,
          $$QuestProgressTableCreateCompanionBuilder,
          $$QuestProgressTableUpdateCompanionBuilder,
          (
            QuestProgressRow,
            BaseReferences<
              _$GaussDatabase,
              $QuestProgressTable,
              QuestProgressRow
            >,
          ),
          QuestProgressRow,
          PrefetchHooks Function()
        > {
  $$QuestProgressTableTableManager(
    _$GaussDatabase db,
    $QuestProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<int> target = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rewardXp = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestProgressCompanion(
                questId: questId,
                dayKey: dayKey,
                title: title,
                progress: progress,
                target: target,
                completed: completed,
                rewardXp: rewardXp,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questId,
                required String dayKey,
                required String title,
                required int progress,
                required int target,
                required bool completed,
                required int rewardXp,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuestProgressCompanion.insert(
                questId: questId,
                dayKey: dayKey,
                title: title,
                progress: progress,
                target: target,
                completed: completed,
                rewardXp: rewardXp,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $QuestProgressTable,
      QuestProgressRow,
      $$QuestProgressTableFilterComposer,
      $$QuestProgressTableOrderingComposer,
      $$QuestProgressTableAnnotationComposer,
      $$QuestProgressTableCreateCompanionBuilder,
      $$QuestProgressTableUpdateCompanionBuilder,
      (
        QuestProgressRow,
        BaseReferences<_$GaussDatabase, $QuestProgressTable, QuestProgressRow>,
      ),
      QuestProgressRow,
      PrefetchHooks Function()
    >;
typedef $$AchievementProgressTableCreateCompanionBuilder =
    AchievementProgressCompanion Function({
      required String achievementId,
      required String title,
      required int current,
      required int target,
      Value<int?> completedAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AchievementProgressTableUpdateCompanionBuilder =
    AchievementProgressCompanion Function({
      Value<String> achievementId,
      Value<String> title,
      Value<int> current,
      Value<int> target,
      Value<int?> completedAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AchievementProgressTableFilterComposer
    extends Composer<_$GaussDatabase, $AchievementProgressTable> {
  $$AchievementProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get current => $composableBuilder(
    column: $table.current,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementProgressTableOrderingComposer
    extends Composer<_$GaussDatabase, $AchievementProgressTable> {
  $$AchievementProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get current => $composableBuilder(
    column: $table.current,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementProgressTableAnnotationComposer
    extends Composer<_$GaussDatabase, $AchievementProgressTable> {
  $$AchievementProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get current =>
      $composableBuilder(column: $table.current, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AchievementProgressTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $AchievementProgressTable,
          AchievementProgressRow,
          $$AchievementProgressTableFilterComposer,
          $$AchievementProgressTableOrderingComposer,
          $$AchievementProgressTableAnnotationComposer,
          $$AchievementProgressTableCreateCompanionBuilder,
          $$AchievementProgressTableUpdateCompanionBuilder,
          (
            AchievementProgressRow,
            BaseReferences<
              _$GaussDatabase,
              $AchievementProgressTable,
              AchievementProgressRow
            >,
          ),
          AchievementProgressRow,
          PrefetchHooks Function()
        > {
  $$AchievementProgressTableTableManager(
    _$GaussDatabase db,
    $AchievementProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementProgressTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AchievementProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> achievementId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> current = const Value.absent(),
                Value<int> target = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementProgressCompanion(
                achievementId: achievementId,
                title: title,
                current: current,
                target: target,
                completedAt: completedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String achievementId,
                required String title,
                required int current,
                required int target,
                Value<int?> completedAt = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AchievementProgressCompanion.insert(
                achievementId: achievementId,
                title: title,
                current: current,
                target: target,
                completedAt: completedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $AchievementProgressTable,
      AchievementProgressRow,
      $$AchievementProgressTableFilterComposer,
      $$AchievementProgressTableOrderingComposer,
      $$AchievementProgressTableAnnotationComposer,
      $$AchievementProgressTableCreateCompanionBuilder,
      $$AchievementProgressTableUpdateCompanionBuilder,
      (
        AchievementProgressRow,
        BaseReferences<
          _$GaussDatabase,
          $AchievementProgressTable,
          AchievementProgressRow
        >,
      ),
      AchievementProgressRow,
      PrefetchHooks Function()
    >;
typedef $$StudyRecordsTableCreateCompanionBuilder =
    StudyRecordsCompanion Function({
      required String questionId,
      required String topicKey,
      required String shelfKey,
      Value<int?> hypothesisChoiceIndex,
      Value<bool?> hypothesisMatched,
      required String reflection,
      required int firstReflectedAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$StudyRecordsTableUpdateCompanionBuilder =
    StudyRecordsCompanion Function({
      Value<String> questionId,
      Value<String> topicKey,
      Value<String> shelfKey,
      Value<int?> hypothesisChoiceIndex,
      Value<bool?> hypothesisMatched,
      Value<String> reflection,
      Value<int> firstReflectedAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$StudyRecordsTableFilterComposer
    extends Composer<_$GaussDatabase, $StudyRecordsTable> {
  $$StudyRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicKey => $composableBuilder(
    column: $table.topicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shelfKey => $composableBuilder(
    column: $table.shelfKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hypothesisChoiceIndex => $composableBuilder(
    column: $table.hypothesisChoiceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hypothesisMatched => $composableBuilder(
    column: $table.hypothesisMatched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reflection => $composableBuilder(
    column: $table.reflection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstReflectedAt => $composableBuilder(
    column: $table.firstReflectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyRecordsTableOrderingComposer
    extends Composer<_$GaussDatabase, $StudyRecordsTable> {
  $$StudyRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicKey => $composableBuilder(
    column: $table.topicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shelfKey => $composableBuilder(
    column: $table.shelfKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hypothesisChoiceIndex => $composableBuilder(
    column: $table.hypothesisChoiceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hypothesisMatched => $composableBuilder(
    column: $table.hypothesisMatched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reflection => $composableBuilder(
    column: $table.reflection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstReflectedAt => $composableBuilder(
    column: $table.firstReflectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyRecordsTableAnnotationComposer
    extends Composer<_$GaussDatabase, $StudyRecordsTable> {
  $$StudyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topicKey =>
      $composableBuilder(column: $table.topicKey, builder: (column) => column);

  GeneratedColumn<String> get shelfKey =>
      $composableBuilder(column: $table.shelfKey, builder: (column) => column);

  GeneratedColumn<int> get hypothesisChoiceIndex => $composableBuilder(
    column: $table.hypothesisChoiceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hypothesisMatched => $composableBuilder(
    column: $table.hypothesisMatched,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reflection => $composableBuilder(
    column: $table.reflection,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstReflectedAt => $composableBuilder(
    column: $table.firstReflectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StudyRecordsTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $StudyRecordsTable,
          StudyRecordRow,
          $$StudyRecordsTableFilterComposer,
          $$StudyRecordsTableOrderingComposer,
          $$StudyRecordsTableAnnotationComposer,
          $$StudyRecordsTableCreateCompanionBuilder,
          $$StudyRecordsTableUpdateCompanionBuilder,
          (
            StudyRecordRow,
            BaseReferences<_$GaussDatabase, $StudyRecordsTable, StudyRecordRow>,
          ),
          StudyRecordRow,
          PrefetchHooks Function()
        > {
  $$StudyRecordsTableTableManager(_$GaussDatabase db, $StudyRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<String> topicKey = const Value.absent(),
                Value<String> shelfKey = const Value.absent(),
                Value<int?> hypothesisChoiceIndex = const Value.absent(),
                Value<bool?> hypothesisMatched = const Value.absent(),
                Value<String> reflection = const Value.absent(),
                Value<int> firstReflectedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyRecordsCompanion(
                questionId: questionId,
                topicKey: topicKey,
                shelfKey: shelfKey,
                hypothesisChoiceIndex: hypothesisChoiceIndex,
                hypothesisMatched: hypothesisMatched,
                reflection: reflection,
                firstReflectedAt: firstReflectedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                required String topicKey,
                required String shelfKey,
                Value<int?> hypothesisChoiceIndex = const Value.absent(),
                Value<bool?> hypothesisMatched = const Value.absent(),
                required String reflection,
                required int firstReflectedAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StudyRecordsCompanion.insert(
                questionId: questionId,
                topicKey: topicKey,
                shelfKey: shelfKey,
                hypothesisChoiceIndex: hypothesisChoiceIndex,
                hypothesisMatched: hypothesisMatched,
                reflection: reflection,
                firstReflectedAt: firstReflectedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $StudyRecordsTable,
      StudyRecordRow,
      $$StudyRecordsTableFilterComposer,
      $$StudyRecordsTableOrderingComposer,
      $$StudyRecordsTableAnnotationComposer,
      $$StudyRecordsTableCreateCompanionBuilder,
      $$StudyRecordsTableUpdateCompanionBuilder,
      (
        StudyRecordRow,
        BaseReferences<_$GaussDatabase, $StudyRecordsTable, StudyRecordRow>,
      ),
      StudyRecordRow,
      PrefetchHooks Function()
    >;
typedef $$StudyPositionsTableCreateCompanionBuilder =
    StudyPositionsCompanion Function({
      required String shelfKey,
      required String questionId,
      required int position,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$StudyPositionsTableUpdateCompanionBuilder =
    StudyPositionsCompanion Function({
      Value<String> shelfKey,
      Value<String> questionId,
      Value<int> position,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$StudyPositionsTableFilterComposer
    extends Composer<_$GaussDatabase, $StudyPositionsTable> {
  $$StudyPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get shelfKey => $composableBuilder(
    column: $table.shelfKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyPositionsTableOrderingComposer
    extends Composer<_$GaussDatabase, $StudyPositionsTable> {
  $$StudyPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get shelfKey => $composableBuilder(
    column: $table.shelfKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyPositionsTableAnnotationComposer
    extends Composer<_$GaussDatabase, $StudyPositionsTable> {
  $$StudyPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get shelfKey =>
      $composableBuilder(column: $table.shelfKey, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StudyPositionsTableTableManager
    extends
        RootTableManager<
          _$GaussDatabase,
          $StudyPositionsTable,
          StudyPositionRow,
          $$StudyPositionsTableFilterComposer,
          $$StudyPositionsTableOrderingComposer,
          $$StudyPositionsTableAnnotationComposer,
          $$StudyPositionsTableCreateCompanionBuilder,
          $$StudyPositionsTableUpdateCompanionBuilder,
          (
            StudyPositionRow,
            BaseReferences<
              _$GaussDatabase,
              $StudyPositionsTable,
              StudyPositionRow
            >,
          ),
          StudyPositionRow,
          PrefetchHooks Function()
        > {
  $$StudyPositionsTableTableManager(
    _$GaussDatabase db,
    $StudyPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyPositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> shelfKey = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyPositionsCompanion(
                shelfKey: shelfKey,
                questionId: questionId,
                position: position,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String shelfKey,
                required String questionId,
                required int position,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StudyPositionsCompanion.insert(
                shelfKey: shelfKey,
                questionId: questionId,
                position: position,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$GaussDatabase,
      $StudyPositionsTable,
      StudyPositionRow,
      $$StudyPositionsTableFilterComposer,
      $$StudyPositionsTableOrderingComposer,
      $$StudyPositionsTableAnnotationComposer,
      $$StudyPositionsTableCreateCompanionBuilder,
      $$StudyPositionsTableUpdateCompanionBuilder,
      (
        StudyPositionRow,
        BaseReferences<_$GaussDatabase, $StudyPositionsTable, StudyPositionRow>,
      ),
      StudyPositionRow,
      PrefetchHooks Function()
    >;

class $GaussDatabaseManager {
  final _$GaussDatabase _db;
  $GaussDatabaseManager(this._db);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db, _db.exams);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$MissionQueueItemsTableTableManager get missionQueueItems =>
      $$MissionQueueItemsTableTableManager(_db, _db.missionQueueItems);
  $$SrsStatesTableTableManager get srsStates =>
      $$SrsStatesTableTableManager(_db, _db.srsStates);
  $$GamificationEventsTableTableManager get gamificationEvents =>
      $$GamificationEventsTableTableManager(_db, _db.gamificationEvents);
  $$XpTransactionsTableTableManager get xpTransactions =>
      $$XpTransactionsTableTableManager(_db, _db.xpTransactions);
  $$QuestProgressTableTableManager get questProgress =>
      $$QuestProgressTableTableManager(_db, _db.questProgress);
  $$AchievementProgressTableTableManager get achievementProgress =>
      $$AchievementProgressTableTableManager(_db, _db.achievementProgress);
  $$StudyRecordsTableTableManager get studyRecords =>
      $$StudyRecordsTableTableManager(_db, _db.studyRecords);
  $$StudyPositionsTableTableManager get studyPositions =>
      $$StudyPositionsTableTableManager(_db, _db.studyPositions);
}
