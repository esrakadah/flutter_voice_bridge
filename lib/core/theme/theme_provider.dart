import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Custom theme modes
enum AppThemeMode {
  light,
  dark,
  system,
  devfest, // DevFest themed mode
}

// Theme management for the app with smooth transitions
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(themeMode: AppThemeMode.devfest));

  void toggleTheme() {
    if (state.themeMode == AppThemeMode.light) {
      emit(state.copyWith(themeMode: AppThemeMode.dark));
    } else if (state.themeMode == AppThemeMode.dark) {
      emit(state.copyWith(themeMode: AppThemeMode.devfest));
    } else if (state.themeMode == AppThemeMode.devfest) {
      emit(state.copyWith(themeMode: AppThemeMode.light));
    } else {
      // If system mode, switch to light first
      emit(state.copyWith(themeMode: AppThemeMode.light));
    }
  }

  void setThemeMode(AppThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  bool get isDarkMode => state.themeMode == AppThemeMode.dark;
  bool get isLightMode => state.themeMode == AppThemeMode.light;
  bool get isSystemMode => state.themeMode == AppThemeMode.system;
  bool get isDevFestMode => state.themeMode == AppThemeMode.devfest;
}

class ThemeState extends Equatable {
  final AppThemeMode themeMode;

  const ThemeState({required this.themeMode});

  ThemeState copyWith({AppThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }

  @override
  List<Object> get props => [themeMode];
}

// Animated theme toggle button widget
class ThemeToggleButton extends StatefulWidget {
  final ThemeCubit themeCubit;
  final Color? lightColor;
  final Color? darkColor;
  final double size;

  const ThemeToggleButton({super.key, required this.themeCubit, this.lightColor, this.darkColor, this.size = 40});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    _scaleController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _rotationController, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _rotationController.forward().then((_) {
      _rotationController.reset();
    });
    widget.themeCubit.toggleTheme();
  }

  void _handleTapDown() {
    _scaleController.forward();
  }

  void _handleTapUp() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      bloc: widget.themeCubit,
      builder: (context, state) {
        return AnimatedBuilder(
          animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: GestureDetector(
                  onTapDown: (_) => _handleTapDown(),
                  onTapUp: (_) => _handleTapUp(),
                  onTapCancel: () => _handleTapUp(),
                  onTap: _handleTap,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(widget.size / 2),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _getThemeIcon(state.themeMode),
                        key: ValueKey(state.themeMode),
                        size: widget.size * 0.5,
                        color: _getThemeIconColor(context, state.themeMode),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
      case AppThemeMode.system:
        return Icons.auto_mode_rounded;
      case AppThemeMode.devfest:
        return Icons.celebration_rounded; // DevFest icon
    }
  }

  Color _getThemeIconColor(BuildContext context, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return widget.lightColor ?? Theme.of(context).colorScheme.primary;
      case AppThemeMode.dark:
        return widget.darkColor ?? Theme.of(context).colorScheme.secondary;
      case AppThemeMode.devfest:
        return const Color(0xFF4285F4); // Google Blue
      case AppThemeMode.system:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);
    }
  }
}
