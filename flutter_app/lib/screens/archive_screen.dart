import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../domain/failures.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/content_blocks.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/gauss_state_panel.dart';
import '../widgets/orbital_action_control.dart';
import '../widgets/question_progress_rail.dart';
import '../widgets/question_manuscript.dart';
import '../widgets/scratchpad.dart';
import '../widgets/study_session_celebration.dart';
import '../widgets/theorem_lens.dart';

/// A calm study room over preserved source questions.
///
/// The learner may make a private hypothesis, reveal the source mapping, draw
/// directly on the prompt, and classify the concept as clear or worth another
/// pass. None of those actions claim correctness or enter the scored ledger.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({
    required this.topicKey,
    this.offset = 0,
    this.count = 5,
    this.revisitOnly = false,
    this.gemsOnly = false,
    this.shuffleSeed,
    super.key,
  });

  const ArchiveScreen.revisit({super.key})
    : topicKey = null,
      offset = 0,
      count = 5,
      revisitOnly = true,
      gemsOnly = false,
      shuffleSeed = null;

  const ArchiveScreen.gems({super.key})
    : topicKey = null,
      offset = 0,
      count = 5,
      revisitOnly = true,
      gemsOnly = true,
      shuffleSeed = null;

  final String? topicKey;
  final int offset;
  final int count;
  final bool revisitOnly;
  final bool gemsOnly;

  /// When set, the same set is presented in a deterministic new order for a
  /// second pass. Membership, shelf key, and saved marks are unchanged.
  final int? shuffleSeed;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  StudyShelf? _shelf;
  Object? _loadError;
  PageController? _pageController;
  final Set<String> _revealed = {};
  final Map<String, int?> _hypotheses = {};
  final Map<String, StudyRecord> _records = {};
  final Set<String> _encounteredSlotIds = {};
  final Map<String, ScratchInkController> _inkControllers = {};
  final Map<String, Timer> _inkClearTimers = {};
  int _index = 0;
  bool _loading = true;
  bool _saving = false;
  bool _inkActive = false;
  bool _didLoad = false;
  int _loadGeneration = 0;
  _PendingReflection? _pendingReflection;

  @override
  void didUpdateWidget(covariant ArchiveScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topicKey != widget.topicKey ||
        oldWidget.offset != widget.offset ||
        oldWidget.count != widget.count ||
        oldWidget.shuffleSeed != widget.shuffleSeed ||
        oldWidget.revisitOnly != widget.revisitOnly ||
        oldWidget.gemsOnly != widget.gemsOnly) {
      // Router replacement can retain this State. Reload only when the set
      // identity changes, not on rotation or ordinary inherited rebuilds.
      _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _loadError = null;
      _saving = false;
    });
    try {
      final controller = GaussScope.of(context);
      final shelf = widget.gemsOnly
          ? await controller.loadGemShelf()
          : widget.revisitOnly
          ? await controller.loadRevisitShelf()
          : await controller.loadStudyShelf(
              widget.topicKey!,
              offset: widget.offset,
              count: widget.count,
              shuffleSeed: widget.shuffleSeed,
            );
      if (!mounted || generation != _loadGeneration) return;
      _pageController?.dispose();
      _records
        ..clear()
        ..addAll(shelf.records);
      _encounteredSlotIds
        ..clear()
        ..addAll(shelf.encounteredSlotIds);
      _hypotheses
        ..clear()
        ..addEntries(
          shelf.records.values.map(
            (record) =>
                MapEntry(record.questionId, record.hypothesisChoiceIndex),
          ),
        );
      _revealed
        ..clear()
        ..addAll(shelf.records.keys);
      _index = shelf.questions.isEmpty ? 0 : shelf.initialIndex;
      _inkActive = false;
      _pendingReflection = null;
      _pageController = PageController(initialPage: _index);
      setState(() {
        _shelf = shelf;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _disposeInkControllers();
    super.dispose();
  }

  ScratchInkController _inkFor(String questionId) =>
      _inkControllers.putIfAbsent(questionId, ScratchInkController.new);

  bool get _hasQuestionInk => _inkControllers.values.any(
    (ink) => !ink.isEmpty || ink.canRestoreClearedInk,
  );

  bool get _hasUncommittedHypothesis => _hypotheses.entries.any(
    (entry) => entry.value != null && !_records.containsKey(entry.key),
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

  void _clearQuestionInk(String questionId) {
    final ink = _inkFor(questionId);
    if (ink.isEmpty) return;
    ink.clear();
    _inkClearTimers.remove(questionId)?.cancel();
    _inkClearTimers[questionId] = Timer(const Duration(seconds: 4), () {
      _inkClearTimers.remove(questionId);
      ink.discardLastClear();
    });
  }

  void _restoreQuestionInk(String questionId) {
    _inkClearTimers.remove(questionId)?.cancel();
    _inkFor(questionId).restoreLastClear();
  }

  void _openQuestionInkWorkspace(String questionId) {
    showScratchpad(context, controller: _inkFor(questionId));
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/map');
    }
  }

  Future<bool> _confirmLeave() async {
    final hasInk = _hasQuestionInk;
    final hasUncommittedHypothesis = _hasUncommittedHypothesis;
    if (!hasInk && !hasUncommittedHypothesis) return true;
    final detail = <String>[
      'Your completed study marks are saved.',
      if (hasUncommittedHypothesis)
        'Your current hypothesis is saved only after you chart or revisit the question.',
      if (hasInk)
        'Ink drawn on these question pages is temporary and will be cleared when you leave this room.',
    ].join(' ');
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              hasInk
                  ? 'Leave and clear question ink?'
                  : 'Leave without charting this hypothesis?',
            ),
            content: Text(detail),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(hasInk ? 'Keep writing' : 'Keep studying'),
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

  Future<void> _requestLeave() async {
    if (await _confirmLeave() && mounted) _leave();
  }

  void _goTo(int index, int total) {
    final clamped = index.clamp(0, total - 1);
    if (clamped == _index) return;
    if (_inkActive) setState(() => _inkActive = false);
    _pageController?.animateToPage(
      clamped,
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    final shelf = _shelf;
    if (shelf == null || index < 0 || index >= shelf.questions.length) return;
    setState(() {
      _index = index;
      _inkActive = false;
    });
    if (!shelf.revisitOnly) {
      GaussScope.of(context).saveStudyPosition(
        shelfKey: shelf.key,
        question: shelf.questions[index],
        position: index,
      );
    }
  }

  void _selectHypothesis(Question question, int choice) {
    if (_revealed.contains(question.id)) return;
    setState(() => _hypotheses[question.id] = choice);
  }

  Future<void> _reflect(
    Question question,
    StudyShelfSlot slot,
    StudyReflection reflection,
  ) async {
    final shelf = _shelf;
    if (shelf == null || _saving) return;
    final generation = _loadGeneration;
    setState(() {
      _saving = true;
      _pendingReflection = null;
    });
    late final StudyReflectionOutcome outcome;
    try {
      outcome = await GaussScope.of(context).saveStudyReflection(
        question: question,
        shelfKey: shelf.key,
        hypothesisChoiceIndex: _hypotheses[question.id],
        reflection: reflection,
        slot: slot,
      );
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _saving = false;
        _pendingReflection = _PendingReflection(
          question: question,
          slot: slot,
          reflection: reflection,
          message: error is GaussFailure
              ? error.safeMessage
              : 'This field note could not be saved. Your current page stays open.',
        );
      });
      return;
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _records[question.id] = outcome.record;
      if (slot.planned) _encounteredSlotIds.add(slot.id);
    });
    try {
      if (outcome.setCompleted ||
          outcome.unitCompleted ||
          outcome.dailyQuestCompleted ||
          outcome.leveledUp) {
        await _showRecap(outcome);
      }
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _saving = false);
      }
    }
  }

  void _retryReflection() {
    final pending = _pendingReflection;
    if (pending == null || _saving) return;
    _reflect(pending.question, pending.slot, pending.reflection);
  }

  Future<void> _openJumpSheet(StudyShelf shelf) async {
    final target = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JumpSheet(
        shelf: shelf,
        records: _records,
        encounteredSlotIds: _encounteredSlotIds,
        currentIndex: _index,
      ),
    );
    if (target != null && mounted) _goTo(target, shelf.questions.length);
  }

  Future<void> _showRecap(StudyReflectionOutcome outcome) async {
    if (!mounted) return;
    final continuation = _recapContinuation(outcome);
    final action = await showDialog<_StudyRecapAction>(
      context: context,
      barrierColor: GaussColors.abyss.withValues(alpha: .82),
      builder: (dialogContext) => StudySessionCelebration(
        outcome: outcome,
        primaryLabel: continuation?.label ?? 'Keep charting',
        onPrimary: () => Navigator.of(
          dialogContext,
        ).pop(continuation == null ? null : _StudyRecapAction.continueStudy),
        onStay: continuation == null
            ? null
            : () => Navigator.of(dialogContext).pop(),
      ),
    );
    if (!mounted ||
        action != _StudyRecapAction.continueStudy ||
        continuation == null) {
      return;
    }
    if (continuation.returnToMap) {
      context.go('/map');
    } else {
      context.replace(continuation.route);
    }
  }

  _StudyRecapContinuation? _recapContinuation(StudyReflectionOutcome outcome) {
    if (!outcome.setCompleted && !outcome.unitCompleted) return null;
    final shelf = _shelf;
    final topicKey = widget.topicKey;
    if (!widget.revisitOnly &&
        !outcome.unitCompleted &&
        shelf != null &&
        topicKey != null) {
      final topic = GaussScope.of(
        context,
      ).topics.firstWhere((item) => item.key == topicKey);
      final nextOffset = widget.offset + shelf.questions.length;
      if (nextOffset < topic.questionCount) {
        return _StudyRecapContinuation(
          label: 'Continue next session',
          route:
              '/study/chapter/$topicKey?offset=$nextOffset&count=${widget.count}',
        );
      }
    }
    return const _StudyRecapContinuation(
      label: 'Return to Map',
      route: '/map',
      returnToMap: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    final topic = widget.topicKey == null
        ? null
        : controller.topics.firstWhere(
            (item) => item.key == widget.topicKey,
            orElse: () => controller.topics.first,
          );
    final shelf = _shelf;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _requestLeave();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _ArchiveBackdrop(),
            SafeArea(
              child: _loading
                  ? const GaussStatePanel(
                      title: 'Opening the study room…',
                      detail:
                          'Reading this preserved set and your private study marks from local storage.',
                      loading: true,
                      accent: GaussColors.signalBright,
                    )
                  : _loadError != null
                  ? _ArchiveMessage(
                      title: 'The study room could not open',
                      detail:
                          'The offline library could not load this set. Nothing was changed.',
                      onLeave: _leave,
                      onRetry: _load,
                    )
                  : shelf == null || shelf.questions.isEmpty
                  ? _ArchiveMessage(
                      title: widget.gemsOnly
                          ? 'Your gem shelf is empty'
                          : widget.revisitOnly
                          ? 'Your revisit orbit is clear'
                          : 'Nothing is shelved here',
                      detail: widget.gemsOnly
                          ? 'Mark a revealed question as “Keep as gem” and it will rest here.'
                          : widget.revisitOnly
                          ? 'Mark a revealed concept as “Revisit later” and it will appear here.'
                          : 'This study set has no preserved questions.',
                      onLeave: _leave,
                    )
                  : Column(
                      children: [
                        _ArchiveTopBar(
                          topic: topic,
                          revisitOnly: widget.revisitOnly,
                          gemsOnly: widget.gemsOnly,
                          shuffled: widget.shuffleSeed != null,
                          masteryReview:
                              shelf.slots[_index].kind == 'mastery_review',
                          index: _index,
                          total: shelf.questions.length,
                          onClose: _requestLeave,
                          onShuffle:
                              widget.revisitOnly || shelf.questions.length < 3
                              ? null
                              : () => context.replace(
                                  '/study/chapter/${widget.topicKey}'
                                  '?offset=${widget.offset}&count=${widget.count}'
                                  '&shuffle=${DateTime.now().millisecondsSinceEpoch % 100000}',
                                ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            key: const ValueKey('study-room-pages'),
                            controller: _pageController,
                            physics: _inkActive
                                ? const NeverScrollableScrollPhysics()
                                : const PageScrollPhysics(),
                            onPageChanged: _onPageChanged,
                            itemCount: shelf.questions.length,
                            itemBuilder: (context, index) {
                              final question = shelf.questions[index];
                              final slot = shelf.slots[index];
                              final ink = _inkFor(question.id);
                              return _ArchivePage(
                                key: ValueKey('study-${slot.id}'),
                                question: question,
                                revealed: _revealed.contains(question.id),
                                hypothesis: _hypotheses[question.id],
                                record: _records[question.id],
                                saving: _saving && index == _index,
                                saveError:
                                    _pendingReflection?.question.id ==
                                        question.id
                                    ? _pendingReflection!.message
                                    : null,
                                active: index == _index,
                                ink: ink,
                                questionNumber: index + 1,
                                onExpandInk: () =>
                                    _openQuestionInkWorkspace(question.id),
                                onClearInk: () =>
                                    _clearQuestionInk(question.id),
                                onRestoreInk: () =>
                                    _restoreQuestionInk(question.id),
                                onInkModeChanged: (active) {
                                  if (index == _index && _inkActive != active) {
                                    setState(() => _inkActive = active);
                                  }
                                },
                                onHypothesis: (choice) =>
                                    _selectHypothesis(question, choice),
                                onReveal: () =>
                                    setState(() => _revealed.add(question.id)),
                                onReflection: (reflection) =>
                                    _reflect(question, slot, reflection),
                                onRetryReflection: _retryReflection,
                              );
                            },
                          ),
                        ),
                        _ArchiveNavBar(
                          index: _index,
                          total: shelf.questions.length,
                          reflected: shelf.slots[_index].planned
                              ? _encounteredSlotIds.contains(
                                  shelf.slots[_index].id,
                                )
                              : _records.containsKey(
                                  shelf.questions[_index].id,
                                ),
                          ink: _inkFor(shelf.questions[_index].id),
                          onPrevious: _index == 0
                              ? null
                              : () => _goTo(_index - 1, shelf.questions.length),
                          onNext: _index == shelf.questions.length - 1
                              ? null
                              : () => _goTo(_index + 1, shelf.questions.length),
                          onJump: () => _openJumpSheet(shelf),
                          onOpenInkWorkspace: () => _openQuestionInkWorkspace(
                            shelf.questions[_index].id,
                          ),
                          onClearInk: () =>
                              _clearQuestionInk(shelf.questions[_index].id),
                          onRestoreInk: () =>
                              _restoreQuestionInk(shelf.questions[_index].id),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingReflection {
  const _PendingReflection({
    required this.question,
    required this.slot,
    required this.reflection,
    required this.message,
  });

  final Question question;
  final StudyShelfSlot slot;
  final StudyReflection reflection;
  final String message;
}

class _ArchiveBackdrop extends StatelessWidget {
  const _ArchiveBackdrop();

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
            colors: [Color(0xE207151C), Color(0xF6050B0D)],
          ),
        ),
      ),
    ],
  );
}

class _ArchiveTopBar extends StatelessWidget {
  const _ArchiveTopBar({
    required this.topic,
    required this.revisitOnly,
    required this.gemsOnly,
    required this.shuffled,
    required this.masteryReview,
    required this.index,
    required this.total,
    required this.onClose,
    required this.onShuffle,
  });

  final TopicDescriptor? topic;
  final bool revisitOnly;
  final bool gemsOnly;
  final bool shuffled;
  final bool masteryReview;
  final int index;
  final int total;
  final VoidCallback onClose;
  final VoidCallback? onShuffle;

  String get _contextLabel => gemsOnly
      ? 'Gem shelf'
      : revisitOnly
      ? 'Revisit orbit'
      : shuffled
      ? '${topic!.label} · Second pass'
      : topic!.label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(12, 5, 12, 7),
    child: Column(
      key: const ValueKey('study-room-header'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: Stack(
            key: const ValueKey('study-room-balanced-action-axis'),
            fit: StackFit.expand,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  key: const ValueKey('study-room-close-action'),
                  onPressed: onClose,
                  tooltip: 'Leave the reading room',
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Align(
                alignment: Alignment.center,
                child: GaussWordmark(
                  key: ValueKey('study-room-centered-wordmark'),
                  width: 82,
                ),
              ),
              if (onShuffle != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    key: const ValueKey('study-room-shuffle-action'),
                    onPressed: onShuffle,
                    tooltip: shuffled
                        ? 'Reshuffle this session again'
                        : 'Second pass in a new order',
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: shuffled
                          ? GaussColors.brassLight
                          : GaussColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        ConstrainedBox(
          key: const ValueKey('study-room-session-heading'),
          constraints: const BoxConstraints(maxWidth: 320),
          child: QuestionProgressRail(
            index: index,
            total: total,
            label: masteryReview ? 'MASTERY REVIEW' : 'STUDY ROOM',
            valueKey: const ValueKey('study-room-progress-chip'),
          ),
        ),
        const SizedBox(height: 5),
        Directionality(
          textDirection: revisitOnly ? TextDirection.ltr : TextDirection.rtl,
          child: Text(
            _contextLabel,
            key: const ValueKey('study-room-context-label'),
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              color: GaussColors.ivory,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ArchivePage extends StatelessWidget {
  const _ArchivePage({
    required this.question,
    required this.revealed,
    required this.hypothesis,
    required this.record,
    required this.saving,
    required this.saveError,
    required this.active,
    required this.ink,
    required this.questionNumber,
    required this.onExpandInk,
    required this.onClearInk,
    required this.onRestoreInk,
    required this.onInkModeChanged,
    required this.onHypothesis,
    required this.onReveal,
    required this.onReflection,
    required this.onRetryReflection,
    super.key,
  });

  final Question question;
  final bool revealed;
  final int? hypothesis;
  final StudyRecord? record;
  final bool saving;
  final String? saveError;
  final bool active;
  final ScratchInkController ink;
  final int questionNumber;
  final VoidCallback onExpandInk;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;
  final ValueChanged<bool> onInkModeChanged;
  final ValueChanged<int> onHypothesis;
  final VoidCallback onReveal;
  final ValueChanged<StudyReflection> onReflection;
  final VoidCallback onRetryReflection;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = GaussViewport.fromSize(constraints.biggest);
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final split = viewport.supportsTwoPane && textScale < 1.6;
      if (!split) {
        return SingleChildScrollView(
          key: const ValueKey('study-room-single-pane'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _manuscript(context),
                  ..._postRevealContent(context),
                ],
              ),
            ),
          ),
        );
      }
      return Padding(
        key: const ValueKey('study-room-split-pane'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: SingleChildScrollView(
                    key: const ValueKey('study-room-prompt-scroll'),
                    padding: const EdgeInsets.fromLTRB(2, 2, 10, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_manuscript(context)],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: GaussColors.deepInk.withValues(alpha: .76),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: GaussColors.hairline),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      key: const ValueKey('study-room-response-scroll'),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _postRevealContent(
                          context,
                          includeHeading: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _manuscript(BuildContext context) => QuestionManuscript(
    key: const ValueKey('study-room-question-paper'),
    ink: ink,
    active: active,
    questionNumber: questionNumber,
    difficulty: question.difficulty.label,
    onDrawingChanged: onInkModeChanged,
    onExpandInk: onExpandInk,
    onClearInk: onClearInk,
    onRestoreInk: onRestoreInk,
    prompt: Directionality(
      key: ValueKey('study-ink-${question.id}'),
      textDirection: TextDirection.rtl,
      child: ContentBlocksView(
        blocks: question.stem,
        textColor: GaussColors.parchmentInk,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: GaussColors.parchmentInk,
          fontFamily: 'Vazirmatn',
          fontSize: 18,
          height: 1.65,
        ),
      ),
    ),
    answers: Column(
      key: const ValueKey('study-room-answer-manuscript'),
      children: [
        for (var choice = 0; choice < question.options.length; choice++)
          _ArchiveChoice(
            blocks: question.options[choice],
            choice: choice,
            selected: hypothesis == choice,
            enabled: !revealed,
            markedBySource: revealed && choice == question.correctChoiceIndex,
            onTap: () => onHypothesis(choice),
            manuscript: true,
          ),
        if (!revealed) ...[
          const SizedBox(height: GaussSpacing.space8),
          Center(
            child: OrbitalActionControl(
              key: const ValueKey('study-room-reveal-source-action'),
              semanticLabel: 'Reveal the unverified source answer',
              icon: Icons.visibility_outlined,
              dimension: 56,
              accent: const Color(0xFF9D691D),
              onPressed: onReveal,
            ),
          ),
        ],
      ],
    ),
  );

  List<Widget> _postRevealContent(
    BuildContext context, {
    bool includeHeading = false,
  }) => [
    if (includeHeading) ...[
      _WorkspaceHeading(revealed: revealed),
      const SizedBox(height: 16),
    ],
    if (revealed) ...[
      const SizedBox(height: 18),
      _HypothesisComparison(
        hypothesis: hypothesis,
        sourceKey: question.correctChoiceIndex,
      ),
      const SizedBox(height: 12),
      _SourceSolution(question: question),
      const SizedBox(height: 12),
      _ReflectionDeck(
        record: record,
        saving: saving,
        saveError: saveError,
        onReflection: onReflection,
        onRetry: onRetryReflection,
      ),
    ],
  ];
}

class _WorkspaceHeading extends StatelessWidget {
  const _WorkspaceHeading({required this.revealed});

  final bool revealed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: GaussMetrics.minTouchTarget,
        height: GaussMetrics.minTouchTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: GaussColors.brass.withValues(alpha: .12),
          shape: BoxShape.circle,
          border: Border.all(color: GaussColors.brass.withValues(alpha: .35)),
        ),
        child: Icon(
          revealed ? Icons.history_edu_outlined : Icons.edit_note_rounded,
          color: GaussColors.brassLight,
          size: 21,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESPONSE DECK',
              style: TextStyle(
                color: GaussColors.brassLight,
                fontSize: GaussTypeScale.insignia,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              revealed ? 'Source and reflection' : 'Make a private call',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ],
  );
}

/// One glance: what the learner committed to, beside what the source claims.
/// Agreement is stated as agreement — never as "correct".
class _HypothesisComparison extends StatelessWidget {
  const _HypothesisComparison({
    required this.hypothesis,
    required this.sourceKey,
  });

  final int? hypothesis;
  final int sourceKey;

  static String _letter(int choice) => String.fromCharCode(65 + choice);

  @override
  Widget build(BuildContext context) {
    final matched = hypothesis != null && hypothesis == sourceKey;
    final headline = hypothesis == null
        ? 'You revealed without committing'
        : matched
        ? 'Your call agrees with the source'
        : 'Your call differs from the source';
    final accent = hypothesis == null
        ? GaussColors.fog
        : matched
        ? GaussColors.signalBright
        : GaussColors.warning;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$headline. '
          '${hypothesis == null ? '' : 'Your call was choice ${_letter(hypothesis!)}. '}'
          'The unverified source names choice ${_letter(sourceKey)}.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: .32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ComparisonChip(
                    label: 'MY CALL',
                    value: hypothesis == null ? '—' : _letter(hypothesis!),
                    color: hypothesis == null
                        ? GaussColors.fog
                        : GaussColors.brassLight,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ComparisonChip(
                    label: 'SOURCE KEY',
                    value: _letter(sourceKey),
                    color: GaussColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Text(
              'Agreement is not proof: the source key itself was never verified. Trust your own reading of the solution.',
              style: TextStyle(
                color: GaussColors.fog,
                fontSize: GaussTypeScale.caption,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonChip extends StatelessWidget {
  const _ComparisonChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: GaussColors.deepInk.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: GaussTypeScale.insignia,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _ArchiveChoice extends StatelessWidget {
  const _ArchiveChoice({
    required this.blocks,
    required this.choice,
    required this.selected,
    required this.enabled,
    required this.markedBySource,
    required this.onTap,
    this.manuscript = false,
  });

  final List<ContentBlock> blocks;
  final int choice;
  final bool selected;
  final bool enabled;
  final bool markedBySource;
  final VoidCallback onTap;
  final bool manuscript;

  @override
  Widget build(BuildContext context) {
    final tone = markedBySource
        ? TheoremChoiceTone.source
        : selected
        ? TheoremChoiceTone.selected
        : TheoremChoiceTone.neutral;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      onTap: enabled ? onTap : null,
      label:
          'Choice ${choice + 1}.'
          '${selected ? ' Your private hypothesis.' : ''}'
          '${markedBySource ? ' Marked as the answer by the unverified source.' : ''}',
      child: manuscript
          ? ManuscriptChoiceShell(
              tone: tone,
              onTap: enabled ? onTap : null,
              emblem: markedBySource
                  ? const Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: Color(0xFF9D691D),
                    )
                  : selected
                  ? const Icon(
                      Icons.edit_note_rounded,
                      size: 19,
                      color: Color(0xFF237E83),
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
              onTap: enabled ? onTap : null,
              emblem: markedBySource
                  ? const Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: GaussColors.warning,
                    )
                  : selected
                  ? const Icon(
                      Icons.edit_note_rounded,
                      size: 19,
                      color: GaussColors.brassLight,
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

class _SourceSolution extends StatelessWidget {
  const _SourceSolution({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_edu_outlined,
                color: GaussColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source explanation — unverified',
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Preserved exactly as imported. Gauss has not confirmed that this reasoning matches the marked answer.',
            style: TextStyle(color: GaussColors.fog, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 14),
          ContentBlocksView(blocks: question.solution),
          if (question.shortcut case final shortcut?) ...[
            const Divider(height: 28),
            const Text(
              'Source shortcut',
              style: TextStyle(
                color: GaussColors.warning,
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

class _ReflectionDeck extends StatelessWidget {
  const _ReflectionDeck({
    required this.record,
    required this.saving,
    required this.saveError,
    required this.onReflection,
    required this.onRetry,
  });

  final StudyRecord? record;
  final bool saving;
  final String? saveError;
  final ValueChanged<StudyReflection> onReflection;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final current = record?.reflection;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GaussColors.signal.withValues(alpha: .09),
            GaussColors.deepInk.withValues(alpha: .96),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: current == null
              ? GaussColors.line
              : GaussColors.signal.withValues(alpha: .55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MiraCompanion(reflection: current),
              const SizedBox(width: 11),
              Expanded(
                child: Text(switch (current) {
                  null => 'How does the concept feel now?',
                  StudyReflection.clear => 'Concept marked clear',
                  StudyReflection.revisit => 'Saved to your revisit orbit',
                  StudyReflection.gem => 'Kept on your gem shelf',
                }, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (saving)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'This is your own study signal. It does not grade the reference answer or create a score.',
            style: TextStyle(
              color: GaussColors.fog,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          if (saveError != null) ...[
            const SizedBox(height: 12),
            _ReflectionSaveFailure(
              message: saveError!,
              retrying: saving,
              onRetry: onRetry,
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 480;
              final clear = _ReflectionButton(
                icon: Icons.check_circle_outline_rounded,
                label: 'Concept feels clear',
                selected: current == StudyReflection.clear,
                onPressed: saving
                    ? null
                    : () => onReflection(StudyReflection.clear),
              );
              final revisit = _ReflectionButton(
                icon: Icons.loop_rounded,
                label: 'Revisit later',
                selected: current == StudyReflection.revisit,
                onPressed: saving
                    ? null
                    : () => onReflection(StudyReflection.revisit),
              );
              final gem = _ReflectionButton(
                icon: Icons.auto_awesome_outlined,
                label: 'Keep as gem',
                selected: current == StudyReflection.gem,
                onPressed: saving
                    ? null
                    : () => onReflection(StudyReflection.gem),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    clear,
                    const SizedBox(height: 9),
                    revisit,
                    const SizedBox(height: 9),
                    gem,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: clear),
                  const SizedBox(width: 10),
                  Expanded(child: revisit),
                  const SizedBox(width: 10),
                  Expanded(child: gem),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReflectionSaveFailure extends StatelessWidget {
  const _ReflectionSaveFailure({
    required this.message,
    required this.retrying,
    required this.onRetry,
  });

  final String message;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label:
        'Field note not saved. $message No new mark is shown until the local ledger confirms it.',
    child: Container(
      key: const ValueKey('study-reflection-save-failure'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: GaussColors.warning.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GaussColors.warning.withValues(alpha: .5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            color: GaussColors.warning,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Field note not saved',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: GaussColors.fog,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: retrying ? null : onRetry,
            icon: retrying
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

/// Mira sits with the learner while the concept settles. She reacts to the
/// learner's own signal, never to the unverified source key.
class _MiraCompanion extends StatelessWidget {
  const _MiraCompanion({required this.reflection});

  final StudyReflection? reflection;

  @override
  Widget build(BuildContext context) {
    final settled = reflection != null && !reflection!.needsAnotherPass;
    return SizedBox.square(
      dimension: 54,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        child: Image.asset(
          settled
              ? 'assets/visual/mascot/mira_correct.png'
              : 'assets/visual/mascot/mira_thinking.png',
          key: ValueKey(settled),
          fit: BoxFit.contain,
          cacheHeight: 180,
          filterQuality: FilterQuality.medium,
          semanticLabel: settled
              ? 'Mira marks the concept as settled with you'
              : 'Mira is thinking with you',
        ),
      ),
    );
  }
}

/// A quiet celebration when a session, a unit, or a level completes. It reports
/// what the ledger recorded — never a claim about the source answer.
enum _StudyRecapAction { continueStudy }

class _StudyRecapContinuation {
  const _StudyRecapContinuation({
    required this.label,
    required this.route,
    this.returnToMap = false,
  });

  final String label;
  final String route;
  final bool returnToMap;
}

class _ReflectionButton extends StatelessWidget {
  const _ReflectionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: selected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
          ),
  );
}

/// Jump anywhere in the current set. Each tile carries its own state so the
/// learner can steer toward unread questions or back to a marked one.
class _JumpSheet extends StatelessWidget {
  const _JumpSheet({
    required this.shelf,
    required this.records,
    required this.encounteredSlotIds,
    required this.currentIndex,
  });

  final StudyShelf shelf;
  final Map<String, StudyRecord> records;
  final Set<String> encounteredSlotIds;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final firstUnread =
        List<int>.generate(shelf.questions.length, (index) => index).indexWhere(
          (index) {
            final slot = shelf.slots[index];
            return slot.planned
                ? !encounteredSlotIds.contains(slot.id)
                : !records.containsKey(shelf.questions[index].id);
          },
        );
    return DraggableScrollableSheet(
      initialChildSize: .62,
      minChildSize: .35,
      maxChildSize: .92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: GaussColors.ink,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: GaussColors.line)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'JUMP TO',
                          style: TextStyle(
                            color: GaussColors.brassLight,
                            fontSize: GaussTypeScale.insignia,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${shelf.questions.length} questions in this session',
                          style: const TextStyle(
                            color: GaussColors.fog,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (firstUnread >= 0)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(firstUnread),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text('First unread'),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 62,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                  childAspectRatio: 1,
                ),
                itemCount: shelf.questions.length,
                itemBuilder: (context, index) {
                  final slot = shelf.slots[index];
                  final encountered =
                      !slot.planned || encounteredSlotIds.contains(slot.id);
                  return _JumpTile(
                    number: index + 1,
                    current: index == currentIndex,
                    record: encountered
                        ? records[shelf.questions[index].id]
                        : null,
                    masteryReview: slot.kind == 'mastery_review',
                    encountered: encountered,
                    onTap: () => Navigator.of(context).pop(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpTile extends StatelessWidget {
  const _JumpTile({
    required this.number,
    required this.current,
    required this.record,
    required this.masteryReview,
    required this.encountered,
    required this.onTap,
  });

  final int number;
  final bool current;
  final StudyRecord? record;
  final bool masteryReview;
  final bool encountered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reflection = record?.reflection;
    final accent = switch (reflection) {
      null => GaussColors.line,
      StudyReflection.clear => GaussColors.signalBright,
      StudyReflection.revisit => GaussColors.warning,
      StudyReflection.gem => GaussColors.brassLight,
    };
    final stateLabel = switch (reflection) {
      null when masteryReview && !encountered => 'mastery review pending',
      null => 'not charted',
      StudyReflection.clear => 'clear',
      StudyReflection.revisit => 'revisit',
      StudyReflection.gem => 'gem',
    };
    return Semantics(
      button: true,
      selected: current,
      label: 'Question $number, $stateLabel',
      child: InkWell(
        key: ValueKey('study-room-jump-question-$number'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: reflection == null
                ? GaussColors.raised
                : accent.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: current ? GaussColors.ivory : accent,
              width: current ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$number',
                style: TextStyle(
                  color: reflection == null ? GaussColors.muted : accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              if (reflection != null)
                Icon(
                  switch (reflection) {
                    StudyReflection.clear => Icons.check_rounded,
                    StudyReflection.revisit => Icons.loop_rounded,
                    StudyReflection.gem => Icons.auto_awesome_outlined,
                  },
                  size: 11,
                  color: accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveNavBar extends StatelessWidget {
  const _ArchiveNavBar({
    required this.index,
    required this.total,
    required this.reflected,
    required this.ink,
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
    required this.onOpenInkWorkspace,
    required this.onClearInk,
    required this.onRestoreInk,
  });

  final int index;
  final int total;
  final bool reflected;
  final ScratchInkController ink;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onJump;
  final VoidCallback onOpenInkWorkspace;
  final VoidCallback onClearInk;
  final VoidCallback onRestoreInk;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              key: const ValueKey('study-room-navigation-dock'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: GaussColors.deepInk.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .24),
                ),
              ),
              child: AnimatedBuilder(
                animation: ink,
                builder: (context, _) => Row(
                  children: [
                    IconButton.outlined(
                      key: const ValueKey('study-room-previous-action'),
                      onPressed: onPrevious,
                      tooltip: 'Previous question',
                      icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    ),
                    const SizedBox(width: GaussSpacing.space8),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.textScalerOf(context).scale(14) >= 20
                              ? 70
                              : 60,
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
                                    ? _ArchiveInkRestore(
                                        onRestore: onRestoreInk,
                                      )
                                    : _ArchiveQuestionPosition(
                                        index: index,
                                        total: total,
                                        reflected: reflected,
                                        onJump: onJump,
                                      )
                              : _ArchiveInkControls(
                                  ink: ink,
                                  onExpand: onOpenInkWorkspace,
                                  onClear: onClearInk,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: GaussSpacing.space8),
                    OrbitalActionControl(
                      key: const ValueKey('study-room-next-action'),
                      semanticLabel: 'Next question',
                      onPressed: onNext,
                      icon: Icons.arrow_forward_rounded,
                      dimension: GaussMetrics.minTouchTarget,
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

class _ArchiveQuestionPosition extends StatelessWidget {
  const _ArchiveQuestionPosition({
    required this.index,
    required this.total,
    required this.reflected,
    required this.onJump,
  });

  final int index;
  final int total;
  final bool reflected;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) => Semantics(
    button: total > 1,
    label:
        'Question ${index + 1} of $total'
        '${reflected ? ', charted' : ''}. Jump to a question.',
    child: Tooltip(
      message: 'Jump to a question',
      child: InkWell(
        key: const ValueKey('study-room-jump-action'),
        onTap: total <= 1 ? null : onJump,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GaussSpacing.space4,
            vertical: GaussSpacing.space4,
          ),
          child: QuestionProgressRail(
            index: index,
            total: total,
            label: reflected ? 'CHARTED' : 'QUESTION',
            valueText: '${index + 1} of $total',
            valueKey: const ValueKey('study-room-navigation-position'),
          ),
        ),
      ),
    ),
  );
}

class _ArchiveInkControls extends StatelessWidget {
  const _ArchiveInkControls({
    required this.ink,
    required this.onExpand,
    required this.onClear,
  });

  final ScratchInkController ink;
  final VoidCallback onExpand;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Question ink controls',
    child: Row(
      key: const ValueKey('study-room-ink-controls'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          key: const ValueKey('study-room-ink-undo'),
          onPressed: ink.canUndo ? ink.undo : null,
          tooltip: 'Undo last ink stroke',
          icon: const Icon(Icons.undo_rounded),
        ),
        IconButton(
          key: const ValueKey('study-room-ink-expand'),
          onPressed: onExpand,
          tooltip: 'Open full scratchpad',
          icon: const Icon(Icons.open_in_full_rounded),
        ),
        IconButton(
          key: const ValueKey('study-room-ink-clear'),
          onPressed: onClear,
          tooltip: 'Clear question ink',
          color: GaussColors.error,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    ),
  );
}

class _ArchiveInkRestore extends StatelessWidget {
  const _ArchiveInkRestore({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Question ink cleared',
    child: Center(
      child: TextButton.icon(
        key: const ValueKey('study-room-ink-restore'),
        onPressed: onRestore,
        icon: const Icon(Icons.undo_rounded, color: GaussColors.brassLight),
        label: const Text('Restore ink'),
      ),
    ),
  );
}

class _ArchiveMessage extends StatelessWidget {
  const _ArchiveMessage({
    required this.title,
    required this.detail,
    required this.onLeave,
    this.onRetry,
  });

  final String title;
  final String detail;
  final VoidCallback onLeave;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => GaussStatePanel(
    title: title,
    detail: detail,
    icon: onRetry == null
        ? Icons.auto_stories_outlined
        : Icons.error_outline_rounded,
    accent: onRetry == null ? GaussColors.brass : GaussColors.error,
    actions: Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton(onPressed: onLeave, child: const Text('Back')),
        if (onRetry != null)
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
      ],
    ),
  );
}
