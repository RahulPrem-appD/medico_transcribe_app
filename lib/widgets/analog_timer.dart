import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AnalogTimer extends StatelessWidget {
  final int seconds;
  final bool isRecording;
  final bool isPaused;
  final double size;

  const AnalogTimer({
    super.key,
    required this.seconds,
    this.isRecording = false,
    this.isPaused = false,
    this.size = 220,
  });

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring with gradient
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.paleBlue.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: isRecording && !isPaused
                      ? AppTheme.accentCoral.withOpacity(0.2)
                      : AppTheme.primarySkyBlue.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
          ),
          // Clock face
          CustomPaint(
            size: Size(size - 20, size - 20),
            painter: _ClockFacePainter(
              seconds: seconds,
              isRecording: isRecording,
              isPaused: isPaused,
            ),
          ),
          // Inner circle with time display
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDuration(seconds),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.w500,
                    color: isRecording && !isPaused
                        ? AppTheme.accentCoral
                        : AppTheme.darkSlate,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRecording
                        ? (isPaused
                            ? AppTheme.warningAmber.withOpacity(0.1)
                            : AppTheme.accentCoral.withOpacity(0.1))
                        : AppTheme.primarySkyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRecording
                              ? (isPaused
                                  ? AppTheme.warningAmber
                                  : AppTheme.accentCoral)
                              : AppTheme.primarySkyBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRecording
                            ? (isPaused ? 'PAUSED' : 'REC')
                            : 'READY',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isRecording
                              ? (isPaused
                                  ? AppTheme.warningAmber
                                  : AppTheme.accentCoral)
                              : AppTheme.primarySkyBlue,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockFacePainter extends CustomPainter {
  final int seconds;
  final bool isRecording;
  final bool isPaused;

  _ClockFacePainter({
    required this.seconds,
    required this.isRecording,
    required this.isPaused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw tick marks
    final tickPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * pi / 180;
      final isMainTick = i % 5 == 0;
      
      final outerRadius = radius - 8;
      final innerRadius = isMainTick ? radius - 20 : radius - 14;
      
      final outer = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );
      final inner = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );

      // Color ticks based on elapsed time
      final tickSecond = i;
      final elapsedInMinute = seconds % 60;
      
      if (isRecording && !isPaused && tickSecond <= elapsedInMinute) {
        tickPaint.color = AppTheme.accentCoral;
        tickPaint.strokeWidth = isMainTick ? 3 : 2;
      } else {
        tickPaint.color = isMainTick
            ? AppTheme.mediumGray.withOpacity(0.5)
            : AppTheme.mediumGray.withOpacity(0.25);
        tickPaint.strokeWidth = isMainTick ? 2 : 1.5;
      }

      canvas.drawLine(inner, outer, tickPaint);
    }

    // Draw progress arc
    if (isRecording) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      // Create gradient for progress arc
      final progressAngle = (seconds % 60) / 60 * 2 * pi;
      
      if (progressAngle > 0) {
        progressPaint.shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: -pi / 2 + progressAngle,
          colors: isPaused
              ? [AppTheme.warningAmber.withOpacity(0.5), AppTheme.warningAmber]
              : [AppTheme.primarySkyBlue, AppTheme.accentCoral],
          tileMode: TileMode.clamp,
        ).createShader(Rect.fromCircle(center: center, radius: radius - 14));

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 14),
          -pi / 2,
          progressAngle,
          false,
          progressPaint,
        );
      }
    }

    // Draw second hand
    if (isRecording && !isPaused) {
      final secondAngle = ((seconds % 60) * 6 - 90) * pi / 180;
      final handLength = radius - 35;
      
      final handPaint = Paint()
        ..color = AppTheme.accentCoral
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final handEnd = Offset(
        center.dx + handLength * cos(secondAngle),
        center.dy + handLength * sin(secondAngle),
      );

      canvas.drawLine(center, handEnd, handPaint);

      // Draw center dot
      final centerDotPaint = Paint()
        ..color = AppTheme.accentCoral
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 5, centerDotPaint);

      // Draw small circle at hand end
      canvas.drawCircle(handEnd, 4, centerDotPaint);
    }

    // Draw minute markers (numbers)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < 12; i++) {
      final minute = i * 5;
      final angle = (i * 30 - 90) * pi / 180;
      final textRadius = radius - 35;
      
      final position = Offset(
        center.dx + textRadius * cos(angle),
        center.dy + textRadius * sin(angle),
      );

      textPainter.text = TextSpan(
        text: minute.toString().padLeft(2, '0'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.mediumGray.withOpacity(0.7),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockFacePainter oldDelegate) {
    return oldDelegate.seconds != seconds ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.isPaused != isPaused;
  }
}

