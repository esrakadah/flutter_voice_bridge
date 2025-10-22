import 'package:flutter/material.dart';
import 'dart:math' as math;

// Enhanced voice recorder button widget with delightful animations
class VoiceRecorderButton extends StatefulWidget {
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final bool isRecording;
  final bool isEnabled;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? errorColor;

  const VoiceRecorderButton({
    super.key,
    this.onStartRecording,
    this.onStopRecording,
    required this.isRecording,
    this.isEnabled = true,
    this.primaryColor,
    this.secondaryColor,
    this.errorColor,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Scale animation for tap feedback
    _scaleController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));

    // Rotation animation for state transitions
    _rotationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _rotationController, curve: Curves.elasticOut));

    // Pulse animation for recording state
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Ripple animation for visual feedback
    _rippleController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _rippleController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(VoiceRecorderButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startRecordingAnimations();
      } else {
        _stopRecordingAnimations();
      }
    }
  }

  void _startRecordingAnimations() {
    _rotationController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _stopRecordingAnimations() {
    _rotationController.reverse();
    _pulseController.stop();
    _pulseController.reset();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    if (!widget.isEnabled) return;
    _scaleController.reverse();
  }

  void _handleTap() {
    if (!widget.isEnabled) return;

    // Trigger ripple effect
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });

    if (widget.isRecording) {
      widget.onStopRecording?.call();
    } else {
      widget.onStartRecording?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    final secondaryColor = widget.secondaryColor ?? theme.colorScheme.secondary;
    final errorColor = widget.errorColor ?? theme.colorScheme.error;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rotationAnimation, _pulseAnimation, _rippleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * (widget.isRecording ? _pulseAnimation.value : 1.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect background
              if (_rippleAnimation.value > 0)
                Container(
                  width: 80 + (_rippleAnimation.value * 40),
                  height: 80 + (_rippleAnimation.value * 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (widget.isRecording ? errorColor : primaryColor).withValues(
                      alpha: 0.2 * (1 - _rippleAnimation.value),
                    ),
                  ),
                ),

              // Outer glow ring when recording
              if (widget.isRecording)
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: errorColor.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 4)],
                  ),
                ),

              // Main button
              GestureDetector(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                onTap: _handleTap,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * math.pi,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: widget.isRecording
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [errorColor, errorColor.withValues(alpha: 0.8)],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryColor, secondaryColor],
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isRecording ? errorColor : primaryColor).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: animation,
                          child: ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: Icon(
                        widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        key: ValueKey(widget.isRecording),
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // State indicator ring
              if (widget.isRecording)
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: null,
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(errorColor.withValues(alpha: 0.6)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Compact version for smaller spaces
class CompactVoiceRecorderButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isRecording;
  final bool isEnabled;
  final double size;

  const CompactVoiceRecorderButton({
    super.key,
    this.onTap,
    required this.isRecording,
    this.isEnabled = true,
    this.size = 48.0,
  });

  @override
  State<CompactVoiceRecorderButton> createState() => _CompactVoiceRecorderButtonState();
}

class _CompactVoiceRecorderButtonState extends State<CompactVoiceRecorderButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.isEnabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isRecording
                      ? [theme.colorScheme.error, theme.colorScheme.error.withValues(alpha: 0.8)]
                      : [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording ? theme.colorScheme.error : theme.colorScheme.primary).withValues(
                      alpha: 0.2,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: widget.size * 0.5,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
