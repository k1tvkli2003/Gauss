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
  static const _maxRetainedPoints = 12000;
  static const _maxPointsPerStroke = 2000;

  final List<_InkStroke> _strokes = [];
  final ValueNotifier<int> _paintRevision = ValueNotifier(0);
  _InkStroke? _activeStroke;
  Offset? _lastPoint;
  int _pointCount = 0;

  bool get _isEmpty => _strokes.isEmpty;

  void _beginStroke(Offset point) {
    final wasEmpty = _isEmpty;
    final stroke = _InkStroke(Path()..moveTo(point.dx, point.dy));
    _strokes.add(stroke);
    _activeStroke = stroke;
    _lastPoint = point;
    _pointCount++;
    _paintRevision.value++;
    if (wasEmpty) setState(() {});
  }

  void _extendStroke(Offset point) {
    var stroke = _activeStroke;
    if (stroke == null) {
      _beginStroke(point);
      return;
    }
    if (stroke.pointCount >= _maxPointsPerStroke) {
      final last = _lastPoint ?? point;
      stroke = _InkStroke(Path()..moveTo(last.dx, last.dy));
      _strokes.add(stroke);
      _activeStroke = stroke;
      _pointCount++;
    }
    stroke.path.lineTo(point.dx, point.dy);
    stroke.pointCount++;
    _lastPoint = point;
    _pointCount++;
    while (_pointCount > _maxRetainedPoints && _strokes.length > 1) {
      final removed = _strokes.removeAt(0);
      _pointCount -= removed.pointCount;
    }
    _paintRevision.value++;
  }

  void _endStroke() {
    _activeStroke = null;
    _lastPoint = null;
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _activeStroke = null;
      _lastPoint = null;
      _pointCount = 0;
    });
    _paintRevision.value++;
  }

  @override
  void dispose() {
    _paintRevision.dispose();
    super.dispose();
  }

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
                  onPressed: _isEmpty ? null : _clear,
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
                  onPanStart: (details) => _beginStroke(details.localPosition),
                  onPanUpdate: (details) =>
                      _extendStroke(details.localPosition),
                  onPanEnd: (_) => _endStroke(),
                  onPanCancel: _endStroke,
                  child: CustomPaint(
                    painter: _ScratchPainter(
                      strokes: _strokes,
                      repaint: _paintRevision,
                    ),
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

class _InkStroke {
  _InkStroke(this.path);

  final Path path;
  int pointCount = 1;
}

class _ScratchPainter extends CustomPainter {
  _ScratchPainter({required this.strokes, required Listenable repaint})
    : super(repaint: repaint);

  final List<_InkStroke> strokes;

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
    for (final stroke in strokes) {
      canvas.drawPath(stroke.path, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}
