import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../components/audio_visualizer.dart';
import '../../core/preferences/animation_preferences.dart';

class AnimationFullscreenView extends StatefulWidget {
  final AudioVisualizationMode initialMode;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  const AnimationFullscreenView({
    super.key,
    this.initialMode = AudioVisualizationMode.waveform,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  State<AnimationFullscreenView> createState() => _AnimationFullscreenViewState();
}

class _AnimationFullscreenViewState extends State<AnimationFullscreenView> {
  late AudioVisualizationMode _currentMode;
  bool _isAnimationPlaying = true;
  double _animationSpeed = 1.0;
  double _animationScale = 1.0; // Add scale state
  int _currentSpeedIndex = 1;

  static const List<double> _speedPresets = [0.5, 1.0, 1.5, 2.0];
  static const List<String> _speedLabels = ['0.5x', '1x', '1.5x', '2x'];
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;
  static const double _scaleStep = 0.25;

  static const List<AudioVisualizationMode> _modes = [
    AudioVisualizationMode.waveform,
    AudioVisualizationMode.spectrum,
    AudioVisualizationMode.particles,
    AudioVisualizationMode.radial,
  ];

  static const List<String> _modeLabels = ['Waveform', 'Spectrum', 'Particles', 'Radial'];

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _loadPreferences();

    // Make status bar transparent for fullscreen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when leaving fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _loadPreferences() async {
    try {
      final settings = await AnimationPreferences.getAnimationSettings();
      setState(() {
        _isAnimationPlaying = settings.enabled;
        _animationSpeed = settings.speed;
        _animationScale = settings.scale; // Load scale

        for (int i = 0; i < _speedPresets.length; i++) {
          if (_speedPresets[i] == settings.speed) {
            _currentSpeedIndex = i;
            break;
          }
        }
      });
    } catch (e) {
      // Use defaults if loading fails
    }
  }

  void _toggleAnimation() {
    setState(() {
      _isAnimationPlaying = !_isAnimationPlaying;
    });
    AnimationPreferences.setAnimationEnabled(_isAnimationPlaying);
  }

  void _changeSpeed() {
    setState(() {
      _currentSpeedIndex = (_currentSpeedIndex + 1) % _speedPresets.length;
      _animationSpeed = _speedPresets[_currentSpeedIndex];
    });
    AnimationPreferences.setAnimationSpeed(_animationSpeed);
  }

  void _changeMode() {
    setState(() {
      final currentIndex = _modes.indexOf(_currentMode);
      final nextIndex = (currentIndex + 1) % _modes.length;
      _currentMode = _modes[nextIndex];
    });
  }

  void _increaseScale() {
    if (_animationScale < _maxScale) {
      setState(() {
        _animationScale = math.min(_animationScale + _scaleStep, _maxScale);
      });
      AnimationPreferences.setAnimationScale(_animationScale);
    }
  }

  void _decreaseScale() {
    if (_animationScale > _minScale) {
      setState(() {
        _animationScale = math.max(_animationScale - _scaleStep, _minScale);
      });
      AnimationPreferences.setAnimationScale(_animationScale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen animation
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: AdvancedAudioVisualizer(
                isRecording: false, // Always false in fullscreen view
                height: double.infinity,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
                tertiaryColor: widget.tertiaryColor,
                mode: _currentMode,
                showControls: false, // We'll show our own controls
                externalAnimationState: _isAnimationPlaying,
                externalAnimationSpeed: _animationSpeed,
                externalAnimationScale: _animationScale, // Pass scale
              ),
            ),
          ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                _buildControlButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                  isPrimary: true,
                ),

                // Mode info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Text(
                    _modeLabels[_modes.indexOf(_currentMode)],
                    style: TextStyle(color: widget.primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Scale controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildControlButton(
                          icon: Icons.remove_rounded,
                          onTap: _animationScale > _minScale ? _decreaseScale : null,
                          tooltip: 'Decrease Size',
                          size: 40,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${(_animationScale * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildControlButton(
                          icon: Icons.add_rounded,
                          onTap: _animationScale < _maxScale ? _increaseScale : null,
                          tooltip: 'Increase Size',
                          size: 40,
                        ),
                      ],
                    ),

                    const SizedBox(width: 16), // Add spacing between groups

                    // Play/Pause
                    _buildControlButton(
                      icon: _isAnimationPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      onTap: _toggleAnimation,
                      tooltip: _isAnimationPlaying ? 'Pause' : 'Play',
                      isPrimary: true,
                      size: 56,
                    ),

                    const SizedBox(width: 16), // Add spacing between groups

                    // Speed control
                    _buildSpeedButton(),

                    const SizedBox(width: 16), // Add spacing between groups

                    // Mode switcher
                    _buildModeButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap, // Make nullable
    required String tooltip,
    bool isPrimary = false,
    double size = 48,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              color: onTap == null
                  ? Colors.grey.withValues(alpha: 0.2) // Disabled style
                  : isPrimary
                  ? widget.primaryColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: onTap == null
                    ? Colors.grey.withValues(alpha: 0.3) // Disabled style
                    : isPrimary
                    ? widget.primaryColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: size * 0.5,
              color: onTap == null
                  ? Colors
                        .grey // Disabled style
                  : isPrimary
                  ? widget.primaryColor
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton() {
    return Tooltip(
      message: 'Speed: ${_speedLabels[_currentSpeedIndex]}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _changeSpeed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: widget.secondaryColor.withValues(alpha: 0.3),
              border: Border.all(color: widget.secondaryColor.withValues(alpha: 0.5), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed_rounded, size: 20, color: widget.secondaryColor),
                const SizedBox(width: 8),
                Text(
                  _speedLabels[_currentSpeedIndex],
                  style: TextStyle(color: widget.secondaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton() {
    return Tooltip(
      message: 'Switch Mode',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _changeMode,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: widget.tertiaryColor.withValues(alpha: 0.3),
              border: Border.all(color: widget.tertiaryColor.withValues(alpha: 0.5), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 20, color: widget.tertiaryColor),
                const SizedBox(width: 8),
                Text(
                  _modeLabels[_modes.indexOf(_currentMode)],
                  style: TextStyle(color: widget.tertiaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
