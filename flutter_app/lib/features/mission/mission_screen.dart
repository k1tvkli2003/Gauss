import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:gauss/domain/failures.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/question_reference.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/features/feedback/feedback_capture.dart';
import 'package:gauss/features/feedback/feedback_models.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/features/manuscript/content_blocks.dart';
import 'package:gauss/ui/components/gauss_brand.dart';
import 'package:gauss/ui/components/gauss_state_panel.dart';
import 'package:gauss/ui/components/orbital_action_control.dart';
import 'package:gauss/features/manuscript/question_progress_rail.dart';
import 'package:gauss/features/manuscript/question_manuscript.dart';
import 'package:gauss/features/manuscript/scratchpad.dart';
import 'package:gauss/features/manuscript/theorem_lens.dart';

part 'mission_question_stage.dart';
part 'mission_action_bar.dart';
part 'mission_answer_and_solution.dart';
part 'mission_completion.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({
    required this.topicKey,
    this.count = GaussStudyCurriculum.batchSize,
    this.studyOffset,
    this.difficulties = const {},
    this.sourceBanks = const {},
    this.revenge = false,
    this.review = false,
    this.resume = false,
    this.coverChoices = false,
    super.key,
  });
  final String topicKey;
  final int count;
  final int? studyOffset;
  final Set<Difficulty> difficulties;
  final Set<String> sourceBanks;
  final bool revenge;
  final bool review;
  final bool resume;

  /// Answer-first mode: choices stay covered until explicitly revealed,
  /// so the answer must be derived before it can be recognized.
  final bool coverChoices;

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  Future<List<Question>>? _missionFuture;
  List<Question> _questions = const [];
  late String _sessionId;
  DateTime _missionStartedAt = DateTime.now();
  int _index = 0;
  int? _selectedChoice;
  bool _checked = false;
  bool _finished = false;
  bool _ritualComplete = false;
  bool _saving = false;
  int _correct = 0;
  DateTime _questionStartedAt = DateTime.now();
  Object? _operationError;
  MissionCompletion? _completion;
  int _elapsedBeforeResume = 0;
  late String _sourceTopicKey;
  late bool _choicesRevealed;
  String? _errorTag;
  final Map<String, ScratchInkController> _inkControllers = {};
  final Map<String, Timer> _inkClearTimers = {};

  String get _modeKey =>
      widget.revenge ? 'revenge' : (widget.review ? 'review' : 'mission');

  @override
  void initState() {
    super.initState();
    _sourceTopicKey = widget.revenge
        ? 'revenge'
        : (widget.review ? 'review' : widget.topicKey);
    _choicesRevealed = !widget.coverChoices;
    _resetSessionIdentity();
  }

  void _resetSessionIdentity() {
    final now = DateTime.now();
    _sessionId = '${_modeKey}_${now.microsecondsSinceEpoch}_${widget.topicKey}';
    _missionStartedAt = now;
    _questionStartedAt = now;
  }

  ScratchInkController _inkFor(String slotKey) =>
      _inkControllers.putIfAbsent(slotKey, ScratchInkController.new);

  bool get _hasQuestionInk => _inkControllers.values.any(
    (ink) => !ink.isEmpty || ink.canRestoreClearedInk,
  );

  void _disposeInkControllers() {
    for (final timer in _inkClearTimers.values) {
      timer.cancel();
    }
    _inkClearTimers.clear();
    for (final controller in _inkControllers.values) {
      controller.dispose();
    }
    _inkControllers.clear();
  }

  void _clearQuestionInk(String slotKey) {
    final ink = _inkFor(slotKey);
    if (ink.isEmpty) return;
    ink.clear();
    _inkClearTimers.remove(slotKey)?.cancel();
    _inkClearTimers[slotKey] = Timer(const Duration(seconds: 4), () {
      _inkClearTimers.remove(slotKey);
      ink.discardLastClear();
    });
  }

  void _restoreQuestionInk(String slotKey) {
    _inkClearTimers.remove(slotKey)?.cancel();
    _inkFor(slotKey).restoreLastClear();
  }

  @override
  void dispose() {
    _disposeInkControllers();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _missionFuture ??= _loadMission(GaussScope.of(context));
  }

  Future<List<Question>> _loadMission(GaussController controller) async {
    try {
      if (widget.resume) {
        final saved = await controller.loadResumableMission();
        if (saved == null) return const [];
        _sessionId = saved.sessionId;
        _sourceTopicKey = saved.topicKey;
        _missionStartedAt = DateTime.now();
        _questionStartedAt = _missionStartedAt;
        _questions = saved.questions;
        _index = saved.resumeIndex;
        final currentAttempt = saved.resumeAttempt;
        _selectedChoice = currentAttempt?.selectedChoiceIndex;
        _checked = currentAttempt != null;
        _choicesRevealed = true;
        _errorTag = currentAttempt?.errorTag;
        _correct = saved.attempts.where((attempt) => attempt.correct).length;
        _elapsedBeforeResume = saved.attempts.fold(
          0,
          (total, attempt) => total + attempt.elapsedSeconds,
        );
        return saved.questions;
      }
      final questions = widget.revenge
          ? await controller.createRevengeMission(count: widget.count)
          : widget.review
          ? await controller.createReviewMission(count: widget.count)
          : widget.studyOffset != null
          ? await controller.createStudySessionMission(
              widget.topicKey,
              offset: widget.studyOffset!,
            )
          : await controller.createMission(
              widget.topicKey,
              count: widget.count,
              difficulties: widget.difficulties,
              sourceBanks: widget.sourceBanks,
            );
      if (!widget.revenge &&
          !widget.review &&
          widget.studyOffset != null &&
          questions.isNotEmpty &&
          questions.length != GaussStudyCurriculum.batchSize) {
        throw StateError(
          'A planned scored mission must contain exactly five questions.',
        );
      }
      if (questions.any((question) => !question.runtimeUsable)) {
        throw StateError(
          'A structurally incomplete source item cannot enter a mission.',
        );
      }
      if (questions.isNotEmpty) {
        await controller.startMission(
          sessionId: _sessionId,
          topicKey: _sourceTopicKey,
          subject: questions.first.subject,
          createdAt: _missionStartedAt,
          questions: questions,
        );
      }
      _questions = questions;
      return questions;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'gauss mission loader',
        ),
      );
      rethrow;
    }
  }

  Future<void> _checkAnswer() async {
    if (_selectedChoice == null || _checked || _saving) return;
    final question = _questions[_index];
    final correct = _selectedChoice == question.correctChoiceIndex;
    setState(() {
      _saving = true;
      _operationError = null;
    });
    try {
      await GaussScope.read(context).recordAttempt(
        AttemptRecord(
          sessionId: _sessionId,
          missionIndex: _index,
          questionId: question.id,
          subject: question.subject,
          topicKey: question.topicKey,
          selectedChoiceIndex: _selectedChoice,
          correct: correct,
          elapsedSeconds: DateTime.now()
              .difference(_questionStartedAt)
              .inSeconds,
          at: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _checked = true;
        if (correct) _correct++;
      });
      if (correct) {
        unawaited(HapticFeedback.mediumImpact());
      } else {
        unawaited(HapticFeedback.selectionClick());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _operationError = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _skipAnswer() async {
    if (_checked || _saving) return;
    final question = _questions[_index];
    setState(() {
      _saving = true;
      _operationError = null;
    });
    try {
      await GaussScope.read(context).recordAttempt(
        AttemptRecord(
          sessionId: _sessionId,
          missionIndex: _index,
          questionId: question.id,
          subject: question.subject,
          topicKey: question.topicKey,
          selectedChoiceIndex: null,
          correct: false,
          elapsedSeconds: DateTime.now()
              .difference(_questionStartedAt)
              .inSeconds,
          at: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() => _checked = true);
      unawaited(HapticFeedback.selectionClick());
    } catch (error) {
      if (!mounted) return;
      setState(() => _operationError = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _next() async {
    if (!_checked || _saving) return;
    if (_index == _questions.length - 1) {
      setState(() {
        _saving = true;
        _operationError = null;
      });
      try {
        final completion = await GaussScope.read(context).completeMission(
          sessionId: _sessionId,
          durationSeconds:
              DateTime.now().difference(_missionStartedAt).inSeconds +
              _elapsedBeforeResume,
        );
        if (!mounted) return;
        setState(() {
          _completion = completion;
          _finished = true;
          _ritualComplete = false;
        });
        unawaited(HapticFeedback.heavyImpact());
      } catch (error) {
        if (!mounted) return;
        setState(() => _operationError = error);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
    setState(() {
      _index++;
      _selectedChoice = null;
      _checked = false;
      _operationError = null;
      _choicesRevealed = !widget.coverChoices;
      _errorTag = null;
      _questionStartedAt = DateTime.now();
    });
  }

  Future<void> _tagError(MissReason reason) async {
    final question = _questions[_index];
    final previous = _errorTag;
    final next = previous == reason.key ? null : reason.key;
    setState(() => _errorTag = next);
    try {
      await GaussScope.read(context).tagAttempt(
        sessionId: _sessionId,
        questionId: question.id,
        errorTag: next,
      );
    } catch (_) {
      // Tagging is optional metadata; revert quietly instead of blocking
      // the mission flow with a retry barrier.
      if (mounted) setState(() => _errorTag = previous);
    }
  }

  Future<void> _reportCurrentQuestionIssue() async {
    if (_questions.isEmpty || _saving) return;
    final question = _questions[_index];
    GaussFeedbackScreenshot? screenshot;
    try {
      screenshot = await GaussFeedbackCapture.captureFrom(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'The screen preview was unavailable. You can still save a text report.',
            ),
          ),
        );
    }
    if (!mounted) return;
    final draft = await showModalBottomSheet<_QuestionIssueDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _QuestionIssueSheet(questionId: question.id, screenshot: screenshot),
    );
    if (draft == null || !mounted) return;

    try {
      await GaussScope.read(context).reportQuestionIssue(
        QuestionIssueReport(
          questionId: question.id,
          questionRevision: question.revision,
          topicKey: question.topicKey,
          kind: draft.kind,
          note: draft.note,
          sessionId: _sessionId,
          missionIndex: _index,
          selectedChoiceIndex: _selectedChoice,
          reportedAt: DateTime.now(),
        ),
        screenshot: draft.includeScreenshot ? screenshot : null,
      );
      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Question report saved to the private outbox.'),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save the report. Please try again.'),
          ),
        );
    }
  }

  void _retryMission() {
    if (widget.resume) {
      if (!_finished) {
        final controller = GaussScope.read(context);
        setState(() => _missionFuture = _loadMission(controller));
        return;
      }
      if (_sourceTopicKey == 'revenge') {
        context.replace('/revenge?count=${_questions.length}');
      } else if (_sourceTopicKey == 'review') {
        context.replace('/review?count=${_questions.length}');
      } else {
        final offsetQuery = widget.studyOffset == null
            ? ''
            : '&offset=${widget.studyOffset}';
        context.replace(
          '/mission/$_sourceTopicKey?count=${_questions.length}$offsetQuery',
        );
      }
      return;
    }
    final controller = GaussScope.read(context);
    _disposeInkControllers();
    setState(() {
      _resetSessionIdentity();
      _questions = const [];
      _index = 0;
      _selectedChoice = null;
      _checked = false;
      _finished = false;
      _ritualComplete = false;
      _saving = false;
      _correct = 0;
      _operationError = null;
      _completion = null;
      _elapsedBeforeResume = 0;
      _choicesRevealed = !widget.coverChoices;
      _errorTag = null;
      _missionFuture = _loadMission(controller);
    });
  }

  void _completeRitual() {
    if (_saving || !_finished || _ritualComplete) return;
    setState(() => _ritualComplete = true);
  }

  Future<bool> _confirmExit() async {
    if (_saving) return false;
    final hasInk = _hasQuestionInk;
    final hasUnsubmittedChoice = !_checked && _selectedChoice != null;
    if (_index == 0 && !hasUnsubmittedChoice && !_checked && !hasInk) {
      return true;
    }
    final detail = <String>[
      'Recorded answers and the remaining queue are saved on this device.',
      if (hasUnsubmittedChoice)
        'Your selected but unchecked answer has not been recorded.',
      if (hasInk)
        'Question ink is temporary and will be cleared when you leave.',
      'Resume whenever you return.',
    ].join(' ');
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              hasInk ? 'Leave and clear question ink?' : 'Leave this mission?',
            ),
            content: Text(detail),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(hasInk ? 'Keep writing' : 'Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _leaveMission() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/map');
    }
  }

  String _missionChapterLabel(Question question) {
    if (widget.revenge) return 'Revisit Orbit';
    if (widget.review) return 'Review Orbit';
    if (widget.resume) return 'Saved Mission';
    try {
      final controller = GaussScope.read(context);
      if (controller.selectedTopic.key == question.topicKey) {
        return controller.selectedTopic.label;
      }
      return question.topicKey
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
    } catch (_) {
      return widget.topicKey
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _finished,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      if (await _confirmExit() && context.mounted) {
        _leaveMission();
      }
    },
    child: Scaffold(
      body: FutureBuilder<List<Question>>(
        future: _missionFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MissionError(
              error: snapshot.error!,
              onRetry: _retryMission,
            );
          }
          if (!snapshot.hasData) return const _MissionLoading();
          if (snapshot.data!.isEmpty) {
            return _MissionError(
              error: widget.resume
                  ? 'There is no saved mission to resume.'
                  : widget.review
                  ? 'Nothing is due for review right now. Your recorded proofs are still holding.'
                  : widget.studyOffset != null
                  ? 'This five-question lesson could not be loaded. Your source data is unchanged.'
                  : 'No usable questions are available for this topic.',
            );
          }
          if (_finished) {
            return _MissionComplete(
              correct: _correct,
              total: _questions.length,
              completion: _completion!,
              ritualComplete: _ritualComplete,
              onSkipRitual: _completeRitual,
              onMap: () => context.go('/map'),
              onRetry: _retryMission,
            );
          }
          final question = _questions[_index];
          final inkSlotKey = '$_index:${question.id}';
          final ink = _inkFor(inkSlotKey);
          return _QuestionStage(
            question: question,
            chapterLabel: _missionChapterLabel(question),
            index: _index,
            total: _questions.length,
            selectedChoice: _selectedChoice,
            checked: _checked,
            busy: _saving,
            covered: !_choicesRevealed,
            errorTag: _errorTag,
            operationError: _operationError,
            ink: ink,
            onSelect: (choice) => setState(() => _selectedChoice = choice),
            onCheck: _checkAnswer,
            onSkip: _skipAnswer,
            onNext: _next,
            onRevealChoices: () => setState(() => _choicesRevealed = true),
            onTagError: _tagError,
            onReportIssue: _reportCurrentQuestionIssue,
            onScratchpad: () => showScratchpad(context, controller: ink),
            onClearInk: () => _clearQuestionInk(inkSlotKey),
            onRestoreInk: () => _restoreQuestionInk(inkSlotKey),
            onClose: () async {
              if (await _confirmExit() && context.mounted) {
                _leaveMission();
              }
            },
          );
        },
      ),
    ),
  );
}

class _MissionLoading extends StatelessWidget {
  const _MissionLoading();

  @override
  Widget build(BuildContext context) => const GaussStatePanel(
    title: 'Charting a mission…',
    detail: 'Preparing the verified question route from local storage.',
    loading: true,
    accent: GaussColors.signalBright,
  );
}

/// A short technical line so a failure can be reported precisely instead of
/// hiding behind one generic sentence. It names the failing step and the
/// underlying cause; it never contains answers or personal data.
String _diagnostic(Object error) {
  if (error is! GaussFailure) return '';
  final cause = '${error.cause}'.replaceAll(RegExp(r'\s+'), ' ').trim();
  return '\n\nDetails: ${error.code}. $cause';
}

class _MissionError extends StatelessWidget {
  const _MissionError({required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => GaussStatePanel(
    title: 'Mission could not be loaded',
    detail: error is String
        ? '$error'
        : 'This device could not open the lesson. Your saved progress is unchanged.'
              '${_diagnostic(error)}',
    icon: Icons.error_outline_rounded,
    accent: GaussColors.error,
    actions: Wrap(
      spacing: GaussSpacing.space24,
      runSpacing: GaussSpacing.space16,
      alignment: WrapAlignment.center,
      children: [
        if (onRetry != null)
          OrbitalActionControl(
            key: const ValueKey('mission-load-retry-action'),
            semanticLabel: 'Try loading the mission again',
            caption: 'Try again',
            onPressed: onRetry,
            icon: Icons.refresh_rounded,
            dimension: 52,
            accent: GaussColors.error,
          ),
        OrbitalActionControl(
          key: const ValueKey('mission-load-map-action'),
          semanticLabel: 'Return to map',
          caption: 'Return to map',
          onPressed: () => context.go('/map'),
          icon: Icons.map_outlined,
          dimension: 56,
          accent: GaussColors.brassLight,
        ),
      ],
    ),
  );
}
