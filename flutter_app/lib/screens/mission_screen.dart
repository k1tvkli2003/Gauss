import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/content_blocks.dart';
import '../widgets/scratchpad.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({
    required this.topicKey,
    this.count = 10,
    this.difficulties = const {},
    this.sourceBanks = const {},
    this.revenge = false,
    this.resume = false,
    super.key,
  });
  final String topicKey;
  final int count;
  final Set<Difficulty> difficulties;
  final Set<String> sourceBanks;
  final bool revenge;
  final bool resume;

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

  @override
  void initState() {
    super.initState();
    _sourceTopicKey = widget.revenge ? 'revenge' : widget.topicKey;
    _resetSessionIdentity();
  }

  void _resetSessionIdentity() {
    final now = DateTime.now();
    _sessionId =
        '${widget.revenge ? 'revenge' : 'mission'}_${now.microsecondsSinceEpoch}_${widget.topicKey}';
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
        _correct = saved.attempts.where((attempt) => attempt.correct).length;
        _elapsedBeforeResume = saved.attempts.fold(
          0,
          (total, attempt) => total + attempt.elapsedSeconds,
        );
        return saved.questions;
      }
      final questions = widget.revenge
          ? await controller.createRevengeMission(count: widget.count)
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
          topicKey: widget.revenge ? 'revenge' : widget.topicKey,
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
      _questionStartedAt = DateTime.now();
    });
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
            operationError: _operationError,
            onSelect: (choice) => setState(() => _selectedChoice = choice),
            onCheck: _checkAnswer,
            onSkip: _skipAnswer,
            onNext: _next,
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
    required this.operationError,
    required this.onSelect,
    required this.onCheck,
    required this.onSkip,
    required this.onNext,
    required this.onScratchpad,
    required this.onClose,
  });
  final Question question;
  final int index;
  final int total;
  final int? selectedChoice;
  final bool checked;
  final bool busy;
  final Object? operationError;
  final ValueChanged<int> onSelect;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onScratchpad;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: busy ? null : onClose,
                tooltip: 'Leave mission',
                icon: const Icon(Icons.close),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: (index + 1) / total,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                  backgroundColor: GaussColors.line,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${index + 1} / $total',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: busy ? null : onScratchpad,
                tooltip: 'Open scratchpad',
                icon: const Icon(Icons.edit_note),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 150),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          question.difficulty.label,
                          style: const TextStyle(
                            color: GaussColors.brassLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          question.sourceBank.toUpperCase(),
                          style: const TextStyle(
                            color: GaussColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: GaussColors.parchment,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: GaussColors.brass.withValues(alpha: .5),
                        ),
                      ),
                      child: ContentBlocksView(
                        blocks: question.stem,
                        textColor: GaussColors.parchmentInk,
                        textStyle: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (
                      var choice = 0;
                      choice < question.options.length;
                      choice++
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AnswerChoice(
                          blocks: question.options[choice],
                          choice: choice,
                          selected: selectedChoice == choice,
                          checked: checked,
                          correctChoice: question.correctChoiceIndex,
                          onTap: checked || busy
                              ? null
                              : () => onSelect(choice),
                        ),
                      ),
                    if (checked) ...[
                      const SizedBox(height: 12),
                      _SolutionPanel(question: question),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xF20C1113),
            border: Border(top: BorderSide(color: GaussColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 850,
                  child: Row(
                    children: [
                      if (operationError != null)
                        const Expanded(
                          child: Text(
                            'We could not save this step. Your answer is still here—try again.',
                            style: TextStyle(
                              color: GaussColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (checked)
                        Expanded(
                          child: Text(
                            selectedChoice == question.correctChoiceIndex
                                ? 'Correct — orbit stabilized.'
                                : question.solutionVerified
                                ? 'Review the solution, then continue.'
                                : 'The conflicting explanation is withheld; use the highlighted answer.',
                            style: TextStyle(
                              color:
                                  selectedChoice == question.correctChoiceIndex
                                  ? GaussColors.teal
                                  : GaussColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (!checked && !busy && operationError == null) ...[
                        TextButton(
                          onPressed: onSkip,
                          child: const Text('Skip'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      FilledButton.icon(
                        onPressed: busy
                            ? null
                            : (operationError != null
                                  ? (checked
                                        ? onNext
                                        : (selectedChoice == null
                                              ? onSkip
                                              : onCheck))
                                  : checked
                                  ? onNext
                                  : (selectedChoice == null ? null : onCheck)),
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(checked ? Icons.arrow_forward : Icons.check),
                        label: Text(
                          busy
                              ? 'Saving…'
                              : operationError != null
                              ? 'Try again'
                              : checked
                              ? (index == total - 1
                                    ? 'Finish mission'
                                    : 'Next question')
                              : 'Check answer',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

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
      label: 'Choice ${choice + 1}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isCorrect
              ? GaussColors.teal.withValues(alpha: .11)
              : (isWrong
                    ? GaussColors.error.withValues(alpha: .1)
                    : GaussColors.raised),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: border,
            width: selected || isCorrect ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                '${choice + 1}',
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
                  'This Nardebam item remains preserved in the local archive, but its answer and explanation mapping are not verified. Gauss excludes it from scoring instead of presenting uncertain guidance.',
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
                    Text(
                      'Explanation withheld',
                      style: Theme.of(context).textTheme.titleMedium,
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
                Text(
                  'Classic solution',
                  style: Theme.of(context).textTheme.titleMedium,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GaussColors.brass.withValues(alpha: .14),
                        border: Border.all(
                          color: GaussColors.brassLight.withValues(alpha: .62),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GaussColors.brass.withValues(alpha: .18),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: GaussColors.brassLight,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Orbit complete',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$correct of $total correct',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${completion.xpEarned} XP recorded · ${completion.totalXp} total',
                      style: const TextStyle(
                        color: GaussColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (completion.levelAfter > completion.levelBefore) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Level ${completion.levelAfter} reached',
                        style: const TextStyle(
                          color: GaussColors.brassLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (rewards.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Semantics(
                        container: true,
                        label: 'Recorded rewards',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: GaussColors.ink.withValues(alpha: .48),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: GaussColors.line),
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
                                      const Icon(
                                        Icons.radio_button_checked,
                                        size: 13,
                                        color: GaussColors.brassLight,
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(child: Text(entry.key)),
                                      Text(
                                        '+${entry.value} XP',
                                        style: const TextStyle(
                                          color: GaussColors.teal,
                                          fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 24),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
