import 'package:get_it/get_it.dart';
import 'core/audio/audio_service.dart';
import 'core/audio/platform_audio_service.dart';
import 'core/transcription/transcription_service.dart';
import 'data/services/voice_memo_service.dart';
import 'ui/views/home/home_cubit.dart';

// Dependency Injection Setup using GetIt
// This registers all services and cubits for the application

final GetIt getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> init() async {
    // Register core services
    getIt.registerLazySingleton<AudioService>(() => PlatformAudioService());

    // Register data services
    getIt.registerLazySingleton<VoiceMemoService>(() => VoiceMemoServiceImpl());

    // Register transcription service (using Mock for development)
    // For production, switch to WhisperTranscriptionService() when native library is available
    getIt.registerLazySingleton<TranscriptionService>(() => MockTranscriptionService());

    // Register Cubits
    getIt.registerFactory<HomeCubit>(
      () => HomeCubit(
        audioService: getIt<AudioService>(),
        voiceMemoService: getIt<VoiceMemoService>(),
        transcriptionService: getIt<TranscriptionService>(),
      ),
    );
  }
}
