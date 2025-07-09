import 'package:equatable/equatable.dart';
import '../../../data/models/voice_memo.dart';

// Home view state management
// Defines all possible states for the home screen recording functionality

abstract class HomeState extends Equatable {
  final List<VoiceMemo> recordings;
  final bool isLoadingRecordings;
  final String? recordingsError;

  const HomeState({this.recordings = const [], this.isLoadingRecordings = false, this.recordingsError});

  @override
  List<Object?> get props => [recordings, isLoadingRecordings, recordingsError];
}

class HomeInitial extends HomeState {
  const HomeInitial({super.recordings, super.isLoadingRecordings, super.recordingsError});
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
  });

  @override
  List<Object?> get props => [...super.props, filePath];
}

class PlaybackCompleted extends HomeState {
  final String filePath;

  const PlaybackCompleted({required this.filePath, super.recordings, super.isLoadingRecordings, super.recordingsError});

  @override
  List<Object?> get props => [...super.props, filePath];
}

class PlaybackError extends HomeState {
  final String errorMessage;

  const PlaybackError({required this.errorMessage, super.recordings, super.isLoadingRecordings, super.recordingsError});

  @override
  List<Object?> get props => [...super.props, errorMessage];
}
