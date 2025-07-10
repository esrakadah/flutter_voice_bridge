import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// Enhanced workshop-quality audio visualizer with independent animation controls
class AdvancedAudioVisualizer extends StatefulWidget {
  final bool isRecording;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final AudioVisualizationMode mode;
  final VoidCallback? onAnimationToggle;
  final bool showControls;

  const AdvancedAudioVisualizer({
    super.key,
    required this.isRecording,
    this.height = 120.0,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    this.mode = AudioVisualizationMode.waveform,
    this.onAnimationToggle,
    this.showControls = true,
  });

  @override
  State<AdvancedAudioVisualizer> createState() => _AdvancedAudioVisualizerState();
}

class _AdvancedAudioVisualizerState extends State<AdvancedAudioVisualizer> with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  late AnimationController _pulseController;
  late AnimationController _phaseController;

  late Animation<double> _primaryAnimation;
  late Animation<double> _secondaryAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _phaseAnimation;

  bool _isAnimationPlaying = true; // Independent of recording status

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations(); // Always start animations by default
  }

  void _initializeAnimations() {
    // Primary wave animation - fast oscillation
    _primaryController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _primaryAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_primaryController);

    // Secondary wave animation - medium oscillation
    _secondaryController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _secondaryAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_secondaryController);

    // Pulse animation for overall amplitude
    _pulseController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Phase animation for wave movement
    _phaseController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _phaseAnimation = Tween<double>(begin: 0.0, end: 4 * math.pi).animate(_phaseController);
  }

  void _startAnimations() {
    if (!_isAnimationPlaying) return;
    _primaryController.repeat();
    _secondaryController.repeat();
    _pulseController.repeat(reverse: true);
    _phaseController.repeat();
  }

  void _stopAnimations() {
    _primaryController.stop();
    _secondaryController.stop();
    _pulseController.stop();
    _phaseController.stop();
  }

  void _toggleAnimations() {
    setState(() {
      _isAnimationPlaying = !_isAnimationPlaying;
      if (_isAnimationPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    });
    widget.onAnimationToggle?.call();
  }

  @override
  void didUpdateWidget(AdvancedAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animations are now independent of recording status
    // They continue based on _isAnimationPlaying state
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _pulseController.dispose();
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_primaryAnimation, _secondaryAnimation, _pulseAnimation, _phaseAnimation]),
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isRecording
                ? [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]
                : _isAnimationPlaying
                ? [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1)]
                : null,
          ),
          child: Stack(
            children: [
              // Main visualizer
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: AdvancedAudioPainter(
                    primaryPhase: _primaryAnimation.value,
                    secondaryPhase: _secondaryAnimation.value,
                    amplitude: _pulseAnimation.value,
                    globalPhase: _phaseAnimation.value,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                    tertiaryColor: widget.tertiaryColor,
                    isRecording: widget.isRecording,
                    isAnimating: _isAnimationPlaying,
                    mode: widget.mode,
                  ),
                  size: Size.infinite,
                ),
              ),

              // Animation control buttons
              if (widget.showControls) Positioned(right: 12, top: 12, child: _buildAnimationControls()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimationControls() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: _isAnimationPlaying ? Icons.pause : Icons.play_arrow,
            onTap: _toggleAnimations,
            tooltip: _isAnimationPlaying ? 'Pause Animation' : 'Play Animation',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onTap, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}

// Audio visualization modes for different effects
enum AudioVisualizationMode { waveform, spectrum, particles, radial, hybrid }

// Advanced custom painter with shader-like effects
class AdvancedAudioPainter extends CustomPainter {
  final double primaryPhase;
  final double secondaryPhase;
  final double amplitude;
  final double globalPhase;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final bool isRecording;
  final bool isAnimating;
  final AudioVisualizationMode mode;

  AdvancedAudioPainter({
    required this.primaryPhase,
    required this.secondaryPhase,
    required this.amplitude,
    required this.globalPhase,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.isRecording,
    required this.isAnimating,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (mode) {
      case AudioVisualizationMode.waveform:
        _paintWaveform(canvas, size);
        break;
      case AudioVisualizationMode.spectrum:
        _paintSpectrum(canvas, size);
        break;
      case AudioVisualizationMode.particles:
        _paintParticles(canvas, size);
        break;
      case AudioVisualizationMode.radial:
        _paintRadial(canvas, size);
        break;
      case AudioVisualizationMode.hybrid:
        _paintHybrid(canvas, size);
        break;
    }
  }

  void _paintWaveform(Canvas canvas, Size size) {
    if (!isAnimating) {
      _paintStaticWave(canvas, size);
      return;
    }

    // Enhanced intensity when recording vs just animating
    final intensityMultiplier = isRecording ? 1.5 : 0.8;

    // Create multiple wave layers for depth
    _paintWaveLayer(canvas, size, 0.7 * intensityMultiplier, primaryColor.withValues(alpha: 0.8), 1.0);
    _paintWaveLayer(canvas, size, 0.5 * intensityMultiplier, secondaryColor.withValues(alpha: 0.6), 1.5);
    _paintWaveLayer(canvas, size, 0.3 * intensityMultiplier, tertiaryColor.withValues(alpha: 0.4), 2.0);

    // Add glow effect when recording
    if (isRecording) {
      _paintGlowEffect(canvas, size);
    }
  }

  void _paintWaveLayer(Canvas canvas, Size size, double amplitudeMultiplier, Color color, double frequencyMultiplier) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final path = Path();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Create complex waveform using multiple sine waves
    final points = <Offset>[];
    final resolution = width / 2;

    for (int i = 0; i <= resolution; i++) {
      final x = (i / resolution) * width;
      final normalizedX = i / resolution;

      // Complex wave function combining multiple harmonics
      final wave1 = math.sin(
        (normalizedX * 4 * math.pi * frequencyMultiplier) + (primaryPhase * frequencyMultiplier) + globalPhase,
      );
      final wave2 =
          math.sin(
            (normalizedX * 8 * math.pi * frequencyMultiplier) +
                (secondaryPhase * frequencyMultiplier * 0.7) +
                globalPhase * 1.3,
          ) *
          0.5;
      final wave3 =
          math.sin(
            (normalizedX * 12 * math.pi * frequencyMultiplier) +
                (primaryPhase * frequencyMultiplier * 1.4) +
                globalPhase * 0.8,
          ) *
          0.25;

      final combinedWave = wave1 + wave2 + wave3;
      final y = centerY + (combinedWave * amplitude * amplitudeMultiplier * height * 0.25);

      points.add(Offset(x, y));
    }

    // Create smooth path through points
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final current = points[i];
        final previous = points[i - 1];
        final controlPoint = Offset(previous.dx + (current.dx - previous.dx) * 0.5, previous.dy);
        path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, current.dx, current.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _paintStaticWave(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final paint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, centerY);
    path.lineTo(width, centerY);

    canvas.drawPath(path, paint);
  }

  void _paintSpectrum(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final barCount = 64;
    final barWidth = width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth;
      final normalizedIndex = i / (barCount - 1);

      // Simulate frequency spectrum with varying heights
      final baseHeight = math.sin(normalizedIndex * math.pi) * 0.7;
      final intensityMultiplier = isRecording ? 1.0 : 0.6;
      final animatedHeight = isAnimating
          ? baseHeight *
                amplitude *
                intensityMultiplier *
                (0.5 + math.sin((primaryPhase * 3) + (normalizedIndex * 6)) * 0.5)
          : baseHeight * 0.1;

      final barHeight = animatedHeight * height * 0.8;
      final color = Color.lerp(primaryColor, tertiaryColor, normalizedIndex)!;

      final paint = Paint()
        ..color = color.withValues(alpha: isAnimating ? (isRecording ? 0.8 : 0.6) : 0.3)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, height - barHeight, barWidth - 2, barHeight),
        Radius.circular(barWidth * 0.2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final particleCount = 100;

    for (int i = 0; i < particleCount; i++) {
      final normalizedIndex = i / (particleCount - 1);
      final angle = normalizedIndex * 2 * math.pi;

      final intensityMultiplier = isRecording ? 1.0 : 0.7;
      final baseRadius = isAnimating
          ? (amplitude * 60 * intensityMultiplier) + (math.sin((primaryPhase * 2) + (angle * 3)) * 20)
          : 10;

      final x = (width / 2) + (math.cos(angle + globalPhase) * baseRadius);
      final y = (height / 2) + (math.sin(angle + globalPhase) * baseRadius * 0.6);

      final particleSize = isAnimating
          ? 2.0 + (math.sin((secondaryPhase * 3) + (angle * 5)) * 1.5) * intensityMultiplier
          : 1.0;

      final color = Color.lerp(primaryColor, secondaryColor, normalizedIndex)!;
      final paint = Paint()
        ..color = color.withValues(alpha: isAnimating ? (isRecording ? 0.7 : 0.5) : 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  void _paintRadial(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height / 2);
    final maxRadius = math.min(width, height) * 0.4;

    for (int ring = 0; ring < 5; ring++) {
      final ringRadius = (ring + 1) * maxRadius / 5;
      final points = 24 + (ring * 8);

      final path = Path();
      for (int i = 0; i < points; i++) {
        final angle = (i / points) * 2 * math.pi;
        final intensityMultiplier = isRecording ? 1.0 : 0.6;
        final waveOffset = isAnimating
            ? math.sin((primaryPhase * 2) + (angle * 4) + (ring * 0.5)) * amplitude * 15 * intensityMultiplier
            : 0;

        final radius = ringRadius + waveOffset;
        final x = center.dx + (math.cos(angle + globalPhase * 0.3) * radius);
        final y = center.dy + (math.sin(angle + globalPhase * 0.3) * radius);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      final color = Color.lerp(primaryColor, tertiaryColor, ring / 4)!;
      final paint = Paint()
        ..color = color.withValues(alpha: isAnimating ? (isRecording ? 0.3 - (ring * 0.05) : 0.2 - (ring * 0.03)) : 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawPath(path, paint);
    }
  }

  void _paintHybrid(Canvas canvas, Size size) {
    // Combine multiple visualization modes
    _paintWaveform(canvas, size);

    // Add spectral overlay
    final overlaySize = Size(size.width, size.height * 0.3);
    canvas.save();
    canvas.translate(0, size.height * 0.7);
    _paintSpectrum(canvas, overlaySize);
    canvas.restore();

    // Add particle accents
    canvas.save();
    canvas.scale(0.5);
    canvas.translate(size.width * 0.5, size.height * 0.5);
    _paintParticles(canvas, Size(size.width, size.height * 0.4));
    canvas.restore();
  }

  void _paintGlowEffect(Canvas canvas, Size size) {
    if (!isRecording) return;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Create glow effect using blur
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3 * amplitude)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 10.0);

    canvas.drawCircle(Offset(width / 2, centerY), width * 0.3 * amplitude, glowPaint);
  }

  @override
  bool shouldRepaint(covariant AdvancedAudioPainter oldDelegate) {
    return oldDelegate.primaryPhase != primaryPhase ||
        oldDelegate.secondaryPhase != secondaryPhase ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.globalPhase != globalPhase ||
        oldDelegate.isRecording != isRecording;
  }
}

// Legacy audio visualizer components (keeping for backward compatibility)
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

// Simple animated audio visualizer (keeping for backward compatibility)
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
                        color: widget.barColor.withValues(alpha: 0.3 * _glowAnimation.value),
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
                                  widget.barColor.withValues(alpha: 0.7),
                                  widget.barColor.withValues(alpha: 0.3),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  widget.barColor.withValues(alpha: 0.3),
                                  widget.barColor.withValues(alpha: 0.1),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(widget.barWidth / 2),
                        boxShadow: widget.isAnimating
                            ? [
                                BoxShadow(
                                  color: widget.barColor.withValues(alpha: 0.2),
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

// Specialized voice wave visualizer for recording state (keeping for specific use)
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
        return SizedBox(
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
      paint.color = primaryColor.withValues(alpha: 0.3);
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
      paint.color = colorLerp.withValues(alpha: 0.6 + (waveOffset.abs() * 0.4));

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
