import 'dart:async';
import 'dart:isolate';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'transcription_service.dart';
import 'whisper_ffi_service.dart';

/// Isolate-based transcription service for non-blocking AI processing
/// Prevents UI freezing during heavy Whisper.cpp operations
class IsolateTranscriptionService implements TranscriptionService {
  static const String _logName = 'VoiceBridge.IsolateTranscription';

  Isolate? _transcriptionIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  bool _isInitialized = false;
  String? _modelPath;

  /// Initialize the transcription service with isolate setup
  @override
  Future<void> initialize([String? modelPath]) async {
    if (_isInitialized) {
      developer.log('✅ [IsolateTranscription] Already initialized', name: _logName);
      return;
    }

    try {
      developer.log('🔧 [IsolateTranscription] Initializing isolate transcription service...', name: _logName);

      // Get model path
      _modelPath = modelPath ?? await WhisperFFIService.getDefaultModelPath();
      developer.log('📂 [IsolateTranscription] Using model path: $_modelPath', name: _logName);

      // Setup receive port for isolate communication
      _receivePort = ReceivePort();

      // Spawn the transcription isolate
      _transcriptionIsolate = await Isolate.spawn(_transcriptionIsolateEntryPoint, _receivePort!.sendPort);

      // Wait for isolate to send back its SendPort
      final Completer<SendPort> sendPortCompleter = Completer<SendPort>();
      _receivePort!.listen((dynamic data) {
        if (data is SendPort) {
          sendPortCompleter.complete(data);
        }
      });

      _sendPort = await sendPortCompleter.future;

      // Initialize the model in the isolate
      final Completer<bool> initCompleter = Completer<bool>();
      _receivePort!.listen((dynamic data) {
        if (data is Map<String, dynamic> && data['type'] == 'init_result') {
          initCompleter.complete(data['success'] as bool);
        }
      });

      // Send initialization message
      _sendPort!.send({'type': 'initialize', 'modelPath': _modelPath});

      final bool initSuccess = await initCompleter.future;
      if (!initSuccess) {
        throw Exception('Failed to initialize Whisper model in isolate');
      }

      _isInitialized = true;
      developer.log('✅ [IsolateTranscription] Service initialized successfully', name: _logName);
    } catch (e) {
      developer.log('❌ [IsolateTranscription] Initialization failed: $e', name: _logName, error: e);
      await dispose();
      rethrow;
    }
  }

  /// Transcribe audio file using background isolate
  @override
  Future<String> transcribeAudio(String audioFilePath) async {
    if (!_isInitialized || _sendPort == null) {
      throw StateError('Service not initialized. Call initialize() first.');
    }

    try {
      developer.log('🎵 [IsolateTranscription] Starting background transcription for: $audioFilePath', name: _logName);

      // Setup completion handling
      final Completer<String> transcriptionCompleter = Completer<String>();

      // Listen for transcription results
      StreamSubscription? subscription;
      subscription = _receivePort!.listen((dynamic data) {
        if (data is Map<String, dynamic> && data['type'] == 'transcription_result') {
          subscription?.cancel();

          if (data['success'] == true) {
            final String result = data['result'] as String;
            transcriptionCompleter.complete(result);
          } else {
            final String error = data['error'] as String;
            transcriptionCompleter.completeError(Exception(error));
          }
        }
      });

      // Send transcription request to isolate
      _sendPort!.send({'type': 'transcribe', 'audioFilePath': audioFilePath});

      // Wait for result with timeout
      final String result = await transcriptionCompleter.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          subscription?.cancel();
          throw Exception('Transcription timeout after 5 minutes');
        },
      );

      developer.log(
        '✅ [IsolateTranscription] Background transcription completed: ${result.length} characters',
        name: _logName,
      );
      return result;
    } catch (e) {
      developer.log('❌ [IsolateTranscription] Background transcription failed: $e', name: _logName, error: e);
      rethrow;
    }
  }

  @override
  Future<List<String>> extractKeywords(String text) async {
    // Keywords extraction can run on main thread (lightweight operation)
    if (text.trim().isEmpty) {
      return [];
    }

    // Simple keyword extraction (same as base implementation)
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .where((word) => word.length > 3)
        .where((word) => !_stopWords.contains(word))
        .toSet()
        .toList();

    words.sort((a, b) => b.length.compareTo(a.length));
    return words.take(10).toList();
  }

  @override
  Future<bool> isInitialized() async {
    return _isInitialized;
  }

  @override
  Future<void> dispose() async {
    try {
      developer.log('🧹 [IsolateTranscription] Disposing isolate service', name: _logName);

      // Send dispose message to isolate
      if (_sendPort != null) {
        _sendPort!.send({'type': 'dispose'});
      }

      // Clean up isolate
      _transcriptionIsolate?.kill(priority: Isolate.immediate);
      _transcriptionIsolate = null;

      // Clean up ports
      _receivePort?.close();
      _receivePort = null;
      _sendPort = null;

      _isInitialized = false;
      _modelPath = null;

      developer.log('✅ [IsolateTranscription] Service disposed', name: _logName);
    } catch (e) {
      developer.log('⚠️ [IsolateTranscription] Error during disposal: $e', name: _logName, error: e);
    }
  }

  // Stop words for keyword extraction
  static const Set<String> _stopWords = {
    'the', 'and', 'that', 'have', 'for', 'not', 'with', 'you', 'this', 'but',
    'his', 'from', 'they', 'she', 'her', 'been', 'than', 'its', 'were', 'said',
    // ... (same as base implementation)
  };

  /// Isolate entry point for background transcription processing
  static void _transcriptionIsolateEntryPoint(SendPort mainSendPort) async {
    final ReceivePort isolateReceivePort = ReceivePort();

    // Send the isolate's SendPort back to main
    mainSendPort.send(isolateReceivePort.sendPort);

    WhisperFFIService? whisperService;
    bool isModelLoaded = false;

    // Listen for messages from main isolate
    await for (final dynamic data in isolateReceivePort) {
      if (data is Map<String, dynamic>) {
        try {
          switch (data['type']) {
            case 'initialize':
              final String modelPath = data['modelPath'] as String;

              try {
                whisperService = WhisperFFIService();
                await whisperService!.initialize();
                await whisperService!.initializeModel(modelPath);
                isModelLoaded = true;

                mainSendPort.send({'type': 'init_result', 'success': true});
              } catch (e) {
                mainSendPort.send({'type': 'init_result', 'success': false, 'error': e.toString()});
              }
              break;

            case 'transcribe':
              if (whisperService == null || !isModelLoaded) {
                mainSendPort.send({
                  'type': 'transcription_result',
                  'success': false,
                  'error': 'Whisper service not initialized',
                });
                continue;
              }

              final String audioFilePath = data['audioFilePath'] as String;

              try {
                final String result = await whisperService!.transcribeAudio(audioFilePath);

                mainSendPort.send({'type': 'transcription_result', 'success': true, 'result': result});
              } catch (e) {
                mainSendPort.send({'type': 'transcription_result', 'success': false, 'error': e.toString()});
              }
              break;

            case 'dispose':
              try {
                await whisperService?.dispose();
              } catch (e) {
                // Log but don't throw during disposal
                print('Error disposing whisper service in isolate: $e');
              }

              isolateReceivePort.close();
              return; // Exit isolate

            default:
              print('Unknown message type in transcription isolate: ${data['type']}');
          }
        } catch (e) {
          print('Error processing message in transcription isolate: $e');
          mainSendPort.send({'type': 'error', 'error': e.toString()});
        }
      }
    }
  }
}
