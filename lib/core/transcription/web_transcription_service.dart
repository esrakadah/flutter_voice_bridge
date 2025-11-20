import 'dart:async';
import 'dart:developer' as developer;
import 'transcription_service.dart';

/// 🌐 WEB TRANSCRIPTION SERVICE
/// A placeholder implementation for the Web platform where native FFI
/// libraries (like Whisper.cpp) are not supported.
class WebTranscriptionService implements TranscriptionService {
  static const String _logName = 'VoiceBridge.WebTranscription';
  bool _isInitialized = false;

  @override
  Future<void> initialize([String? modelPath]) async {
    developer.log('🌐 [WebTranscription] Initializing web service (mock)...', name: _logName);
    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 500));
    _isInitialized = true;
    developer.log('✅ [WebTranscription] Web service initialized', name: _logName);
  }

  @override
  Future<String> transcribeAudio(String audioFilePath) async {
    if (!_isInitialized) {
      throw StateError('WebTranscriptionService not initialized');
    }

    developer.log('🌐 [WebTranscription] Transcription requested for: $audioFilePath', name: _logName);
    
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 1));

    // Return a friendly message explaining limitation
    return "Transcription is not available on the web version of this app. "
           "The Whisper AI model requires native device capabilities (FFI) "
           "which are not supported in the browser environment.";
  }

  @override
  Future<List<String>> extractKeywords(String text) async {
    return ['web', 'demo', 'limitation'];
  }

  @override
  Future<bool> isInitialized() async {
    return _isInitialized;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    developer.log('✅ [WebTranscription] Disposed', name: _logName);
  }
}
