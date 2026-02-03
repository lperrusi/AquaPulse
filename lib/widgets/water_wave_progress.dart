/// Water Wave Progress Animation Widget
///
/// A custom progress indicator that shows a realistic water-like wave animation.
/// Used to visualize hydration progress in a more engaging way with advanced visual effects.

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WaterWaveProgress extends StatefulWidget {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double size;

  const WaterWaveProgress({
    Key? key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 12.0,
    this.size = 140.0,
  }) : super(key: key);

  @override
  State<WaterWaveProgress> createState() => _WaterWaveProgressState();
}

class _WaterWaveProgressState extends State<WaterWaveProgress> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _splashController;
  late Animation<double> _animation;
  late Animation<double> _splashAnimation;
  late double _oldValue;
  late double _currentValue;
  bool _showSplash = false;

  @override
  void initState() {
    super.initState();
    _oldValue = 0;
    _currentValue = widget.value;
    
    // Main wave animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: _oldValue, end: _currentValue).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    // Splash effect animation controller
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _splashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: Curves.easeOutCirc,
      ),
    );
    
    _splashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showSplash = false;
        });
        _splashController.reset();
      }
    });
    
    _animationController.addListener(() {
      setState(() {});
    });
    
    _animationController.forward();
    // Start the continuous wave animation
    _animationController.repeat(reverse: false);
  }

  @override
  void didUpdateWidget(covariant WaterWaveProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // Show splash effect when value changes
      setState(() {
        _showSplash = true;
      });
      _splashController.forward();
      
      _oldValue = _currentValue;
      _currentValue = widget.value;
      _animation = Tween<double>(begin: _oldValue, end: _currentValue).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOutCubic,
        ),
      );
      
      // Don't reset the wave animation controller to keep the waves flowing
      // Just make sure the progress value is updated
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: WaveProgressPainter(
              animationValue: _animationController.value,
              value: _animation.value,
              color: widget.color,
              backgroundColor: widget.backgroundColor,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class WaveProgressPainter extends CustomPainter {
  static const double waveFrequency = 10; // Controls how many waves appear
  static const double waveAmplitude = 0.12; // Controls the height of the waves
  final double animationValue;
  final double value;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  
  WaveProgressPainter({
    required this.animationValue,
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Create clipping path for circular shape
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // Draw filled background
    final backgroundFillPaint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundFillPaint);

    // Calculate the fill level based on progress value
    final fillLevel = center.dy + radius - (2 * radius * value);

    // Create gradient for water effect
    final waterGradient = ui.Gradient.linear(
      Offset(center.dx, fillLevel), 
      Offset(center.dx, center.dy + radius),
      [
        color.withOpacity(0.7),
        color,
      ],
    );

    // Create wave paths
    final wave1Path = Path();
    final wave2Path = Path();
    
    // Bottom rectangle fill
    wave1Path.moveTo(center.dx - radius, center.dy + radius);
    wave1Path.lineTo(center.dx - radius, fillLevel);
    wave2Path.moveTo(center.dx - radius, center.dy + radius);
    wave2Path.lineTo(center.dx - radius, fillLevel);
    
    // Draw animated wave pattern
    for (double x = -radius; x <= radius; x += 5) {
      // First wave
      final wave1Height = sin((x / radius * waveFrequency) + (animationValue * 2 * pi)) * 
                        waveAmplitude * strokeWidth;
      wave1Path.lineTo(center.dx + x, fillLevel + wave1Height);
      
      // Second wave (slightly offset)
      final wave2Height = sin((x / radius * waveFrequency) + (animationValue * 2 * pi) + pi/4) * 
                        waveAmplitude * strokeWidth;
      wave2Path.lineTo(center.dx + x, fillLevel + wave2Height);
    }
    
    // Complete the wave paths
    wave1Path.lineTo(center.dx + radius, fillLevel);
    wave1Path.lineTo(center.dx + radius, center.dy + radius);
    wave1Path.close();
    
    wave2Path.lineTo(center.dx + radius, fillLevel);
    wave2Path.lineTo(center.dx + radius, center.dy + radius);
    wave2Path.close();
    
    // Draw the first wave with gradient
    final wave1Paint = Paint()
      ..shader = waterGradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(wave1Path, wave1Paint);
    
    // Draw the second wave with slightly transparent color for layered effect
    final wave2Paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(wave2Path, wave2Paint);
    
    // Draw circular border
    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, borderPaint);
    
    // Draw splash effect when progress changes
    if (value >= 0.99) {
      // Draw highlight effect for completion
      final highlightPaint = Paint()
        ..color = color.withOpacity((sin(animationValue * 2 * pi) + 1) / 4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.8;
      
      canvas.drawCircle(center, radius, highlightPaint);
      
      // Add sparkle effect
      final sparkleRadius = radius * 0.2;
      final sparkleAngle = animationValue * 2 * pi;
      
      final sparkleX = center.dx + (radius * 0.7) * cos(sparkleAngle);
      final sparkleY = center.dy + (radius * 0.7) * sin(sparkleAngle);
      
      final sparklePaint = Paint()
        ..color = Colors.white.withOpacity((sin(animationValue * 4 * pi) + 1) / 3 + 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(sparkleX, sparkleY), sparkleRadius * ((sin(animationValue * 8 * pi) + 1) / 4 + 0.1), sparklePaint);
    }
    
    // Draw droplet overlay effect
    for (int i = 0; i < 3; i++) {
      final dropletAngle = animationValue * 2 * pi + (i * 2 * pi / 3);
      if (value > 0.2) {
        final dropY = fillLevel - 10 + (sin(animationValue * 3 * pi + i) * 5);
        final dropX = center.dx + sin(dropletAngle) * (radius * 0.6);
        
        if (dropY < center.dy + radius) { 
          final dropletPaint = Paint()
            ..color = Colors.white.withOpacity(0.4 - (0.2 * i / 3))
            ..style = PaintingStyle.fill;
          
          // Small water droplet effect
          canvas.drawCircle(Offset(dropX, dropY), 3 - (i * 0.5), dropletPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaveProgressPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.value != value ||
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
