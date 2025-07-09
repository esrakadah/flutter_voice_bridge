import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../core/audio/audio_service.dart';
import '../../../data/services/voice_memo_service.dart';
import '../../../data/models/voice_memo.dart';
import 'home_state.dart';

// Home Cubit for managing audio recording state
// Handles all business logic for the home screen recording functionality

class HomeCubit extends Cubit<HomeState> {
  final AudioService _audioService;
  final VoiceMemoService _voiceMemoService;

  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;
  String? _lastCompletedRecordingPath;
  int _recordingSeconds = 0;

  HomeCubit({required AudioService audioService, required VoiceMemoService voiceMemoService})
    : _audioService = audioService,
      _voiceMemoService = voiceMemoService,
      super(const HomeInitial()) {
    developer.log(
      '🏠 [HomeCubit] Initialized with audio service: ${_audioService.runtimeType}',
      name: 'VoiceBridge.Cubit',
    );
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
      emit(RecordingCompleted(recordingPath: finalPath, recordingDuration: _recordingDuration));
      developer.log('✅ [HomeCubit] State changed to RecordingCompleted', name: 'VoiceBridge.Cubit');

      // Reset state
      _resetRecordingState();
    } catch (e) {
      developer.log('❌ [HomeCubit] Error stopping recording: $e', name: 'VoiceBridge.Cubit', error: e);
      _stopRecordingTimer();
      emit(RecordingError(errorMessage: e.toString()));
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

  @override
  Future<void> close() {
    developer.log('🔄 [HomeCubit] Closing cubit, cleaning up timer', name: 'VoiceBridge.Cubit');
    _stopRecordingTimer();
    return super.close();
  }
}
