import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../core/preferences/animation_preferences.dart';

// Enhanced workshop-quality audio visualizer with independent animation controls
class AdvancedAudioVisualizer extends StatefulWidget {
  final bool isRecording;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Color quaternaryColor;
  final AudioVisualizationMode mode;
  final VoidCallback? onAnimationToggle;
  final bool showControls;
  final VoidCallback? onTap; // Add tap callback for navigation

  // External control properties for fullscreen mode
  final bool? externalAnimationState;
  final double? externalAnimationSpeed;
  final double? externalAnimationScale; // Add external scale control

  const AdvancedAudioVisualizer({
    super.key,
    required this.isRecording,
    this.height = 120.0,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.quaternaryColor,
    this.mode = AudioVisualizationMode.waveform,
    this.onAnimationToggle,
    this.showControls = true,
    this.onTap, // Tap callback for fullscreen navigation
    this.externalAnimationState, // External animation control
    this.externalAnimationSpeed,
    this.externalAnimationScale, // External scale control
  });

  @override
  State<AdvancedAudioVisualizer> createState() => _AdvancedAudioVisualizerState();
}

class _AdvancedAudioVisualizerState extends State<AdvancedAudioVisualizer> with TickerProviderStateMixin {
  // Single master animation controller for perfect synchronization
  late AnimationController _masterController;
  late Animation<double> _masterAnimation;

  bool _isAnimationPlaying = true;
  double _animationSpeed = 1.0; // 1.0 = normal speed
  double _animationScale = 1.0; // 1.0 = normal scale

  // Speed presets
  static const List<double> _speedPresets = [0.5, 1.0, 1.5, 2.0];
  static const List<String> _speedLabels = ['0.5x', '1x', '1.5x', '2x'];
  int _currentSpeedIndex = 1; // Start with normal speed (1.0x)

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnimationPreferences();
  }

  void _loadAnimationPreferences() async {
    // Use external state if provided (for fullscreen mode)
    if (widget.externalAnimationState != null && widget.externalAnimationSpeed != null) {
      setState(() {
        _isAnimationPlaying = widget.externalAnimationState!;
        _animationSpeed = widget.externalAnimationSpeed!;
        _animationScale = widget.externalAnimationScale ?? 1.0; // Use external scale if provided

        // Find the index for the external speed
        for (int i = 0; i < _speedPresets.length; i++) {
          if (_speedPresets[i] == _animationSpeed) {
            _currentSpeedIndex = i;
            break;
          }
        }

        // Update animation controller duration
        final newDuration = Duration(milliseconds: (2400 / _animationSpeed).round());
        _masterController.duration = newDuration;
      });

      if (_isAnimationPlaying) {
        _startAnimations();
      }
      return;
    }

    try {
      final settings = await AnimationPreferences.getAnimationSettings();

      setState(() {
        _isAnimationPlaying = settings.enabled;
        _animationSpeed = settings.speed;
        _animationScale = settings.scale; // Load scale from preferences

        // Find the index for the loaded speed
        for (int i = 0; i < _speedPresets.length; i++) {
          if (_speedPresets[i] == settings.speed) {
            _currentSpeedIndex = i;
            break;
          }
        }

        // Update animation controller duration
        final newDuration = Duration(milliseconds: (2400 / _animationSpeed).round());
        _masterController.duration = newDuration;
      });

      // Start animations if enabled
      if (_isAnimationPlaying) {
        _startAnimations();
      }
    } catch (e) {
      // If loading fails, use defaults and start animations
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    // Single master controller with base duration
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 2400), // Base duration for smooth loops
      vsync: this,
    );

    _masterAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi, // One full cycle
    ).animate(_masterController);
  }

  void _startAnimations() {
    if (!_isAnimationPlaying) return;
    _masterController.repeat();
  }

  void _stopAnimations() {
    _masterController.stop();
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

    // Save preference
    AnimationPreferences.setAnimationEnabled(_isAnimationPlaying);
    widget.onAnimationToggle?.call();
  }

  void _changeSpeed() {
    setState(() {
      _currentSpeedIndex = (_currentSpeedIndex + 1) % _speedPresets.length;
      _animationSpeed = _speedPresets[_currentSpeedIndex];

      // Update master controller duration based on speed
      final newDuration = Duration(milliseconds: (2400 / _animationSpeed).round());

      _masterController.duration = newDuration;

      // Restart animation with new speed if playing
      if (_isAnimationPlaying) {
        _masterController.reset();
        _masterController.repeat();
      }
    });

    // Save speed preference
    AnimationPreferences.setAnimationSpeed(_animationSpeed);
  }

  // Derived animation values from master controller
  double get _primaryPhase => _masterAnimation.value * 1.0; // Base frequency
  double get _secondaryPhase => _masterAnimation.value * 1.5; // 1.5x frequency
  double get _pulsePhase => _masterAnimation.value * 0.5; // Slower pulse
  double get _globalPhase => _masterAnimation.value * 0.8; // Gentle drift

  // Pulse amplitude derived from pulse phase
  double get _pulseAmplitude => 0.3 + (0.7 * (0.5 + 0.5 * math.sin(_pulsePhase)));

  @override
  void didUpdateWidget(AdvancedAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle external state changes (for fullscreen mode)
    if (widget.externalAnimationState != null && widget.externalAnimationSpeed != null) {
      if (widget.externalAnimationState != oldWidget.externalAnimationState ||
          widget.externalAnimationSpeed != oldWidget.externalAnimationSpeed ||
          widget.externalAnimationScale != oldWidget.externalAnimationScale) {
        setState(() {
          _isAnimationPlaying = widget.externalAnimationState!;
          _animationSpeed = widget.externalAnimationSpeed!;
          _animationScale = widget.externalAnimationScale ?? 1.0; // Update scale

          // Update controller duration
          final newDuration = Duration(milliseconds: (2400 / _animationSpeed).round());
          _masterController.duration = newDuration;

          // Update speed index
          for (int i = 0; i < _speedPresets.length; i++) {
            if (_speedPresets[i] == _animationSpeed) {
              _currentSpeedIndex = i;
              break;
            }
          }
        });

        // Restart animation with new settings
        if (_isAnimationPlaying) {
          _masterController.reset();
          _masterController.repeat();
        } else {
          _stopAnimations();
        }
      }
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _masterAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap, // Enable tap to navigate to fullscreen
          child: Container(
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
                      primaryPhase: _primaryPhase,
                      secondaryPhase: _secondaryPhase,
                      amplitude: _pulseAmplitude,
                      globalPhase: _globalPhase,
                      primaryColor: widget.primaryColor,
                      secondaryColor: widget.secondaryColor,
                      tertiaryColor: widget.tertiaryColor,
                      quaternaryColor: widget.quaternaryColor,
                      isRecording: widget.isRecording,
                      isAnimating: _isAnimationPlaying,
                      mode: widget.mode,
                      scale: _animationScale, // Pass scale to painter
                    ),
                    size: Size.infinite,
                  ),
                ),

                // Animation control buttons
                if (widget.showControls) Positioned(right: 12, top: 12, child: _buildAnimationControls()),

                // Tap indicator for fullscreen (when onTap is provided)
                if (widget.onTap != null && !widget.showControls)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Icon(Icons.fullscreen_rounded, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimationControls() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          _buildControlButton(
            icon: _isAnimationPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: _toggleAnimations,
            tooltip: _isAnimationPlaying ? 'Pause Animation' : 'Play Animation',
            isPrimary: true,
          ),

          const SizedBox(width: 4),

          // Speed control button
          _buildSpeedButton(),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isPrimary ? widget.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
            ),
            child: Icon(icon, size: 20, color: isPrimary ? widget.primaryColor : Colors.white.withValues(alpha: 0.9)),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton() {
    return Tooltip(
      message: 'Animation Speed: ${_speedLabels[_currentSpeedIndex]}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _changeSpeed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: widget.secondaryColor.withValues(alpha: 0.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed_rounded, size: 16, color: widget.secondaryColor),
                const SizedBox(width: 4),
                Text(
                  _speedLabels[_currentSpeedIndex],
                  style: TextStyle(color: widget.secondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
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
  final Color quaternaryColor;
  final bool isRecording;
  final bool isAnimating;
  final AudioVisualizationMode mode;
  final double scale; // Add scale parameter

  AdvancedAudioPainter({
    required this.primaryPhase,
    required this.secondaryPhase,
    required this.amplitude,
    required this.globalPhase,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.quaternaryColor,
    required this.isRecording,
    required this.isAnimating,
    required this.mode,
    this.scale = 1.0, // Default scale
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

    // Create multiple wave layers for depth (DevFest order: Blue, Yellow, Green, Red)
    _paintWaveLayer(canvas, size, 0.8 * intensityMultiplier * scale, primaryColor.withValues(alpha: 0.8), 1.0);
    _paintWaveLayer(canvas, size, 0.6 * intensityMultiplier * scale, secondaryColor.withValues(alpha: 0.7), 1.3);
    _paintWaveLayer(canvas, size, 0.45 * intensityMultiplier * scale, tertiaryColor.withValues(alpha: 0.6), 1.7);
    _paintWaveLayer(canvas, size, 0.3 * intensityMultiplier * scale, quaternaryColor.withValues(alpha: 0.5), 2.2);

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

    // Create a subtle gradient line when static (DevFest colors: Blue, Yellow, Green, Red)
    final gradient = ui.Gradient.linear(Offset(0, centerY), Offset(width, centerY), [
      primaryColor.withValues(alpha: 0.5),
      secondaryColor.withValues(alpha: 0.4),
      tertiaryColor.withValues(alpha: 0.35),
      quaternaryColor.withValues(alpha: 0.3),
    ]);

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
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
      final baseHeight = math.sin(normalizedIndex * math.pi) * 0.8; // Slightly taller
      final intensityMultiplier = isRecording ? 1.2 : 0.8; // More intense
      final animatedHeight = isAnimating
          ? baseHeight *
                amplitude *
                intensityMultiplier *
                (0.5 + math.sin((primaryPhase * 3) + (normalizedIndex * 6)) * 0.5)
          : baseHeight * 0.15; // Higher static bars

      final barHeight = math.max(animatedHeight * height * 0.85 * scale, 2.0); // Ensure minimum height, apply scale

      // Create frequency-based color mapping (like a real spectrum analyzer)
      final hue = normalizedIndex * 280; // From red to blue across spectrum
      final vibrantColor = HSVColor.fromAHSV(1.0, hue, 0.8, 0.9).toColor();
      final blendedColor = Color.lerp(vibrantColor, primaryColor, 0.2)!;

      final paint = Paint()
        ..color = blendedColor.withValues(alpha: isAnimating ? (isRecording ? 0.9 : 0.7) : 0.4)
        ..style = PaintingStyle.fill;

      // Add gradient effect to bars
      if (isAnimating && barHeight > 10) {
        final gradient = ui.Gradient.linear(
          Offset(x, height),
          Offset(x, height - barHeight),
          [
            blendedColor.withValues(alpha: 0.9),
            blendedColor.withValues(alpha: 0.6),
            blendedColor.withValues(alpha: 0.3),
          ],
          [0.0, 0.7, 1.0],
        );

        paint.shader = gradient;
      }

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, height - barHeight, barWidth - 2, barHeight),
        Radius.circular(barWidth * 0.3), // More rounded
      );

      // Add glow for taller bars
      if (isAnimating && barHeight > height * 0.3) {
        final glowPaint = Paint()
          ..color = blendedColor.withValues(alpha: 0.3)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 2.0);
        canvas.drawRRect(rect, glowPaint);
      }

      canvas.drawRRect(rect, paint);
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final particleCount = 120; // More particles for denser effect

    // Add padding to prevent clipping
    final padding = 20.0;
    final effectiveWidth = width - (padding * 2);
    final effectiveHeight = height - (padding * 2);
    final centerX = width / 2;
    final centerY = height / 2;

    // Calculate max radius to fit within bounds (use smaller dimension to ensure fit)
    final maxRadius = math.min(effectiveWidth, effectiveHeight) / 2 * 0.75 * scale; // Apply scale

    for (int i = 0; i < particleCount; i++) {
      final normalizedIndex = i / (particleCount - 1);
      final angle = normalizedIndex * 2 * math.pi;

      final intensityMultiplier = isRecording ? 1.2 : 0.8; // Adjusted intensity
      final baseRadius = isAnimating
          ? (amplitude * maxRadius * 0.6 * intensityMultiplier) +
                (math.sin((primaryPhase * 2) + (angle * 3)) * maxRadius * 0.25) // Proportional to container
          : maxRadius * 0.15; // Proportional static radius

      final x = centerX + (math.cos(angle + globalPhase) * baseRadius);
      final y = centerY + (math.sin(angle + globalPhase) * baseRadius * 0.8); // Slightly flattened to fit better

      final particleSize =
          (isAnimating
              ? 2.5 +
                    (math.sin((secondaryPhase * 3) + (angle * 5)) * 1.8) *
                        intensityMultiplier // Adjusted size
              : 1.2) *
          scale; // Apply scale to particle size

      // More vibrant, colorful particles with rainbow effect
      final hue = (normalizedIndex * 360 + globalPhase * 50) % 360;
      final vibrantColor = HSVColor.fromAHSV(1.0, hue, 0.8, 0.9).toColor();
      final blendedColor = Color.lerp(vibrantColor, primaryColor, 0.3)!;

      final paint = Paint()
        ..color = blendedColor.withValues(alpha: isAnimating ? (isRecording ? 0.9 : 0.7) : 0.3)
        ..style = PaintingStyle.fill;

      // Add glow effect for particles (only if they're well within bounds)
      if (isAnimating && x > padding && x < width - padding && y > padding && y < height - padding) {
        final glowPaint = Paint()
          ..color = blendedColor.withValues(alpha: 0.3)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, particleSize * 0.8);
        canvas.drawCircle(Offset(x, y), particleSize * 1.5, glowPaint);
      }

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  void _paintRadial(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height / 2);

    // Add padding to prevent clipping and use smaller dimension
    final padding = 25.0;
    final availableSize = math.min(width - padding * 2, height - padding * 2);
    final maxRadius = availableSize / 2 * 0.85 * scale; // Conservative sizing to prevent clipping, apply scale

    for (int ring = 0; ring < 7; ring++) {
      // More rings for complexity
      final baseRingRadius = (ring + 1) * maxRadius / 7;
      final points = 20 + (ring * 6); // Fewer points for smoother curves

      final path = Path();
      for (int i = 0; i < points; i++) {
        final angle = (i / points) * 2 * math.pi;
        final intensityMultiplier = isRecording ? 1.1 : 0.8; // Adjusted intensity
        final waveOffset = isAnimating
            ? math.sin((primaryPhase * 2) + (angle * 4) + (ring * 0.5)) *
                  amplitude *
                  (maxRadius * 0.15) * // Proportional wave size
                  intensityMultiplier
            : 0;

        final radius = baseRingRadius + waveOffset;
        final x = center.dx + (math.cos(angle + globalPhase * (0.2 + ring * 0.1)) * radius);
        final y = center.dy + (math.sin(angle + globalPhase * (0.2 + ring * 0.1)) * radius);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      // Create vibrant rainbow colors for each ring
      final hue = (ring * 60 + globalPhase * 30) % 360; // Rainbow progression
      final vibrantColor = HSVColor.fromAHSV(1.0, hue, 0.7, 0.85).toColor();
      final blendedColor = Color.lerp(vibrantColor, primaryColor, 0.4)!;

      final paint = Paint()
        ..color = blendedColor.withValues(
          alpha: isAnimating ? (isRecording ? 0.6 - (ring * 0.05) : 0.4 - (ring * 0.03)) : 0.15,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 + (ring * 0.4); // Slightly thinner strokes

      // Add glow effect for outer rings (with bounds check)
      if (isAnimating && ring < 3) {
        final glowPaint = Paint()
          ..color = blendedColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.5 + ring * 0.4) * 1.8
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3.0);
        canvas.drawPath(path, glowPaint);
      }

      canvas.drawPath(path, paint);
    }

    // Add central pulsing dot for focus (ensure it fits)
    if (isAnimating) {
      final centralRadius = math.min(amplitude * 6 + 3, maxRadius * 0.1); // Cap the size
      final centralPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.3)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, centralRadius);

      canvas.drawCircle(center, centralRadius * 1.5, glowPaint);
      canvas.drawCircle(center, centralRadius, centralPaint);
    }
  }

  void _paintHybrid(Canvas canvas, Size size) {
    // Combine multiple visualization modes with enhanced scaling

    // Background waveform (scaled down to fit)
    canvas.save();
    canvas.scale(0.85);
    canvas.translate(size.width * 0.075, size.height * 0.05);
    _paintWaveform(canvas, Size(size.width, size.height * 0.5));
    canvas.restore();

    // Spectral overlay at bottom (fits within bounds)
    final overlaySize = Size(size.width, size.height * 0.35);
    canvas.save();
    canvas.translate(0, size.height * 0.65);
    _paintSpectrum(canvas, overlaySize);
    canvas.restore();

    // Particle effects (properly contained)
    canvas.save();
    canvas.scale(0.75); // Ensure particles fit
    canvas.translate(size.width * 0.125, size.height * 0.125);
    _paintParticles(canvas, Size(size.width, size.height * 0.5));
    canvas.restore();

    // Add radial accent in center (smaller and centered)
    canvas.save();
    canvas.scale(0.25); // Smaller scale to prevent overlap
    canvas.translate(size.width * 1.5, size.height * 1.5); // Better centering
    _paintRadial(canvas, Size(size.width, size.height));
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
        oldDelegate.isRecording != isRecording ||
        oldDelegate.scale != scale; // Include scale in repaint check
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
