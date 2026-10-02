import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 🎓 **WORKSHOP MODULE 3: Dart FFI Deep Dive**
///
/// **Learning Objectives:**
/// - Master direct C/C++ library integration in Flutter
/// - Understand memory management between Dart and native code
/// - Keep long native calls off the UI isolate with [Isolate.run]
/// - Practice resource cleanup and error handling in FFI context
///
/// **How the isolate part works:** native memory belongs to the process, not to an isolate. The Whisper model is
/// loaded once and its context pointer travels between isolates as a plain integer address. Each heavy call
/// (`whisper_ffi_init`, `whisper_ffi_transcribe`) runs in [Isolate.run], which reopens the already-loaded library
/// (a cheap `dlopen`), rebuilds the pointer from the address, and returns a Dart value. The UI isolate never
/// blocks, so the recording timer and animations keep running during a transcription.

typedef WhisperInitNative = Pointer<Void> Function(Pointer<Utf8> modelPath);
typedef WhisperInit = Pointer<Void> Function(Pointer<Utf8> modelPath);

typedef WhisperTranscribeNative = Pointer<Utf8> Function(Pointer<Void> context, Pointer<Utf8> audioPath);
typedef WhisperTranscribe = Pointer<Utf8> Function(Pointer<Void> context, Pointer<Utf8> audioPath);

typedef WhisperFreeNative = Void Function(Pointer<Void> context);
typedef WhisperFree = void Function(Pointer<Void> context);

typedef WhisperFreeStringNative = Void Function(Pointer<Utf8> text);
typedef WhisperFreeString = void Function(Pointer<Utf8> text);

class WhisperFFIService {
  static const String _logName = 'VoiceBridge.WhisperFFI';
  static const String _libraryName = 'libwhisper_ffi.dylib';
  static const String modelFileName = 'ggml-base.en.bin';
  static const String _modelAssetPath = 'assets/models/$modelFileName';

  String? _libraryPath;
  int? _contextAddress;

  /// Serialises native calls: one whisper context must not run two transcriptions at once.
  Future<void> _pendingCall = Future<void>.value();

  bool get isInitialized => _libraryPath != null;
  bool get isModelLoaded => _contextAddress != null;

  /// Finds and loads the native library; cheap, runs on the calling isolate.
  Future<void> initialize() async {
    if (isInitialized) return;
    if (!Platform.isMacOS && !Platform.isIOS) {
      throw UnsupportedError('Whisper FFI is only built for macOS (platform: ${Platform.operatingSystem})');
    }
    _libraryPath = _resolveLibraryPath();
    developer.log('✅ [WhisperFFI] Native library loaded from $_libraryPath', name: _logName);
  }

  /// Loads the model in a background isolate; the context stays alive until [dispose].
  Future<void> initializeModel(String modelPath) async {
    final libraryPath = _libraryPath;
    if (libraryPath == null) {
      throw StateError('WhisperFFI service not initialized. Call initialize() first.');
    }
    if (!File(modelPath).existsSync()) {
      throw FileSystemException('Whisper model file not found', modelPath);
    }
    await dispose();

    final contextAddress = await _serialised(() => Isolate.run(() => _loadModel(libraryPath, modelPath)));
    if (contextAddress == 0) {
      throw StateError('whisper_ffi_init returned null for $modelPath');
    }
    _contextAddress = contextAddress;
    developer.log('✅ [WhisperFFI] Model loaded: $modelPath', name: _logName);
  }

  /// Transcribes a 16 kHz mono WAV file in a background isolate.
  Future<String> transcribeAudio(String audioFilePath) async {
    final libraryPath = _libraryPath;
    final contextAddress = _contextAddress;
    if (libraryPath == null || contextAddress == null) {
      throw StateError('Whisper model not loaded. Call initializeModel() first.');
    }
    final audioFile = File(audioFilePath);
    if (!audioFile.existsSync()) {
      throw FileSystemException('Audio file not found', audioFilePath);
    }
    if (audioFile.lengthSync() == 0) {
      throw FileSystemException('Audio file is empty', audioFilePath);
    }

    final transcription = await _serialised(
      () => Isolate.run(() => _transcribe(libraryPath, contextAddress, audioFilePath)),
    );
    if (transcription == null) {
      throw StateError('whisper_ffi_transcribe returned null for $audioFilePath');
    }
    developer.log('✅ [WhisperFFI] Transcribed ${transcription.length} characters', name: _logName);
    return transcription.trim();
  }

  /// Frees the native model context; waits for any running transcription first.
  Future<void> dispose() async {
    final libraryPath = _libraryPath;
    final contextAddress = _contextAddress;
    if (libraryPath == null || contextAddress == null) return;
    _contextAddress = null;
    await _serialised(() async => _freeModel(libraryPath, contextAddress));
    developer.log('🧹 [WhisperFFI] Model context freed', name: _logName);
  }

  Future<T> _serialised<T>(Future<T> Function() call) {
    final result = _pendingCall.then((_) => call());
    _pendingCall = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Copies the bundled model to the cache once. The copy is written to a `.part` file and renamed, so a crash
  /// mid-copy can never leave a truncated model that later launches would reuse.
  static Future<String> getDefaultModelPath() async {
    final cacheDirectory = await getApplicationCacheDirectory();
    final modelPath = path.join(cacheDirectory.path, modelFileName);
    if (File(modelPath).existsSync()) return modelPath;

    developer.log('📥 [WhisperFFI] Extracting $_modelAssetPath to the cache', name: _logName);
    final assetData = await rootBundle.load(_modelAssetPath);
    final partialFile = File('$modelPath.part');
    await partialFile.writeAsBytes(assetData.buffer.asUint8List(assetData.offsetInBytes, assetData.lengthInBytes));
    await partialFile.rename(modelPath);
    return modelPath;
  }

  static String _resolveLibraryPath() {
    final candidates = [
      _libraryName, // app bundle: Contents/Frameworks via @rpath
      path.join(
        Directory.current.path,
        'native',
        'whisper',
        'build',
        'lib',
        _libraryName,
      ), // `flutter test` from repo root
    ];
    final failures = <String>[];
    for (final candidate in candidates) {
      try {
        DynamicLibrary.open(candidate);
        return candidate;
      } on ArgumentError catch (error) {
        failures.add('  • $candidate: ${error.message}');
      }
    }
    throw StateError(
      'Could not load $_libraryName. Run ./scripts/build_whisper.sh first.\n${failures.join('\n')}',
    );
  }
}

int _loadModel(String libraryPath, String modelPath) {
  final init = DynamicLibrary.open(
    libraryPath,
  ).lookupFunction<WhisperInitNative, WhisperInit>('whisper_ffi_init');
  final modelPathPointer = modelPath.toNativeUtf8();
  try {
    return init(modelPathPointer).address;
  } finally {
    malloc.free(modelPathPointer);
  }
}

String? _transcribe(String libraryPath, int contextAddress, String audioFilePath) {
  final library = DynamicLibrary.open(libraryPath);
  final transcribe = library.lookupFunction<WhisperTranscribeNative, WhisperTranscribe>('whisper_ffi_transcribe');
  final freeString = library.lookupFunction<WhisperFreeStringNative, WhisperFreeString>('whisper_ffi_free_string');

  final audioPathPointer = audioFilePath.toNativeUtf8();
  try {
    final resultPointer = transcribe(Pointer<Void>.fromAddress(contextAddress), audioPathPointer);
    if (resultPointer == nullptr) return null;
    try {
      return resultPointer.toDartString();
    } finally {
      freeString(resultPointer);
    }
  } finally {
    malloc.free(audioPathPointer);
  }
}

void _freeModel(String libraryPath, int contextAddress) {
  DynamicLibrary.open(
    libraryPath,
  ).lookupFunction<WhisperFreeNative, WhisperFree>('whisper_ffi_free')(Pointer<Void>.fromAddress(contextAddress));
}
