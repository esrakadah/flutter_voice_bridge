import 'package:equatable/equatable.dart';
import '../../../data/models/voice_memo.dart';

// Home view state management
// Defines all possible states for the home screen recording functionality

abstract class HomeState extends Equatable {
  final List<VoiceMemo> recordings;
  final bool isLoadingRecordings;
  final String? recordingsError;

  // Transcription-related state
  final String? transcriptionText;
  final bool isTranscribing;
  final String? transcriptionError;
  final List<String> keywords;

  const HomeState({
    this.recordings = const [],
    this.isLoadingRecordings = false,
    this.recordingsError,
    this.transcriptionText,
    this.isTranscribing = false,
    this.transcriptionError,
    this.keywords = const [],
  });

  @override
  List<Object?> get props => [
    recordings,
    isLoadingRecordings,
    recordingsError,
    transcriptionText,
    isTranscribing,
    transcriptionError,
    keywords,
  ];
}

class HomeInitial extends HomeState {
  const HomeInitial({
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing,
    super.transcriptionError,
    super.keywords,
  });
}

class RecordingInProgress extends HomeState {
  final String? recordingPath;
  final Duration recordingDuration;

  const RecordingInProgress({
    this.recordingPath,
    this.recordingDuration = Duration.zero,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing,
    super.transcriptionError,
    super.keywords,
  });

  @override
  List<Object?> get props => [...super.props, recordingPath, recordingDuration];
}

class RecordingStarted extends HomeState {
  final String recordingPath;

  const RecordingStarted({
    required this.recordingPath,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing,
    super.transcriptionError,
    super.keywords,
  });

  @override
  List<Object?> get props => [...super.props, recordingPath];
}

class RecordingCompleted extends HomeState {
  final String recordingPath;
  final Duration recordingDuration;

  const RecordingCompleted({
    required this.recordingPath,
    required this.recordingDuration,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing,
    super.transcriptionError,
    super.keywords,
  });

  @override
  List<Object?> get props => [...super.props, recordingPath, recordingDuration];
}

class RecordingError extends HomeState {
  final String errorMessage;

  const RecordingError({
    required this.errorMessage,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing,
    super.transcriptionError,
    super.keywords,
  });

  @override
  List<Object?> get props => [...super.props, errorMessage];
}

// Playback States
class PlaybackInProgress extends HomeState {
  final String filePath;

  const PlaybackInProgress({
    required this.filePath,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing,
    super.transcriptionError,
    super.keywords,
  });

  @override
  List<Object?> get props => [...super.props, filePath];
}

class PlaybackCompleted extends HomeState {
  final String filePath;

  const PlaybackCompleted({
    required this.filePath,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing,
    super.transcriptionError,
    super.keywords,
  });

  @override
  List<Object?> get props => [...super.props, filePath];
}

class PlaybackError extends HomeState {
  final String errorMessage;

  const PlaybackError({
    required this.errorMessage,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing,
    super.transcriptionError,
    super.keywords,
  });

  @override
  List<Object?> get props => [...super.props, errorMessage];
}

// Transcription States
class TranscriptionInProgress extends HomeState {
  final String audioFilePath;

  const TranscriptionInProgress({
    required this.audioFilePath,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing = true,
    super.transcriptionError,
    super.keywords,
  });

  @override
  List<Object?> get props => [...super.props, audioFilePath];
}

class TranscriptionCompleted extends HomeState {
  final String audioFilePath;
  final String transcribedText;
  final List<String> extractedKeywords;

  const TranscriptionCompleted({
    required this.audioFilePath,
    required this.transcribedText,
    required this.extractedKeywords,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    String? transcriptionText,
    super.isTranscribing = false,
    super.transcriptionError,
    List<String>? keywords,
  }) : super(transcriptionText: transcriptionText ?? transcribedText, keywords: keywords ?? extractedKeywords);

  @override
  List<Object?> get props => [...super.props, audioFilePath, transcribedText, extractedKeywords];
}

class TranscriptionError extends HomeState {
  final String audioFilePath;
  final String errorMessage;

  const TranscriptionError({
    required this.audioFilePath,
    required this.errorMessage,
    super.recordings,
    super.isLoadingRecordings,
    super.recordingsError,
    super.transcriptionText,
    super.isTranscribing = false,
    String? transcriptionError,
    super.keywords,
  }) : super(transcriptionError: transcriptionError ?? errorMessage);

  @override
  List<Object?> get props => [...super.props, audioFilePath, errorMessage];
}
