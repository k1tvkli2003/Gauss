part of 'study_hub_screen.dart';

class _CourseInstrument extends StatelessWidget {
  const _CourseInstrument({required this.subject, required this.onChanged});

  final Subject subject;
  final ValueChanged<Subject> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 5, 18, 11),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _StudyGeometry.courseMaxWidth,
        ),
        child: _StudyGlass(
          key: const ValueKey('study-course-instrument'),
          radius: 22,
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final accessible =
                  textScale >= _StudyGeometry.accessibleLayoutScale;
              final stacked =
                  constraints.maxWidth <
                  _StudyGeometry.compactCourseBreakpoint - 50;
              final options = [
                for (final item in Subject.values)
                  _CourseOption(
                    semanticKey: ValueKey('study-subject-${item.key}'),
                    subject: item,
                    selected: subject == item,
                    compactAccessible: accessible,
                    chapterCount: GaussStudyCurriculum.forSubject(item).length,
                    onTap: () => onChanged(item),
                  ),
              ];
              final rawChoices = stacked
                  ? Column(
                      children: [
                        options.first,
                        const SizedBox(height: 8),
                        options.last,
                      ],
                    )
                  // Both options share one structure, so they size to the
                  // same content height; a fixed height clipped real fonts.
                  : Row(
                      children: [
                        Expanded(child: options.first),
                        const SizedBox(width: 12),
                        Expanded(child: options.last),
                      ],
                    );
              final choices = accessible
                  ? MediaQuery.withClampedTextScaling(
                      // Course names are selector chrome. Keep the complete
                      // labels while preserving a compact two-orbit chooser.
                      maxScaleFactor: 1.35,
                      child: rawChoices,
                    )
                  : rawChoices;
              return Stack(
                alignment: Alignment.center,
                children: [
                  choices,
                  IgnorePointer(
                    child: ExcludeSemantics(
                      child: Container(
                        key: const ValueKey('study-course-axis-label'),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GaussColors.deepInk,
                          border: Border.all(
                            color: GaussColors.brass.withValues(alpha: .62),
                          ),
                        ),
                        // The brass orbital ring motif marks the axis
                        // shared by the two courses.
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: GaussColors.brassLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _CourseOption extends StatelessWidget {
  const _CourseOption({
    required this.semanticKey,
    required this.subject,
    required this.selected,
    required this.compactAccessible,
    required this.chapterCount,
    required this.onTap,
  });

  final Key semanticKey;
  final Subject subject;
  final bool selected;
  final bool compactAccessible;
  final int chapterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? GaussColors.ivory : GaussColors.fog;
    return Semantics(
      key: semanticKey,
      button: true,
      selected: selected,
      label: _subjectTitle(subject),
      hint: '$chapterCount chapters${selected ? ', selected course' : ''}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: GaussMotion.resolve(context, GaussMotion.standard),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: subject == Subject.math
                          ? const [Color(0xFF6F4A16), Color(0xFF2A2117)]
                          : const [Color(0xFF245E66), Color(0xFF132D35)],
                    )
                  : null,
              color: selected
                  ? null
                  : GaussColors.raised.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? (subject == Subject.math
                              ? GaussColors.brassLight
                              : GaussColors.signalBright)
                          .withValues(alpha: .58)
                    : GaussColors.hairline,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color:
                            (subject == Subject.math
                                    ? GaussColors.brass
                                    : GaussColors.signal)
                                .withValues(alpha: .12),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // At phone split widths, a side-by-side icon and the full
                // "Mathematics" label create unequal card heights. Reflow
                // both choices as centered instruments before either label
                // has to wrap, so the pair keeps one optical baseline.
                final vertical = constraints.maxWidth < 145;
                final compact = compactAccessible && vertical;
                final chromeTextScaler = compact
                    ? const TextScaler.linear(1.25)
                    : null;
                final icon = Container(
                  width: compact ? 30 : 36,
                  height: compact ? 30 : 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GaussColors.deepInk.withValues(
                      alpha: selected ? .5 : .78,
                    ),
                    border: Border.all(
                      color: foreground.withValues(alpha: .28),
                    ),
                  ),
                  child: Center(
                    child: SubjectGlyph(
                      subject: subject,
                      size: compact ? 17 : 19,
                      color: foreground,
                    ),
                  ),
                );
                final copy = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: vertical
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subjectTitle(subject),
                      maxLines: 1,
                      softWrap: false,
                      textScaler: chromeTextScaler,
                      textAlign: vertical ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$chapterCount chapters',
                      maxLines: 1,
                      softWrap: false,
                      textScaler: chromeTextScaler,
                      textAlign: vertical ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        color: foreground.withValues(alpha: .78),
                        fontSize: GaussTypeScale.insignia,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
                if (vertical) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      SizedBox(height: compact ? 4 : 6),
                      copy,
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Flexible(child: copy),
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
