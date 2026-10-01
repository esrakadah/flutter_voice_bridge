import 'dart:developer' as developer;
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'core/audio/audio_service.dart';
import 'core/audio/platform_audio_service.dart';
import 'core/transcription/transcription_service.dart';
import 'core/theme/theme_provider.dart';
import 'data/services/voice_memo_service.dart';
import 'ui/views/home/home_cubit.dart';
import 'gemma/data/gemma_service.dart';
import 'gemma/ui/gemma_cubit.dart';

/// 🎓 **WORKSHOP MODULE 1.3: Dependency Injection Mastery**
///
/// **Learning Objectives:**
/// - Master service locator pattern with GetIt
/// - Understand different registration types (Singleton vs Factory)
/// - Learn platform-conditional service registration
/// - Practice clean dependency management
///
/// **Key Patterns Demonstrated:**
/// - Service Locator: GetIt as global service registry
/// - Factory Pattern: New instances for stateful components
/// - Singleton Pattern: Shared instances for stateless services
/// - Platform Detection: Conditional service registration
///
/// **Dependency Injection Benefits:**
/// - ✅ Testability: Easy to swap implementations
/// - ✅ Flexibility: Runtime service selection
/// - ✅ Maintainability: Clear dependency declarations

// 🏭 SERVICE LOCATOR PATTERN
// GetIt acts as a global registry for all application dependencies
// This pattern provides a single place to configure all services
final GetIt getIt = GetIt.instance;

class DependencyInjection {
  /// 🔧 DEPENDENCY SETUP METHOD
  /// This method demonstrates different registration strategies:
  /// - LazySingleton: Created once when first accessed, reused afterward
  /// - Factory: New instance created each time it's requested
  /// - Platform-conditional: Different implementations based on runtime platform
  static Future<void> init() async {
    // 🎤 AUDIO SERVICE REGISTRATION
    // Registered as LazySingleton because:
    // ✅ Audio hardware should have single controller
    // ✅ Platform channels are stateless and reusable
    // ✅ No need for multiple instances
    getIt.registerLazySingleton<AudioService>(() => PlatformAudioService());

    // 💾 DATA SERVICE REGISTRATION
    // File operations are stateless, so singleton is appropriate
    getIt.registerLazySingleton<VoiceMemoService>(() => VoiceMemoServiceImpl());

    // 🧠 GEMMA AI SERVICE
    // Manages the AI model and chat session. Singleton to keep the model loaded.
    getIt.registerLazySingleton<GemmaService>(() => GemmaService());

    // 🤖 TRANSCRIPTION SERVICE - PLATFORM CONDITIONAL REGISTRATION
    // This demonstrates intelligent service selection based on platform capabilities
    // Shows how to handle platform-specific features gracefully
    // 🤖 TRANSCRIPTION: real whisper.cpp on macOS; placeholder text on iOS and Android, where the native library
    // is not built. Owned by the container: disposed in [dispose], never by a cubit.
    getIt.registerLazySingleton<TranscriptionService>(
      () => Platform.isMacOS ? WhisperTranscriptionService() : PlaceholderTranscriptionService(),
      dispose: (service) => service.dispose(),
    );

    // 🎨 THEME MANAGEMENT
    // Singleton because theme state should be shared across entire app
    // Theme changes affect global UI state
    getIt.registerLazySingleton<ThemeCubit>(ThemeCubit.new, dispose: (cubit) => cubit.close());

    // 🏠 UI STATE MANAGEMENT - FACTORY REGISTRATION
    // HomeCubit is registered as Factory because:
    // ✅ Each screen instance should have its own state
    // ✅ Prevents state leakage between navigation
    // ✅ Allows proper disposal of resources
    getIt.registerFactory<HomeCubit>(
      () => HomeCubit(
        // 💉 CONSTRUCTOR INJECTION
        // All dependencies are resolved from the service locator
        // This creates a dependency graph that's resolved at runtime
        audioService: getIt<AudioService>(), // 🎤 Shared audio service
        voiceMemoService: getIt<VoiceMemoService>(), // 💾 Shared data service
        transcriptionService: getIt<TranscriptionService>(), // 🤖 AI service
      ),
    );

    // 💬 GEMMA CHAT CUBIT
    // Manages the chat UI state. LazySingleton to preserve chat state across navigation.
    // This prevents re-initialization when navigating back to the chat screen.
    getIt.registerLazySingleton<GemmaCubit>(
      () => GemmaCubit(gemmaService: getIt<GemmaService>())..initialize(),
      dispose: (cubit) => cubit.close(),
    );
  }

  /// 🧹 CLEANUP METHOD
  /// Important for testing - allows resetting the service locator
  /// In production apps, you might also use this during app restart
  static Future<void> reset() => getIt.reset();

  /// 🔍 DEBUGGING HELPER
  /// Useful during development to see what services are registered
  static void printRegisteredServices() {
    developer.log('📋 Registered Services:', name: 'DI');
    developer.log('  🎤 AudioService: ${getIt.isRegistered<AudioService>()}', name: 'DI');
    developer.log('  🤖 TranscriptionService: ${getIt.isRegistered<TranscriptionService>()}', name: 'DI');
    developer.log('  💾 VoiceMemoService: ${getIt.isRegistered<VoiceMemoService>()}', name: 'DI');
    developer.log('  🎨 ThemeCubit: ${getIt.isRegistered<ThemeCubit>()}', name: 'DI');
  }
}

/// 🎓 **LEARNING EXERCISE: Service Registration Types**
///
/// **Question**: Why is HomeCubit registered as Factory while AudioService is Singleton?
///
/// **Answer**:
/// - AudioService: Hardware interface, stateless, should be shared
/// - HomeCubit: Contains UI state, should be unique per screen instance
///
/// **Try This**: What would happen if we registered HomeCubit as Singleton?
/// **Result**: State would be shared across all HomeView instances, causing UI bugs
