// Transcription Service for converting audio to text
// This will use MLKit, Whisper via FFI, or other AI transcription services

import 'dart:developer' as developer;
import 'whisper_ffi_service.dart';

abstract class TranscriptionService {
  Future<String> transcribeAudio(String audioFilePath);
  Future<List<String>> extractKeywords(String text);
  Future<bool> isInitialized();
  Future<void> initialize();
  Future<void> dispose();
}

/// Whisper FFI implementation of TranscriptionService
/// Uses Whisper.cpp via Dart FFI for offline speech recognition
class WhisperTranscriptionService implements TranscriptionService {
  static const String _logName = 'VoiceBridge.Transcription';

  final WhisperFFIService _whisperFFI = WhisperFFIService();
  String? _modelPath;

  /// Initialize the transcription service with Whisper model
  @override
  Future<void> initialize([String? modelPath]) async {
    try {
      developer.log('🔧 [Transcription] Initializing Whisper transcription service...', name: _logName);

      // Use provided model path or extract from assets
      _modelPath = modelPath ?? await WhisperFFIService.getDefaultModelPath();
      developer.log('📂 [Transcription] Using model path: $_modelPath', name: _logName);

      // Initialize FFI service
      await _whisperFFI.initialize();

      // Initialize model (this will be done lazily for now to avoid blocking startup)
      // await _whisperFFI.initializeModel(_modelPath!);

      developer.log('✅ [Transcription] Service initialized successfully', name: _logName);
    } catch (e) {
      developer.log('❌ [Transcription] Initialization failed: $e', name: _logName, error: e);
      rethrow;
    }
  }

  /// Transcribe audio file to text using Whisper
  @override
  Future<String> transcribeAudio(String audioFilePath) async {
    try {
      developer.log('🎵 [Transcription] Starting transcription for: $audioFilePath', name: _logName);

      // Ensure model is loaded
      if (!_whisperFFI.isModelLoaded) {
        if (_modelPath == null) {
          throw StateError('Service not initialized. Call initialize() first.');
        }
        developer.log('📥 [Transcription] Loading Whisper model...', name: _logName);
        await _whisperFFI.initializeModel(_modelPath!);
      }

      // Perform transcription
      final transcription = await _whisperFFI.transcribeAudio(audioFilePath);

      developer.log('✅ [Transcription] Transcription completed: ${transcription.length} characters', name: _logName);

      return transcription;
    } catch (e) {
      developer.log('❌ [Transcription] Transcription failed: $e', name: _logName, error: e);
      rethrow;
    }
  }

  /// Extract keywords from transcribed text
  /// Simple implementation using basic text processing
  @override
  Future<List<String>> extractKeywords(String text) async {
    try {
      developer.log('🔍 [Transcription] Extracting keywords from text: ${text.length} characters', name: _logName);

      if (text.trim().isEmpty) {
        return [];
      }

      // Simple keyword extraction (can be enhanced with NLP libraries)
      final words = text
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
          .split(RegExp(r'\s+')) // Split by whitespace
          .where((word) => word.length > 3) // Filter short words
          .where((word) => !_stopWords.contains(word)) // Filter stop words
          .toSet() // Remove duplicates
          .toList();

      // Sort by length (longer words might be more meaningful)
      words.sort((a, b) => b.length.compareTo(a.length));

      // Take top 10 keywords
      final keywords = words.take(10).toList();

      developer.log('✅ [Transcription] Extracted ${keywords.length} keywords: ${keywords.join(', ')}', name: _logName);

      return keywords;
    } catch (e) {
      developer.log('❌ [Transcription] Keyword extraction failed: $e', name: _logName, error: e);
      return [];
    }
  }

  /// Check if the service is initialized and ready
  @override
  Future<bool> isInitialized() async {
    return _whisperFFI.isInitialized;
  }

  /// Dispose resources and clean up
  @override
  Future<void> dispose() async {
    try {
      developer.log('🧹 [Transcription] Disposing transcription service', name: _logName);
      await _whisperFFI.dispose();
      _modelPath = null;
      developer.log('✅ [Transcription] Service disposed', name: _logName);
    } catch (e) {
      developer.log('⚠️ [Transcription] Error during disposal: $e', name: _logName, error: e);
    }
  }

  // Simple stop words list for keyword extraction
  static const Set<String> _stopWords = {
    'the',
    'and',
    'that',
    'have',
    'for',
    'not',
    'with',
    'you',
    'this',
    'but',
    'his',
    'from',
    'they',
    'she',
    'her',
    'been',
    'than',
    'its',
    'were',
    'said',
    'each',
    'which',
    'their',
    'time',
    'will',
    'about',
    'would',
    'there',
    'could',
    'other',
    'after',
    'first',
    'well',
    'also',
    'what',
    'some',
    'where',
    'when',
    'much',
    'should',
    'very',
    'most',
    'through',
    'just',
    'form',
    'sentence',
    'great',
    'think',
    'help',
    'low',
    'line',
    'turn',
    'cause',
    'same',
    'mean',
    'differ',
    'move',
    'right',
    'study',
    'might',
    'still',
    'such',
    'under',
  };
}

/// Mock implementation for testing and development
class MockTranscriptionService implements TranscriptionService {
  static const String _logName = 'VoiceBridge.MockTranscription';

  bool _isInitialized = false;

  @override
  Future<void> initialize([String? modelPath]) async {
    developer.log('🔧 [MockTranscription] Initializing mock service...', name: _logName);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate initialization
    _isInitialized = true;
    developer.log('✅ [MockTranscription] Mock service initialized', name: _logName);
  }

  @override
  Future<String> transcribeAudio(String audioFilePath) async {
    developer.log('🎵 [MockTranscription] Mock transcribing: $audioFilePath', name: _logName);

    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    // Return mock transcription based on file name
    final fileName = audioFilePath.split('/').last;
    final mockText =
        'This is a mock transcription for $fileName. '
        'In a real implementation, this would contain the actual speech-to-text result from Whisper.cpp. '
        'The transcription quality would depend on the model used and the audio quality.';

    developer.log('✅ [MockTranscription] Mock transcription completed', name: _logName);
    return mockText;
  }

  @override
  Future<List<String>> extractKeywords(String text) async {
    developer.log('🔍 [MockTranscription] Mock extracting keywords', name: _logName);

    // Return mock keywords
    final mockKeywords = ['mock', 'transcription', 'speech', 'audio', 'whisper'];

    developer.log('✅ [MockTranscription] Mock keywords extracted: ${mockKeywords.join(', ')}', name: _logName);
    return mockKeywords;
  }

  @override
  Future<bool> isInitialized() async {
    return _isInitialized;
  }

  @override
  Future<void> dispose() async {
    developer.log('🧹 [MockTranscription] Disposing mock service', name: _logName);
    _isInitialized = false;
  }
}

// Legacy class name for backward compatibility
typedef TranscriptionServiceImpl = WhisperTranscriptionService;
