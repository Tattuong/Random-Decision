import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';
import '../models/app_theme_preset.dart';

class SpinWheel extends StatefulWidget {
  final List<String> labels;
  final bool isSpinning;
  final int? targetIndex;
  final WheelStyle style;
  final VoidCallback? onSpinComplete;
  final double size;

  const SpinWheel({
    super.key,
    required this.labels,
    this.isSpinning = false,
    this.targetIndex,
    this.style = WheelStyle.defaultStyle,
    this.onSpinComplete,
    this.size = 320,
  });

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _rotation = 0;
  int? _lastTarget;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSpinComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(SpinWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning &&
        widget.targetIndex != null &&
        widget.targetIndex != _lastTarget &&
        !oldWidget.isSpinning) {
      _startSpin(widget.targetIndex!);
    }
  }

  void _startSpin(int targetIndex) {
    _lastTarget = targetIndex;
    final count = widget.labels.length;
    if (count == 0) return;

    final slice = 2 * math.pi / count;
    final targetMod = (count - targetIndex - 0.5) * slice;
    final currentMod = _rotation % (2 * math.pi);
    var delta = targetMod - currentMod;
    if (delta <= 0) delta += 2 * math.pi;

    final extraTurns = 6 + math.Random().nextInt(3);
    final end = _rotation + extraTurns * 2 * math.pi + delta;

    _animation = Tween<double>(begin: _rotation, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() => _rotation = _animation.value));

    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final style = widget.style;

    return SizedBox(
      width: size + 40,
      height: size + 70,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: _Pointer(style: style),
          ),
          Positioned(
            top: 28,
            child: Transform.rotate(
              angle: _rotation,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: style.glowColor.withValues(alpha: 0.45),
                      blurRadius: style.glowBlur,
                      spreadRadius: style.glowSpread,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _WheelPainter(
                    labels: widget.labels,
                    style: style,
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.22,
                      height: size * 0.22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            style.centerColor,
                          ],
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
                        ],
                      ),
                      child: Icon(Icons.casino_rounded, color: style.centerIconColor, size: size * 0.08),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pointer extends StatelessWidget {
  final WheelStyle style;

  const _Pointer({required this.style});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 44),
      painter: _PointerPainter(style: style),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final WheelStyle style;

  _PointerPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 6, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [style.pointerTop, style.pointerBottom],
        ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) => oldDelegate.style != style;
}

class _WheelPainter extends CustomPainter {
  final List<String> labels;
  final WheelStyle style;

  _WheelPainter({required this.labels, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final count = labels.length;
    if (count == 0) return;

    final slice = 2 * math.pi / count;

    for (var i = 0; i < count; i++) {
      final start = i * slice - math.pi / 2;
      final color = AppColors.memberPalette[i % AppColors.memberPalette.length];

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius - 2), start, slice, false)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            radius,
            [
              Color.lerp(color, Colors.white, 0.15)!,
              color,
              Color.lerp(color, Colors.black, 0.18)!,
            ],
            [0.2, 0.65, 1.0],
          ),
      );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.segmentBorderWidth
          ..color = Colors.white.withValues(alpha: style.segmentBorderAlpha),
      );

      final midAngle = start + slice / 2;
      _drawLabel(canvas, center, labels[i], midAngle, radius, slice, style);
    }

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.outerRingWidth
        ..color = style.outerRingColor,
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    String text,
    double midAngle,
    double radius,
    double slice,
    WheelStyle style,
  ) {
    final display = text.length > 14 ? '${text.substring(0, 12)}…' : text;
    final labelRadius = radius * 0.62;
    final maxWidth = 2 * labelRadius * math.sin(slice / 2) * 0.88;
    final fontSize = (style.labelFontSize * (slice / (math.pi / 3))).clamp(11.0, style.labelFontSize);

    final tp = TextPainter(
      text: TextSpan(
        text: display,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.1,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    )..layout(maxWidth: maxWidth.clamp(36.0, 120.0));

    final pos = Offset(
      center.dx + math.cos(midAngle) * labelRadius,
      center.dy + math.sin(midAngle) * labelRadius,
    );

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.labels != labels || oldDelegate.style != style;
}
