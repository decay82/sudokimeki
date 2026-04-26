import 'dart:math';
import 'package:flutter/material.dart';

class TutorialSparkleWrapper extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const TutorialSparkleWrapper({
    super.key,
    required this.child,
    required this.isActive,
  });

  @override
  State<TutorialSparkleWrapper> createState() => _TutorialSparkleWrapperState();
}

class _TutorialSparkleWrapperState extends State<TutorialSparkleWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_StarParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _particles = List.generate(8, (_) => _StarParticle(Random()));
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(TutorialSparkleWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SparklePainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StarParticle {
  final double x;     // 버튼 내 상대 위치 0.0~1.0
  final double y;
  final double size;
  final double phase; // 독립 깜빡임 타이밍 오프셋
  final Color color;

  _StarParticle(Random random)
      : x = 0.1 + random.nextDouble() * 0.8,
        y = 0.1 + random.nextDouble() * 0.8,
        size = 3.0 + random.nextDouble() * 4.0,
        phase = random.nextDouble(),
        color = random.nextBool() ? Colors.yellow : Colors.white;
}

class _SparklePainter extends CustomPainter {
  final List<_StarParticle> particles;
  final double progress;

  _SparklePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final phase = (progress + p.phase) % 1.0;
      final opacity = sin(phase * 2 * pi) * 0.5 + 0.5;
      if (opacity < 0.08) continue;

      paint.color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      final cx = p.x * size.width;
      final cy = p.y * size.height;
      final s = p.size * opacity;

      _drawStar(canvas, paint, cx, cy, s);
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double cx, double cy, double s) {
    final path = Path();
    const arms = 4;
    final outerR = s;
    final innerR = s * 0.35;

    for (int i = 0; i < arms * 2; i++) {
      final angle = i * pi / arms - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => true;
}
