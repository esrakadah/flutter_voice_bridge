import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/errors/voice_bridge_error.dart';
import '../../../core/platform/voice_bridge_channels.dart';
import '../../../core/transcription/transcription_service.dart';
import '../../../data/models/voice_memo.dart';
import '../../../data/services/voice_memo_service.dart';
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
/// - Dependency Injection: Services and the clock are injected via the constructor
/// - State Immutability: one immutable [HomeState], changed only through `copyWith`
/// - Error Handling: typed failures become user-facing messages
///
/// **Architecture Layer:** Business Logic (between UI and Data layers)
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required AudioService audioService,
    required VoiceMemoService voiceMemoService,
    required TranscriptionService transcriptionService,
    DateTime Function()? clock,
  }) : _audioService = audioService,
       _voiceMemoService = voiceMemoService,
       _transcriptionService = transcriptionService,
       _clock = clock ?? DateTime.now,
       super(const HomeState()) {
    _initializeTranscriptionService();
    loadRecordings();
  }

  static const String _logName = 'VoiceBridge.Cubit';
  static const Duration _timerTick = Duration(seconds: 1);

  final AudioService _audioService;
  final VoiceMemoService _voiceMemoService;

  /// Shared app-wide singleton; owned and disposed by the DI container, never by this cubit.
  final TranscriptionService _transcriptionService;
  final DateTime Function() _clock;

  Timer? _recordingTimer;
  bool _isRecorderBusy = false;

  Future<void> _initializeTranscriptionService() async {
    try {
      await _transcriptionService.initialize();
      developer.log('✅ [HomeCubit] Transcription service initialized', name: _logName);
    } catch (error) {
      developer.log('❌ [HomeCubit] Transcription service failed to initialize: $error', name: _logName, error: error);
    }
  }

  Future<void> startRecording() async {
    // A second tap while the first start is still in flight must not reach the recorder.
    if (_isRecorderBusy || state.isRecording) return;
    _isRecorderBusy = true;
    try {
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        await _audioService.requestPermission();
      }
      await _audioService.startRecording();
      _enterRecordingPhase();
    } on RecordingFailure catch (failure) {
      if (failure.platformCode == VoiceBridgeErrorCodes.alreadyRecording) {
        // The native recorder is running (for example after a hot restart): show it so it can be stopped.
        _enterRecordingPhase();
      } else {
        _emitRecordingFailure(failure, context: 'HomeCubit.startRecording');
      }
    } catch (error) {
      _emitRecordingFailure(error, context: 'HomeCubit.startRecording');
    } finally {
      _isRecorderBusy = false;
    }
  }

  void _enterRecordingPhase() {
    emit(
      state.copyWith(
        recordingPhase: RecordingPhase.recording,
        recordingDuration: Duration.zero,
        recordingError: () => null,
        transcriptionText: () => null,
        transcriptionError: () => null,
        transcriptionFilePath: () => null,
        keywords: const [],
      ),
    );
    _startRecordingTimer();
  }

  Future<void> stopRecording() async {
    if (_isRecorderBusy || !state.isRecording) return;
    _isRecorderBusy = true;
    _stopRecordingTimer();
    try {
      final finalPath = await _audioService.stopRecording();
      await _createVoiceMemo(finalPath);
      emit(state.copyWith(recordingPhase: RecordingPhase.completed, lastRecordingPath: () => finalPath));
    } catch (error) {
      _emitRecordingFailure(error, context: 'HomeCubit.stopRecording');
      return;
    } finally {
      _isRecorderBusy = false;
    }

    await loadRecordings();
    final finalPath = state.lastRecordingPath;
    if (finalPath != null) await transcribeRecording(finalPath);
  }

  Future<void> loadRecordings() async {
    emit(state.copyWith(isLoadingRecordings: true, recordingsError: () => null));
    try {
      final recordings = await _voiceMemoService.listRecordings();
      emit(state.copyWith(recordings: recordings, isLoadingRecordings: false));
    } catch (error) {
      developer.log('❌ [HomeCubit] Error loading recordings: $error', name: _logName, error: error);
      emit(state.copyWith(isLoadingRecordings: false, recordingsError: () => error.toString()));
    }
  }

  Future<void> deleteRecording(String filePath) async {
    final remaining = state.recordings.where((memo) => memo.filePath != filePath).toList();
    emit(_forgetFile(state.copyWith(recordings: remaining), filePath));
    try {
      await _voiceMemoService.deleteRecording(filePath);
    } catch (error) {
      emit(state.copyWith(recordingsError: () => 'Failed to delete recording: $error'));
      await loadRecordings();
    }
  }

  Future<void> deleteAllRecordings() async {
    emit(
      state.copyWith(
        recordings: const [],
        recordingPhase: state.isRecording ? null : RecordingPhase.idle,
        lastRecordingPath: () => null,
        transcriptionFilePath: () => null,
        transcriptionText: () => null,
        transcriptionError: () => null,
        keywords: const [],
      ),
    );
    try {
      await _voiceMemoService.deleteAllRecordings();
    } catch (error) {
      emit(state.copyWith(recordingsError: () => 'Failed to delete all recordings: $error'));
      await loadRecordings();
    }
  }

  /// Drops every reference to a deleted file, so retry and the status card never point at it.
  HomeState _forgetFile(HomeState current, String filePath) {
    var next = current;
    if (next.lastRecordingPath == filePath) {
      next = next.copyWith(
        lastRecordingPath: () => null,
        recordingPhase: next.isRecording ? null : RecordingPhase.idle,
      );
    }
    if (next.transcriptionFilePath == filePath) {
      next = next.copyWith(
        transcriptionFilePath: () => null,
        transcriptionText: () => null,
        transcriptionError: () => null,
        keywords: const [],
      );
    }
    return next;
  }

  Future<void> playRecording(String filePath) async {
    emit(
      state.copyWith(
        playingFilePath: () => filePath,
        playbackError: () => null,
        recordingPhase: state.isRecording ? null : RecordingPhase.idle,
      ),
    );
    try {
      await _audioService.playRecording(filePath);
      emit(state.copyWith(playingFilePath: () => null));
    } catch (error) {
      developer.log('❌ [HomeCubit] Error during playback: $error', name: _logName, error: error);
      emit(state.copyWith(playingFilePath: () => null, playbackError: () => _userMessageFor(error)));
    }
  }

  Future<void> transcribeRecording(String audioFilePath) async {
    if (audioFilePath.isEmpty) {
      emit(state.copyWith(transcriptionError: () => 'Transcription failed: no audio file selected'));
      return;
    }

    emit(
      state.copyWith(
        transcribingFilePath: () => audioFilePath,
        transcriptionFilePath: () => audioFilePath,
        transcriptionText: () => null,
        transcriptionError: () => null,
        keywords: const [],
      ),
    );

    // A newer transcription may start while this one waits; only the latest one may update the screen.
    bool isStillCurrent() => state.transcribingFilePath == audioFilePath;

    try {
      if (!await _transcriptionService.isInitialized()) {
        await _transcriptionService.initialize();
      }

      final transcribedText = await _transcriptionService.transcribeAudio(audioFilePath);
      if (transcribedText.isEmpty) {
        throw const TranscriptionFailure(
          details: 'No speech detected (silent audio, unsupported format or a model problem)',
          type: TranscriptionErrorType.processingFailed,
        );
      }

      final keywords = await _extractKeywordsOrEmpty(transcribedText);
      final savedMemo = await _saveTranscriptionOrNull(audioFilePath, transcribedText, keywords);
      if (!isStillCurrent()) return;
      emit(
        state.copyWith(
          transcribingFilePath: () => null,
          transcriptionText: () => transcribedText,
          keywords: keywords,
          recordings: savedMemo == null ? null : _withUpdatedMemo(savedMemo),
        ),
      );
    } catch (error) {
      developer.log('❌ [HomeCubit] Transcription failed: $error', name: _logName, error: error);
      if (!isStillCurrent()) return;
      emit(
        state.copyWith(
          transcribingFilePath: () => null,
          transcriptionError: () => 'Transcription failed: ${_detailsFor(error)}',
        ),
      );
    }
  }

  /// Retries the file whose transcription is on screen, else the last recording, else the newest file.
  Future<void> retryLastTranscription() async {
    final path =
        state.transcriptionFilePath ??
        state.lastRecordingPath ??
        (state.recordings.isNotEmpty ? state.recordings.first.filePath : null);
    if (path == null) {
      emit(state.copyWith(transcriptionError: () => 'No recording available to transcribe'));
      return;
    }
    await transcribeRecording(path);
  }

  /// A failed save must not hide a transcript the user can already read.
  Future<VoiceMemo?> _saveTranscriptionOrNull(String filePath, String text, List<String> keywords) async {
    try {
      return await _voiceMemoService.saveTranscription(filePath, text: text, keywords: keywords);
    } catch (error) {
      developer.log('⚠️ [HomeCubit] Could not save the transcription: $error', name: _logName);
      return null;
    }
  }

  List<VoiceMemo> _withUpdatedMemo(VoiceMemo memo) => [
    for (final recording in state.recordings) recording.filePath == memo.filePath ? memo : recording,
  ];

  Future<List<String>> _extractKeywordsOrEmpty(String text) async {
    try {
      return await _transcriptionService.extractKeywords(text);
    } catch (error) {
      developer.log('⚠️ [HomeCubit] Keyword extraction failed: $error', name: _logName);
      return const [];
    }
  }

  void _emitRecordingFailure(Object error, {required String context}) {
    final failure = _failureFor(error);
    ErrorHelpers.logError(failure, context: context);
    emit(state.copyWith(recordingPhase: RecordingPhase.failed, recordingError: () => failure.userMessage));
  }

  VoiceBridgeError _failureFor(Object error) {
    if (error is VoiceBridgeError) return error;
    return ErrorHelpers.fromException(error is Exception ? error : Exception(error.toString()));
  }

  String _userMessageFor(Object error) => _failureFor(error).userMessage;

  /// The reason without a "Transcription failed:" prefix, which the caller adds once.
  String _detailsFor(Object error) => switch (error) {
    TranscriptionFailure(:final details) => details,
    VoiceBridgeError(:final message) => message,
    _ => error.toString(),
  };

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(_timerTick, (_) {
      if (!state.isRecording) return;
      emit(state.copyWith(recordingDuration: state.recordingDuration + _timerTick));
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<void> _createVoiceMemo(String filePath) async {
    try {
      final fileStat = await File(filePath).stat();
      final createdAt = _clock();
      final voiceMemo = VoiceMemo(
        id: createdAt.millisecondsSinceEpoch.toString(),
        filePath: filePath,
        title: VoiceMemo.defaultTitle(createdAt),
        keywords: const <String>[],
        createdAt: createdAt,
        durationSeconds: state.recordingDuration.inSeconds,
        fileSizeBytes: fileStat.size.toDouble(),
        isTranscribed: false,
        status: VoiceMemoStatus.completed,
      );
      await _voiceMemoService.saveVoiceMemo(voiceMemo);
    } catch (error) {
      developer.log('❌ [HomeCubit] Error saving voice memo: $error', name: _logName, error: error);
    }
  }

  /// Async work (loading, transcription) can finish after the screen is gone; drop those late updates.
  @override
  void emit(HomeState state) {
    if (isClosed) return;
    super.emit(state);
  }

  @override
  Future<void> close() {
    _stopRecordingTimer();
    return super.close();
  }
}
