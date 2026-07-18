import 'package:flutter/material.dart';

import '../app/gauss_theme.dart';

Future<void> showScratchpad(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (context) => const _ScratchpadSheet(),
);

/// A non-destructive ink layer that sits directly on a question plate.
///
/// Drawing is opt-in so ordinary scrolling, selection, and screen-reader
/// interaction remain untouched. Ink is intentionally session-local; closing
/// the question never mutates the preserved corpus or learner progress.
class InlineQuestionScratch extends StatefulWidget {
  const InlineQuestionScratch({required this.child, super.key});

  final Widget child;

  @override
  State<InlineQuestionScratch> createState() => _InlineQuestionScratchState();
}

class _InlineQuestionScratchState extends State<InlineQuestionScratch> {
  final _ink = _ScratchInkController();
  final GlobalKey _canvasKey = GlobalKey();
  bool _drawing = false;
  double _strokeWidth = _PenWidth.medium.width;

  @override
  void dispose() {
    _ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _ink,
            builder: (context, _) => IconButton(
              onPressed: _ink.isEmpty ? null : _ink.clear,
              tooltip: 'Clear drawing',
              icon: const Icon(Icons.delete_sweep_outlined),
              color: GaussColors.parchmentInk,
              disabledColor: GaussColors.parchmentInk.withValues(alpha: .25),
            ),
          ),
          _PenWidthMenu(
            color: GaussColors.parchmentInk,
            value: _strokeWidth,
            onSelected: (value) => setState(() => _strokeWidth = value),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: _drawing ? 'Stop drawing' : 'Draw on this question',
            child: Semantics(
              button: true,
              toggled: _drawing,
              label: 'Draw directly on this question',
              child: InkResponse(
                onTap: () => setState(() => _drawing = !_drawing),
                radius: 25,
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _drawing
                        ? GaussColors.brass.withValues(alpha: .22)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _drawing
                          ? GaussColors.brass
                          : GaussColors.parchmentInk.withValues(alpha: .22),
                    ),
                  ),
                  child: Icon(
                    _drawing ? Icons.edit_off_outlined : Icons.draw_outlined,
                    color: GaussColors.parchmentInk,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_drawing,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    child: GestureDetector(
                      key: _canvasKey,
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) => _ink.begin(
                        details.localPosition,
                        _canvasSize,
                        _strokeWidth,
                      ),
                      onPanUpdate: (details) =>
                          _ink.extend(details.localPosition, _canvasSize),
                      onPanEnd: (_) => _ink.end(),
                      onPanCancel: _ink.end,
                      child: CustomPaint(
                        painter: _ScratchPainter(ink: _ink, drawGrid: false),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        child: _drawing
            ? const Padding(
                key: ValueKey('inline-scratch-hint'),
                padding: EdgeInsets.only(top: 7),
                child: Text(
                  'Pen is active · draw on the question, then tap the pen to scroll again.',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Color(0xFF6D6045),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );

  Size get _canvasSize {
    final renderObject = _canvasKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.size;
    }
    return const Size(1, 1);
  }
}

class _ScratchpadSheet extends StatefulWidget {
  const _ScratchpadSheet();

  @override
  State<_ScratchpadSheet> createState() => _ScratchpadSheetState();
}

class _ScratchpadSheetState extends State<_ScratchpadSheet> {
  final _ink = _ScratchInkController();
  double _strokeWidth = _PenWidth.medium.width;

  @override
  void dispose() {
    _ink.dispose();
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
            padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: GaussColors.brassLight),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Scratchpad',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _PenWidthMenu(
                  color: GaussColors.brassLight,
                  value: _strokeWidth,
                  onSelected: (value) => setState(() => _strokeWidth = value),
                ),
                AnimatedBuilder(
                  animation: _ink,
                  builder: (context, _) => IconButton(
                    onPressed: _ink.isEmpty ? null : _ink.clear,
                    tooltip: 'Clear scratchpad',
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
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
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) =>
                          _ink.begin(details.localPosition, size, _strokeWidth),
                      onPanUpdate: (details) =>
                          _ink.extend(details.localPosition, size),
                      onPanEnd: (_) => _ink.end(),
                      onPanCancel: _ink.end,
                      child: CustomPaint(
                        painter: _ScratchPainter(ink: _ink, drawGrid: true),
                        size: size,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Text(
              'This working sheet is temporary. Use the pen menu to change line weight.',
              style: TextStyle(color: GaussColors.muted),
            ),
          ),
        ],
      ),
    ),
  );
}

enum _PenWidth {
  fine(1.8, 'Fine'),
  medium(2.8, 'Medium'),
  bold(4.2, 'Bold');

  const _PenWidth(this.width, this.label);
  final double width;
  final String label;
}

class _PenWidthMenu extends StatelessWidget {
  const _PenWidthMenu({
    required this.color,
    required this.value,
    required this.onSelected,
  });

  final Color color;
  final double value;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<double>(
    tooltip: 'Pen size',
    initialValue: value,
    onSelected: onSelected,
    icon: Icon(Icons.line_weight_rounded, color: color, size: 20),
    itemBuilder: (context) => [
      for (final width in _PenWidth.values)
        PopupMenuItem<double>(
          value: width.width,
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Divider(
                  color: GaussColors.brassLight,
                  thickness: width.width,
                ),
              ),
              const SizedBox(width: 12),
              Text(width.label),
              const Spacer(),
              if (value == width.width)
                const Icon(Icons.check_rounded, size: 18),
            ],
          ),
        ),
    ],
  );
}

class _ScratchInkController extends ChangeNotifier {
  static const _maxRetainedPoints = 12000;
  static const _maxPointsPerStroke = 2000;

  final List<_InkStroke> strokes = [];
  _InkStroke? _activeStroke;
  int _pointCount = 0;

  bool get isEmpty => strokes.isEmpty;

  void begin(Offset point, Size size, double width) {
    if (!_drawable(size)) return;
    final stroke = _InkStroke(width)..points.add(_normalize(point, size));
    strokes.add(stroke);
    _activeStroke = stroke;
    _pointCount++;
    notifyListeners();
  }

  void extend(Offset point, Size size) {
    if (!_drawable(size)) return;
    var stroke = _activeStroke;
    if (stroke == null) return;
    if (stroke.points.length >= _maxPointsPerStroke) {
      stroke = _InkStroke(stroke.width)
        ..points.add(
          stroke.points.isEmpty ? _normalize(point, size) : stroke.points.last,
        );
      strokes.add(stroke);
      _activeStroke = stroke;
      _pointCount++;
    }
    stroke.points.add(_normalize(point, size));
    _pointCount++;
    while (_pointCount > _maxRetainedPoints && strokes.length > 1) {
      _pointCount -= strokes.removeAt(0).points.length;
    }
    notifyListeners();
  }

  void end() => _activeStroke = null;

  void clear() {
    strokes.clear();
    _activeStroke = null;
    _pointCount = 0;
    notifyListeners();
  }

  static bool _drawable(Size size) => size.width > 0 && size.height > 0;

  static Offset _normalize(Offset point, Size size) => Offset(
    (point.dx / size.width).clamp(0, 1),
    (point.dy / size.height).clamp(0, 1),
  );
}

class _InkStroke {
  _InkStroke(this.width);

  final double width;
  final List<Offset> points = [];
}

class _ScratchPainter extends CustomPainter {
  _ScratchPainter({required this.ink, required this.drawGrid})
    : super(repaint: ink);

  final _ScratchInkController ink;
  final bool drawGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawGrid) {
      final grid = Paint()
        ..color = const Color(0xFFBCA778).withValues(alpha: .22)
        ..strokeWidth = .7;
      for (var x = 24.0; x < size.width; x += 24) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      }
      for (var y = 24.0; y < size.height; y += 24) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }
    for (final stroke in ink.strokes) {
      if (stroke.points.isEmpty) continue;
      final path = Path();
      final first = stroke.points.first;
      path.moveTo(first.dx * size.width, first.dy * size.height);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(first.dx * size.width, first.dy * size.height),
          stroke.width / 2,
          Paint()..color = GaussColors.parchmentInk,
        );
      } else {
        canvas.drawPath(
          path,
          Paint()
            ..color = GaussColors.parchmentInk
            ..strokeWidth = stroke.width
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchPainter oldDelegate) => false;
}
