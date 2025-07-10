import 'package:flutter/material.dart';
import 'ui/views/home_view.dart';
// import 'package:google_fonts/google_fonts.dart'; // Temporarily disabled due to network restrictions

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Voice Bridge',
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppTheme {
  /// Generates a dark theme for the application.
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: const Color(0xFFBB86FC),
      textTheme: ThemeData.dark().textTheme.copyWith(
        displayLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyLarge: const TextStyle(color: Colors.white70),
      ),
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ).copyWith(secondary: const Color(0xFF03DAC6), surface: const Color(0xFF121212), onSurface: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        buttonColor: const Color(0xFFBB86FC),
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF03DAC6)),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF03DAC6),
        inactiveTrackColor: const Color(0x4DFFFFFF), // white with 30% opacity
        thumbColor: const Color(0xFF03DAC6),
        overlayColor: const Color(0x2903DAC6),
        valueIndicatorTextStyle: const TextStyle(color: Colors.black),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      listTileTheme: ListTileThemeData(
        tileColor: const Color(0xFF1E1E1E),
        textColor: Colors.white,
        iconColor: const Color(0xFF03DAC6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF333333),
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: const Color(0xFFBB86FC),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1AFFFFFF), // white with 10% opacity
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF03DAC6),
        linearTrackColor: Color(0x40FFFFFF),
      ),
      dividerColor: const Color(0x33FFFFFF), // white with 20% opacity
    );
  }

  /// Generates a light theme for the application.
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      primaryColor: const Color(0xFF6200EE),
      textTheme: ThemeData.light().textTheme.copyWith(
        displayLarge: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        bodyLarge: const TextStyle(color: Colors.black87),
      ),
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
      ).copyWith(secondary: const Color(0xFF03DAC6), surface: const Color(0xFFFFFFFF), onSurface: Colors.black),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 1,
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        buttonColor: const Color(0xFF6200EE),
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFF03DAC6)),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF6200EE),
        inactiveTrackColor: const Color(0x4D000000), // black with 30% opacity
        thumbColor: const Color(0xFF6200EE),
        overlayColor: const Color(0x296200EE),
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      listTileTheme: ListTileThemeData(
        tileColor: const Color(0xFFFFFFFF),
        textColor: Colors.black,
        iconColor: const Color(0xFF6200EE),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF333333),
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: const Color(0xFFBB86FC),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0D000000), // black with 5% opacity
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: Colors.black87),
        hintStyle: const TextStyle(color: Colors.black38),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF6200EE),
        linearTrackColor: Color(0x30000000),
      ),
      dividerColor: const Color(0x1F000000), // black with 12% opacity
    );
  }
}
