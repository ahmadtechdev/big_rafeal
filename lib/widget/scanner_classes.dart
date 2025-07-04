// Helper class for animations
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/app_colors.dart';

class TickerProviderImpl extends TickerProvider {
  const TickerProviderImpl();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

// Custom painter to create the overlay with scanning box
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double boxWidth = size.width * 0.7;
    final double boxHeight = boxWidth;
    final double left = (size.width - boxWidth) / 2;
    final double top = (size.height - boxHeight) / 2;
    final double right = left + boxWidth;
    final double bottom = top + boxHeight;

    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw overlay
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(Rect.fromLTRB(left, top, right, bottom))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw scan box borders
    final borderPaint = Paint()
      ..color = AppColors.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Top-left corner
    canvas.drawLine(Offset(left, top + 30), Offset(left, top), borderPaint);
    canvas.drawLine(Offset(left, top), Offset(left + 30, top), borderPaint);

    // Top-right corner
    canvas.drawLine(Offset(right - 30, top), Offset(right, top), borderPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + 30), borderPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, bottom - 30), Offset(left, bottom), borderPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + 30, bottom), borderPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(right - 30, bottom), Offset(right, bottom), borderPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - 30), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Animated scanner line
class ScannerAnimation extends StatefulWidget {
  const ScannerAnimation({super.key});

  @override
  _ScannerAnimationState createState() => _ScannerAnimationState();
}

class _ScannerAnimationState extends State<ScannerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double boxWidth = MediaQuery.of(context).size.width * 0.7;
    final double boxHeight = boxWidth;
    final double left = (MediaQuery.of(context).size.width - boxWidth) / 2;
    final double top = (MediaQuery.of(context).size.height - boxHeight) / 4.2;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          top: top + (boxHeight * _animationController.value),
          left: left,
          child: Container(
            width: boxWidth,
            height: 2.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0),
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        );
      },
    );
  }
}