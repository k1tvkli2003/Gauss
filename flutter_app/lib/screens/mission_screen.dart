import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../domain/question_reference.dart';
import '../domain/study_curriculum.dart';
import '../feedback/feedback_capture.dart';
import '../feedback/feedback_models.dart';
import '../state/gauss_controller.dart';
import '../widgets/content_blocks.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/gauss_state_panel.dart';
import '../widgets/orbital_action_control.dart';
import '../widgets/question_progress_rail.dart';
import '../widgets/question_manuscript.dart';
import '../widgets/scratchpad.dart';
import '../widgets/theorem_lens.dart';

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
      await GaussScope.of(context).recordAttempt(
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
      await GaussScope.of(context).recordAttempt(
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
        final completion = await GaussScope.of(context).completeMission(
          sessionId: _sessionId,
          durationSeconds:
              DateTime.now().difference(_missionStartedAt).inSeconds +
              _elapsedBeforeResume,
        );
        if (!mounted) return;
        setState(() {
          _completion = completion;
          _finished = true;
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
      await GaussScope.of(context).tagAttempt(
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
      await GaussScope.of(context).reportQuestionIssue(
        QuestionIssueReport(
          questionId: question.id,
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
        final controller = GaussScope.of(context);
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
    final controller = GaussScope.of(context);
    _disposeInkControllers();
    setState(() {
      _resetSessionIdentity();
      _questions = const [];
      _index = 0;
      _selectedChoice = null;
      _checked = false;
      _finished = false;
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
      final controller = GaussScope.of(context);
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

class _QuestionStage extends StatelessWidget {
  const _QuestionStage({
    required this.question,
    required this.chapterLabel,
    required this.index,
    required this.total,
    required this.selectedChoice,
    required this.checked,
    required this.busy,
    required this.covered,
    required this.errorTag,
    required this.operationError,
    required this.ink,
    required this.onSelect,
    required this.onCheck,
    required this.onSkip,
    required this.onNext,
    required this.onRevealChoices,
    required this.onTagError,
    required this.onReportIssue,
    required this.onScratchpad,
    required this.onClearInk,
    required this.onRestoreInk,
    required this.onClose,
  });
  final Question question;
  final String chapterLabel;
  final int index;
  final int total;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final bool covered;
  final String? errorTag;
  final Object? operationError;
  final ScratchInkController ink;
  final ValueChanged<int> onSelect;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onRevealChoices;
  final ValueChanged<MissReason> onTagError;
  final VoidCallback onReportIssue;
  final VoidCallback onScratchpad;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final correct = checked && selectedChoice == question.correctChoiceIndex;
    final wrongPick = checked && selectedChoice != null && !correct;
    return Stack(
      fit: StackFit.expand,
      children: [
        const _MissionBackdrop(),
        SafeArea(
          child: Column(
            children: [
              _MissionTopBar(
                index: index,
                total: total,
                chapterLabel: chapterLabel,
                busy: busy,
                onClose: onClose,
                onScratchpad: onScratchpad,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    if (!wide) {
                      return _QuestionScroll(
                        question: question,
                        ink: ink,
                        index: index,
                        selectedChoice: selectedChoice,
                        checked: checked,
                        busy: busy,
                        covered: covered,
                        errorTag: errorTag,
                        showSolution: checked,
                        onSelect: onSelect,
                        onRevealChoices: onRevealChoices,
                        onTagError: onTagError,
                        onReportIssue: onReportIssue,
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth >= 1200 ? 270 : 238,
                            child: _CompanionDeck(
                              checked: checked,
                              correct: correct,
                              index: index,
                              total: total,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _QuestionScroll(
                              question: question,
                              ink: ink,
                              index: index,
                              selectedChoice: selectedChoice,
                              checked: checked,
                              busy: busy,
                              covered: covered,
                              errorTag: errorTag,
                              showSolution: false,
                              onSelect: onSelect,
                              onRevealChoices: onRevealChoices,
                              onTagError: onTagError,
                              onReportIssue: onReportIssue,
                              inset: EdgeInsets.zero,
                            ),
                          ),
                          if (checked) ...[
                            const SizedBox(width: 18),
                            SizedBox(
                              width: constraints.maxWidth >= 1250 ? 350 : 310,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (wrongPick) ...[
                                      _MissTagBar(
                                        selected: errorTag,
                                        onSelect: onTagError,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    _SolutionPanel(question: question),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              _MissionActionBar(
                question: question,
                ink: ink,
                index: index,
                total: total,
                selectedChoice: selectedChoice,
                checked: checked,
                busy: busy,
                operationError: operationError,
                onCheck: onCheck,
                onSkip: onSkip,
                onNext: onNext,
                onOpenInkWorkspace: onScratchpad,
                onClearInk: onClearInk,
                onRestoreInk: onRestoreInk,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionBackdrop extends StatelessWidget {
  const _MissionBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/visual/map/orrery_atmosphere_portrait.png',
        fit: BoxFit.cover,
        cacheWidth: 1200,
        filterQuality: FilterQuality.low,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xD907151C), Color(0xF2050B0D)],
          ),
        ),
      ),
    ],
  );
}

class _MissionTopBar extends StatelessWidget {
  const _MissionTopBar({
    required this.index,
    required this.total,
    required this.chapterLabel,
    required this.busy,
    required this.onClose,
    required this.onScratchpad,
  });

  final int index;
  final int total;
  final String chapterLabel;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onScratchpad;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
    child: Column(
      key: const ValueKey('mission-question-header'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: GaussMetrics.minTouchTarget,
          child: Stack(
            key: const ValueKey('mission-question-header-axis'),
            fit: StackFit.expand,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  key: const ValueKey('mission-close-action'),
                  onPressed: busy ? null : onClose,
                  tooltip: 'Leave mission',
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Align(
                alignment: Alignment.center,
                child: GaussWordmark(
                  key: ValueKey('mission-centered-wordmark'),
                  width: 82,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  key: const ValueKey('mission-scratchpad-action'),
                  onPressed: busy ? null : onScratchpad,
                  tooltip: 'Open full scratchpad',
                  icon: const GaussScratchGlyph(color: GaussColors.brassLight),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: GaussSpacing.space8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: QuestionProgressRail(
            key: const ValueKey('mission-question-progress'),
            index: index,
            total: total,
            label: chapterLabel,
            valueKey: const ValueKey('mission-question-position'),
          ),
        ),
      ],
    ),
  );
}

class _QuestionScroll extends StatelessWidget {
  const _QuestionScroll({
    required this.question,
    required this.ink,
    required this.index,
    required this.selectedChoice,
    required this.checked,
    required this.busy,
    required this.covered,
    required this.errorTag,
    required this.showSolution,
    required this.onSelect,
    required this.onRevealChoices,
    required this.onTagError,
    required this.onReportIssue,
    this.inset = const EdgeInsets.fromLTRB(16, 8, 16, 18),
  });

  final Question question;
  final ScratchInkController ink;
  final int index;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final bool covered;
  final String? errorTag;
  final bool showSolution;
  final ValueChanged<int> onSelect;
  final VoidCallback onRevealChoices;
  final ValueChanged<MissReason> onTagError;
  final VoidCallback onReportIssue;
  final EdgeInsets inset;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(12);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final manuscriptInset = compact
        ? (textScale >= 18
              ? const EdgeInsets.fromLTRB(8, 6, 8, 22)
              : const EdgeInsets.fromLTRB(12, 6, 12, 22))
        : inset;
    return SingleChildScrollView(
      key: const ValueKey('mission-question-scroll'),
      padding: manuscriptInset,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                explicitChildNodes: true,
                label:
                    'Question ${index + 1}. '
                    '${_blocksSemanticLabel(question.stem)}',
                child: QuestionManuscript(
                  key: const ValueKey('mission-question-paper'),
                  ink: ink,
                  questionNumber: index + 1,
                  difficulty: question.difficulty.label,
                  onExpandInk: () => showScratchpad(context, controller: ink),
                  onClearInk: ink.clear,
                  onRestoreInk: ink.restoreLastClear,
                  prompt: Directionality(
                    textDirection: TextDirection.rtl,
                    child: ContentBlocksView(
                      blocks: question.stem,
                      textColor: GaussColors.parchmentInk,
                      textStyle: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            color: GaussColors.parchmentInk,
                            fontFamily: 'Vazirmatn',
                            fontSize: 18,
                            height: 1.65,
                          ),
                    ),
                  ),
                  answers: covered && !checked
                      ? _CoveredChoicesPanel(
                          onReveal: busy ? null : onRevealChoices,
                          manuscript: true,
                        )
                      : Column(
                          key: const ValueKey('mission-answer-manuscript'),
                          children: [
                            for (
                              var choice = 0;
                              choice < question.options.length;
                              choice++
                            )
                              _AnswerChoice(
                                blocks: question.options[choice],
                                choice: choice,
                                selected: selectedChoice == choice,
                                checked: checked,
                                correctChoice: question.correctChoiceIndex,
                                onTap: checked || busy
                                    ? null
                                    : () => onSelect(choice),
                                manuscript: true,
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: GaussSpacing.space8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OrbitalActionControl(
                  key: const ValueKey('mission-report-question-action'),
                  semanticLabel: 'Report a problem with this question',
                  onPressed: busy ? null : onReportIssue,
                  icon: Icons.flag_outlined,
                  dimension: 48,
                  accent: GaussColors.fog,
                ),
              ),
              if (showSolution && checked) ...[
                if (selectedChoice != null &&
                    selectedChoice != question.correctChoiceIndex) ...[
                  const SizedBox(height: 6),
                  _MissTagBar(selected: errorTag, onSelect: onTagError),
                ],
                const SizedBox(height: 12),
                _SolutionPanel(question: question),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoveredChoicesPanel extends StatelessWidget {
  const _CoveredChoicesPanel({required this.onReveal, this.manuscript = false});

  final VoidCallback? onReveal;
  final bool manuscript;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label:
        'Answer-first mode. The four choices are covered. Derive your answer, then uncover them to commit.',
    child: Container(
      key: const ValueKey('mission-covered-choices'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: manuscript
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GaussColors.panelHigh.withValues(alpha: .94),
                  GaussColors.ink.withValues(alpha: .96),
                ],
              ),
        color: manuscript ? const Color(0x12FFFFFF) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GaussColors.brass.withValues(alpha: .4)),
      ),
      child: Column(
        children: [
          const GaussScratchGlyph(color: GaussColors.brassLight, size: 34),
          const SizedBox(height: 12),
          const Text(
            'Choices are covered',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Derive the answer first — on paper or the scratchpad — so the options cannot whisper. Uncover when your result is ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GaussColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          OrbitalActionControl(
            key: const ValueKey('mission-reveal-choices-action'),
            semanticLabel: 'Uncover answer choices',
            caption: 'Uncover choices',
            onPressed: onReveal,
            icon: Icons.visibility_outlined,
            dimension: 56,
            accent: GaussColors.brassLight,
          ),
        ],
      ),
    ),
  );
}

class _MissTagBar extends StatelessWidget {
  const _MissTagBar({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<MissReason> onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'Why did this one slip? Optional private note; scoring never changes.',
    child: Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: GaussColors.warning.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GaussColors.warning.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHY DID IT SLIP?',
            style: TextStyle(
              color: GaussColors.warning,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final reason in MissReason.values)
                _MissTagChip(
                  reason: reason,
                  selected: selected == reason.key,
                  onTap: () => onSelect(reason),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'A private note to your future self. Scoring never changes.',
            style: TextStyle(
              color: GaussColors.fog,
              fontSize: GaussTypeScale.caption,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MissTagChip extends StatelessWidget {
  const _MissTagChip({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final MissReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: reason.label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? GaussColors.warning.withValues(alpha: .16)
              : GaussColors.deepInk,
          borderRadius: BorderRadius.circular(GaussRadii.pill),
          border: Border.all(
            color: selected ? GaussColors.warning : GaussColors.hairline,
          ),
        ),
        child: Text(
          reason.label,
          style: TextStyle(
            color: selected ? GaussColors.warning : GaussColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _CompanionDeck extends StatelessWidget {
  const _CompanionDeck({
    required this.checked,
    required this.correct,
    required this.index,
    required this.total,
  });

  final bool checked;
  final bool correct;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final message = !checked
        ? 'Take your time. A clear chain of reasoning is the real win.'
        : correct
        ? 'Proof aligned. The next point on the map is ready.'
        : 'Useful signal. Read the solution, then test the idea again.';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GaussColors.panelHigh.withValues(alpha: .94),
            GaussColors.ink.withValues(alpha: .96),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GaussColors.line),
      ),
      child: Column(
        children: [
          const Text(
            'MIRA · PROOF COMPANION',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GaussColors.brassLight,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              child: Image.asset(
                checked && correct
                    ? 'assets/visual/mascot/mira_correct.png'
                    : 'assets/visual/mascot/mira_thinking.png',
                key: ValueKey(checked && correct),
                fit: BoxFit.contain,
                cacheWidth: 720,
                filterQuality: FilterQuality.medium,
                semanticLabel: checked && correct
                    ? 'Mira celebrates a correct answer.'
                    : 'Mira is thinking with you.',
              ),
            ),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: GaussColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 13),
          Text(
            '${index + 1} of $total',
            style: const TextStyle(
              color: GaussColors.signalBright,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionActionBar extends StatelessWidget {
  const _MissionActionBar({
    required this.question,
    required this.ink,
    required this.index,
    required this.total,
    required this.selectedChoice,
    required this.checked,
    required this.busy,
    required this.operationError,
    required this.onCheck,
    required this.onSkip,
    required this.onNext,
    required this.onOpenInkWorkspace,
    required this.onClearInk,
    required this.onRestoreInk,
  });

  final Question question;
  final ScratchInkController ink;
  final int index;
  final int total;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final Object? operationError;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onOpenInkWorkspace;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;

  VoidCallback? get primaryAction {
    if (busy) return null;
    if (operationError != null) {
      if (checked) return onNext;
      return selectedChoice == null ? onSkip : onCheck;
    }
    if (checked) return onNext;
    return selectedChoice == null ? null : onCheck;
  }

  String get primaryLabel {
    if (busy) return 'Saving…';
    if (operationError != null) return 'Try again';
    if (!checked) return 'Check answer';
    return index == total - 1 ? 'Finish mission' : 'Next question';
  }

  @override
  Widget build(BuildContext context) {
    final accessibleActionHeight =
        MediaQuery.textScalerOf(context).scale(14) >= 20;
    final isCorrect = selectedChoice == question.correctChoiceIndex;
    final feedback = operationError != null
        ? 'Save interrupted. Retry.'
        : checked
        ? isCorrect
              ? 'Correct. Proof holds.'
              : question.solutionVerified
              ? 'Review the proof, then continue.'
              : 'Source answer shown. Report anything that looks off.'
        : null;
    final feedbackColor = operationError != null
        ? GaussColors.error
        : isCorrect
        ? GaussColors.signalBright
        : GaussColors.brassLight;
    final reading =
        feedback ??
        (selectedChoice == null ? 'Select an answer' : 'Ready to check');
    final compactReading = operationError != null
        ? 'RETRY'
        : checked
        ? isCorrect
              ? 'PROOF HOLDS'
              : 'REVIEW'
        : selectedChoice == null
        ? 'SELECT'
        : 'READY';
    final readingIcon = operationError != null
        ? Icons.refresh_rounded
        : checked
        ? isCorrect
              ? Icons.verified_rounded
              : Icons.lightbulb_outline_rounded
        : selectedChoice == null
        ? Icons.touch_app_outlined
        : Icons.adjust_rounded;
    final safeBottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    // The stage-level SafeArea normally consumes Android's navigation inset.
    // Only own a bottom inset here when this dock is embedded without that
    // ancestor (for example in a focused widget harness). This prevents the
    // navigation clearance from being counted twice on real devices.
    final stageAlreadyInset = MediaQuery.paddingOf(context).bottom == 0;
    final dockBottom = stageAlreadyInset
        ? 6.0
        : math.max(10.0, safeBottom + 6.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, dockBottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(31),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                key: const ValueKey('mission-question-action-dock'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: GaussColors.deepInk.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(
                    color: GaussColors.brass.withValues(alpha: .26),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x52000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: ink,
                  builder: (context, _) => Row(
                    children: [
                      SizedBox.square(
                        dimension: 52,
                        child: !checked && !busy && operationError == null
                            ? IconButton.outlined(
                                key: const ValueKey('mission-skip-action'),
                                onPressed: onSkip,
                                tooltip: 'Skip this question',
                                icon: const Icon(
                                  Icons.fast_forward_rounded,
                                  size: 20,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: GaussSpacing.space8),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: accessibleActionHeight ? 70 : 52,
                          ),
                          child: AnimatedSwitcher(
                            duration: GaussMotion.resolve(
                              context,
                              GaussMotion.standard,
                            ),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: ink.isEmpty || ink.canRestoreClearedInk
                                ? ink.canRestoreClearedInk
                                      ? _MissionInkRestore(
                                          onRestore: onRestoreInk,
                                        )
                                      : _MissionReadinessSignal(
                                          semanticLabel: reading,
                                          label: compactReading,
                                          icon: readingIcon,
                                          color: feedback == null
                                              ? GaussColors.fog
                                              : feedbackColor,
                                          live: feedback != null,
                                        )
                                : _MissionInkControls(
                                    ink: ink,
                                    onExpand: onOpenInkWorkspace,
                                    onClear: onClearInk,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: GaussSpacing.space8),
                      _MissionPrimaryOrbit(
                        busy: busy,
                        checked: checked,
                        finalQuestion: index == total - 1,
                        operationError: operationError != null,
                        semanticLabel: primaryLabel,
                        onPressed: primaryAction,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionReadinessSignal extends StatelessWidget {
  const _MissionReadinessSignal({
    required this.semanticLabel,
    required this.label,
    required this.icon,
    required this.color,
    required this.live,
  });

  final String semanticLabel;
  final String label;
  final IconData icon;
  final Color color;
  final bool live;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('mission-readiness-signal'),
    liveRegion: live,
    label: semanticLabel,
    excludeSemantics: true,
    child: Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: GaussSpacing.space8,
        runSpacing: GaussSpacing.space4,
        children: [
          Icon(icon, size: 16, color: color),
          Text(
            label,
            key: ValueKey('mission-action-reading-$semanticLabel'),
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              color: color,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
              height: 1.15,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MissionPrimaryOrbit extends StatelessWidget {
  const _MissionPrimaryOrbit({
    required this.busy,
    required this.checked,
    required this.finalQuestion,
    required this.operationError,
    required this.semanticLabel,
    required this.onPressed,
  });

  final bool busy;
  final bool checked;
  final bool finalQuestion;
  final bool operationError;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox.square(
        dimension: 52,
        child: Padding(
          padding: EdgeInsets.all(15),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return OrbitalActionControl(
      key: const ValueKey('mission-primary-action'),
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      icon: operationError
          ? Icons.refresh_rounded
          : checked
          ? finalQuestion
                ? Icons.flag_rounded
                : Icons.arrow_forward_rounded
          : Icons.check_rounded,
      accent: operationError
          ? GaussColors.error
          : checked
          ? GaussColors.signalBright
          : GaussColors.brassLight,
      dimension: 52,
    );
  }
}

class _MissionInkControls extends StatelessWidget {
  const _MissionInkControls({
    required this.ink,
    required this.onExpand,
    required this.onClear,
  });

  final ScratchInkController ink;
  final VoidCallback onExpand;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('mission-ink-controls'),
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      IconButton(
        key: const ValueKey('mission-ink-undo'),
        onPressed: ink.canUndo ? ink.undo : null,
        tooltip: 'Undo last ink stroke',
        icon: const Icon(Icons.undo_rounded),
      ),
      IconButton(
        key: const ValueKey('mission-ink-expand'),
        onPressed: onExpand,
        tooltip: 'Open full scratchpad',
        icon: const Icon(Icons.open_in_full_rounded),
      ),
      IconButton(
        key: const ValueKey('mission-ink-clear'),
        onPressed: onClear,
        tooltip: 'Clear question ink',
        color: GaussColors.error,
        icon: const Icon(Icons.delete_sweep_outlined),
      ),
    ],
  );
}

class _MissionInkRestore extends StatelessWidget {
  const _MissionInkRestore({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Question ink cleared. Restore is available for four seconds.',
    child: Center(
      child: TextButton.icon(
        key: const ValueKey('mission-ink-restore'),
        onPressed: onRestore,
        icon: const Icon(Icons.undo_rounded, color: GaussColors.brassLight),
        label: const Text('Restore ink'),
      ),
    ),
  );
}

String _blocksSemanticLabel(List<ContentBlock> blocks) => blocks
    .map(
      (block) => switch (block) {
        TextBlock(:final text) => normalizeLearningDigits(text),
        ImageBlock(:final alt) =>
          alt.isEmpty ? 'Question image' : normalizeLearningDigits(alt),
      },
    )
    .where((text) => text.trim().isNotEmpty)
    .join('. ');

class _AnswerChoice extends StatelessWidget {
  const _AnswerChoice({
    required this.blocks,
    required this.choice,
    required this.selected,
    required this.checked,
    required this.correctChoice,
    required this.onTap,
    this.manuscript = false,
  });
  final List<ContentBlock> blocks;
  final int choice;
  final bool selected;
  final bool checked;
  final int correctChoice;
  final VoidCallback? onTap;
  final bool manuscript;

  @override
  Widget build(BuildContext context) {
    final isCorrect = checked && choice == correctChoice;
    final isWrong = checked && selected && choice != correctChoice;
    final tone = isCorrect
        ? TheoremChoiceTone.positive
        : isWrong
        ? TheoremChoiceTone.negative
        : selected
        ? TheoremChoiceTone.selected
        : TheoremChoiceTone.neutral;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      excludeSemantics: true,
      onTap: onTap,
      label:
          'Choice ${choice + 1}. ${_blocksSemanticLabel(blocks)}. '
          '${isCorrect
              ? 'Correct answer.'
              : isWrong
              ? 'Selected answer, incorrect.'
              : selected
              ? 'Selected.'
              : ''}',
      child: manuscript
          ? ManuscriptChoiceShell(
              tone: tone,
              onTap: onTap,
              emblem: isCorrect
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: GaussColors.teal,
                    )
                  : isWrong
                  ? const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: GaussColors.error,
                    )
                  : Text(
                      String.fromCharCode(65 + choice),
                      style: const TextStyle(
                        color: GaussColors.parchmentInk,
                        fontFamily: 'serif',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
              child: ContentBlocksView(
                blocks: blocks,
                compact: true,
                textColor: GaussColors.parchmentInk,
              ),
            )
          : TheoremChoiceShell(
              tone: tone,
              onTap: onTap,
              emblem: isCorrect
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: GaussColors.teal,
                    )
                  : isWrong
                  ? const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: GaussColors.error,
                    )
                  : Text(
                      String.fromCharCode(65 + choice),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
              child: ContentBlocksView(blocks: blocks, compact: true),
            ),
    );
  }
}

class _SolutionPanel extends StatelessWidget {
  const _SolutionPanel({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    final certified = question.missionReady && question.solutionVerified;
    final heading = certified ? 'Classic solution' : 'Source solution';
    return Semantics(
      container: true,
      label: certified
          ? 'Scientifically reviewed solution.'
          : 'Source-provided solution shown provisionally for private practice.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    certified
                        ? Icons.lightbulb_outline
                        : Icons.menu_book_outlined,
                    color: GaussColors.brassLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      heading,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (certified)
                    const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: GaussColors.signalBright,
                    ),
                ],
              ),
              if (!certified) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GaussColors.brass.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: GaussColors.brass.withValues(alpha: .22),
                    ),
                  ),
                  child: const Text(
                    'Shown from the preserved source for private practice. If anything looks inconsistent, use the report action and keep going.',
                    style: TextStyle(
                      color: GaussColors.muted,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ContentBlocksView(blocks: question.solution),
              if (question.shortcut case final shortcut?) ...[
                const Divider(height: 28),
                const Text(
                  'Smart shortcut',
                  style: TextStyle(
                    color: GaussColors.brassLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ContentBlocksView(blocks: shortcut),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionIssueDraft {
  const _QuestionIssueDraft({
    required this.kind,
    required this.note,
    required this.includeScreenshot,
  });

  final QuestionIssueKind kind;
  final String note;
  final bool includeScreenshot;
}

class _QuestionIssueSheet extends StatefulWidget {
  const _QuestionIssueSheet({required this.questionId, this.screenshot});

  final String questionId;
  final GaussFeedbackScreenshot? screenshot;

  @override
  State<_QuestionIssueSheet> createState() => _QuestionIssueSheetState();
}

class _QuestionIssueSheetState extends State<_QuestionIssueSheet> {
  var _kind = QuestionIssueKind.questionText;
  var _includeScreenshot = true;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('question-issue-sheet'),
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + keyboard),
        decoration: BoxDecoration(
          color: GaussColors.panelHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: GaussColors.brass.withValues(alpha: .36)),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 30),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GaussColors.fog.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'REPORT QUESTION ISSUE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                questionDisplayReference(widget.questionId),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                softWrap: true,
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: 11,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kind in QuestionIssueKind.values)
                    ChoiceChip(
                      key: ValueKey('question-issue-kind-${kind.key}'),
                      label: Text(kind.label),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.screenshot != null) ...[
                Container(
                  key: const ValueKey('question-issue-screenshot-preview'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GaussColors.deepInk.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GaussColors.hairline),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: Image.memory(
                            widget.screenshot!.bytes,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          key: const ValueKey(
                            'question-issue-include-screenshot',
                          ),
                          value: _includeScreenshot,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Attach this screen'),
                          subtitle: const Text(
                            'Pixels are stored exactly as shown and are not redacted.',
                          ),
                          onChanged: (value) => setState(
                            () => _includeScreenshot = value ?? false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                key: const ValueKey('question-issue-note'),
                controller: _note,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Optional note',
                  hintText: 'What looked wrong?',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('question-issue-save'),
                onPressed: () => Navigator.pop(
                  context,
                  _QuestionIssueDraft(
                    kind: _kind,
                    note: _note.text.trim(),
                    includeScreenshot:
                        widget.screenshot != null && _includeScreenshot,
                  ),
                ),
                icon: const Icon(Icons.bookmark_added_outlined),
                label: const Text('Save report on this device'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionComplete extends StatelessWidget {
  const _MissionComplete({
    required this.correct,
    required this.total,
    required this.completion,
    required this.onMap,
    required this.onRetry,
  });
  final int correct;
  final int total;
  final MissionCompletion completion;
  final VoidCallback onMap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final rewards = <String, int>{};
    for (final line in completion.lines) {
      rewards.update(
        line.reason,
        (amount) => amount + line.amount,
        ifAbsent: () => line.amount,
      );
    }

    final accuracy = total == 0 ? 0.0 : correct / total;
    final headline = accuracy == 1
        ? 'Perfect orbit'
        : accuracy >= .8
        ? 'Orbit secured'
        : 'Mission charted';
    final detail = accuracy == 1
        ? 'Every proof aligned. This five-point orbit is now complete.'
        : accuracy >= .8
        ? 'A strong signal is recorded. The missed coordinate is ready for a calm revisit.'
        : 'Every miss is now a useful revisit coordinate. Your progress is safely recorded.';
    final semanticSummary = StringBuffer(
      '$headline. $correct of $total correct. '
      '${completion.xpEarned} XP earned. ${completion.totalXp} total XP.',
    );
    for (final reward in rewards.entries) {
      semanticSummary.write(' ${reward.key}, ${reward.value} XP.');
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const _MissionBackdrop(),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('mission-completion-scroll'),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Semantics(
                        key: const ValueKey('mission-completion-screen'),
                        container: true,
                        liveRegion: true,
                        label: semanticSummary.toString(),
                        child: Container(
                          padding: const EdgeInsets.all(GaussSpacing.space20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                GaussColors.panelHigh.withValues(alpha: .96),
                                GaussColors.ink.withValues(alpha: .98),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              GaussRadii.large,
                            ),
                            border: Border.all(
                              color: GaussColors.brass.withValues(alpha: .42),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x99000000),
                                blurRadius: 36,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final textHeight = MediaQuery.textScalerOf(
                                context,
                              ).scale(14);
                              final wide =
                                  constraints.maxWidth >= 650 &&
                                  textHeight < 20;
                              final visual = _MissionCompletionVisual(
                                accuracy: accuracy,
                                correct: correct,
                                total: total,
                                compact: !wide,
                              );
                              final summary = _MissionCompletionSummary(
                                total: total,
                                headline: headline,
                                detail: detail,
                                completion: completion,
                                rewards: rewards,
                              );
                              if (!wide) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    visual,
                                    const SizedBox(
                                      height: GaussSpacing.space12,
                                    ),
                                    summary,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(width: 286, child: visual),
                                  const SizedBox(width: GaussSpacing.space24),
                                  Expanded(child: summary),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _MissionCompletionDock(onRetry: onRetry, onMap: onMap),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionCompletionVisual extends StatelessWidget {
  const _MissionCompletionVisual({
    required this.accuracy,
    required this.correct,
    required this.total,
    required this.compact,
  });

  final double accuracy;
  final int correct;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: compact ? 218 : 330,
    child: RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: GaussMotion.resolve(
          context,
          const Duration(milliseconds: 980),
        ),
        curve: Curves.easeOutCubic,
        builder: (context, reveal, _) => Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _MissionCompletionOrbitPainter(reveal: reveal),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Transform.scale(
                scale: .94 + reveal * .06,
                child: Opacity(
                  opacity: reveal,
                  child: Image.asset(
                    accuracy >= .7
                        ? 'assets/visual/mascot/mira_correct.png'
                        : 'assets/visual/mascot/mira_thinking.png',
                    height: compact ? 178 : 264,
                    fit: BoxFit.contain,
                    cacheHeight: compact ? 534 : 792,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: compact ? 0 : 8,
              child: _ScoreSeal(
                accuracy: accuracy,
                correct: correct,
                total: total,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MissionCompletionSummary extends StatelessWidget {
  const _MissionCompletionSummary({
    required this.total,
    required this.headline,
    required this.detail,
    required this.completion,
    required this.rewards,
  });

  final int total;
  final String headline;
  final String detail;
  final MissionCompletion completion;
  final Map<String, int> rewards;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: GaussWordmark(width: 118),
      ),
      const SizedBox(height: GaussSpacing.space12),
      Text(
        '$total-QUESTION MISSION',
        style: const TextStyle(
          color: GaussColors.brassLight,
          fontSize: GaussTypeScale.insignia,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.25,
        ),
      ),
      const SizedBox(height: GaussSpacing.space4),
      Text(
        headline,
        key: const ValueKey('mission-completion-headline'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: GaussSpacing.space8),
      Text(
        detail,
        style: const TextStyle(color: GaussColors.muted, height: 1.5),
      ),
      const SizedBox(height: GaussSpacing.space16),
      _MissionCompletionMetrics(completion: completion),
      if (completion.levelAfter > completion.levelBefore) ...[
        const SizedBox(height: GaussSpacing.space12),
        Semantics(
          label: 'Level ${completion.levelAfter} reached',
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GaussColors.brass.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(GaussRadii.medium),
              border: Border.all(
                color: GaussColors.brass.withValues(alpha: .42),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: GaussColors.brassLight,
                ),
                const SizedBox(width: GaussSpacing.space8),
                Expanded(
                  child: Text(
                    'Level ${completion.levelAfter} reached',
                    style: const TextStyle(
                      color: GaussColors.brassLight,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: GaussSpacing.space12),
      _MissionRewardReceipt(rewards: rewards),
    ],
  );
}

class _MissionCompletionMetrics extends StatelessWidget {
  const _MissionCompletionMetrics({required this.completion});

  final MissionCompletion completion;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final accessible =
          constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) >= 20;
      final earned = _CompletionMetric(
        icon: Icons.auto_awesome_rounded,
        label: 'THIS MISSION',
        value: completion.xpEarned > 0
            ? '+${completion.xpEarned} XP'
            : 'XP cap met',
        color: GaussColors.signalBright,
      );
      final total = _CompletionMetric(
        icon: Icons.explore_rounded,
        label: 'PRIVATE TOTAL',
        value: '${completion.totalXp} XP',
        color: GaussColors.brassLight,
      );
      if (accessible) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [earned, const SizedBox(height: 8), total],
        );
      }
      return Row(
        children: [
          Expanded(child: earned),
          const SizedBox(width: 8),
          Expanded(child: total),
        ],
      );
    },
  );
}

class _CompletionMetric extends StatelessWidget {
  const _CompletionMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 72),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(GaussRadii.medium),
      border: Border.all(color: color.withValues(alpha: .34)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .65,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MissionRewardReceipt extends StatelessWidget {
  const _MissionRewardReceipt({required this.rewards});

  final Map<String, int> rewards;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Recorded XP receipt',
    child: Container(
      key: const ValueKey('mission-reward-receipt'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GaussColors.deepInk.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(GaussRadii.medium),
        border: Border.all(color: GaussColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RECORDED XP',
            style: TextStyle(
              color: GaussColors.fog,
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 6),
          if (rewards.isEmpty)
            const Text(
              'Mission recorded. Today’s reward cap was already met.',
              style: TextStyle(color: GaussColors.muted, height: 1.45),
            )
          else
            for (final reward in rewards.entries)
              _MissionRewardLine(reason: reward.key, amount: reward.value),
        ],
      ),
    ),
  );
}

class _MissionRewardLine extends StatelessWidget {
  const _MissionRewardLine({required this.reason, required this.amount});

  final String reason;
  final int amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 250 ||
            MediaQuery.textScalerOf(context).scale(14) >= 20;
        final reasonWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TheoremStarMark(size: 16),
            const SizedBox(width: 8),
            Flexible(child: Text(reason)),
          ],
        );
        final amountWidget = Text(
          '+$amount XP',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: GaussColors.signalBright,
            fontWeight: FontWeight.w900,
          ),
        );
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              reasonWidget,
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 24),
                child: amountWidget,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: reasonWidget),
            const SizedBox(width: 12),
            amountWidget,
          ],
        );
      },
    ),
  );
}

class _MissionCompletionDock extends StatelessWidget {
  const _MissionCompletionDock({required this.onRetry, required this.onMap});

  final VoidCallback onRetry;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              key: const ValueKey('mission-completion-actions'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
              decoration: BoxDecoration(
                color: GaussColors.deepInk.withValues(alpha: .93),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: OrbitalActionControl(
                        key: const ValueKey('mission-retry-action'),
                        semanticLabel: 'Start another mission',
                        caption: 'New mission',
                        onPressed: onRetry,
                        icon: Icons.replay_rounded,
                        dimension: 52,
                        accent: GaussColors.ice,
                      ),
                    ),
                  ),
                  const SizedBox(width: GaussSpacing.space12),
                  Expanded(
                    child: Center(
                      child: OrbitalActionControl(
                        key: const ValueKey('mission-map-action'),
                        semanticLabel: 'Return to map',
                        caption: 'Return to map',
                        onPressed: onMap,
                        icon: Icons.map_outlined,
                        dimension: 58,
                        accent: GaussColors.signalBright,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ScoreSeal extends StatelessWidget {
  const _ScoreSeal({
    required this.accuracy,
    required this.correct,
    required this.total,
  });

  final double accuracy;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '$correct of $total correct, ${(accuracy * 100).round()} percent accuracy',
    excludeSemantics: true,
    child: Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GaussColors.deepInk.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(GaussRadii.pill),
        border: Border.all(color: GaussColors.brassLight),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 16)],
      ),
      child: Text(
        '$correct / $total · ${(accuracy * 100).round()}%',
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GaussColors.ivory,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _MissionCompletionOrbitPainter extends CustomPainter {
  const _MissionCompletionOrbitPainter({required this.reveal});

  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .38;
    final glow = Paint()
      ..color = GaussColors.brass.withValues(alpha: .16 * reveal)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius * .86, glow);

    for (final ratio in const [.62, .82, 1.0]) {
      canvas.drawCircle(
        center,
        radius * ratio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ratio == 1 ? 1.2 : .7
          ..color = GaussColors.brass.withValues(
            alpha: (ratio == 1 ? .38 : .2) * reveal,
          ),
      );
    }

    final route = Path();
    final points = <Offset>[];
    for (var index = 0; index < 5; index++) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      points.add(point);
      if (index == 0) {
        route.moveTo(point.dx, point.dy);
      } else {
        route.lineTo(point.dx, point.dy);
      }
    }
    route.close();
    canvas.drawPath(
      route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = GaussColors.brassLight.withValues(alpha: .2 * reveal),
    );

    for (var index = 0; index < points.length; index++) {
      final pointReveal = ((reveal * 6) - index).clamp(0.0, 1.0);
      canvas.drawCircle(
        points[index],
        8 * pointReveal,
        Paint()
          ..color = GaussColors.brassLight.withValues(alpha: .16 * pointReveal)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        points[index],
        3 + 1.7 * pointReveal,
        Paint()
          ..color = Color.lerp(
            GaussColors.line,
            GaussColors.signalBright,
            pointReveal,
          )!,
      );
    }
  }

  @override
  bool shouldRepaint(_MissionCompletionOrbitPainter oldDelegate) =>
      oldDelegate.reveal != reveal;
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

class _MissionError extends StatelessWidget {
  const _MissionError({required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => GaussStatePanel(
    title: 'Mission could not be loaded',
    detail: error is String
        ? '$error'
        : 'The offline archive could not open this mission. Your saved progress is unchanged.',
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
