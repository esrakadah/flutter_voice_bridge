import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// 🎉 **WORKSHOP MODULE: Custom Rendering with Confetti**
///
/// **Learning Objectives:**
/// - Understand CustomPainter for GPU-accelerated rendering
/// - Implement physics-based particle systems
/// - Master AnimationController for smooth 60fps animations
/// - Practice custom paint compositing with blend modes

/// Confetti particle with physics properties
class ConfettiParticle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double rotation;
  double rotationSpeed;
  final Color color;
  final double size;
  final ConfettiShape shape;
  double alpha; // For fade out effect

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
    required this.shape,
    this.alpha = 1.0,
  });

  /// Update particle position with physics (gravity, air resistance)
  void update(double dt) {
    // Apply gravity
    velocityY += 980 * dt; // 980 pixels/s² (like real gravity)

    // Apply air resistance
    velocityX *= 0.99;
    velocityY *= 0.99;

    // Update position
    x += velocityX * dt;
    y += velocityY * dt;

    // Update rotation
    rotation += rotationSpeed * dt;

    // Fade out near the end
    if (y > 500) {
      alpha = max(0, alpha - dt * 0.5);
    }
  }

  bool get isDead => y > 1000 || alpha <= 0;
}

enum ConfettiShape {
  rectangle,
  circle,
  triangle,
  star,
}

/// CustomPainter for GPU-accelerated confetti rendering
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final Animation<double> animation;

  ConfettiPainter({
    required this.particles,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.alpha)
        ..style = PaintingStyle.fill;

      // Save canvas state for rotation
      canvas.save();

      // Translate to particle position
      canvas.translate(particle.x, particle.y);

      // Rotate around center
      canvas.rotate(particle.rotation);

      // Draw shape based on particle type
      switch (particle.shape) {
        case ConfettiShape.rectangle:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            paint,
          );
          break;

        case ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;

        case ConfettiShape.triangle:
          final path = Path()
            ..moveTo(0, -particle.size / 2)
            ..lineTo(particle.size / 2, particle.size / 2)
            ..lineTo(-particle.size / 2, particle.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case ConfettiShape.star:
          _drawStar(canvas, paint, particle.size);
          break;
      }

      // Restore canvas state
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = size / 4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * pi / 5) - pi / 2;
      final innerAngle = outerAngle + pi / 5;

      if (i == 0) {
        path.moveTo(
          outerRadius * cos(outerAngle),
          outerRadius * sin(outerAngle),
        );
      } else {
        path.lineTo(
          outerRadius * cos(outerAngle),
          outerRadius * sin(outerAngle),
        );
      }

      path.lineTo(
        innerRadius * cos(innerAngle),
        innerRadius * sin(innerAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}

/// Confetti overlay widget with animation controller
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final ConfettiController controller;

  const ConfettiOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<ConfettiParticle> _particles = [];
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    dev.log('ConfettiOverlay: initState');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationController.addListener(_updateParticles);

    widget.controller._setTrigger(_triggerConfetti);
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    dev.log('ConfettiOverlay: didUpdateWidget');
    // Re-register the trigger if the controller changed
    if (oldWidget.controller != widget.controller) {
      dev.log('ConfettiOverlay: Controller changed, re-registering trigger');
      widget.controller._setTrigger(_triggerConfetti);
    }
  }

  @override
  void dispose() {
    dev.log('ConfettiOverlay: dispose');
    _animationController.dispose();
    super.dispose();
  }

  void _triggerConfetti() {
    dev.log('ConfettiOverlay: _triggerConfetti called');
    if (!mounted) {
      dev.log('ConfettiOverlay: Triggered but not mounted, aborting');
      return;
    }

    if (_animationController.isAnimating) {
      dev.log('ConfettiOverlay: Animation running, resetting');
      _animationController.reset();
    }

    _particles.clear();
    _lastFrameTime = null;

    // Create particles
    final size = MediaQuery.of(context).size;
    final random = Random();

    // DevFest colors (Google Developer colors) + rainbow
    final colors = [
      const Color(0xFF4285F4), // Google Blue
      const Color(0xFF34A853), // Google Green
      const Color(0xFFFBBC04), // Google Yellow
      const Color(0xFFEA4335), // Google Red
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF8BC34A), // Light Green
    ];

    // Create 300 particles from multiple spawn points for extra celebration!
    for (int i = 0; i < 300; i++) {
      // Random spawn position (spread across top 30% of width for better spread)
      final spawnX = size.width * (0.35 + random.nextDouble() * 0.3);
      final spawnY = -50.0 - random.nextDouble() * 50; // Staggered start

      // Random initial velocity (upward and outward with more spread)
      final angle = -pi / 2 + (random.nextDouble() - 0.5) * pi / 2; // Wider spread
      final speed = 500 + random.nextDouble() * 400; // Faster, more energetic
      final velocityX = speed * cos(angle);
      final velocityY = speed * sin(angle);

      _particles.add(ConfettiParticle(
        x: spawnX,
        y: spawnY,
        velocityX: velocityX,
        velocityY: velocityY,
        rotation: random.nextDouble() * 2 * pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
        color: colors[random.nextInt(colors.length)],
        size: 8 + random.nextDouble() * 8,
        shape: ConfettiShape.values[random.nextInt(ConfettiShape.values.length)],
      ));
    }
    dev.log('ConfettiOverlay: Created ${_particles.length} particles');

    _animationController.forward();
  }

  void _updateParticles() {
    final now = DateTime.now();
    final dt = _lastFrameTime == null
        ? 0.016 // First frame, assume 60fps
        : now.difference(_lastFrameTime!).inMilliseconds / 1000.0;
    _lastFrameTime = now;

    if (!mounted) return;

    setState(() {
      // Update all particles
      for (final particle in _particles) {
        particle.update(dt);
      }

      // Remove dead particles
      _particles.removeWhere((p) => p.isDead);

      // Stop animation if all particles are gone
      if (_particles.isEmpty && _animationController.isAnimating) {
        dev.log('ConfettiOverlay: All particles are dead, stopping animation');
        _animationController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ConfettiPainter(
                  particles: _particles,
                  animation: _animationController,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Controller to trigger confetti animation
class ConfettiController {
  VoidCallback? _trigger;

  void _setTrigger(VoidCallback trigger) {
    dev.log('ConfettiController: Setting trigger');
    _trigger = trigger;
  }

  void celebrate() {
    dev.log('ConfettiController: celebrate() called');
    _trigger?.call();
  }
}

/// Confetti button widget
class ConfettiButton extends StatefulWidget {
  final ConfettiController controller;
  final double size;

  const ConfettiButton({
    super.key,
    required this.controller,
    this.size = 36,
  });

  @override
  State<ConfettiButton> createState() => _ConfettiButtonState();
}

class _ConfettiButtonState extends State<ConfettiButton>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onPressed() {
    dev.log('ConfettiButton: _onPressed() called');
    // Haptic feedback for tactile response
    HapticFeedback.mediumImpact();

    // Trigger confetti
    widget.controller.celebrate();

    // Bounce animation
    _bounceController.forward().then((_) => _bounceController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFBBC04), // Google Yellow
                  Color(0xFFEA4335), // Google Red
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBC04).withValues(alpha: _glowAnimation.value),
                  blurRadius: 12 + (_glowAnimation.value * 8),
                  spreadRadius: 2 + (_glowAnimation.value * 2),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onPressed,
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.celebration,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
