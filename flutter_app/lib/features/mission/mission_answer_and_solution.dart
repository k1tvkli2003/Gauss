part of 'mission_screen.dart';

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
      key: ValueKey('mission-choice-$choice'),
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
  const _SolutionPanel({required this.question, this.manuscript = false});

  final Question question;
  final bool manuscript;

  @override
  Widget build(BuildContext context) {
    final certified = question.missionReady && question.solutionVerified;
    final heading = certified ? 'Classic solution' : 'Source solution';
    final contentColor = manuscript
        ? GaussColors.parchmentInk
        : GaussColors.fog;
    final headingColor = manuscript
        ? GaussColors.parchmentInk
        : GaussColors.brassLight;
    final content = Padding(
      padding: EdgeInsets.all(manuscript ? 8 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                certified ? Icons.lightbulb_outline : Icons.menu_book_outlined,
                color: manuscript ? const Color(0xFF247A7D) : headingColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  heading,
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (certified)
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: manuscript
                      ? const Color(0xFF247A7D)
                      : GaussColors.signalBright,
                ),
            ],
          ),
          if (!certified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: manuscript
                    ? const Color(0x14247A7D)
                    : GaussColors.brass.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: manuscript
                      ? const Color(0x55247A7D)
                      : GaussColors.brass.withValues(alpha: .22),
                ),
              ),
              child: Text(
                'Shown from the preserved source for private practice. If anything looks inconsistent, use the report action and keep going.',
                style: TextStyle(
                  color: contentColor.withValues(alpha: .66),
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ContentBlocksView(
            blocks: question.solution,
            textColor: manuscript ? GaussColors.parchmentInk : null,
          ),
          if (question.shortcut case final shortcut?) ...[
            Divider(
              height: 28,
              color: manuscript
                  ? GaussColors.parchmentInk.withValues(alpha: .2)
                  : null,
            ),
            Text(
              'Smart shortcut',
              style: TextStyle(
                color: headingColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ContentBlocksView(
              blocks: shortcut,
              textColor: manuscript ? GaussColors.parchmentInk : null,
            ),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      label: certified
          ? 'Scientifically reviewed solution.'
          : 'Source-provided solution shown provisionally for private practice.',
      child: manuscript
          ? KeyedSubtree(
              key: const ValueKey('mission-manuscript-solution'),
              child: content,
            )
          : Card(child: content),
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
