part of 'map_screen.dart';

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.controller,
    required this.subject,
    required this.sections,
    required this.section,
    required this.activeTopic,
    required this.activeTopicReflected,
    required this.lastSectionBySubject,
    required this.onSubject,
    required this.onNavigate,
  });

  final GaussController controller;
  final Subject subject;
  final List<StudySectionDefinition> sections;
  final StudySectionDefinition section;
  final TopicDescriptor activeTopic;
  final int activeTopicReflected;
  final Map<Subject, String> lastSectionBySubject;
  final ValueChanged<Subject> onSubject;
  final void Function(Subject, StudySectionDefinition, {String? topicKey})
  onNavigate;

  @override
  Widget build(BuildContext context) => Padding(
    // The accepted map direction treats the sky as the primary surface. The
    // top controls therefore float directly over it; only the actionable
    // orbit selector keeps a glass enclosure. This also returns horizontal
    // room to compact English metrics without weakening their touch targets.
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final tightPhone = constraints.maxWidth < 360;
        // Identical two-orbit flank instruments keep both the mathematical
        // axis and the perceived visual weight balanced. The centered brand
        // and course crest own independent rows, so neither flank can push
        // them away from the true screen axis.
        final flankTrack = compact ? 100.0 : 178.0;
        final sectionTotal = section.topicKeys.fold<int>(
          0,
          (sum, key) =>
              sum +
              controller.topics
                  .firstWhere((topic) => topic.key == key)
                  .questionCount,
        );
        final sectionReflected = section.topicKeys.fold<int>(
          0,
          (sum, key) => sum + controller.study.topic(key).reflected,
        );
        final subjectTopics = controller.topics.where(
          (topic) => topic.subject == subject,
        );
        final subjectTotal = subjectTopics.fold<int>(
          0,
          (sum, topic) => sum + topic.questionCount,
        );
        final subjectReflected = controller.topics
            .where((topic) => topic.subject == subject)
            .fold<int>(
              0,
              (sum, topic) => sum + controller.study.topic(topic.key).reflected,
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: ValueKey(
                compact ? 'map-compact-header-frame' : 'map-wide-header-frame',
              ),
              // Keep the identity instruments in a deliberate masthead, but
              // do not let app chrome consume the first third of the route.
              // Compact Course copy is already encoded by the crest semantics
              // and the live reading, so its ornamental caption can yield the
              // vertical space to the actual learning path.
              height: compact ? 84 : 116,
              child: Column(
                children: [
                  // The extended landscape rail already carries the
                  // wordmark; a second one over the map is duplicate chrome.
                  if (!GaussViewport.of(context).extendsNavigationRail)
                    SizedBox(
                      // Preserve the wordmark's 3:1 intrinsic ratio. The former
                      // 24dp slot forced an 88dp mark into a 24dp box, so its
                      // transparent top/bottom breathing room made the actual
                      // letters look absent on Android despite valid semantics.
                      height: compact ? 24 : 36,
                      child: Center(
                        child: GaussWordmark(
                          key: ValueKey(
                            compact
                                ? 'map-compact-centered-wordmark'
                                : 'map-wide-centered-wordmark',
                          ),
                          width: compact ? 70 : 104,
                        ),
                      ),
                    ),
                  SizedBox(height: compact ? 0 : 4),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            key: ValueKey(
                              compact
                                  ? 'map-compact-identity-track'
                                  : 'map-wide-identity-track',
                            ),
                            width: flankTrack,
                            child: Align(
                              alignment: Alignment.center,
                              child: _CompactDailyProgress(
                                summary: controller.gamification,
                                compact: compact,
                                onDailyProgress: () =>
                                    _openDailyProgress(context),
                              ),
                            ),
                          ),
                        ),
                        _MapCourseProgressCrest(
                          key: const ValueKey('map-course-progress-crest'),
                          reflected: subjectReflected,
                          total: subjectTotal,
                          tight: compact || tightPhone,
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: SizedBox(
                            key: ValueKey(
                              compact
                                  ? 'map-compact-subject-track'
                                  : 'map-wide-subject-track',
                            ),
                            width: flankTrack,
                            child: Align(
                              alignment: Alignment.center,
                              child: _SubjectSwitch(
                                subject: subject,
                                onSubject: onSubject,
                                compact: compact,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            _OrbitSelector(
              section: section,
              sectionIndex: sections.indexOf(section) + 1,
              sectionCount: sections.length,
              reflected: sectionReflected,
              total: sectionTotal,
              activeTopic: activeTopic,
              chapterIndex: section.topicKeys.indexOf(activeTopic.key) + 1,
              chapterReflected: activeTopicReflected,
              compact: compact,
              onPressed: () => _openOrbitNavigator(context),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _openOrbitNavigator(BuildContext context) async {
    Widget navigatorFor(BuildContext overlayContext) => _OrbitNavigator(
      controller: controller,
      initialSubject: subject,
      initialSection: section,
      lastSectionBySubject: Map.unmodifiable(lastSectionBySubject),
      onContinue: (nextSubject, nextSection, {topicKey}) {
        Navigator.of(overlayContext).pop();
        onNavigate(nextSubject, nextSection, topicKey: topicKey);
      },
    );
    if (MediaQuery.sizeOf(context).width < GaussBreakpoints.medium) {
      await showModalBottomSheet<void>(
        context: context,
        // The Map lives inside the shell's nested navigator. Presenting this
        // course-picker on the root route keeps it above the shell footer
        // instead of allowing the footer to visually cut through its chapter
        // rail on compact Android screens.
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final textScale = MediaQuery.textScalerOf(sheetContext).scale(1);
          return ConstrainedBox(
            // The constellation navigator is a focused context switch, not a
            // second full-screen route. Large text keeps a taller scrollable
            // surface while normal phone layouts leave the Map visibly
            // present behind the sheet.
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(sheetContext).height *
                  (textScale >= 1.55 ? .94 : .76),
            ),
            child: navigatorFor(sheetContext),
          );
        },
      );
      return;
    }
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Orbit Navigator',
      barrierColor: GaussColors.abyss.withValues(alpha: .68),
      transitionDuration: GaussMotion.resolve(
        context,
        const Duration(milliseconds: 260),
      ),
      pageBuilder: (dialogContext, _, _) => SafeArea(
        minimum: const EdgeInsets.all(GaussSpacing.space16),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
            child: navigatorFor(dialogContext),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(.08, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _openDailyProgress(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        // The sheet follows its content on tall phones instead of reserving a
        // fixed fraction of the display. A bounded ceiling keeps the same
        // composition scroll-safe at 200% text, after rotation, and when an
        // already-open sheet expands into a tablet window class.
        final maxSheetHeight = math.min(
          media.size.height *
              (media.size.width < GaussBreakpoints.medium ? .9 : .82),
          760.0,
        );
        final bottomClearance = math.max(
          GaussSpacing.space24,
          media.viewPadding.bottom + GaussSpacing.space16,
        );
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: DecoratedBox(
            key: const ValueKey('map-daily-orbit-sheet'),
            decoration: BoxDecoration(
              color: GaussColors.deepInk,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(GaussRadii.large),
              ),
              border: Border(
                top: BorderSide(
                  color: GaussColors.brassLight.withValues(alpha: .42),
                ),
              ),
            ),
            child: SingleChildScrollView(
              key: const ValueKey('map-daily-orbit-scroll'),
              padding: EdgeInsetsDirectional.fromSTEB(
                GaussSpacing.space16,
                10,
                GaussSpacing.space16,
                bottomClearance,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: GaussColors.fog.withValues(alpha: .4),
                            borderRadius: BorderRadius.circular(
                              GaussRadii.pill,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily orbit',
                                  style: TextStyle(
                                    color: GaussColors.brassLight,
                                    fontSize: GaussTypeScale.caption,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .2,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Your private learning rhythm',
                                  style: TextStyle(
                                    color: GaussColors.ivory,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('map-daily-orbit-close'),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            tooltip: 'Close daily progress',
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      MapGamificationHud(
                        summary: controller.gamification,
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          context.go('/insights');
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A missed day can use one calm grace day. Earned XP, completed lessons, and seals always remain on this device.',
                        style: TextStyle(
                          color: GaussColors.muted,
                          fontSize: GaussTypeScale.caption,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactDailyProgress extends StatelessWidget {
  const _CompactDailyProgress({
    required this.summary,
    required this.compact,
    required this.onDailyProgress,
  });

  final GamificationSummary summary;
  final bool compact;
  final VoidCallback onDailyProgress;

  @override
  Widget build(BuildContext context) {
    final accent = summary.streakGraceUsed
        ? GaussColors.ice
        : GaussColors.brassLight;
    return SizedBox(
      key: const ValueKey('map-daily-progress-button'),
      width: compact ? 100 : 178,
      height: 56,
      child: Semantics(
        button: true,
        label:
            'Open daily progress. ${summary.streak} day streak. '
            '${summary.todayXp} experience today.',
        child: Tooltip(
          message: 'Daily streak and rewards',
          child: ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onDailyProgress,
                customBorder: const StadiumBorder(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DailyOrbitMetric(
                            key: const ValueKey('map-daily-streak-orbit'),
                            value: '${summary.streak}',
                            label: summary.streakGraceUsed ? 'Grace' : 'Streak',
                            icon: summary.streakGraceUsed
                                ? Icons.shield_moon_outlined
                                : Icons.local_fire_department_rounded,
                            accent: accent,
                            compact: compact,
                          ),
                        ),
                        SizedBox(width: compact ? 4 : 8),
                        Expanded(
                          child: _DailyOrbitMetric(
                            key: const ValueKey('map-daily-xp-orbit'),
                            value: '${summary.todayXp}',
                            label: 'Today XP',
                            icon: Icons.bolt_rounded,
                            accent: GaussColors.signalBright,
                            compact: compact,
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

class _DailyOrbitMetric extends StatelessWidget {
  const _DailyOrbitMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.compact,
    super.key,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: GaussMotion.resolve(context, GaussMotion.micro),
    curve: Curves.easeOutCubic,
    constraints: const BoxConstraints(
      minWidth: GaussMetrics.minTouchTarget,
      minHeight: GaussMetrics.minTouchTarget,
    ),
    height: 52,
    padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 7),
    // A quiet tonal chip: the icon carries the metric's color, the chip
    // itself stays neutral so the header does not compete with the route.
    decoration: BoxDecoration(
      color: GaussColors.surface.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(compact ? 26 : 18),
      border: Border.all(color: GaussColors.hairline),
    ),
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: compact
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: accent),
                const SizedBox(width: 3),
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    color: GaussColors.ivory,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 3),
                    Text(
                      value,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: GaussColors.ivory,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    color: GaussColors.fog,
                    fontSize: GaussTypeScale.insignia,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
    ),
  );
}

class _MapCourseProgressCrest extends StatelessWidget {
  const _MapCourseProgressCrest({
    required this.reflected,
    required this.total,
    required this.tight,
    super.key,
  });

  final int reflected;
  final int total;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (reflected / total).clamp(0.0, 1.0);
    final accessible = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final compactCrest = tight || accessible;
    // At 200% Android text the live course reading still needs 16dp after
    // clamping. Give it real room instead of letting the central crest spill
    // out of the masthead by a couple of pixels.
    final ringSize = accessible
        ? 42.0
        : compactCrest
        ? 44.0
        : 48.0;
    return Semantics(
      container: true,
      label: '$reflected of $total course questions charted.',
      child: ExcludeSemantics(
        child: SizedBox(
          width: compactCrest ? 72 : 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: ringSize,
                child: CustomPaint(
                  painter: _MapCourseProgressPainter(progress: progress),
                  child: Center(
                    child: TheoremStarMark(
                      size: compactCrest ? 27 : 29,
                      semanticLabel: null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: accessible ? 0 : 2),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.35,
                child: Text(
                  '$reflected / $total',
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    color: GaussColors.ivory,
                    fontSize: GaussTypeScale.caption,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCourseProgressPainter extends CustomPainter {
  const _MapCourseProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    final orbit = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = GaussColors.brass.withValues(alpha: .32),
    );
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = GaussColors.signal.withValues(alpha: .18),
    );
    if (progress > 0) {
      canvas.drawArc(
        orbit,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = GaussColors.signalBright,
      );
    }
    for (var tick = 0; tick < 8; tick++) {
      final angle = -math.pi / 2 + tick * math.pi / 4;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        point,
        tick.isEven ? 1.45 : 1,
        Paint()
          ..color = (tick == 0 ? GaussColors.brassLight : GaussColors.brass)
              .withValues(alpha: tick == 0 ? .9 : .52),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapCourseProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
