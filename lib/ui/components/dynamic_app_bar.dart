import 'package:flutter/material.dart';
import '../../core/branding/branding_model.dart';
import '../../core/theme/theme_provider.dart';
import 'confetti_overlay.dart';

/// Dynamic app bar that adapts to branding configuration
class DynamicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ThemeCubit themeCubit;
  final ConfettiController confettiController;
  final BrandingConfig branding;
  final VoidCallback onSettingsPressed;

  const DynamicAppBar({
    super.key,
    required this.themeCubit,
    required this.confettiController,
    required this.branding,
    required this.onSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flag = branding.flag;

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
          // Event details with flag
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    branding.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF4285F4) // Google Blue
                          : const Color(0xFF1A73E8), // Darker Google Blue
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (branding.year.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    branding.year,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFFBBC04) // Google Yellow
                          : const Color(0xFFF9AB00), // Darker Google Yellow
                    ),
                  ),
                ],
                if (flag != null) ...[
                  const SizedBox(width: 6),
                  Text(flag, style: const TextStyle(fontSize: 18)),
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
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ConfettiButton(controller: confettiController, size: 36),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ThemeToggleButton(
            themeCubit: themeCubit,
            size: 36,
            lightColor: const Color(0xFF4285F4), // Google Blue
            darkColor: const Color(0xFF8AB4F8), // Lighter Google Blue
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(icon: const Icon(Icons.settings), onPressed: onSettingsPressed, tooltip: 'Settings'),
        ),
      ],
    );
  }
}
