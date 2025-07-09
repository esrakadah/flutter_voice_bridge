import 'package:equatable/equatable.dart';

// Home view state management
// Defines all possible states for the home screen recording functionality

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class RecordingInProgress extends HomeState {
  final String? recordingPath;
  final Duration recordingDuration;

  const RecordingInProgress({this.recordingPath, this.recordingDuration = Duration.zero});

  @override
  List<Object?> get props => [recordingPath, recordingDuration];
}

class RecordingStarted extends HomeState {
  final String recordingPath;

  const RecordingStarted({required this.recordingPath});

  @override
  List<Object?> get props => [recordingPath];
}

class RecordingCompleted extends HomeState {
  final String recordingPath;
  final Duration recordingDuration;

  const RecordingCompleted({required this.recordingPath, required this.recordingDuration});

  @override
  List<Object?> get props => [recordingPath, recordingDuration];
}

class RecordingError extends HomeState {
  final String errorMessage;

  const RecordingError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

// Playback States
class PlaybackInProgress extends HomeState {
  final String filePath;

  const PlaybackInProgress({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class PlaybackCompleted extends HomeState {
  final String filePath;

  const PlaybackCompleted({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class PlaybackError extends HomeState {
  final String errorMessage;

  const PlaybackError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
