import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/content_blocks.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/scratchpad.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({
    required this.topicKey,
    this.count = 10,
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
          : await controller.createMission(
              widget.topicKey,
              count: widget.count,
              difficulties: widget.difficulties,
              sourceBanks: widget.sourceBanks,
            );
      if (questions.any((question) => !question.missionReady)) {
        throw StateError(
          'Preserved source items cannot enter a scored mission.',
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
        context.replace('/mission/$_sourceTopicKey?count=${_questions.length}');
      }
      return;
    }
    final controller = GaussScope.of(context);
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
    if (_index == 0 && _selectedChoice == null && !_checked) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave this mission?'),
            content: const Text(
              'Recorded answers and the remaining queue are saved on this device. Resume whenever you return.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
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
                  : 'No mission-ready questions are available for this topic.',
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
          return _QuestionStage(
            question: _questions[_index],
            index: _index,
            total: _questions.length,
            selectedChoice: _selectedChoice,
            checked: _checked,
            busy: _saving,
            covered: !_choicesRevealed,
            errorTag: _errorTag,
            operationError: _operationError,
            onSelect: (choice) => setState(() => _selectedChoice = choice),
            onCheck: _checkAnswer,
            onSkip: _skipAnswer,
            onNext: _next,
            onRevealChoices: () => setState(() => _choicesRevealed = true),
            onTagError: _tagError,
            onScratchpad: () => showScratchpad(context),
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
    required this.index,
    required this.total,
    required this.selectedChoice,
    required this.checked,
    required this.busy,
    required this.covered,
    required this.errorTag,
    required this.operationError,
    required this.onSelect,
    required this.onCheck,
    required this.onSkip,
    required this.onNext,
    required this.onRevealChoices,
    required this.onTagError,
    required this.onScratchpad,
    required this.onClose,
  });
  final Question question;
  final int index;
  final int total;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final bool covered;
  final String? errorTag;
  final Object? operationError;
  final ValueChanged<int> onSelect;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onRevealChoices;
  final ValueChanged<MissReason> onTagError;
  final VoidCallback onScratchpad;
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
                index: index,
                total: total,
                selectedChoice: selectedChoice,
                checked: checked,
                busy: busy,
                operationError: operationError,
                onCheck: onCheck,
                onSkip: onSkip,
                onNext: onNext,
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
    required this.busy,
    required this.onClose,
    required this.onScratchpad,
  });

  final int index;
  final int total;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onScratchpad;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
    child: Row(
      children: [
        IconButton(
          onPressed: busy ? null : onClose,
          tooltip: 'Leave mission',
          icon: const Icon(Icons.close_rounded),
        ),
        const GaussWordmark(width: 92),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GaussRadii.pill),
            child: LinearProgressIndicator(
              value: (index + 1) / total,
              minHeight: 7,
              backgroundColor: GaussColors.hairline,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Semantics(
          label: 'Question ${index + 1} of $total',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GaussColors.deepInk.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GaussColors.hairline),
            ),
            child: Text(
              '${index + 1} / $total',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 3),
        IconButton(
          onPressed: busy ? null : onScratchpad,
          tooltip: 'Open scratchpad',
          icon: const GaussScratchGlyph(color: GaussColors.brassLight),
        ),
      ],
    ),
  );
}

class _QuestionScroll extends StatelessWidget {
  const _QuestionScroll({
    required this.question,
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
    this.inset = const EdgeInsets.fromLTRB(16, 8, 16, 18),
  });

  final Question question;
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
  final EdgeInsets inset;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: inset,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'QUESTION ${index + 1}',
                  style: const TextStyle(
                    color: GaussColors.brassLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: GaussColors.brass.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(GaussRadii.pill),
                    border: Border.all(
                      color: GaussColors.brass.withValues(alpha: .3),
                    ),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      question.difficulty.label,
                      style: const TextStyle(
                        color: GaussColors.brassLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              container: true,
              excludeSemantics: true,
              label: _blocksSemanticLabel(question.stem),
              child: _QuestionPaper(question: question),
            ),
            const SizedBox(height: 15),
            if (covered && !checked)
              _CoveredChoicesPanel(onReveal: busy ? null : onRevealChoices)
            else
              for (var choice = 0; choice < question.options.length; choice++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnswerChoice(
                    blocks: question.options[choice],
                    choice: choice,
                    selected: selectedChoice == choice,
                    checked: checked,
                    correctChoice: question.correctChoiceIndex,
                    onTap: checked || busy ? null : () => onSelect(choice),
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

class _CoveredChoicesPanel extends StatelessWidget {
  const _CoveredChoicesPanel({required this.onReveal});

  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'Answer-first mode. The four choices are covered. Derive your answer, then uncover them to commit.',
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GaussColors.panelHigh.withValues(alpha: .94),
            GaussColors.ink.withValues(alpha: .96),
          ],
        ),
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
          FilledButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.visibility_outlined, size: 19),
            label: const Text('Uncover the choices'),
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
              fontSize: 9,
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
            style: TextStyle(color: GaussColors.fog, fontSize: 9.5),
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

class _QuestionPaper extends StatelessWidget {
  const _QuestionPaper({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 142),
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF7EED9), GaussColors.parchment],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: GaussColors.brass.withValues(alpha: .65)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          top: -12,
          right: -9,
          child: Opacity(
            opacity: .08,
            child: TheoremStarMark(size: 82, darkInk: true),
          ),
        ),
        InlineQuestionScratch(
          key: ValueKey('mission-ink-${question.id}'),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ContentBlocksView(
              blocks: question.stem,
              textColor: GaussColors.parchmentInk,
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: GaussColors.parchmentInk,
                fontFamily: 'Vazirmatn',
                height: 1.7,
              ),
            ),
          ),
        ),
      ],
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
              fontSize: 9,
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
    required this.index,
    required this.total,
    required this.selectedChoice,
    required this.checked,
    required this.busy,
    required this.operationError,
    required this.onCheck,
    required this.onSkip,
    required this.onNext,
  });

  final Question question;
  final int index;
  final int total;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final Object? operationError;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onNext;

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
    final isCorrect = selectedChoice == question.correctChoiceIndex;
    final feedback = operationError != null
        ? 'This step is still on screen. Try saving it again.'
        : checked
        ? isCorrect
              ? 'Correct. The proof holds.'
              : question.solutionVerified
              ? 'Review the reasoning, then continue.'
              : 'The verified answer is highlighted; the conflicting note stays hidden.'
        : null;
    final feedbackColor = operationError != null
        ? GaussColors.error
        : isCorrect
        ? GaussColors.signalBright
        : GaussColors.brassLight;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFA0B1417),
        border: Border(top: BorderSide(color: GaussColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final controls = Row(
                  mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (!checked && !busy && operationError == null) ...[
                      TextButton(onPressed: onSkip, child: const Text('Skip')),
                      const SizedBox(width: 7),
                    ],
                    if (compact)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: primaryAction,
                          icon: _PrimaryActionIcon(
                            busy: busy,
                            checked: checked,
                          ),
                          label: Text(primaryLabel),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: primaryAction,
                        icon: _PrimaryActionIcon(busy: busy, checked: checked),
                        label: Text(primaryLabel),
                      ),
                  ],
                );
                if (!compact) {
                  return Row(
                    children: [
                      if (feedback != null)
                        Expanded(
                          child: Text(
                            feedback,
                            style: TextStyle(
                              color: feedbackColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      controls,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (feedback != null) ...[
                      Text(
                        feedback,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: feedbackColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    controls,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionIcon extends StatelessWidget {
  const _PrimaryActionIcon({required this.busy, required this.checked});

  final bool busy;
  final bool checked;

  @override
  Widget build(BuildContext context) => busy
      ? const SizedBox.square(
          dimension: 17,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(checked ? Icons.arrow_forward_rounded : Icons.check_rounded);
}

String _blocksSemanticLabel(List<ContentBlock> blocks) => blocks
    .map(
      (block) => switch (block) {
        TextBlock(:final text) => text,
        ImageBlock(:final alt) => alt.isEmpty ? 'Question image' : alt,
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
  });
  final List<ContentBlock> blocks;
  final int choice;
  final bool selected;
  final bool checked;
  final int correctChoice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = checked && choice == correctChoice;
    final isWrong = checked && selected && choice != correctChoice;
    final border = isCorrect
        ? GaussColors.teal
        : (isWrong
              ? GaussColors.error
              : (selected ? GaussColors.brassLight : GaussColors.line));
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label:
          'Choice ${choice + 1}. ${_blocksSemanticLabel(blocks)}. '
          '${isCorrect
              ? 'Correct answer.'
              : isWrong
              ? 'Selected answer, incorrect.'
              : selected
              ? 'Selected.'
              : ''}',
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCorrect
                ? [
                    GaussColors.signal.withValues(alpha: .19),
                    GaussColors.deepInk,
                  ]
                : isWrong
                ? [
                    GaussColors.error.withValues(alpha: .14),
                    GaussColors.deepInk,
                  ]
                : [GaussColors.panelHigh, GaussColors.raised],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: border,
            width: selected || isCorrect ? 2 : 1,
          ),
          boxShadow: selected || isCorrect
              ? [
                  BoxShadow(
                    color: border.withValues(alpha: .12),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: border),
                  ),
                  child: isCorrect
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: GaussColors.teal,
                        )
                      : (isWrong
                            ? const Icon(
                                Icons.close,
                                size: 18,
                                color: GaussColors.error,
                              )
                            : Text(
                                String.fromCharCode(65 + choice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ContentBlocksView(blocks: blocks, compact: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SolutionPanel extends StatelessWidget {
  const _SolutionPanel({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    if (!question.missionReady) {
      return Semantics(
        container: true,
        label:
            'Source item quarantined. Its answer and explanation mapping are not verified.',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: GaussColors.brassLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Source item quarantined',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'This source item remains preserved in the local archive, but its answer and explanation mapping are not verified. Gauss excludes it from scoring instead of presenting uncertain guidance.',
                  style: TextStyle(color: GaussColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!question.solutionVerified) {
      return Semantics(
        container: true,
        label:
            'Explanation withheld. The archived explanation conflicts with its answer contract.',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.rule_folder_outlined,
                      color: GaussColors.brassLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Explanation withheld',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'The archived explanation conflicts with this question’s answer contract. Gauss preserves the source text but does not present it as guidance.',
                  style: TextStyle(color: GaussColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: GaussColors.brassLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Classic solution',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        const _MissionBackdrop(),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        GaussColors.panelHigh.withValues(alpha: .96),
                        GaussColors.ink.withValues(alpha: .97),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: GaussColors.line),
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
                      final wide = constraints.maxWidth >= 650;
                      final visual = SizedBox(
                        width: wide ? 280 : double.infinity,
                        height: wide ? 370 : 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: GaussColors.brass.withValues(
                                      alpha: .19,
                                    ),
                                    blurRadius: 70,
                                    spreadRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              accuracy >= .7
                                  ? 'assets/visual/mascot/mira_correct.png'
                                  : 'assets/visual/mascot/mira_thinking.png',
                              fit: BoxFit.contain,
                              cacheWidth: 820,
                              filterQuality: FilterQuality.medium,
                              semanticLabel: accuracy >= .7
                                  ? 'Mira celebrates the completed mission.'
                                  : 'Mira considers the completed mission with you.',
                            ),
                            Positioned(
                              bottom: 2,
                              child: _ScoreSeal(
                                accuracy: accuracy,
                                correct: correct,
                                total: total,
                              ),
                            ),
                          ],
                        ),
                      );
                      final summary = Column(
                        crossAxisAlignment: wide
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          const GaussWordmark(width: 148),
                          const SizedBox(height: 16),
                          Text(
                            'Mission complete',
                            textAlign: wide
                                ? TextAlign.start
                                : TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            correct == total
                                ? 'Every answer aligned. This orbit now burns brighter.'
                                : 'A new signal is recorded. Revisit the misses when you are ready.',
                            textAlign: wide
                                ? TextAlign.start
                                : TextAlign.center,
                            style: const TextStyle(color: GaussColors.muted),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: wide
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              _CompletionMetric(
                                label: 'EARNED',
                                value: '+${completion.xpEarned} XP',
                                color: GaussColors.signalBright,
                              ),
                              const SizedBox(width: 10),
                              _CompletionMetric(
                                label: 'TOTAL',
                                value: '${completion.totalXp} XP',
                                color: GaussColors.brassLight,
                              ),
                            ],
                          ),
                          if (completion.levelAfter >
                              completion.levelBefore) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Level ${completion.levelAfter} reached',
                              style: const TextStyle(
                                color: GaussColors.brassLight,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                          if (rewards.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Semantics(
                              container: true,
                              label: 'Recorded rewards',
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: GaussColors.deepInk.withValues(
                                    alpha: .8,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: GaussColors.hairline,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    for (final entry in rewards.entries)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Row(
                                          children: [
                                            const TheoremStarMark(size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(entry.key)),
                                            Text(
                                              '+${entry.value} XP',
                                              style: const TextStyle(
                                                color: GaussColors.signalBright,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: onRetry,
                                  child: const Text('New mission'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: onMap,
                                  child: const Text('Back to map'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                      if (!wide) {
                        return Column(children: [visual, summary]);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          visual,
                          const SizedBox(width: 28),
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
      ],
    );
  }
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(GaussRadii.pill),
      border: Border.all(color: GaussColors.brass),
      boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 16)],
    ),
    child: Text(
      '$correct / $total · ${(accuracy * 100).round()}%',
      style: const TextStyle(
        color: GaussColors.ivory,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CompletionMetric extends StatelessWidget {
  const _CompletionMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: GaussColors.deepInk,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GaussColors.hairline),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
      ],
    ),
  );
}

class _MissionLoading extends StatelessWidget {
  const _MissionLoading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 14),
        Text('Charting a mission…'),
      ],
    ),
  );
}

class _MissionError extends StatelessWidget {
  const _MissionError({required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: GaussColors.error,
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(
                'Mission could not be loaded',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error is String
                    ? '$error'
                    : 'The offline archive could not open this mission. Your saved progress is unchanged.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: GaussColors.muted),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onRetry != null) ...[
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                    const SizedBox(width: 10),
                  ],
                  FilledButton(
                    onPressed: () => context.go('/map'),
                    child: const Text('Return to map'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
