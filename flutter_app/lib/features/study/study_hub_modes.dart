part of 'study_hub_screen.dart';

class _StudyModes extends StatelessWidget {
  const _StudyModes({
    required this.revisitCount,
    required this.dueCount,
    required this.gemCount,
    required this.onRevisit,
    required this.onGems,
    required this.onScratchpad,
    required this.onMap,
  });

  final int revisitCount;
  final int dueCount;
  final int gemCount;
  final VoidCallback onRevisit;
  final VoidCallback onGems;
  final VoidCallback onScratchpad;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final modes = [
      (
        icon: Icons.loop_rounded,
        title: 'Revisit orbit',
        detail: revisitCount == 0
            ? 'Nothing waiting'
            : dueCount == 0
            ? '$revisitCount shelved · none due yet'
            : '$dueCount due now · $revisitCount shelved',
        onTap: onRevisit,
      ),
      (
        icon: Icons.diamond_outlined,
        title: 'Gem shelf',
        detail: gemCount == 0
            ? 'Keep a question you admire'
            : '$gemCount kept for their ideas',
        onTap: onGems,
      ),
      (
        icon: Icons.draw_outlined,
        title: 'Scratchpad',
        detail: 'Full-sheet freehand work',
        onTap: onScratchpad,
      ),
      (
        icon: Icons.route_outlined,
        title: 'Path atlas',
        detail: 'Browse the continuous route',
        onTap: onMap,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: _StudyGlass(
            key: const ValueKey('study-library-tools'),
            radius: 22,
            padding: const EdgeInsets.all(6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final window = GaussWindowClass.fromWidth(
                  math.max(
                    MediaQuery.sizeOf(context).width,
                    constraints.maxWidth,
                  ),
                );
                final accessibleText =
                    MediaQuery.textScalerOf(
                      context,
                    ).scale(GaussTypeScale.body) >=
                    20;
                if (window.isCompact ||
                    constraints.maxWidth < 480 ||
                    accessibleText) {
                  return Column(
                    children: [
                      for (var index = 0; index < modes.length; index++) ...[
                        if (index > 0)
                          Divider(
                            height: 1,
                            color: GaussColors.hairline.withValues(alpha: .7),
                          ),
                        _ModePlate(
                          key: ValueKey('study-mode-${modes[index].title}'),
                          icon: modes[index].icon,
                          title: modes[index].title,
                          detail: modes[index].detail,
                          onTap: modes[index].onTap,
                        ),
                      ],
                    ],
                  );
                }
                if (window.isMedium) {
                  final plateWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final mode in modes)
                        SizedBox(
                          width: plateWidth,
                          child: _ModePlate(
                            key: ValueKey('study-mode-${mode.title}'),
                            icon: mode.icon,
                            title: mode.title,
                            detail: mode.detail,
                            onTap: mode.onTap,
                          ),
                        ),
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var index = 0; index < modes.length; index++) ...[
                      if (index > 0)
                        Container(
                          width: 1,
                          height: 44,
                          color: GaussColors.hairline.withValues(alpha: .7),
                        ),
                      Expanded(
                        child: _ModePlate(
                          key: ValueKey('study-mode-${modes[index].title}'),
                          icon: modes[index].icon,
                          title: modes[index].title,
                          detail: modes[index].detail,
                          onTap: modes[index].onTap,
                        ),
                      ),
                    ],
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

class _ModePlate extends StatelessWidget {
  const _ModePlate({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $detail',
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: GaussColors.brass.withValues(alpha: .11),
                    border: Border.all(
                      color: GaussColors.brass.withValues(alpha: .28),
                    ),
                  ),
                  child: Icon(icon, color: GaussColors.brassLight, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: GaussColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: GaussColors.fog,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
