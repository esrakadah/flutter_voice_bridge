import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../core/audio/audio_service.dart';
import '../../../core/transcription/transcription_service.dart';
import '../../../data/services/voice_memo_service.dart';
import '../../../data/models/voice_memo.dart';
import 'home_state.dart';

/// 🎓 **WORKSHOP MODULE 1.2: BLoC State Management**
///
/// **Learning Objectives:**
/// - Understand separation between UI and business logic
/// - Learn proper state management with BLoC pattern
/// - See how Cubits handle complex async operations
/// - Practice dependency injection and service coordination
///
/// **Key Patterns Demonstrated:**
/// - Single Responsibility: Only handles recording business logic
/// - Dependency Injection: Services injected via constructor
/// - State Immutability: All states are immutable value objects
/// - Error Handling: Consistent error propagation and logging
///
/// **Architecture Layer:** Business Logic (between UI and Data layers)

// 🏗️ ARCHITECTURE PATTERN: Business Logic Layer
// This Cubit acts as the orchestrator between UI events and data services
// It contains NO UI code and NO direct data access - only coordination logic

// 📚 LEARNING FOCUS: Cubit State Management
// Cubits are simplified BLoCs that emit states without events
// Perfect for straightforward state transitions triggered by UI actions

class HomeCubit extends Cubit<HomeState> {
  // 🔧 DEPENDENCY INJECTION PATTERN
  // Services are injected via constructor, enabling:
  // ✅ Easy testing with mock implementations
  // ✅ Loose coupling between business logic and data layers
  // ✅ Single responsibility - each service handles one concern
  final AudioService _audioService; // 🎤 Platform-specific audio operations
  final VoiceMemoService _voiceMemoService; // 💾 File system and data persistence
  final TranscriptionService _transcriptionService; // 🤖 AI-powered speech-to-text

  // 📊 PRIVATE STATE MANAGEMENT
  // These are internal state variables that don't need to trigger UI rebuilds
  // They're used for coordination and will be included in emitted states when needed
  Timer? _recordingTimer; // ⏱️ Timer for recording duration tracking
  Duration _recordingDuration = Duration.zero; // 📏 Current recording length
  String? _currentRecordingPath; // 📁 Path to active recording file
  String? _lastCompletedRecordingPath; // 📁 Path to most recent completed recording
  int _recordingSeconds = 0; // 🔢 Simple counter for UI display

  // 🏗️ CONSTRUCTOR INJECTION PATTERN
  // This is a classic dependency injection pattern where all dependencies
  // are provided at construction time, making the class:
  // ✅ Testable (dependencies can be mocked)
  // ✅ Flexible (different implementations can be injected)
  // ✅ Clear about its dependencies (explicit in constructor)
  HomeCubit({
    required AudioService audioService,
    required VoiceMemoService voiceMemoService,
    required TranscriptionService transcriptionService,
  }) : _audioService = audioService,
       _voiceMemoService = voiceMemoService,
       _transcriptionService = transcriptionService,
       super(const HomeInitial()) {
    // 📍 Initial state - app starts in "ready" state
    developer.log(
      '🏠 [HomeCubit] Initialized with audio service: ${_audioService.runtimeType}',
      name: 'VoiceBridge.Cubit',
    );
    developer.log(
      '🤖 [HomeCubit] Initialized with transcription service: ${_transcriptionService.runtimeType}',
      name: 'VoiceBridge.Cubit',
    );

    // Initialize transcription service
    _initializeTranscriptionService();

    // Load existing recordings on initialization
    loadRecordings();
  }

  // Initialize transcription service
  Future<void> _initializeTranscriptionService() async {
    try {
      developer.log('🔧 [HomeCubit] Initializing transcription service...', name: 'VoiceBridge.Cubit');
      await _transcriptionService.initialize();
      developer.log('✅ [HomeCubit] Transcription service initialized', name: 'VoiceBridge.Cubit');
    } catch (e) {
      developer.log(
        '❌ [HomeCubit] Failed to initialize transcription service: $e',
        name: 'VoiceBridge.Cubit',
        error: e,
      );
    }
  }

  // 🎯 BUSINESS LOGIC METHOD: Start Recording
  // This method demonstrates the complete flow of starting an audio recording
  // Notice how it coordinates multiple services and handles various edge cases
  Future<void> startRecording() async {
    developer.log('▶️ [HomeCubit] Starting recording process...', name: 'VoiceBridge.Cubit');

    try {
      // 🔐 PERMISSION HANDLING PATTERN
      // Always check permissions before attempting platform operations
      // This prevents crashes and provides better user experience
      developer.log('🔐 [HomeCubit] Checking audio permissions...', name: 'VoiceBridge.Cubit');
      final bool hasPermission = await _audioService.hasPermission();
      developer.log('🔐 [HomeCubit] Has permission: $hasPermission', name: 'VoiceBridge.Cubit');

      if (!hasPermission) {
        developer.log('🔐 [HomeCubit] Requesting audio permission...', name: 'VoiceBridge.Cubit');
        await _audioService.requestPermission();
      }

      // Start recording
      developer.log('🎤 [HomeCubit] Calling audio service startRecording...', name: 'VoiceBridge.Cubit');
      final String recordingPath = await _audioService.startRecording();
      _currentRecordingPath = recordingPath;
      developer.log('✅ [HomeCubit] Recording started at path: $recordingPath', name: 'VoiceBridge.Cubit');

      // Emit started state
      emit(RecordingStarted(recordingPath: recordingPath));
      developer.log('📡 [HomeCubit] State changed to RecordingStarted', name: 'VoiceBridge.Cubit');

      // Start timer for recording duration
      _startRecordingTimer();
      emit(const RecordingInProgress());
      developer.log('⏺️ [HomeCubit] State changed to RecordingInProgress, timer started', name: 'VoiceBridge.Cubit');
    } catch (e) {
      developer.log('❌ [HomeCubit] Error starting recording: $e', name: 'VoiceBridge.Cubit', error: e);
      developer.log('❌ [HomeCubit] Error type: ${e.runtimeType}', name: 'VoiceBridge.Cubit');

      // Check for specific permission errors
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission') || errorMessage.contains('denied')) {
        developer.log('🚫 [HomeCubit] Permission denied error detected', name: 'VoiceBridge.Cubit');
        emit(const RecordingError(errorMessage: 'PERMISSION_DENIED'));
      } else {
        emit(RecordingError(errorMessage: e.toString()));
      }
    }
  }

  // Load recordings functionality
  Future<void> loadRecordings() async {
    developer.log('📂 [HomeCubit] Loading recordings list...', name: 'VoiceBridge.Cubit');

    try {
      // Emit loading state
      emit(_copyCurrentState(isLoadingRecordings: true, recordingsError: null));

      // Load recordings from service
      developer.log('🔄 [HomeCubit] Calling voiceMemoService.listRecordings...', name: 'VoiceBridge.Cubit');
      final List<VoiceMemo> recordings = await _voiceMemoService.listRecordings();
      developer.log('✅ [HomeCubit] Loaded ${recordings.length} recordings', name: 'VoiceBridge.Cubit');

      // Log each recording for debugging
      for (int i = 0; i < recordings.length; i++) {
        final recording = recordings[i];
        developer.log(
          '📼 [HomeCubit] Recording $i: ${recording.title} (${recording.filePath})',
          name: 'VoiceBridge.Cubit',
        );
      }

      // Emit current state with recordings
      emit(_copyCurrentState(recordings: recordings, isLoadingRecordings: false, recordingsError: null));
      developer.log('📡 [HomeCubit] State updated with ${recordings.length} recordings', name: 'VoiceBridge.Cubit');
    } catch (e) {
      developer.log('❌ [HomeCubit] Error loading recordings: $e', name: 'VoiceBridge.Cubit', error: e);
      emit(_copyCurrentState(isLoadingRecordings: false, recordingsError: e.toString()));
    }
  }

  // Delete recording functionality
  Future<void> deleteRecording(String filePath) async {
    developer.log('🗑️ [HomeCubit] Deleting recording: $filePath', name: 'VoiceBridge.Cubit');

    try {
      // Delete file via service
      await _voiceMemoService.deleteRecording(filePath);
      developer.log('✅ [HomeCubit] Recording deleted successfully', name: 'VoiceBridge.Cubit');

      // Reload recordings list
      await loadRecordings();
    } catch (e) {
      developer.log('❌ [HomeCubit] Error deleting recording: $e', name: 'VoiceBridge.Cubit', error: e);
      emit(_copyCurrentState(recordingsError: 'Failed to delete recording: $e'));
    }
  }

  // Play recording by file path
  Future<void> playRecording(String filePath) async {
    developer.log('🔊 [HomeCubit] Playing recording: $filePath', name: 'VoiceBridge.Cubit');

    try {
      // Emit playback in progress state
      emit(_copyCurrentState(baseState: PlaybackInProgress(filePath: filePath)));

      // Start playback via audio service
      final String result = await _audioService.playRecording(filePath);
      developer.log('✅ [HomeCubit] Playback started: $result', name: 'VoiceBridge.Cubit');

      // Emit completed state
      emit(_copyCurrentState(baseState: PlaybackCompleted(filePath: filePath)));
    } catch (e) {
      developer.log('❌ [HomeCubit] Error during playback: $e', name: 'VoiceBridge.Cubit', error: e);
      emit(_copyCurrentState(baseState: PlaybackError(errorMessage: e.toString())));
    }
  }

  // Play last recording functionality
  Future<void> playLastRecording() async {
    developer.log('🔊 [HomeCubit] Starting playback process...', name: 'VoiceBridge.Cubit');

    if (_lastCompletedRecordingPath == null) {
      developer.log('❌ [HomeCubit] No recording available to play', name: 'VoiceBridge.Cubit');
      emit(const PlaybackError(errorMessage: 'No recording available to play'));
      return;
    }

    try {
      // Emit playback in progress state
      emit(PlaybackInProgress(filePath: _lastCompletedRecordingPath!));
      developer.log('📡 [HomeCubit] State changed to PlaybackInProgress', name: 'VoiceBridge.Cubit');

      // Start playback via audio service
      final String result = await _audioService.playRecording(_lastCompletedRecordingPath!);
      developer.log('✅ [HomeCubit] Playback started: $result', name: 'VoiceBridge.Cubit');

      // For now, immediately emit completed state
      // In the future, we could listen to playback completion events
      emit(PlaybackCompleted(filePath: _lastCompletedRecordingPath!));
      developer.log('🎵 [HomeCubit] State changed to PlaybackCompleted', name: 'VoiceBridge.Cubit');
    } catch (e) {
      developer.log('❌ [HomeCubit] Error during playback: $e', name: 'VoiceBridge.Cubit', error: e);
      emit(PlaybackError(errorMessage: e.toString()));
    }
  }

  // Stop recording functionality
  Future<void> stopRecording() async {
    developer.log('⏹️ [HomeCubit] Stopping recording process...', name: 'VoiceBridge.Cubit');
    developer.log('⏹️ [HomeCubit] Current recording path: $_currentRecordingPath', name: 'VoiceBridge.Cubit');

    try {
      // Stop recording
      developer.log('🛑 [HomeCubit] Calling audio service stopRecording...', name: 'VoiceBridge.Cubit');
      final String finalPath = await _audioService.stopRecording();
      developer.log('✅ [HomeCubit] Recording stopped at path: $finalPath', name: 'VoiceBridge.Cubit');

      // Stop timer
      _stopRecordingTimer();

      // Create voice memo record
      developer.log('💾 [HomeCubit] Creating voice memo record...', name: 'VoiceBridge.Cubit');
      await _createVoiceMemo(finalPath);

      // Store last completed recording path for playback
      _lastCompletedRecordingPath = finalPath;

      // Emit completed state
      emit(
        _copyCurrentState(
          baseState: RecordingCompleted(recordingPath: finalPath, recordingDuration: _recordingDuration),
        ),
      );
      developer.log('✅ [HomeCubit] State changed to RecordingCompleted', name: 'VoiceBridge.Cubit');

      // Reset state
      _resetRecordingState();

      // Reload recordings list to include the new recording
      await loadRecordings();

      // Start transcription of the recorded audio (optional - don't fail recording if this fails)
      try {
        developer.log('🤖 [HomeCubit] Starting automatic transcription...', name: 'VoiceBridge.Cubit');
        await transcribeRecording(finalPath);
      } catch (e) {
        developer.log(
          '⚠️ [HomeCubit] Automatic transcription failed, but recording saved successfully: $e',
          name: 'VoiceBridge.Cubit',
        );
        // Don't rethrow - recording is saved, transcription can be retried manually
      }
    } catch (e) {
      developer.log('❌ [HomeCubit] Error stopping recording: $e', name: 'VoiceBridge.Cubit', error: e);
      _stopRecordingTimer();
      emit(RecordingError(errorMessage: e.toString()));
    }
  }

  // Transcribe recording functionality
  Future<void> transcribeRecording(String audioFilePath) async {
    developer.log('🤖 [HomeCubit] Starting transcription for: $audioFilePath', name: 'VoiceBridge.Cubit');

    try {
      // Validate input
      if (audioFilePath.isEmpty) {
        throw ArgumentError('Audio file path cannot be empty');
      }

      // Emit transcription in progress state
      emit(_copyCurrentState(baseState: TranscriptionInProgress(audioFilePath: audioFilePath)));
      developer.log('📡 [HomeCubit] State changed to TranscriptionInProgress', name: 'VoiceBridge.Cubit');

      // Ensure transcription service is initialized before proceeding
      developer.log('🔍 [HomeCubit] Checking if transcription service is initialized...', name: 'VoiceBridge.Cubit');
      final isInitialized = await _transcriptionService.isInitialized();
      if (!isInitialized) {
        developer.log(
          '🔧 [HomeCubit] Transcription service not initialized, initializing now...',
          name: 'VoiceBridge.Cubit',
        );
        await _transcriptionService.initialize();
        developer.log('✅ [HomeCubit] Transcription service initialized successfully', name: 'VoiceBridge.Cubit');
      } else {
        developer.log('✅ [HomeCubit] Transcription service already initialized', name: 'VoiceBridge.Cubit');
      }

      // Perform transcription with null safety
      developer.log('🎵 [HomeCubit] Starting audio transcription...', name: 'VoiceBridge.Cubit');
      final transcribedText = await _transcriptionService.transcribeAudio(audioFilePath);

      // Validate transcription result
      if (transcribedText.isEmpty) {
        developer.log('⚠️ [HomeCubit] Transcription returned empty text', name: 'VoiceBridge.Cubit');
        throw Exception(
          'Transcription returned empty result. This might be due to:\n'
          '• Silent audio or no speech detected\n'
          '• Audio format compatibility issues\n'
          '• Whisper model initialization problems',
        );
      }

      developer.log(
        '✅ [HomeCubit] Transcription completed: ${transcribedText.length} characters',
        name: 'VoiceBridge.Cubit',
      );

      // Extract keywords with null safety
      List<String> keywords = [];
      try {
        keywords = await _transcriptionService.extractKeywords(transcribedText);
        developer.log('🔍 [HomeCubit] Keywords extracted: ${keywords.join(', ')}', name: 'VoiceBridge.Cubit');
      } catch (e) {
        developer.log('⚠️ [HomeCubit] Keyword extraction failed: $e', name: 'VoiceBridge.Cubit');
        // Continue with empty keywords list instead of failing the whole transcription
      }

      // Emit transcription completed state
      emit(
        _copyCurrentState(
          baseState: TranscriptionCompleted(
            audioFilePath: audioFilePath,
            transcribedText: transcribedText,
            extractedKeywords: keywords,
          ),
        ),
      );
      developer.log('📡 [HomeCubit] State changed to TranscriptionCompleted', name: 'VoiceBridge.Cubit');

      // Log the results for debugging
      developer.log('📝 [HomeCubit] TRANSCRIPTION RESULT:', name: 'VoiceBridge.Transcription');
      developer.log('📁 [HomeCubit] File: $audioFilePath', name: 'VoiceBridge.Transcription');
      developer.log('📝 [HomeCubit] Text: $transcribedText', name: 'VoiceBridge.Transcription');
      developer.log('🏷️ [HomeCubit] Keywords: ${keywords.join(', ')}', name: 'VoiceBridge.Transcription');
    } catch (e) {
      developer.log('❌ [HomeCubit] Error during transcription: $e', name: 'VoiceBridge.Cubit', error: e);
      developer.log('❌ [HomeCubit] Error type: ${e.runtimeType}', name: 'VoiceBridge.Cubit');
      developer.log('❌ [HomeCubit] Stack trace: ${StackTrace.current}', name: 'VoiceBridge.Cubit');

      emit(
        _copyCurrentState(
          baseState: TranscriptionError(
            audioFilePath: audioFilePath,
            errorMessage: 'Transcription failed: ${e.toString()}',
          ),
        ),
      );
    }
  }

  // Private helper methods
  void _startRecordingTimer() {
    developer.log('⏱️ [HomeCubit] Starting recording timer', name: 'VoiceBridge.Timer');

    _recordingDuration = Duration.zero;
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingSeconds++;
      developer.log('⏱️ [HomeCubit] Recording time: $_recordingSeconds seconds', name: 'VoiceBridge.Timer');

      _recordingDuration = Duration(seconds: _recordingSeconds);
      if (state is RecordingInProgress) {
        emit(RecordingInProgress(recordingPath: _currentRecordingPath, recordingDuration: _recordingDuration));
      }
    });
  }

  void _stopRecordingTimer() {
    developer.log('⏹️ [HomeCubit] Stopping recording timer', name: 'VoiceBridge.Timer');

    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<void> _createVoiceMemo(String filePath) async {
    try {
      developer.log('📝 [HomeCubit] Creating voice memo for file: $filePath', name: 'VoiceBridge.Cubit');

      final VoiceMemo voiceMemo = VoiceMemo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: filePath,
        title: 'Voice Memo ${DateTime.now().day}/${DateTime.now().month}',
        keywords: const <String>[],
        createdAt: DateTime.now(),
        durationSeconds: _recordingDuration.inSeconds,
        fileSizeBytes: 0.0, // TODO: Calculate actual file size
        isTranscribed: false,
        status: VoiceMemoStatus.completed,
      );

      developer.log('💾 [HomeCubit] Calling voiceMemoService.saveVoiceMemo...', name: 'VoiceBridge.Cubit');
      await _voiceMemoService.saveVoiceMemo(voiceMemo);
      developer.log('✅ [HomeCubit] Voice memo saved successfully', name: 'VoiceBridge.Cubit');
    } catch (e) {
      // Log error but don't fail the recording completion
      developer.log('❌ [HomeCubit] Error saving voice memo: $e', name: 'VoiceBridge.Cubit', error: e);
    }
  }

  void _resetRecordingState() {
    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
    _recordingSeconds = 0;
    // Note: We keep _lastCompletedRecordingPath for playback functionality
  }

  // Getter to check if playback is available
  bool get hasRecordingToPlay => _lastCompletedRecordingPath != null;

  // Test transcription functionality with a dummy file
  Future<void> testTranscription() async {
    developer.log('🧪 [HomeCubit] Testing transcription functionality...', name: 'VoiceBridge.Cubit');

    try {
      // Emit transcription in progress state
      emit(_copyCurrentState(baseState: const TranscriptionInProgress(audioFilePath: 'test')));

      // Test the transcription service initialization
      final isInitialized = await _transcriptionService.isInitialized();
      if (!isInitialized) {
        developer.log('🔧 [HomeCubit] Initializing transcription service...', name: 'VoiceBridge.Cubit');
        await _transcriptionService.initialize();
      }

      // Test with mock text if we can't find a real audio file
      const testText = 'This is a test transcription to verify the UI is working correctly.';
      const testKeywords = ['test', 'transcription', 'working', 'correctly'];

      developer.log('✅ [HomeCubit] Test transcription completed', name: 'VoiceBridge.Cubit');

      // Emit test transcription completed state
      emit(
        _copyCurrentState(
          baseState: const TranscriptionCompleted(
            audioFilePath: 'test',
            transcribedText: testText,
            extractedKeywords: testKeywords,
          ),
        ),
      );
    } catch (e) {
      developer.log('❌ [HomeCubit] Test transcription failed: $e', name: 'VoiceBridge.Cubit', error: e);
      emit(
        _copyCurrentState(
          baseState: TranscriptionError(audioFilePath: 'test', errorMessage: e.toString()),
        ),
      );
    }
  }

  // Helper method to copy current state with updated recordings data
  HomeState _copyCurrentState({
    List<VoiceMemo>? recordings,
    bool? isLoadingRecordings,
    String? recordingsError,
    HomeState? baseState,
    String? transcriptionText,
    bool? isTranscribing,
    String? transcriptionError,
    List<String>? keywords,
  }) {
    final currentState = state;

    // Use provided base state or current state type
    if (baseState != null) {
      // For new state types (like PlaybackInProgress), include recordings data
      if (baseState is PlaybackInProgress) {
        return PlaybackInProgress(
          filePath: baseState.filePath,
          recordings: recordings ?? currentState.recordings,
          isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
          recordingsError: recordingsError ?? currentState.recordingsError,
          transcriptionText: transcriptionText ?? currentState.transcriptionText,
          isTranscribing: isTranscribing ?? currentState.isTranscribing,
          transcriptionError: transcriptionError ?? currentState.transcriptionError,
          keywords: keywords ?? currentState.keywords,
        );
      } else if (baseState is PlaybackCompleted) {
        return PlaybackCompleted(
          filePath: baseState.filePath,
          recordings: recordings ?? currentState.recordings,
          isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
          recordingsError: recordingsError ?? currentState.recordingsError,
          transcriptionText: transcriptionText ?? currentState.transcriptionText,
          isTranscribing: isTranscribing ?? currentState.isTranscribing,
          transcriptionError: transcriptionError ?? currentState.transcriptionError,
          keywords: keywords ?? currentState.keywords,
        );
      } else if (baseState is PlaybackError) {
        return PlaybackError(
          errorMessage: baseState.errorMessage,
          recordings: recordings ?? currentState.recordings,
          isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
          recordingsError: recordingsError ?? currentState.recordingsError,
          transcriptionText: transcriptionText ?? currentState.transcriptionText,
          isTranscribing: isTranscribing ?? currentState.isTranscribing,
          transcriptionError: transcriptionError ?? currentState.transcriptionError,
          keywords: keywords ?? currentState.keywords,
        );
      } else if (baseState is TranscriptionInProgress) {
        return TranscriptionInProgress(
          audioFilePath: baseState.audioFilePath,
          recordings: recordings ?? currentState.recordings,
          isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
          recordingsError: recordingsError ?? currentState.recordingsError,
          transcriptionText: transcriptionText ?? currentState.transcriptionText,
          isTranscribing: isTranscribing ?? baseState.isTranscribing,
          transcriptionError: transcriptionError ?? currentState.transcriptionError,
          keywords: keywords ?? currentState.keywords,
        );
      } else if (baseState is TranscriptionCompleted) {
        return TranscriptionCompleted(
          audioFilePath: baseState.audioFilePath,
          transcribedText: baseState.transcribedText,
          extractedKeywords: baseState.extractedKeywords,
          recordings: recordings ?? currentState.recordings,
          isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
          recordingsError: recordingsError ?? currentState.recordingsError,
          transcriptionText: transcriptionText ?? baseState.transcribedText,
          isTranscribing: isTranscribing ?? baseState.isTranscribing,
          transcriptionError: transcriptionError ?? currentState.transcriptionError,
          keywords: keywords ?? baseState.extractedKeywords,
        );
      } else if (baseState is TranscriptionError) {
        return TranscriptionError(
          audioFilePath: baseState.audioFilePath,
          errorMessage: baseState.errorMessage,
          recordings: recordings ?? currentState.recordings,
          isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
          recordingsError: recordingsError ?? currentState.recordingsError,
          transcriptionText: transcriptionText ?? currentState.transcriptionText,
          isTranscribing: isTranscribing ?? baseState.isTranscribing,
          transcriptionError: transcriptionError ?? baseState.errorMessage,
          keywords: keywords ?? currentState.keywords,
        );
      }
    }

    // Copy existing state with updated recordings data
    if (currentState is HomeInitial) {
      return HomeInitial(
        recordings: recordings ?? currentState.recordings,
        isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
        recordingsError: recordingsError ?? currentState.recordingsError,
        transcriptionText: transcriptionText ?? currentState.transcriptionText,
        isTranscribing: isTranscribing ?? currentState.isTranscribing,
        transcriptionError: transcriptionError ?? currentState.transcriptionError,
        keywords: keywords ?? currentState.keywords,
      );
    } else if (currentState is RecordingInProgress) {
      return RecordingInProgress(
        recordingPath: currentState.recordingPath,
        recordingDuration: currentState.recordingDuration,
        recordings: recordings ?? currentState.recordings,
        isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
        recordingsError: recordingsError ?? currentState.recordingsError,
        transcriptionText: transcriptionText ?? currentState.transcriptionText,
        isTranscribing: isTranscribing ?? currentState.isTranscribing,
        transcriptionError: transcriptionError ?? currentState.transcriptionError,
        keywords: keywords ?? currentState.keywords,
      );
    } else if (currentState is RecordingStarted) {
      return RecordingStarted(
        recordingPath: currentState.recordingPath,
        recordings: recordings ?? currentState.recordings,
        isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
        recordingsError: recordingsError ?? currentState.recordingsError,
        transcriptionText: transcriptionText ?? currentState.transcriptionText,
        isTranscribing: isTranscribing ?? currentState.isTranscribing,
        transcriptionError: transcriptionError ?? currentState.transcriptionError,
        keywords: keywords ?? currentState.keywords,
      );
    } else if (currentState is RecordingCompleted) {
      return RecordingCompleted(
        recordingPath: currentState.recordingPath,
        recordingDuration: currentState.recordingDuration,
        recordings: recordings ?? currentState.recordings,
        isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
        recordingsError: recordingsError ?? currentState.recordingsError,
        transcriptionText: transcriptionText ?? currentState.transcriptionText,
        isTranscribing: isTranscribing ?? currentState.isTranscribing,
        transcriptionError: transcriptionError ?? currentState.transcriptionError,
        keywords: keywords ?? currentState.keywords,
      );
    } else if (currentState is RecordingError) {
      return RecordingError(
        errorMessage: currentState.errorMessage,
        recordings: recordings ?? currentState.recordings,
        isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
        recordingsError: recordingsError ?? currentState.recordingsError,
        transcriptionText: transcriptionText ?? currentState.transcriptionText,
        isTranscribing: isTranscribing ?? currentState.isTranscribing,
        transcriptionError: transcriptionError ?? currentState.transcriptionError,
        keywords: keywords ?? currentState.keywords,
      );
    }

    // Default fallback to HomeInitial
    return HomeInitial(
      recordings: recordings ?? currentState.recordings,
      isLoadingRecordings: isLoadingRecordings ?? currentState.isLoadingRecordings,
      recordingsError: recordingsError ?? currentState.recordingsError,
      transcriptionText: transcriptionText ?? currentState.transcriptionText,
      isTranscribing: isTranscribing ?? currentState.isTranscribing,
      transcriptionError: transcriptionError ?? currentState.transcriptionError,
      keywords: keywords ?? currentState.keywords,
    );
  }

  @override
  Future<void> close() async {
    developer.log('🔄 [HomeCubit] Closing cubit, cleaning up resources', name: 'VoiceBridge.Cubit');
    _stopRecordingTimer();

    // Clean up transcription service
    try {
      await _transcriptionService.dispose();
      developer.log('✅ [HomeCubit] Transcription service disposed', name: 'VoiceBridge.Cubit');
    } catch (e) {
      developer.log('⚠️ [HomeCubit] Error disposing transcription service: $e', name: 'VoiceBridge.Cubit', error: e);
    }

    return super.close();
  }
}
