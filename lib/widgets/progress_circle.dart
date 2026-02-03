/// Progress Circle Widget
///
/// Displays a circular progress indicator matching the Figma design exactly.
/// Shows current intake, goal, and excess progress with golden color when goal is exceeded.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class ProgressCircle extends StatelessWidget {
  final double current;
  final double goal;
  final double size;
  final double strokeWidth;

  const ProgressCircle({
    Key? key,
    required this.current,
    required this.goal,
    this.size = 200,
    this.strokeWidth = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate progress - allow it to exceed 1.0 (100%) to show overflow
    final progress = goal > 0 
        ? (current / goal)
        : 0.0;
    
    // Main progress is capped at 1.0 (100% of goal) for the blue circle
    final mainProgress = progress.clamp(0.0, 1.0);
    
    // Excess progress shows anything beyond 100%, but cap at 2.0 (200%) for visual purposes
    final excessProgress = progress > 1.0 
        ? (progress - 1.0).clamp(0.0, 1.0)
        : 0.0;
    
    final radius = (size - strokeWidth) / 2;
    final circumference = 2 * math.pi * radius;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: NeumorphicStyle.progressCircleShadow(),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle - matches Figma: #E8F4FD
          CustomPaint(
            size: Size(size, size),
            painter: _CirclePainter(
              color: NeumorphicStyle.lightBlue,
              strokeWidth: strokeWidth,
            ),
          ),

          // Progress circle with gradient - matches Figma exactly
          // Use TweenAnimationBuilder for smooth animation
          // Show up to 100% of goal in blue
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: mainProgress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, currentProgress, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _ProgressCirclePainter(
                  progress: currentProgress,
                  strokeWidth: strokeWidth,
                  radius: radius,
                  circumference: circumference,
                  gradient: NeumorphicStyle.primaryGradient(),
                ),
              );
            },
          ),

          // Excess progress circle (golden) - shows overflow beyond goal
          // This appears on top of the blue circle to show how much was exceeded
          if (excessProgress > 0)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0.0,
                end: excessProgress,
              ),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (context, excess, child) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _ProgressCirclePainter(
                    progress: excess,
                    strokeWidth: strokeWidth / 1.5, // Thinner for excess
                    radius: radius,
                    circumference: circumference,
                    gradient: null,
                    color: NeumorphicStyle.golden,
                  ),
                );
              },
            ),

          // Center content - matches Figma exactly
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current intake - matches Figma: text-[32px] font-bold
              Text(
                '${current.round()} ml',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: excessProgress > 0 
                      ? NeumorphicStyle.golden 
                      : NeumorphicStyle.darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Goal - matches Figma: text-sm font-medium
              Text(
                'Goal: ${goal.round()} ml',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: NeumorphicStyle.lightText,
                ),
                textAlign: TextAlign.center,
              ),
              // Excess amount - matches Figma
              if (excessProgress > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '+${(current - goal).round()} ml',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NeumorphicStyle.golden,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Painter for the background circle
class _CirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _CirclePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for the progress circle with gradient support
class _ProgressCirclePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final double radius;
  final double circumference;
  final LinearGradient? gradient;
  final Color? color;

  _ProgressCirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.radius,
    required this.circumference,
    this.gradient,
    this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    if (gradient != null) {
      // Create a shader for the gradient
      final rect = Rect.fromCircle(center: center, radius: radius);
      paint.shader = gradient!.createShader(rect);
    } else if (color != null) {
      paint.color = color!;
    }
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _ProgressCirclePainter ||
        oldDelegate.progress != progress;
  }
}
