import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;

// Native Whisper.cpp function signatures
typedef WhisperInitNative = Pointer<Void> Function(Pointer<Utf8> modelPath);
typedef WhisperInit = Pointer<Void> Function(Pointer<Utf8> modelPath);

typedef WhisperTranscribeNative = Pointer<Utf8> Function(Pointer<Void> ctx, Pointer<Utf8> audioPath);
typedef WhisperTranscribe = Pointer<Utf8> Function(Pointer<Void> ctx, Pointer<Utf8> audioPath);

typedef WhisperFreeNative = Void Function(Pointer<Void> ctx);
typedef WhisperFree = void Function(Pointer<Void> ctx);

typedef WhisperFreeStringNative = Void Function(Pointer<Utf8> str);
typedef WhisperFreeString = void Function(Pointer<Utf8> str);

/// FFI Service for Whisper.cpp integration
/// Handles native library loading, initialization, and transcription
class WhisperFFIService {
  static const String _logName = 'VoiceBridge.WhisperFFI';

  late final DynamicLibrary _whisperLib;
  late final WhisperInit _whisperInit;
  late final WhisperTranscribe _whisperTranscribe;
  late final WhisperFree _whisperFree;
  late final WhisperFreeString _whisperFreeString;

  Pointer<Void>? _whisperContext;
  bool _isInitialized = false;

  /// Initialize the Whisper FFI service and load the native library
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('✅ [WhisperFFI] Already initialized', name: _logName);
      return;
    }

    try {
      developer.log('🔧 [WhisperFFI] Initializing Whisper FFI service...', name: _logName);

      // Load the dynamic library
      _loadLibrary();

      // Bind native functions
      _bindFunctions();

      developer.log('✅ [WhisperFFI] Service initialized successfully', name: _logName);
      _isInitialized = true;
    } catch (e) {
      developer.log('❌ [WhisperFFI] Initialization failed: $e', name: _logName, error: e);
      rethrow;
    }
  }

  /// Initialize Whisper context with model file
  Future<void> initializeModel(String modelPath) async {
    if (!_isInitialized) {
      throw StateError('WhisperFFI service not initialized. Call initialize() first.');
    }

    if (_whisperContext != null) {
      developer.log('⚠️ [WhisperFFI] Model already loaded, cleaning up first', name: _logName);
      await dispose();
    }

    try {
      developer.log('🤖 [WhisperFFI] Loading Whisper model: $modelPath', name: _logName);

      // Check if model file exists
      final modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        throw FileSystemException('Whisper model file not found', modelPath);
      }

      // Convert path to native string
      final modelPathPtr = modelPath.toNativeUtf8();

      try {
        // Initialize Whisper context
        _whisperContext = _whisperInit(modelPathPtr);

        if (_whisperContext == nullptr) {
          throw Exception('Failed to initialize Whisper context');
        }

        developer.log('✅ [WhisperFFI] Model loaded successfully', name: _logName);
      } finally {
        // Free the native string
        malloc.free(modelPathPtr);
      }
    } catch (e) {
      developer.log('❌ [WhisperFFI] Model initialization failed: $e', name: _logName, error: e);
      rethrow;
    }
  }

  /// Transcribe audio file to text
  Future<String> transcribeAudio(String audioFilePath) async {
    if (_whisperContext == null) {
      throw StateError('Whisper model not loaded. Call initializeModel() first.');
    }

    try {
      developer.log('🎵 [WhisperFFI] Transcribing audio: $audioFilePath', name: _logName);

      // Check if audio file exists
      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        throw FileSystemException('Audio file not found', audioFilePath);
      }

      // Convert path to native string
      final audioPathPtr = audioFilePath.toNativeUtf8();
      Pointer<Utf8> resultPtr = nullptr;

      try {
        // Call native transcription function
        resultPtr = _whisperTranscribe(_whisperContext!, audioPathPtr);

        if (resultPtr == nullptr) {
          throw Exception('Transcription failed - null result');
        }

        // Convert result to Dart string
        final transcription = resultPtr.toDartString();

        developer.log('✅ [WhisperFFI] Transcription completed: ${transcription.length} characters', name: _logName);
        developer.log(
          '📝 [WhisperFFI] Result: ${transcription.substring(0, transcription.length.clamp(0, 100))}${transcription.length > 100 ? '...' : ''}',
          name: _logName,
        );

        return transcription;
      } finally {
        // Free native strings
        malloc.free(audioPathPtr);
        if (resultPtr != nullptr) {
          _whisperFreeString(resultPtr);
        }
      }
    } catch (e) {
      developer.log('❌ [WhisperFFI] Transcription failed: $e', name: _logName, error: e);
      rethrow;
    }
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if model is loaded
  bool get isModelLoaded => _whisperContext != null;

  /// Get suggested model file paths for different platforms
  static String getDefaultModelPath() {
    if (Platform.isIOS) {
      return path.join('ios', 'Runner', 'Models', 'ggml-base.en.bin');
    } else if (Platform.isAndroid) {
      return path.join('android', 'app', 'src', 'main', 'assets', 'models', 'ggml-base.en.bin');
    } else if (Platform.isMacOS) {
      return path.join('macos', 'Runner', 'Models', 'ggml-base.en.bin');
    } else {
      return path.join('assets', 'models', 'ggml-base.en.bin');
    }
  }

  /// Dispose resources and clean up
  Future<void> dispose() async {
    try {
      if (_whisperContext != null) {
        developer.log('🧹 [WhisperFFI] Cleaning up Whisper context', name: _logName);
        _whisperFree(_whisperContext!);
        _whisperContext = null;
      }

      developer.log('✅ [WhisperFFI] Resources cleaned up', name: _logName);
    } catch (e) {
      developer.log('⚠️ [WhisperFFI] Error during cleanup: $e', name: _logName, error: e);
    }
  }

  // Private helper methods

  void _loadLibrary() {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        // On iOS/macOS, load the framework or dylib
        _whisperLib = DynamicLibrary.open('libwhisper.dylib');
      } else if (Platform.isAndroid || Platform.isLinux) {
        // On Android/Linux, load the shared library
        _whisperLib = DynamicLibrary.open('libwhisper.so');
      } else if (Platform.isWindows) {
        // On Windows, load the DLL
        _whisperLib = DynamicLibrary.open('whisper.dll');
      } else {
        throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
      }

      developer.log('✅ [WhisperFFI] Native library loaded for ${Platform.operatingSystem}', name: _logName);
    } catch (e) {
      developer.log('❌ [WhisperFFI] Failed to load native library: $e', name: _logName, error: e);

      // Provide helpful error message
      final libName = Platform.isWindows
          ? 'whisper.dll'
          : (Platform.isIOS || Platform.isMacOS)
          ? 'libwhisper.dylib'
          : 'libwhisper.so';

      throw Exception(
        'Failed to load Whisper native library ($libName). '
        'Make sure the library is compiled and available in the app bundle. '
        'Original error: $e',
      );
    }
  }

  void _bindFunctions() {
    try {
      // Bind whisper_init function
      _whisperInit = _whisperLib.lookup<NativeFunction<WhisperInitNative>>('whisper_init').asFunction<WhisperInit>();

      // Bind whisper_transcribe function
      _whisperTranscribe = _whisperLib
          .lookup<NativeFunction<WhisperTranscribeNative>>('whisper_transcribe')
          .asFunction<WhisperTranscribe>();

      // Bind whisper_free function
      _whisperFree = _whisperLib.lookup<NativeFunction<WhisperFreeNative>>('whisper_free').asFunction<WhisperFree>();

      // Bind whisper_free_string function
      _whisperFreeString = _whisperLib
          .lookup<NativeFunction<WhisperFreeStringNative>>('whisper_free_string')
          .asFunction<WhisperFreeString>();

      developer.log('✅ [WhisperFFI] Native functions bound successfully', name: _logName);
    } catch (e) {
      developer.log('❌ [WhisperFFI] Failed to bind native functions: $e', name: _logName, error: e);

      throw Exception(
        'Failed to bind Whisper native functions. '
        'Make sure the library exports the required functions: '
        'whisper_init, whisper_transcribe, whisper_free, whisper_free_string. '
        'Original error: $e',
      );
    }
  }
}
