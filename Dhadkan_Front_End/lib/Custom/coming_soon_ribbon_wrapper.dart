import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A reusable wrapper widget that adds curved "Coming Soon" ribbon banners
/// to any screen or widget that is under development.
class ComingSoonRibbonWrapper extends StatelessWidget {
  /// The child widget to display behind the ribbons
  final Widget child;

  /// Optional custom message to display on the ribbons
  final String message;

  /// Whether to blur/dim the background content
  final bool blurBackground;

  /// Ribbon background color
  final Color ribbonColor;

  /// Ribbon text color
  final Color textColor;

  /// Number of ribbon curves to show
  final int ribbonCount;

  const ComingSoonRibbonWrapper({
    super.key,
    required this.child,
    this.message = 'COMING SOON',
    this.blurBackground = true,
    this.ribbonColor = Colors.blue,
    this.textColor = Colors.white,
    this.ribbonCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background content (optionally blurred)
        if (blurBackground)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.1),
              BlendMode.darken,
            ),
            child: child,
          )
        else
          child,

        // Add the custom curved ribbon painter on top
        Positioned.fill(
          child: CustomPaint(
            painter: CurvedRibbonPainter(
              ribbonColor: ribbonColor,
              textColor: textColor,
              message: message,
              ribbonCount: ribbonCount,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for drawing curved ribbons across the screen
class CurvedRibbonPainter extends CustomPainter {
  final Color ribbonColor;
  final Color textColor;
  final String message;
  final int ribbonCount;

  CurvedRibbonPainter({
    required this.ribbonColor,
    required this.textColor,
    required this.message,
    required this.ribbonCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: message,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final paint = Paint()
      ..color = ribbonColor
      ..style = PaintingStyle.fill;

    const ribbonHeight = 24.0;
    final spacing = size.height / (ribbonCount + 1);

    // Draw curved ribbons
    for (int i = 0; i < ribbonCount; i++) {
      final y = (i + 1) * spacing;

      final path = Path();

      // Start from left
      path.moveTo(0, y);

      // Add smooth curves across the screen
      for (double x = 0; x <= size.width; x += size.width / 4) {
        const waveHeight = ribbonHeight * 0.8;
        final nextX = math.min(x + size.width / 4, size.width);

        // Alternate wave direction
        if ((x / (size.width / 4)).round() % 2 == 0) {
          path.quadraticBezierTo((x + nextX) / 2, y + waveHeight, nextX, y);
        } else {
          path.quadraticBezierTo((x + nextX) / 2, y - waveHeight, nextX, y);
        }
      }

      // Complete the ribbon shape
      path.lineTo(size.width, y + ribbonHeight / 2);
      path.lineTo(0, y + ribbonHeight / 2);
      path.close();

      canvas.drawPath(path, paint);

      // Draw repeated text along the curve
      final repetitions = (size.width / (textPainter.width + 40)).floor();
      for (int j = 0; j < repetitions; j++) {
        final xPos = j * (textPainter.width + 40) + 20;

        // Save canvas state before rotation
        canvas.save();

        // Position and draw text
        canvas.translate(xPos, y - textPainter.height / 2 + 2);

        // Apply gentle text rotation based on curve position
        final wavePos = (xPos / (size.width / 4)).floor() % 2;
        final waveAngle = wavePos == 0 ? 0.1 : -0.1;
        canvas.rotate(waveAngle);

        textPainter.paint(canvas, Offset.zero);

        // Restore canvas to original state
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Usage example:
///
/// ```dart
/// ComingSoonRibbonWrapper(
///   child: YourScreenWidget(),
///   message: 'COMING SOON', // optional custom message
///   blurBackground: true, // optional, defaults to true
///   ribbonColor: Colors.blue, // optional, defaults to blue
///   textColor: Colors.white, // optional, defaults to white
///   ribbonCount: 3, // optional, number of ribbons to show
/// )
/// ```
