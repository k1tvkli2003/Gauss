import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/content_blocks.dart';
import '../widgets/gauss_brand.dart';
import '../widgets/scratchpad.dart';

/// A calm study room over preserved source questions.
///
/// The learner may make a private hypothesis, reveal the source mapping, draw
/// directly on the prompt, and classify the concept as clear or worth another
/// pass. None of those actions claim correctness or enter the scored ledger.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({
    required this.topicKey,
    this.offset = 0,
    this.count = 20,
    this.revisitOnly = false,
    this.gemsOnly = false,
    this.shuffleSeed,
    super.key,
  });

  const ArchiveScreen.revisit({super.key})
    : topicKey = null,
      offset = 0,
      count = 20,
      revisitOnly = true,
      gemsOnly = false,
      shuffleSeed = null;

  const ArchiveScreen.gems({super.key})
    : topicKey = null,
      offset = 0,
      count = 20,
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
  int _index = 0;
  bool _loading = true;
  bool _saving = false;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
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
      if (!mounted) return;
      _pageController?.dispose();
      _records
        ..clear()
        ..addAll(shelf.records);
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
      _pageController = PageController(initialPage: _index);
      setState(() {
        _shelf = shelf;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/map');
    }
  }

  void _goTo(int index, int total) {
    final clamped = index.clamp(0, total - 1);
    if (clamped == _index) return;
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
    setState(() => _index = index);
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

  Future<void> _reflect(Question question, StudyReflection reflection) async {
    final shelf = _shelf;
    if (shelf == null || _saving) return;
    final originalShelf = _records[question.id]?.shelfKey;
    setState(() => _saving = true);
    try {
      final outcome = await GaussScope.of(context).saveStudyReflection(
        question: question,
        shelfKey: originalShelf ?? shelf.key,
        hypothesisChoiceIndex: _hypotheses[question.id],
        reflection: reflection,
      );
      if (!mounted) return;
      setState(() => _records[question.id] = outcome.record);
      if (outcome.lines.isNotEmpty &&
          (outcome.setCompleted ||
              outcome.unitCompleted ||
              outcome.leveledUp)) {
        await _showRecap(outcome);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openJumpSheet(StudyShelf shelf) async {
    final target = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _JumpSheet(shelf: shelf, records: _records, currentIndex: _index),
    );
    if (target != null && mounted) _goTo(target, shelf.questions.length);
  }

  Future<void> _showRecap(StudyReflectionOutcome outcome) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: GaussColors.abyss.withValues(alpha: .82),
      builder: (context) => _StudyRecapDialog(outcome: outcome),
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ArchiveBackdrop(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
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
                        index: _index,
                        total: shelf.questions.length,
                        onClose: _leave,
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
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: shelf.questions.length,
                          itemBuilder: (context, index) {
                            final question = shelf.questions[index];
                            return _ArchivePage(
                              key: ValueKey('study-${question.id}'),
                              question: question,
                              revealed: _revealed.contains(question.id),
                              hypothesis: _hypotheses[question.id],
                              record: _records[question.id],
                              saving: _saving && index == _index,
                              onHypothesis: (choice) =>
                                  _selectHypothesis(question, choice),
                              onReveal: () =>
                                  setState(() => _revealed.add(question.id)),
                              onReflection: (reflection) =>
                                  _reflect(question, reflection),
                            );
                          },
                        ),
                      ),
                      _ArchiveNavBar(
                        index: _index,
                        total: shelf.questions.length,
                        reflected: _records.containsKey(
                          shelf.questions[_index].id,
                        ),
                        onPrevious: _index == 0
                            ? null
                            : () => _goTo(_index - 1, shelf.questions.length),
                        onNext: _index == shelf.questions.length - 1
                            ? null
                            : () => _goTo(_index + 1, shelf.questions.length),
                        onJump: () => _openJumpSheet(shelf),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
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
    required this.index,
    required this.total,
    required this.onClose,
    required this.onShuffle,
  });

  final TopicDescriptor? topic;
  final bool revisitOnly;
  final bool gemsOnly;
  final bool shuffled;
  final int index;
  final int total;
  final VoidCallback onClose;
  final VoidCallback? onShuffle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 14, 5),
    child: Row(
      children: [
        IconButton(
          onPressed: onClose,
          tooltip: 'Leave the reading room',
          icon: const Icon(Icons.close_rounded),
        ),
        const GaussWordmark(width: 92),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STUDY ROOM',
                style: TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Directionality(
                textDirection: revisitOnly
                    ? TextDirection.ltr
                    : TextDirection.rtl,
                child: Text(
                  gemsOnly
                      ? 'Gem shelf'
                      : revisitOnly
                      ? 'Revisit orbit'
                      : shuffled
                      ? '${topic!.label} · دور دوم'
                      : topic!.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GaussColors.ivory,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onShuffle != null)
          IconButton(
            onPressed: onShuffle,
            tooltip: shuffled
                ? 'Reshuffle this set again'
                : 'Second pass in a new order',
            icon: Icon(
              Icons.shuffle_rounded,
              color: shuffled ? GaussColors.brassLight : GaussColors.muted,
            ),
          ),
        const SizedBox(width: 4),
        Semantics(
          label: 'Study item ${index + 1} of $total',
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
    required this.onHypothesis,
    required this.onReveal,
    required this.onReflection,
    super.key,
  });

  final Question question;
  final bool revealed;
  final int? hypothesis;
  final StudyRecord? record;
  final bool saving;
  final ValueChanged<int> onHypothesis;
  final VoidCallback onReveal;
  final ValueChanged<StudyReflection> onReflection;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ProvenanceBanner(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'PRESERVED ITEM',
                  style: TextStyle(
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
            Container(
              constraints: const BoxConstraints(minHeight: 142),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF7EED9), GaussColors.parchment],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .65),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: InlineQuestionScratch(
                  key: ValueKey('study-ink-${question.id}'),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: ContentBlocksView(
                      blocks: question.stem,
                      textColor: GaussColors.parchmentInk,
                      textStyle: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(
                            color: GaussColors.parchmentInk,
                            fontFamily: 'Vazirmatn',
                            height: 1.7,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              revealed
                  ? 'Your hypothesis is frozen after reveal.'
                  : 'Choose a private hypothesis, or reveal without one.',
              style: const TextStyle(
                color: GaussColors.fog,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 15),
            for (var choice = 0; choice < question.options.length; choice++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ArchiveChoice(
                  blocks: question.options[choice],
                  choice: choice,
                  selected: hypothesis == choice,
                  enabled: !revealed,
                  markedBySource:
                      revealed && choice == question.correctChoiceIndex,
                  onTap: () => onHypothesis(choice),
                ),
              ),
            const SizedBox(height: 6),
            if (!revealed)
              OutlinedButton.icon(
                onPressed: onReveal,
                icon: const Icon(Icons.visibility_outlined, size: 19),
                label: const Text('Reveal reference answer'),
              )
            else ...[
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
                onReflection: onReflection,
              ),
            ],
          ],
        ),
      ),
    ),
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
                fontSize: 9.5,
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
            fontSize: 8,
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

class _ProvenanceBanner extends StatelessWidget {
  const _ProvenanceBanner();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'Reference item. Its provided answer and explanation are not verified by Gauss. Reading only; nothing here is scored.',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: GaussColors.warning.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GaussColors.warning.withValues(alpha: .4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: GaussColors.warning),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Reference item — the provided answer and explanation are not verified by Gauss. Reading only; nothing here is scored.',
              style: TextStyle(
                color: GaussColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
  });

  final List<ContentBlock> blocks;
  final int choice;
  final bool selected;
  final bool enabled;
  final bool markedBySource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = markedBySource
        ? GaussColors.warning
        : selected
        ? GaussColors.brass
        : GaussColors.line;
    return Semantics(
      container: true,
      button: enabled,
      selected: selected,
      label:
          'Choice ${choice + 1}.'
          '${selected ? ' Your private hypothesis.' : ''}'
          '${markedBySource ? ' Marked as the answer by the unverified source.' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: markedBySource
                    ? [
                        GaussColors.warning.withValues(alpha: .12),
                        GaussColors.deepInk,
                      ]
                    : selected
                    ? [
                        GaussColors.brass.withValues(alpha: .16),
                        GaussColors.deepInk,
                      ]
                    : [GaussColors.panelHigh, GaussColors.raised],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: border,
                width: markedBySource || selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? GaussColors.brass.withValues(alpha: .13)
                          : Colors.transparent,
                      border: Border.all(color: border),
                    ),
                    child: markedBySource
                        ? const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: GaussColors.warning,
                          )
                        : selected
                        ? const Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: GaussColors.brassLight,
                          )
                        : Text(
                            String.fromCharCode(65 + choice),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    required this.onReflection,
  });

  final StudyRecord? record;
  final bool saving;
  final ValueChanged<StudyReflection> onReflection;

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

/// A quiet celebration when a set, a unit, or a level completes. It reports
/// what the ledger recorded — never a claim about the source answer.
class _StudyRecapDialog extends StatelessWidget {
  const _StudyRecapDialog({required this.outcome});

  final StudyReflectionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final headline = outcome.unitCompleted
        ? 'Unit charted'
        : outcome.setCompleted
        ? 'Set complete'
        : 'Level ${outcome.levelAfter}';
    final detail = outcome.unitCompleted
        ? 'Every question in this unit now carries your own mark.'
        : outcome.setCompleted
        ? 'Twenty coordinates charted. The next set is ready when you are.'
        : 'Your steady charting moved the observatory forward.';
    final totals = <String, int>{};
    for (final line in outcome.lines) {
      totals.update(
        line.reason,
        (value) => value + line.amount,
        ifAbsent: () => line.amount,
      );
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(22),
      backgroundColor: Colors.transparent,
      child: Semantics(
        container: true,
        label:
            '$headline. $detail. ${outcome.xpEarned} experience recorded. '
            '${outcome.leveledUp ? 'Level ${outcome.levelAfter} reached.' : ''}',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GaussColors.panelHigh.withValues(alpha: .97),
                GaussColors.ink.withValues(alpha: .98),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: GaussColors.brass.withValues(alpha: .5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 34,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 132,
                child: Image.asset(
                  'assets/visual/mascot/mira_correct.png',
                  fit: BoxFit.contain,
                  cacheHeight: 400,
                  filterQuality: FilterQuality.medium,
                  semanticLabel: 'Mira marks the milestone with you',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GaussColors.muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: GaussColors.deepInk.withValues(alpha: .82),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: GaussColors.hairline),
                ),
                child: Column(
                  children: [
                    for (final entry in totals.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const TheoremStarMark(size: 16),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '+${entry.value} XP',
                              style: const TextStyle(
                                color: GaussColors.signalBright,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (outcome.leveledUp) ...[
                      const Divider(height: 18),
                      Text(
                        'Level ${outcome.levelAfter} reached',
                        style: const TextStyle(
                          color: GaussColors.brassLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Keep charting'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    required this.currentIndex,
  });

  final StudyShelf shelf;
  final Map<String, StudyRecord> records;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final firstUnread = shelf.questions.indexWhere(
      (question) => !records.containsKey(question.id),
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
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${shelf.questions.length} questions in this set',
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
                itemBuilder: (context, index) => _JumpTile(
                  number: index + 1,
                  current: index == currentIndex,
                  record: records[shelf.questions[index].id],
                  onTap: () => Navigator.of(context).pop(index),
                ),
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
    required this.onTap,
  });

  final int number;
  final bool current;
  final StudyRecord? record;
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
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
  });

  final int index;
  final int total;
  final bool reflected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 5, 12, 9),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: GaussColors.deepInk.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: GaussColors.brass.withValues(alpha: .24),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 480;
                  final position = Semantics(
                    button: true,
                    label:
                        'Question ${index + 1} of $total'
                        '${reflected ? ', charted' : ''}. Jump to a question.',
                    child: Tooltip(
                      message: 'Jump to a question',
                      child: InkWell(
                        onTap: total <= 1 ? null : onJump,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  reflected
                                      ? '${index + 1} of $total · charted'
                                      : '${index + 1} of $total',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: GaussColors.fog,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (total > 1) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.unfold_more_rounded,
                                  size: 13,
                                  color: GaussColors.brassLight,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  if (compact) {
                    return Row(
                      children: [
                        IconButton.outlined(
                          onPressed: onPrevious,
                          tooltip: 'Previous question',
                          icon: const Icon(Icons.arrow_back_rounded, size: 19),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: position),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: onNext,
                          tooltip: 'Next question',
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onPrevious,
                        icon: const Icon(Icons.arrow_back_rounded, size: 19),
                        label: const Text('Previous'),
                      ),
                      const SizedBox(width: 18),
                      Expanded(child: position),
                      const SizedBox(width: 18),
                      FilledButton.icon(
                        onPressed: onNext,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                        label: const Text('Next'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
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
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TheoremStarMark(size: 52, monochrome: true),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GaussColors.muted),
              ),
              const SizedBox(height: 20),
              Wrap(
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
            ],
          ),
        ),
      ),
    ),
  );
}
