import 'package:flutter/material.dart';

import '../app/gauss_theme.dart';

Future<void> showScratchpad(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (context) => const _ScratchpadSheet(),
);

class _ScratchpadSheet extends StatefulWidget {
  const _ScratchpadSheet();

  @override
  State<_ScratchpadSheet> createState() => _ScratchpadSheetState();
}

class _ScratchpadSheetState extends State<_ScratchpadSheet> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .88,
    child: Material(
      color: GaussColors.ink,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: GaussColors.brassLight),
                const SizedBox(width: 9),
                Text(
                  'Scratchpad',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _points.isEmpty
                      ? null
                      : () => setState(_points.clear),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close scratchpad',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GaussColors.parchment,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) =>
                      setState(() => _points.add(details.localPosition)),
                  onPanUpdate: (details) =>
                      setState(() => _points.add(details.localPosition)),
                  onPanEnd: (_) => setState(() => _points.add(null)),
                  child: CustomPaint(
                    painter: _ScratchPainter(_points),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Text(
              'Your working stays on this sheet until you close it.',
              style: TextStyle(color: GaussColors.muted),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScratchPainter extends CustomPainter {
  const _ScratchPainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFBCA778).withValues(alpha: .22)
      ..strokeWidth = .7;
    for (var x = 24.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 24.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final ink = Paint()
      ..color = GaussColors.parchmentInk
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < points.length - 1; index++) {
      final from = points[index];
      final to = points[index + 1];
      if (from != null && to != null) canvas.drawLine(from, to, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) => true;
}
