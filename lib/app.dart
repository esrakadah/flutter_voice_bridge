import 'package:flutter/material.dart';
import 'ui/views/home_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Bridge AI',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    const seedColor = Color(0xFF6366F1); // Modern indigo
    const backgroundColor = Color(0xFFFAFAFC);
    const surfaceColor = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
            background: backgroundColor,
            surface: surfaceColor,
          ).copyWith(
            primary: seedColor,
            secondary: const Color(0xFF8B5CF6), // Purple accent
            tertiary: const Color(0xFF06B6D4), // Cyan accent
            error: const Color(0xFFEF4444), // Modern red
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF1F2937), // Dark gray text
            onBackground: const Color(0xFF1F2937),
            outline: const Color(0xFFE5E7EB), // Light border
          ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: Color(0xFF111827),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
          color: Color(0xFF111827),
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: Color(0xFF111827),
        ),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF374151), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF6B7280), height: 1.4),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF9CA3AF), height: 1.3),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF111827),
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: Color(0xFF6B7280)),
    );
  }

  ThemeData _buildDarkTheme() {
    const seedColor = Color(0xFF818CF8); // Lighter indigo for dark mode
    const backgroundColor = Color(0xFF0F172A);
    const surfaceColor = Color(0xFF1E293B);

    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
            background: backgroundColor,
            surface: surfaceColor,
          ).copyWith(
            primary: seedColor,
            secondary: const Color(0xFFA78BFA), // Lighter purple for dark mode
            tertiary: const Color(0xFF22D3EE), // Lighter cyan for dark mode
            error: const Color(0xFFF87171), // Lighter red for dark mode
            onPrimary: const Color(0xFF111827),
            onSecondary: const Color(0xFF111827),
            onSurface: const Color(0xFFF8FAFC),
            onBackground: const Color(0xFFF8FAFC),
            outline: const Color(0xFF374151),
          ),

      // Typography for dark mode
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: Color(0xFFF8FAFC),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
          color: Color(0xFFF8FAFC),
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: Color(0xFFF8FAFC),
        ),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFE2E8F0)),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFFE2E8F0), height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFFCBD5E1), height: 1.4),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8), height: 1.3),
      ),

      // Card theme for dark mode
      cardTheme: CardThemeData(
        elevation: 4,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // App bar theme for dark mode
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF8FAFC),
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
      ),

      // Floating action button theme for dark mode
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Elevated button theme for dark mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Icon theme for dark mode
      iconTheme: const IconThemeData(color: Color(0xFFCBD5E1)),
    );
  }
}
