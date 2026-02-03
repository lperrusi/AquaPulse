/// Notification Toast Widget
///
/// Toast component for showing notifications with progress bar animation.
/// Matches Figma design exactly.

import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/neumorphic_style.dart';

class NotificationToast extends StatefulWidget {
  final bool isVisible;
  final String title;
  final String message;
  final VoidCallback onClose;
  final VoidCallback? onAction;

  const NotificationToast({
    super.key,
    required this.isVisible,
    required this.title,
    required this.message,
    required this.onClose,
    this.onAction,
  });

  @override
  State<NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _progressTimer;
  double _progress = 100.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(NotificationToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _showToast();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _hideToast();
    }
  }

  void _showToast() {
    _progress = 100.0;
    _animationController.forward();
    _startProgressTimer();
  }

  void _hideToast() {
    _progressTimer?.cancel();
    _animationController.reverse();
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    const duration = Duration(seconds: 5);
    const interval = Duration(milliseconds: 50);
    const decrement = 100.0 / (duration.inMilliseconds / interval.inMilliseconds);

    _progressTimer = Timer.periodic(interval, (timer) {
      if (mounted) {
        setState(() {
          _progress -= decrement;
          if (_progress <= 0) {
            _progress = 0;
            timer.cancel();
            widget.onClose();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && !_animationController.isAnimating) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 500
                    ? (MediaQuery.of(context).size.width - 500) / 2
                    : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: NeumorphicStyle.primaryBlue.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: NeumorphicStyle.primaryGradient(),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: NeumorphicStyle.primaryGradient(),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    size: 16,
                                    color: NeumorphicStyle.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style: NeumorphicStyle.neumorphicText(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: widget.onClose,
                                    icon: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: NeumorphicStyle.surfaceBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: NeumorphicStyle.lightText,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.message,
                                style: NeumorphicStyle.neumorphicText(
                                  fontSize: 14,
                                  color: NeumorphicStyle.lightText,
                                ),
                              ),

                              // Action Button
                              if (widget.onAction != null) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: widget.onAction,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: NeumorphicStyle.primaryGradient(),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Add Water Now',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
