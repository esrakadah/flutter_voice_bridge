import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'di.dart';

/// 🎓 **WORKSHOP MODULE 0: Application Bootstrap**
///
/// **Learning Objectives:**
/// - Understand Flutter app initialization sequence
/// - Learn async initialization patterns
/// - See dependency injection setup timing
/// - Practice proper widget binding initialization
///
/// **Key Concepts:**
/// - WidgetsFlutterBinding: Connects Flutter to platform
/// - Async Main: Handling initialization before app starts
/// - Dependency Setup: Services ready before UI renders

/// 🚀 APPLICATION ENTRY POINT
/// This is where the Flutter app begins execution
/// The async main pattern allows setup before UI rendering starts
void main() async {
  // 🔧 FLUTTER BINDING INITIALIZATION
  // This ensures Flutter is ready to interact with the platform
  // Must be called before any platform channel operations
  // Required for: Platform channels, plugins, async operations in main()
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 ORIENTATION SETUP
  // Allow both portrait and landscape orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 💉 DEPENDENCY INJECTION SETUP
  // Initialize all services before starting the UI
  // This ensures all dependencies are ready when widgets need them
  // Services include: Audio, Transcription, File System, Theme
  await DependencyInjection.init();

  // 🎯 HELPFUL DEBUG INFO
  // In development, show what services are available
  // Remove this in production builds
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    DependencyInjection.printRegisteredServices();
  }

  // 🎨 START THE APPLICATION
  // App widget is the root of the widget tree
  // All dependencies are now ready for injection
  runApp(const App());
}

/// 🎓 **LEARNING NOTES: Initialization Order**
///
/// **Critical Sequence:**
/// 1. WidgetsFlutterBinding.ensureInitialized() - Platform ready
/// 2. DependencyInjection.init() - Services ready
/// 3. runApp(App()) - UI starts rendering
///
/// **Why Async Main?**
/// - Allows setup operations before UI renders
/// - Prevents "service not found" errors
/// - Ensures clean app startup state
///
/// **Common Mistakes:**
/// ❌ Calling platform channels before ensureInitialized()
/// ❌ Starting UI before dependency injection
/// ❌ Forgetting to await async initialization
