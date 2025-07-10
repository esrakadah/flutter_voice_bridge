import 'package:flutter/material.dart';
import 'dart:math' as math;

// Audio visualizer component for displaying audio waveforms
class AudioVisualizer extends StatelessWidget {
  final List<double> audioData;
  final Color barColor;
  final double barWidth;
  final double barSpacing;
  final double maxHeight;

  const AudioVisualizer({
    super.key,
    required this.audioData,
    this.barColor = Colors.blue,
    this.barWidth = 4.0,
    this.barSpacing = 2.0,
    this.maxHeight = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: audioData.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;

          return Container(
            width: barWidth,
            height: value * maxHeight,
            margin: EdgeInsets.only(right: index < audioData.length - 1 ? barSpacing : 0),
            decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(barWidth / 2)),
          );
        }).toList(),
      ),
    );
  }
}

// Enhanced animated audio visualizer with gradient effects and micro-interactions
class AnimatedAudioVisualizer extends StatefulWidget {
  final int barCount;
  final Color barColor;
  final double barWidth;
  final double barSpacing;
  final double maxHeight;
  final bool isAnimating;

  const AnimatedAudioVisualizer({
    super.key,
    this.barCount = 20,
    this.barColor = Colors.blue,
    this.barWidth = 4.0,
    this.barSpacing = 2.0,
    this.maxHeight = 100.0,
    this.isAnimating = false,
  });

  @override
  State<AnimatedAudioVisualizer> createState() => _AnimatedAudioVisualizerState();
}

class _AnimatedAudioVisualizerState extends State<AnimatedAudioVisualizer> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePulseAnimation();
    _initializeGlowAnimation();
  }

  void _initializeAnimations() {
    _controllers = List.generate(widget.barCount, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 400 + (index * 30)),
        vsync: this,
      );
    });

    _animations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;

      // Create varied animation curves for more organic movement
      final curve = index % 3 == 0
          ? Curves.easeInOut
          : index % 3 == 1
          ? Curves.elasticInOut
          : Curves.bounceInOut;

      return Tween<double>(
        begin: 0.05,
        end: 0.3 + (math.sin(index * 0.5) * 0.4).abs(),
      ).animate(CurvedAnimation(parent: controller, curve: curve));
    }).toList();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  void _initializeGlowAnimation() {
    _glowController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    // Start bar animations with staggered timing
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && widget.isAnimating) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }

    // Start pulse and glow effects
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }

    _pulseController.stop();
    _pulseController.reset();
    _glowController.stop();
    _glowController.reset();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isAnimating ? _pulseAnimation.value : 1.0,
          child: Container(
            height: widget.maxHeight,
            decoration: widget.isAnimating
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.maxHeight / 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.barColor.withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 20 * _glowAnimation.value,
                        spreadRadius: 5 * _glowAnimation.value,
                      ),
                    ],
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.barCount, (index) {
                return AnimatedBuilder(
                  animation: _animations[index],
                  builder: (context, child) {
                    final heightMultiplier = widget.isAnimating ? _animations[index].value : 0.05;

                    return Container(
                      width: widget.barWidth,
                      height: math.max(widget.maxHeight * heightMultiplier, 2.0),
                      margin: EdgeInsets.only(right: index < widget.barCount - 1 ? widget.barSpacing : 0),
                      decoration: BoxDecoration(
                        gradient: widget.isAnimating
                            ? LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  widget.barColor,
                                  widget.barColor.withOpacity(0.7),
                                  widget.barColor.withOpacity(0.3),
                                ],
                              )
                            : LinearGradient(
                                colors: [widget.barColor.withOpacity(0.3), widget.barColor.withOpacity(0.1)],
                              ),
                        borderRadius: BorderRadius.circular(widget.barWidth / 2),
                        boxShadow: widget.isAnimating
                            ? [
                                BoxShadow(
                                  color: widget.barColor.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// Specialized voice wave visualizer for recording state
class VoiceWaveVisualizer extends StatefulWidget {
  final bool isRecording;
  final Color primaryColor;
  final Color secondaryColor;
  final double height;
  final int waveCount;

  const VoiceWaveVisualizer({
    super.key,
    required this.isRecording,
    required this.primaryColor,
    required this.secondaryColor,
    this.height = 60.0,
    this.waveCount = 30,
  });

  @override
  State<VoiceWaveVisualizer> createState() => _VoiceWaveVisualizerState();
}

class _VoiceWaveVisualizerState extends State<VoiceWaveVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.animateTo(0.0);
      }
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
        return Container(
          height: widget.height,
          child: CustomPaint(
            painter: VoiceWavePainter(
              animationValue: _animation.value,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              isRecording: widget.isRecording,
              waveCount: widget.waveCount,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isRecording;
  final int waveCount;

  VoiceWavePainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isRecording,
    required this.waveCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    if (!isRecording) {
      // Draw static flat line when not recording
      paint.color = primaryColor.withOpacity(0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(width / 2, centerY), width: width * 0.6, height: 2),
          const Radius.circular(1),
        ),
        paint,
      );
      return;
    }

    // Draw animated wave bars when recording
    final barWidth = width / waveCount;

    for (int i = 0; i < waveCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final normalizedPosition = i / (waveCount - 1);

      // Create wave effect with sine function
      final waveOffset = math.sin((normalizedPosition * math.pi * 4) + (animationValue * math.pi * 2));
      final amplitude = math.sin(normalizedPosition * math.pi) * 0.8; // Envelope

      final barHeight = (amplitude * waveOffset.abs() * height * 0.7) + (height * 0.1);

      // Gradient effect based on position
      final colorLerp = Color.lerp(primaryColor, secondaryColor, normalizedPosition)!;
      paint.color = colorLerp.withOpacity(0.6 + (waveOffset.abs() * 0.4));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, centerY), width: barWidth * 0.6, height: math.max(barHeight, 2)),
          Radius.circular(barWidth * 0.3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VoiceWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.isRecording != isRecording;
  }
}
