import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
import 'confetti_overlay.dart';

/// DevFest Berlin 2025 themed app bar
/// Features Google Developer colors and DevFest branding
class DevFestAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ThemeCubit themeCubit;
  final ConfettiController confettiController;
  final String eventName;
  final String location;
  final String year;
  final String? flag;

  const DevFestAppBar({
    super.key,
    required this.themeCubit,
    required this.confettiController,
    this.eventName = 'DevFest',
    this.location = 'Berlin',
    this.year = '2025',
    this.flag = '🇩🇪',
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A73E8).withValues(alpha: 0.15), // Google Blue
                    const Color(0xFF0F9D58).withValues(alpha: 0.10), // Google Green
                  ]
                : [
                    const Color(0xFF4285F4).withValues(alpha: 0.12), // Google Blue
                    const Color(0xFF34A853).withValues(alpha: 0.08), // Google Green
                  ],
          ),
        ),
      ),
      title: Row(
        children: [
          // DevFest Logo
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Image.asset(
              'assets/devfest-berlin.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load
                return _buildFallbackLogo(context);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Event details with flag
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$eventName $location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF4285F4) // Google Blue
                        : const Color(0xFF1A73E8), // Darker Google Blue
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  year,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFFBBC04) // Google Yellow
                        : const Color(0xFFF9AB00), // Darker Google Yellow
                  ),
                ),
                if (flag != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    flag!,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Google Developer colored dot indicator
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4285F4), // Blue
                const Color(0xFF34A853), // Green
                const Color(0xFFFBBC04), // Yellow
                const Color(0xFFEA4335), // Red
              ],
            ),
          ),
        ),

        // Confetti button
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ConfettiButton(
            controller: confettiController,
            size: 36,
          ),
        ),

        // Theme toggle button
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: ThemeToggleButton(
            themeCubit: themeCubit,
            size: 36,
            lightColor: const Color(0xFF4285F4), // Google Blue
            darkColor: const Color(0xFF8AB4F8), // Lighter Google Blue
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackLogo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4285F4), // Google Blue
            const Color(0xFF34A853), // Google Green
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'DevFest',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// DevFest-inspired color scheme for the app
class DevFestColors {
  // Google Developer colors
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleYellow = Color(0xFFFBBC04);
  static const Color googleGreen = Color(0xFF34A853);

  // Dark mode variants
  static const Color googleBlueDark = Color(0xFF8AB4F8);
  static const Color googleRedDark = Color(0xFFF28B82);
  static const Color googleYellowDark = Color(0xFFFDD663);
  static const Color googleGreenDark = Color(0xFF81C995);

  /// Get a DevFest-themed color scheme for light mode
  static ColorScheme getLightScheme() {
    return ColorScheme.light(
      primary: googleBlue,
      onPrimary: Colors.white,
      secondary: googleGreen,
      onSecondary: Colors.white,
      tertiary: googleYellow,
      onTertiary: Colors.black87,
      error: googleRed,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
    );
  }

  /// Get a DevFest-themed color scheme for dark mode
  static ColorScheme getDarkScheme() {
    return ColorScheme.dark(
      primary: googleBlueDark,
      onPrimary: Colors.black,
      secondary: googleGreenDark,
      onSecondary: Colors.black,
      tertiary: googleYellowDark,
      onTertiary: Colors.black,
      error: googleRedDark,
      onError: Colors.black,
      surface: const Color(0xFF1F1F1F),
      onSurface: Colors.white,
    );
  }
}
