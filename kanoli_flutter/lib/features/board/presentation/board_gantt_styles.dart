// Shared timeline styles, pattern fills, and small visual primitives.
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum BoardGanttPattern { solid, diagonalStripe, dots, crosshatch }

class BoardGanttStyle {
  const BoardGanttStyle({
    required this.color,
    required this.pattern,
    required this.styleKey,
  });

  final Color color;
  final BoardGanttPattern pattern;
  final String styleKey;
}

class BoardGanttMarker extends StatelessWidget {
  const BoardGanttMarker({
    required this.itemId,
    required this.style,
    required this.onTap,
    super.key,
  });

  final String itemId;
  final BoardGanttStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: itemId,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: style.color, width: 1.5),
            ),
            child: CustomPaint(
              painter: _BoardGanttPatternPainter(style: style),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class BoardGanttSwatch extends StatelessWidget {
  const BoardGanttSwatch({required this.style, super.key});

  final BoardGanttStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: style.color, width: 1.2),
      ),
      child: CustomPaint(
        painter: _BoardGanttPatternPainter(style: style),
        child: const SizedBox(width: 18, height: 18),
      ),
    );
  }
}

class BoardGanttStyleResolver {
  static const List<Color> palette = <Color>[
    AppTheme.primary,
    AppTheme.secondary,
    AppTheme.tertiary,
    AppTheme.quaternary,
    AppTheme.quinary,
    AppTheme.senary,
  ];
  static const List<BoardGanttPattern> patterns = <BoardGanttPattern>[
    BoardGanttPattern.solid,
    BoardGanttPattern.diagonalStripe,
    BoardGanttPattern.dots,
    BoardGanttPattern.crosshatch,
  ];

  static BoardGanttStyle resolve(int index) {
    final color = palette[index % palette.length];
    final pattern = patterns[(index ~/ palette.length) % patterns.length];
    return BoardGanttStyle(
      color: color,
      pattern: pattern,
      styleKey: '${color.toARGB32()}:${pattern.name}',
    );
  }
}

class _BoardGanttPatternPainter extends CustomPainter {
  const _BoardGanttPatternPainter({required this.style});

  final BoardGanttStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = style.color.withAlpha(52);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      fillPaint,
    );

    final accent = Paint()
      ..color = style.color.withAlpha(176)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    switch (style.pattern) {
      case BoardGanttPattern.solid:
        break;
      case BoardGanttPattern.diagonalStripe:
        for (double x = -size.height; x < size.width; x += 8) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            accent,
          );
        }
      case BoardGanttPattern.dots:
        final dotPaint = Paint()..color = style.color.withAlpha(196);
        for (double x = 6; x < size.width; x += 10) {
          for (double y = 6; y < size.height; y += 10) {
            canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
          }
        }
      case BoardGanttPattern.crosshatch:
        for (double x = -size.height; x < size.width; x += 8) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            accent,
          );
          canvas.drawLine(
            Offset(x, 0),
            Offset(x + size.height, size.height),
            accent,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_BoardGanttPatternPainter oldDelegate) {
    return oldDelegate.style.styleKey != style.styleKey;
  }
}
