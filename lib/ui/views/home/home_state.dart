import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/voice_memo.dart';

/// Where the recorder is in its lifecycle.
enum RecordingPhase { idle, recording, completed, failed }

/// Everything the home screen shows, in one immutable value.
///
/// One class instead of a hierarchy: every field survives every transition unless a transition changes it on
/// purpose, so the recordings list can no longer disappear when the recorder changes phase.
///
/// Nullable fields are cleared through [copyWith] by passing a getter that returns null, for example
/// `state.copyWith(transcriptionError: () => null)`. Omitting the argument keeps the current value.
@immutable
class HomeState extends Equatable {
  const HomeState({
    this.recordingPhase = RecordingPhase.idle,
    this.recordingDuration = Duration.zero,
    this.recordingError,
    this.lastRecordingPath,
    this.playingFilePath,
    this.playbackError,
    this.recordings = const [],
    this.isLoadingRecordings = false,
    this.recordingsError,
    this.transcribingFilePath,
    this.transcriptionText,
    this.transcriptionError,
    this.keywords = const [],
  });

  final RecordingPhase recordingPhase;
  final Duration recordingDuration;
  final String? recordingError;

  /// The most recent finished recording; playback and transcription retry use it.
  final String? lastRecordingPath;

  final String? playingFilePath;
  final String? playbackError;

  final List<VoiceMemo> recordings;
  final bool isLoadingRecordings;
  final String? recordingsError;

  /// Set while a transcription runs; the file being transcribed.
  final String? transcribingFilePath;
  final String? transcriptionText;
  final String? transcriptionError;
  final List<String> keywords;

  bool get isRecording => recordingPhase == RecordingPhase.recording;
  bool get isTranscribing => transcribingFilePath != null;

  HomeState copyWith({
    RecordingPhase? recordingPhase,
    Duration? recordingDuration,
    ValueGetter<String?>? recordingError,
    ValueGetter<String?>? lastRecordingPath,
    ValueGetter<String?>? playingFilePath,
    ValueGetter<String?>? playbackError,
    List<VoiceMemo>? recordings,
    bool? isLoadingRecordings,
    ValueGetter<String?>? recordingsError,
    ValueGetter<String?>? transcribingFilePath,
    ValueGetter<String?>? transcriptionText,
    ValueGetter<String?>? transcriptionError,
    List<String>? keywords,
  }) {
    return HomeState(
      recordingPhase: recordingPhase ?? this.recordingPhase,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      recordingError: recordingError != null ? recordingError() : this.recordingError,
      lastRecordingPath: lastRecordingPath != null ? lastRecordingPath() : this.lastRecordingPath,
      playingFilePath: playingFilePath != null ? playingFilePath() : this.playingFilePath,
      playbackError: playbackError != null ? playbackError() : this.playbackError,
      recordings: recordings ?? this.recordings,
      isLoadingRecordings: isLoadingRecordings ?? this.isLoadingRecordings,
      recordingsError: recordingsError != null ? recordingsError() : this.recordingsError,
      transcribingFilePath: transcribingFilePath != null ? transcribingFilePath() : this.transcribingFilePath,
      transcriptionText: transcriptionText != null ? transcriptionText() : this.transcriptionText,
      transcriptionError: transcriptionError != null ? transcriptionError() : this.transcriptionError,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  List<Object?> get props => [
    recordingPhase,
    recordingDuration,
    recordingError,
    lastRecordingPath,
    playingFilePath,
    playbackError,
    recordings,
    isLoadingRecordings,
    recordingsError,
    transcribingFilePath,
    transcriptionText,
    transcriptionError,
    keywords,
  ];
}
