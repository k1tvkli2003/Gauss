import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gauss/ui/tokens/gauss_tokens.dart';
import 'package:gauss/ui/theme/gauss_theme.dart';
import 'package:gauss/domain/failures.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/features/manuscript/content_blocks.dart';
import 'package:gauss/ui/components/gauss_brand.dart';
import 'package:gauss/ui/components/gauss_state_panel.dart';
import 'package:gauss/ui/components/orbital_action_control.dart';
import 'package:gauss/features/manuscript/question_progress_rail.dart';
import 'package:gauss/features/manuscript/question_manuscript.dart';
import 'package:gauss/features/manuscript/scratchpad.dart';
import 'package:gauss/features/study/study_session_celebration.dart';
import 'package:gauss/features/manuscript/theorem_lens.dart';

part 'study_room_page.dart';
part 'study_room_reflection.dart';
part 'study_room_navigation.dart';

/// A calm study room over preserved source questions.
///
/// The learner may make a private hypothesis, reveal the source mapping, draw
/// directly on the prompt, and classify the concept as clear or worth another
/// pass. None of those actions claim correctness or enter the scored ledger.
class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({
    required this.topicKey,
    this.offset = 0,
    this.count = 5,
    this.revisitOnly = false,
    this.gemsOnly = false,
    this.shuffleSeed,
    super.key,
  });

  const StudyRoomScreen.revisit({super.key})
    : topicKey = null,
      offset = 0,
      count = 5,
      revisitOnly = true,
      gemsOnly = false,
      shuffleSeed = null;

  const StudyRoomScreen.gems({super.key})
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
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> {
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
  void didUpdateWidget(covariant StudyRoomScreen oldWidget) {
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
      // Shuffling retains shelf identity. Keep unsaved work for its members;
      // a different session must start from its own persisted records.
      final sameShelf = _shelf?.key == shelf.key;
      final questionIds = shelf.questions
          .map((question) => question.id)
          .toSet();
      final drafts = sameShelf
          ? Map<String, int?>.fromEntries(
              _hypotheses.entries.where(
                (entry) =>
                    questionIds.contains(entry.key) &&
                    !shelf.records.containsKey(entry.key),
              ),
            )
          : <String, int?>{};
      final revealed = sameShelf
          ? _revealed.intersection(questionIds)
          : <String>{};
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
        )
        ..addAll(drafts);
      _revealed
        ..clear()
        ..addAll(shelf.records.keys)
        ..addAll(revealed);
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
