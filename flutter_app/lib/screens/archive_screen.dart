import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../domain/models.dart';
import '../state/gauss_controller.dart';
import '../widgets/content_blocks.dart';
import '../widgets/gauss_brand.dart';

/// The reading room: a read-only surface over the preserved half of a
/// chapter — source items whose answer/solution mapping is unverified.
/// Nothing here is scored, persisted, or fed to the review orbit; the value
/// is access to the full library with honest provenance labels.
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({required this.topicKey, super.key});

  final String topicKey;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  Future<List<Question>>? _archiveFuture;
  final PageController _pageController = PageController();
  final Set<int> _revealed = {};
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _archiveFuture ??= GaussScope.of(context).loadArchive(widget.topicKey);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    _pageController.animateToPage(
      clamped,
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = GaussScope.of(context);
    final topic = controller.topics.firstWhere(
      (item) => item.key == widget.topicKey,
      orElse: () => controller.topics.first,
    );
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _ArchiveBackdrop(),
          SafeArea(
            child: FutureBuilder<List<Question>>(
              future: _archiveFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ArchiveMessage(
                    title: 'The reading room could not open',
                    detail:
                        'The offline archive could not load this chapter. Nothing was changed.',
                    onLeave: _leave,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final questions = snapshot.data!;
                if (questions.isEmpty) {
                  return _ArchiveMessage(
                    title: 'Nothing is shelved here',
                    detail:
                        'Every question in this chapter is verified and already lives in scored missions.',
                    onLeave: _leave,
                  );
                }
                return Column(
                  children: [
                    _ArchiveTopBar(
                      topic: topic,
                      index: _index,
                      total: questions.length,
                      onClose: _leave,
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) =>
                            setState(() => _index = index),
                        itemCount: questions.length,
                        itemBuilder: (context, index) => _ArchivePage(
                          question: questions[index],
                          revealed: _revealed.contains(index),
                          onReveal: () =>
                              setState(() => _revealed.add(index)),
                        ),
                      ),
                    ),
                    _ArchiveNavBar(
                      index: _index,
                      total: questions.length,
                      onPrevious: _index == 0
                          ? null
                          : () => _goTo(_index - 1, questions.length),
                      onNext: _index == questions.length - 1
                          ? null
                          : () => _goTo(_index + 1, questions.length),
                    ),
                  ],
                );
              },
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
    required this.index,
    required this.total,
    required this.onClose,
  });

  final TopicDescriptor topic;
  final int index;
  final int total;
  final VoidCallback onClose;

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
                'READING ROOM',
                style: TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  topic.label,
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
        const SizedBox(width: 10),
        Semantics(
          label: 'Preserved item ${index + 1} of $total',
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
    required this.onReveal,
  });

  final Question question;
  final bool revealed;
  final VoidCallback onReveal;

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
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
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
            const SizedBox(height: 15),
            for (var choice = 0; choice < question.options.length; choice++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ArchiveChoice(
                  blocks: question.options[choice],
                  choice: choice,
                  markedBySource:
                      revealed && choice == question.correctChoiceIndex,
                ),
              ),
            const SizedBox(height: 6),
            if (!revealed)
              OutlinedButton.icon(
                onPressed: onReveal,
                icon: const Icon(Icons.visibility_outlined, size: 19),
                label: const Text('Reveal the source answer'),
              )
            else
              _SourceSolution(question: question),
          ],
        ),
      ),
    ),
  );
}

class _ProvenanceBanner extends StatelessWidget {
  const _ProvenanceBanner();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'Preserved source item. Its answer and explanation are unverified. Reading only; nothing here is scored.',
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
              'Preserved source item — answer and explanation unverified. Reading only; nothing here is scored.',
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
    required this.markedBySource,
  });

  final List<ContentBlock> blocks;
  final int choice;
  final bool markedBySource;

  @override
  Widget build(BuildContext context) {
    final border = markedBySource ? GaussColors.warning : GaussColors.line;
    return Semantics(
      container: true,
      label:
          'Choice ${choice + 1}.'
          '${markedBySource ? ' Marked as the answer by the unverified source.' : ''}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: markedBySource
                ? [
                    GaussColors.warning.withValues(alpha: .12),
                    GaussColors.deepInk,
                  ]
                : [GaussColors.panelHigh, GaussColors.raised],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: markedBySource ? 2 : 1),
        ),
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
                child: markedBySource
                    ? const Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: GaussColors.warning,
                      )
                    : Text(
                        String.fromCharCode(65 + choice),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(child: ContentBlocksView(blocks: blocks, compact: true)),
            ],
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

class _ArchiveNavBar extends StatelessWidget {
  const _ArchiveNavBar({
    required this.index,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xFA0B1417),
      border: Border(top: BorderSide(color: GaussColors.line)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back_rounded, size: 19),
                label: const Text('Previous'),
              ),
              const Spacer(),
              Text(
                '${index + 1} of $total preserved',
                style: const TextStyle(
                  color: GaussColors.fog,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                label: const Text('Next'),
              ),
            ],
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
  });

  final String title;
  final String detail;
  final VoidCallback onLeave;

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
              FilledButton(onPressed: onLeave, child: const Text('Back')),
            ],
          ),
        ),
      ),
    ),
  );
}
