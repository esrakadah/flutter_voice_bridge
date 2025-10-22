import 'package:shared_preferences/shared_preferences.dart';

enum AnimationMode { waveform, spectrum, particles, radial }

/// Service for managing animation preferences persistence
class AnimationPreferences {
  static const String _animationEnabledKey = 'animation_enabled';
  static const String _animationSpeedKey = 'animation_speed';
  static const String _animationModeKey = 'animation_mode';
  static const String _animationScaleKey = 'animation_scale';

  static const double _defaultSpeed = 1.0;
  static const bool _defaultEnabled = true;

  /// Get whether animations are enabled
  static Future<bool> getAnimationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_animationEnabledKey) ?? _defaultEnabled;
  }

  /// Set whether animations are enabled
  static Future<void> setAnimationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationEnabledKey, enabled);
  }

  /// Get animation speed multiplier
  static Future<double> getAnimationSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_animationSpeedKey) ?? _defaultSpeed;
  }

  /// Set animation speed multiplier
  static Future<void> setAnimationSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_animationSpeedKey, speed);
  }

  /// Get animation mode
  static Future<AnimationMode> getAnimationMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_animationModeKey) ?? 0;
    return AnimationMode.values[modeIndex.clamp(0, AnimationMode.values.length - 1)];
  }

  /// Set animation mode
  static Future<void> setAnimationMode(AnimationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_animationModeKey, mode.index);
  }

  /// Get animation scale
  static Future<double> getAnimationScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_animationScaleKey) ?? 1.0;
  }

  /// Set animation scale
  static Future<void> setAnimationScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_animationScaleKey, scale);
  }

  /// Get all animation preferences at once
  static Future<AnimationSettings> getAnimationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool(_animationEnabledKey) ?? true;
    final speed = prefs.getDouble(_animationSpeedKey) ?? 1.0;
    final modeIndex = prefs.getInt(_animationModeKey) ?? 0;
    final scale = prefs.getDouble(_animationScaleKey) ?? 1.0;

    final mode = AnimationMode.values[modeIndex.clamp(0, AnimationMode.values.length - 1)];

    return AnimationSettings(enabled: enabled, speed: speed, mode: mode, scale: scale);
  }

  /// Save all animation preferences at once
  static Future<void> setAnimationSettings(AnimationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationEnabledKey, settings.enabled);
    await prefs.setDouble(_animationSpeedKey, settings.speed);
    await prefs.setInt(_animationModeKey, settings.mode.index);
    await prefs.setDouble(_animationScaleKey, settings.scale);
  }
}

/// Data class for animation settings
class AnimationSettings {
  final bool enabled;
  final double speed;
  final AnimationMode mode;
  final double scale;

  const AnimationSettings({
    this.enabled = true,
    this.speed = 1.0,
    this.mode = AnimationMode.waveform,
    this.scale = 1.0,
  });

  AnimationSettings copyWith({bool? enabled, double? speed, AnimationMode? mode, double? scale}) {
    return AnimationSettings(
      enabled: enabled ?? this.enabled,
      speed: speed ?? this.speed,
      mode: mode ?? this.mode,
      scale: scale ?? this.scale,
    );
  }

  @override
  String toString() {
    return 'AnimationSettings(enabled: $enabled, speed: $speed, mode: $mode, scale: $scale)';
  }
}
