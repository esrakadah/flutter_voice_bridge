import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../core/audio/audio_service.dart';
import '../../../core/transcription/transcription_service.dart';
import '../../../data/services/voice_memo_service.dart';
import '../../../data/models/voice_memo.dart';
import 'home_state.dart';

// Home Cubit for managing audio recording state
// Handles all business logic for the home screen recording functionality

class HomeCubit extends Cubit<HomeState> {
  final AudioService _audioService;
  final VoiceMemoService _voiceMemoService;
  final TranscriptionService _transcriptionService;

  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;
  String? _lastCompletedRecordingPath;
  int _recordingSeconds = 0;

  HomeCubit({
    required AudioService audioService,
    required VoiceMemoService voiceMemoService,
    required TranscriptionService transcriptionService,
  }) : _audioService = audioService,
       _voiceMemoService = voiceMemoService,
       _transcriptionService = transcriptionService,
       super(const HomeInitial()) {
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

  // Start recording functionality
  Future<void> startRecording() async {
    developer.log('▶️ [HomeCubit] Starting recording process...', name: 'VoiceBridge.Cubit');

    try {
      // Check permissions first
      final bool hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        await _audioService.requestPermission();
      }

      // Start recording
      final String recordingPath = await _audioService.startRecording();
      _currentRecordingPath = recordingPath;

      // Emit started state
      emit(RecordingStarted(recordingPath: recordingPath));
      developer.log('📡 [HomeCubit] State changed to RecordingStarted', name: 'VoiceBridge.Cubit');

      // Start timer for recording duration
      _startRecordingTimer();
      emit(const RecordingInProgress());
      developer.log('⏺️ [HomeCubit] State changed to RecordingInProgress, timer started', name: 'VoiceBridge.Cubit');
    } catch (e) {
      developer.log('❌ [HomeCubit] Error starting recording: $e', name: 'VoiceBridge.Cubit', error: e);

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
      final List<VoiceMemo> recordings = await _voiceMemoService.listRecordings();
      developer.log('✅ [HomeCubit] Loaded ${recordings.length} recordings', name: 'VoiceBridge.Cubit');

      // Emit current state with recordings
      emit(_copyCurrentState(recordings: recordings, isLoadingRecordings: false, recordingsError: null));
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

    try {
      // Stop recording
      final String finalPath = await _audioService.stopRecording();

      // Stop timer
      _stopRecordingTimer();

      // Create voice memo record
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

      // Start transcription of the recorded audio
      await transcribeRecording(finalPath);
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
      // Emit transcription in progress state
      emit(_copyCurrentState(baseState: TranscriptionInProgress(audioFilePath: audioFilePath)));
      developer.log('📡 [HomeCubit] State changed to TranscriptionInProgress', name: 'VoiceBridge.Cubit');

      // Perform transcription
      final transcribedText = await _transcriptionService.transcribeAudio(audioFilePath);
      developer.log(
        '✅ [HomeCubit] Transcription completed: ${transcribedText.length} characters',
        name: 'VoiceBridge.Cubit',
      );

      // Extract keywords
      final keywords = await _transcriptionService.extractKeywords(transcribedText);
      developer.log('🔍 [HomeCubit] Keywords extracted: ${keywords.join(', ')}', name: 'VoiceBridge.Cubit');

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

      // Log the results for debugging (no UI yet)
      developer.log('📝 [HomeCubit] TRANSCRIPTION RESULT:', name: 'VoiceBridge.Transcription');
      developer.log('📁 [HomeCubit] File: $audioFilePath', name: 'VoiceBridge.Transcription');
      developer.log('📝 [HomeCubit] Text: $transcribedText', name: 'VoiceBridge.Transcription');
      developer.log('🏷️ [HomeCubit] Keywords: ${keywords.join(', ')}', name: 'VoiceBridge.Transcription');
    } catch (e) {
      developer.log('❌ [HomeCubit] Error during transcription: $e', name: 'VoiceBridge.Cubit', error: e);
      emit(
        _copyCurrentState(
          baseState: TranscriptionError(audioFilePath: audioFilePath, errorMessage: e.toString()),
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

      await _voiceMemoService.saveVoiceMemo(voiceMemo);
    } catch (e) {
      // Log error but don't fail the recording completion
      // In production, this would use a proper logging service
      // ignore: avoid_print
      print('Error saving voice memo: $e');
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
