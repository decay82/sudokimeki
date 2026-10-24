import 'package:flutter/material.dart';

/// 튜토리얼 단계 타입
enum TutorialTarget {
  center, // 화면 중앙
  smartInputButton, // 스마트 입력 버튼
  numberButtons, // 하단 숫자 버튼들
  cell, // 셀
}

/// 튜토리얼 단계 정보
class TutorialStep {
  final TutorialTarget target;
  final String message;
  final Rect? highlightRect; // 강조할 영역 (null이면 중앙 텍스트만)

  const TutorialStep({
    required this.target,
    required this.message,
    this.highlightRect,
  });
}

/// 튜토리얼 오버레이 위젯
class TutorialOverlay extends StatelessWidget {
  final TutorialStep step;
  final VoidCallback onTap;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Stack(
          children: [
            // 강조 영역 (스포트라이트 효과)
            if (step.highlightRect != null)
              CustomPaint(
                size: Size.infinite,
                painter: SpotlightPainter(
                  highlightRect: step.highlightRect!,
                ),
              ),

            // 메시지 표시
            _buildMessage(context),

            // 화면 터치 안내
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '화면을 터치하여 계속',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    // 중앙 메시지인 경우
    if (step.target == TutorialTarget.center) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            step.message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE91E63),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 강조 영역이 있는 경우 - 화살표와 함께 메시지 표시
    if (step.highlightRect != null) {
      final rect = step.highlightRect!;
      final screenHeight = MediaQuery.of(context).size.height;

      // 강조 영역이 화면 상단에 있으면 아래에, 하단에 있으면 위에 메시지 표시
      final isTopHalf = rect.center.dy < screenHeight / 2;

      return Positioned(
        top: isTopHalf ? rect.bottom + 20 : null,
        bottom: !isTopHalf ? screenHeight - rect.top + 20 : null,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            step.message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE91E63),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// 스포트라이트 효과를 그리는 CustomPainter
class SpotlightPainter extends CustomPainter {
  final Rect highlightRect;

  SpotlightPainter({required this.highlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    // 전체 어두운 배경
    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 밝은 강조 영역
    final highlightPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.clear;

    // 전체를 어둡게
    canvas.saveLayer(Rect.largest, Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkPaint);

    // 강조 영역을 밝게 (둥근 모서리)
    final rrect = RRect.fromRectAndRadius(
      highlightRect.inflate(8), // 약간 여유 공간
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, highlightPaint);
    canvas.restore();

    // 강조 영역 테두리
    final borderPaint = Paint()
      ..color = const Color(0xFFFF6B9D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect;
  }
}
