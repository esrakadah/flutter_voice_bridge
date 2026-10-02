import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

/// 🎓 **WORKSHOP MODULE 3: Dart FFI Deep Dive**
///
/// **Learning Objectives:**
/// - Master direct C/C++ library integration in Flutter
/// - Understand memory management between Dart and native code
/// - Learn function signature mapping and type safety
/// - Practice resource cleanup and error handling in FFI context
///
/// **Key Concepts Demonstrated:**
/// - Function Signatures: Mapping C functions to Dart
/// - Memory Management: Proper allocation and cleanup
/// - Dynamic Library Loading: Platform-specific library loading
/// - Pointer Handling: Safe manipulation of native memory
///
/// **Performance Focus:** This demonstrates the fastest possible integration method

// ⚡ FFI PATTERN: Direct C Library Integration
// FFI (Foreign Function Interface) allows direct calls to C/C++ libraries
// This is the most performant way to integrate native libraries (faster than Platform Channels)
// 🔗 FFI FUNCTION SIGNATURE MAPPING
// Every C function needs two typedef declarations:
// 1. Native signature (what the C library exports)
// 2. Dart signature (what we call from Dart code)

// 🚀 WHISPER INITIALIZATION FUNCTION
// C: whisper_context* whisper_ffi_init(const char* model_path)
typedef WhisperInitNative = Pointer<Void> Function(Pointer<Utf8> modelPath); // Native C signature
typedef WhisperInit = Pointer<Void> Function(Pointer<Utf8> modelPath); // Dart function signature

// 🎤 AUDIO TRANSCRIPTION FUNCTION
// C: char* whisper_ffi_transcribe(whisper_context* ctx, const char* audio_path)
typedef WhisperTranscribeNative = Pointer<Utf8> Function(Pointer<Void> ctx, Pointer<Utf8> audioPath);
typedef WhisperTranscribe = Pointer<Utf8> Function(Pointer<Void> ctx, Pointer<Utf8> audioPath);

// 🧹 CONTEXT CLEANUP FUNCTION
// C: void whisper_ffi_free(whisper_context* ctx)
typedef WhisperFreeNative = Void Function(Pointer<Void> ctx);
typedef WhisperFree = void Function(Pointer<Void> ctx);

// 🧹 STRING MEMORY CLEANUP FUNCTION
// C: void whisper_ffi_free_string(char* str)
typedef WhisperFreeStringNative = Void Function(Pointer<Utf8> str);
typedef WhisperFreeString = void Function(Pointer<Utf8> str);

/// 🤖 WHISPER FFI SERVICE
/// This class demonstrates advanced FFI patterns for AI library integration
///
/// **Memory Management Strategy:**
/// - Native library holds AI model in memory
/// - Audio processing happens in native code (C++)
/// - Results are returned as C strings, converted to Dart, then freed
///
/// **Performance Characteristics:**
/// - Direct C library calls (no serialization overhead)
/// - GPU acceleration available on supported platforms
/// - Model loaded once, reused for multiple transcriptions
class WhisperFFIService {
  static const String _logName = 'VoiceBridge.WhisperFFI';

  // 📚 DYNAMIC LIBRARY AND FUNCTION POINTERS
  // DynamicLibrary: Handle to the loaded native library
  // Function pointers: Direct references to C functions for fast calls
  late final DynamicLibrary _whisperLib; // 📖 Loaded native library
  late final WhisperInit _whisperInit; // 🚀 Model initialization function
  late final WhisperTranscribe _whisperTranscribe; // 🎤 Audio processing function
  late final WhisperFree _whisperFree; // 🧹 Context cleanup function
  late final WhisperFreeString _whisperFreeString; // 🧹 String memory cleanup

  // 💾 NATIVE RESOURCE MANAGEMENT
  // _whisperContext: Opaque pointer to native AI model context
  // _isInitialized: Prevents double initialization and resource leaks
  Pointer<Void>? _whisperContext; // 🧠 Native AI model context
  bool _isInitialized = false; // 🔒 Initialization state guard

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

      // Validate input parameters
      if (audioFilePath.isEmpty) {
        throw ArgumentError('Audio file path cannot be empty');
      }

      // Check if audio file exists
      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        throw FileSystemException('Audio file not found', audioFilePath);
      }

      // Check file size (0 bytes indicates a problem)
      final fileSize = await audioFile.length();
      if (fileSize == 0) {
        throw Exception('Audio file is empty (0 bytes)');
      }

      developer.log('📊 [WhisperFFI] Audio file size: $fileSize bytes', name: _logName);

      // Convert path to native string
      final audioPathPtr = audioFilePath.toNativeUtf8();
      Pointer<Utf8> resultPtr = nullptr;

      try {
        // Call native transcription function
        developer.log('🔄 [WhisperFFI] Calling native transcribe function...', name: _logName);
        resultPtr = _whisperTranscribe(_whisperContext!, audioPathPtr);

        if (resultPtr == nullptr) {
          throw Exception(
            'Transcription failed - native function returned null result. '
            'This could indicate:\n'
            '• Audio format not supported by Whisper\n'
            '• Insufficient memory\n'
            '• Model initialization issue\n'
            '• Silent audio with no speech',
          );
        }

        // Convert result to Dart string
        final transcription = resultPtr.toDartString();

        // Validate the transcription result
        if (transcription.isEmpty) {
          developer.log('⚠️ [WhisperFFI] Transcription returned empty string', name: _logName);
          return ''; // Return empty string instead of throwing
        }

        developer.log('✅ [WhisperFFI] Transcription completed: ${transcription.length} characters', name: _logName);
        developer.log(
          '📝 [WhisperFFI] Result: ${transcription.substring(0, transcription.length.clamp(0, 100))}${transcription.length > 100 ? '...' : ''}',
          name: _logName,
        );

        return transcription.trim(); // Trim whitespace
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

  /// Get model file path by extracting from Flutter assets to temporary location
  static Future<String> getDefaultModelPath() async {
    const String modelAssetPath = 'assets/models/ggml-base.en.bin';
    developer.log('📁 [WhisperFFI] Getting model path, asset path: "$modelAssetPath"', name: _logName);

    try {
      // Get temporary directory
      final Directory tempDir = await getApplicationCacheDirectory();
      final String modelTempPath = path.join(tempDir.path, 'ggml-base.en.bin');
      final File tempModelFile = File(modelTempPath);

      developer.log('ℹ️ [WhisperFFI] Temp model path: "$modelTempPath"', name: _logName);

      // Check if the model file already exists in the temporary directory
      if (await tempModelFile.exists()) {
        developer.log('✅ [WhisperFFI] Model already exists in cache. Using existing file.', name: _logName);
        return modelTempPath;
      }

      developer.log('📥 [WhisperFFI] Model not found in cache. Extracting from assets...', name: _logName);

      // Load the model file from assets
      final ByteData assetData = await rootBundle.load(modelAssetPath);

      // Write asset data to temporary file
      await tempModelFile.writeAsBytes(assetData.buffer.asUint8List());

      developer.log('✅ [WhisperFFI] Model extracted to: $modelTempPath', name: _logName);
      developer.log('📊 [WhisperFFI] Model file size: ${assetData.lengthInBytes} bytes', name: _logName);

      return modelTempPath;
    } catch (e, s) {
      developer.log(
        '❌ [WhisperFFI] Critical error: Failed to extract model from assets.',
        name: _logName,
        error: e,
        stackTrace: s,
      );
      // In a production app, you might want to inform the user or try a fallback.
      // For this workshop, we throw to make the issue visible.
      throw Exception('Failed to provide a valid model path. Asset: "$modelAssetPath". Error: $e');
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
    if (Platform.isIOS || Platform.isMacOS) {
      _loadAppleLibrary();
    } else if (Platform.isAndroid || Platform.isLinux) {
      _loadLinuxLibrary();
    } else if (Platform.isWindows) {
      _loadWindowsLibrary();
    } else {
      throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
    }

    developer.log('✅ [WhisperFFI] Native library loaded for ${Platform.operatingSystem}', name: _logName);
  }

  void _loadAppleLibrary() {
    final List<String> libraryPaths = [
      // App bundle paths (runtime)
      'libwhisper_ffi.dylib', // Standard @rpath lookup
      '@rpath/libwhisper_ffi.dylib', // Explicit @rpath
      'Frameworks/libwhisper_ffi.dylib', // App bundle Frameworks
      // Development paths (when running from Xcode/IDE)
      'macos/Runner/libwhisper_ffi.dylib',
      './macos/Runner/libwhisper_ffi.dylib',
      path.join(Directory.current.path, 'macos', 'Runner', 'libwhisper_ffi.dylib'),

      // Build output paths
      'native/whisper/whisper.cpp/build/libwhisper_ffi.dylib',
      './native/whisper/whisper.cpp/build/libwhisper_ffi.dylib',
      path.join(Directory.current.path, 'native', 'whisper', 'whisper.cpp', 'build', 'libwhisper_ffi.dylib'),
    ];

    Exception? lastError;

    for (final libraryPath in libraryPaths) {
      try {
        developer.log('🔍 [WhisperFFI] Trying to load library from: $libraryPath', name: _logName);
        _whisperLib = DynamicLibrary.open(libraryPath);
        developer.log('✅ [WhisperFFI] Successfully loaded library from: $libraryPath', name: _logName);
        return;
      } catch (e) {
        developer.log('⚠️ [WhisperFFI] Failed to load from $libraryPath: $e', name: _logName);
        lastError = e is Exception ? e : Exception(e.toString());
        continue;
      }
    }

    // If we get here, all paths failed
    throw Exception(
      'Failed to load Whisper native library (libwhisper_ffi.dylib) from any of the expected locations:\n'
      '${libraryPaths.map((path) => '  • $path').join('\n')}\n\n'
      'Please ensure the library is built and accessible. Try running:\n'
      '  ./scripts/build_whisper.sh\n\n'
      'Last error: $lastError',
    );
  }

  void _loadLinuxLibrary() {
    final List<String> libraryPaths = [
      'libwhisper_ffi.so',
      './libwhisper_ffi.so',
      'linux/libwhisper_ffi.so',
      './linux/libwhisper_ffi.so',
    ];

    Exception? lastError;

    for (final libraryPath in libraryPaths) {
      try {
        _whisperLib = DynamicLibrary.open(libraryPath);
        developer.log('✅ [WhisperFFI] Successfully loaded library from: $libraryPath', name: _logName);
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        continue;
      }
    }

    throw Exception(
      'Failed to load Whisper native library (libwhisper_ffi.so). '
      'Please ensure the library is built and accessible. '
      'Last error: $lastError',
    );
  }

  void _loadWindowsLibrary() {
    final List<String> libraryPaths = [
      'whisper_ffi.dll',
      './whisper_ffi.dll',
      'windows/whisper_ffi.dll',
      './windows/whisper_ffi.dll',
    ];

    Exception? lastError;

    for (final libraryPath in libraryPaths) {
      try {
        _whisperLib = DynamicLibrary.open(libraryPath);
        developer.log('✅ [WhisperFFI] Successfully loaded library from: $libraryPath', name: _logName);
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        continue;
      }
    }

    throw Exception(
      'Failed to load Whisper native library (whisper_ffi.dll). '
      'Please ensure the library is built and accessible. '
      'Last error: $lastError',
    );
  }

  void _bindFunctions() {
    try {
      // Bind whisper_ffi_init function
      _whisperInit = _whisperLib
          .lookup<NativeFunction<WhisperInitNative>>('whisper_ffi_init')
          .asFunction<WhisperInit>();

      // Bind whisper_ffi_transcribe function
      _whisperTranscribe = _whisperLib
          .lookup<NativeFunction<WhisperTranscribeNative>>('whisper_ffi_transcribe')
          .asFunction<WhisperTranscribe>();

      // Bind whisper_ffi_free function
      _whisperFree = _whisperLib
          .lookup<NativeFunction<WhisperFreeNative>>('whisper_ffi_free')
          .asFunction<WhisperFree>();

      // Bind whisper_ffi_free_string function
      _whisperFreeString = _whisperLib
          .lookup<NativeFunction<WhisperFreeStringNative>>('whisper_ffi_free_string')
          .asFunction<WhisperFreeString>();

      developer.log('✅ [WhisperFFI] Native functions bound successfully', name: _logName);
    } catch (e) {
      developer.log('❌ [WhisperFFI] Failed to bind native functions: $e', name: _logName, error: e);

      throw Exception(
        'Failed to bind Whisper native functions. '
        'Make sure the library exports the required functions: '
        'whisper_ffi_init, whisper_ffi_transcribe, whisper_ffi_free, whisper_ffi_free_string. '
        'Original error: $e',
      );
    }
  }
}
