import 'dart:math';
import 'package:flutter/material.dart';

class HealthGauge extends StatefulWidget {
  final int score;

  const HealthGauge({super.key, required this.score});

  @override
  State<HealthGauge> createState() => _HealthGaugeState();
}

class _HealthGaugeState extends State<HealthGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.decelerate),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentVal = _animation.value;
        final color = _getColorForScore(currentVal);
        final status = _getStatusForScore(currentVal);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 130,
              child: CustomPaint(
                painter: _GaugePainter(
                  value: currentVal,
                  color: color,
                ),
                child: Align(
                  alignment: const Alignment(0.0, 0.6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentVal.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getColorForScore(double score) {
    if (score < 40) return const Color(0xFFC62828);
    if (score < 75) return const Color(0xFFF9A825);
    return const Color(0xFF2E7D32);
  }

  String _getStatusForScore(double score) {
    if (score < 40) return "POOR";
    if (score < 75) return "FAIR";
    return "EXCELLENT";
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = min(size.width / 2 - 12, size.height - 12);

    final bgPaint = Paint()
      ..color = const Color(0xFFE5E5DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    const startAngle = pi + 0.35;
    const sweepAngle = pi - 0.7;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final ratio = (value / 100).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * ratio,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
