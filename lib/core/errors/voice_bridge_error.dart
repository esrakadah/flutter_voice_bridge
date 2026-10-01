/// Voice Bridge Error System
/// Provides typed errors with user-friendly messages and recovery suggestions
library;

import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import '../platform/voice_bridge_channels.dart';

abstract class VoiceBridgeError implements Exception {
  const VoiceBridgeError();

  String get message;
  String get userMessage;
  String? get recoverySuggestion;
  ErrorSeverity get severity;
}

enum ErrorSeverity { low, medium, high, critical }

/// Audio Recording Errors
class RecordingFailure extends VoiceBridgeError {
  final String details;
  final RecordingErrorType type;

  const RecordingFailure({required this.details, required this.type});

  /// Maps the error codes sent by the native recorders (iOS, macOS, Android) to a typed failure.
  factory RecordingFailure.fromPlatformException(PlatformException exception) {
    final details = exception.message ?? exception.code;
    final type = switch (exception.code) {
      VoiceBridgeErrorCodes.permissionDenied ||
      VoiceBridgeErrorCodes.permissionUnknown => RecordingErrorType.permissionDenied,
      VoiceBridgeErrorCodes.alreadyRecording ||
      VoiceBridgeErrorCodes.alreadyPending ||
      VoiceBridgeErrorCodes.audioFocus ||
      VoiceBridgeErrorCodes.audioSession => RecordingErrorType.deviceBusy,
      VoiceBridgeErrorCodes.recordingError ||
      VoiceBridgeErrorCodes.recordingFailed ||
      VoiceBridgeErrorCodes.instanceError => RecordingErrorType.hardwareFailure,
      _ => RecordingErrorType.unknown,
    };
    return RecordingFailure(details: details, type: type);
  }

  @override
  String get message => 'Recording failed: $details';

  @override
  String get userMessage {
    switch (type) {
      case RecordingErrorType.permissionDenied:
        return 'Microphone permission is required to record audio';
      case RecordingErrorType.deviceBusy:
        return 'Audio device is currently busy. Please try again';
      case RecordingErrorType.insufficientStorage:
        return 'Not enough storage space for recording';
      case RecordingErrorType.hardwareFailure:
        return 'Audio hardware is not available';
      case RecordingErrorType.unknown:
        return 'An unexpected error occurred during recording';
    }
  }

  @override
  String? get recoverySuggestion {
    switch (type) {
      case RecordingErrorType.permissionDenied:
        return 'Go to Settings → Privacy → Microphone and enable access';
      case RecordingErrorType.deviceBusy:
        return 'Close other apps using the microphone and try again';
      case RecordingErrorType.insufficientStorage:
        return 'Free up storage space and try again';
      case RecordingErrorType.hardwareFailure:
        return 'Check your device\'s microphone and restart the app';
      case RecordingErrorType.unknown:
        return 'Restart the app and try again';
    }
  }

  @override
  ErrorSeverity get severity {
    switch (type) {
      case RecordingErrorType.permissionDenied:
        return ErrorSeverity.high;
      case RecordingErrorType.deviceBusy:
        return ErrorSeverity.medium;
      case RecordingErrorType.insufficientStorage:
        return ErrorSeverity.high;
      case RecordingErrorType.hardwareFailure:
        return ErrorSeverity.critical;
      case RecordingErrorType.unknown:
        return ErrorSeverity.medium;
    }
  }
}

enum RecordingErrorType { permissionDenied, deviceBusy, insufficientStorage, hardwareFailure, unknown }

/// Transcription Errors
class TranscriptionFailure extends VoiceBridgeError {
  final String details;
  final TranscriptionErrorType type;

  const TranscriptionFailure({required this.details, required this.type});

  @override
  String get message => 'Transcription failed: $details';

  @override
  String get userMessage {
    switch (type) {
      case TranscriptionErrorType.modelNotLoaded:
        return 'AI model is not ready. Please wait and try again';
      case TranscriptionErrorType.unsupportedFormat:
        return 'Audio format is not supported for transcription';
      case TranscriptionErrorType.processingFailed:
        return 'Failed to process audio for transcription';
      case TranscriptionErrorType.memoryInsufficient:
        return 'Not enough memory to process this audio file';
      case TranscriptionErrorType.fileNotFound:
        return 'Audio file not found or corrupted';
      case TranscriptionErrorType.unknown:
        return 'Transcription service encountered an error';
    }
  }

  @override
  String? get recoverySuggestion {
    switch (type) {
      case TranscriptionErrorType.modelNotLoaded:
        return 'Wait for the AI model to load completely';
      case TranscriptionErrorType.unsupportedFormat:
        return 'Try recording a new audio file';
      case TranscriptionErrorType.processingFailed:
        return 'Check audio quality and try again';
      case TranscriptionErrorType.memoryInsufficient:
        return 'Close other apps and try again';
      case TranscriptionErrorType.fileNotFound:
        return 'Record a new audio file';
      case TranscriptionErrorType.unknown:
        return 'Restart the app and try again';
    }
  }

  @override
  ErrorSeverity get severity {
    switch (type) {
      case TranscriptionErrorType.modelNotLoaded:
        return ErrorSeverity.medium;
      case TranscriptionErrorType.unsupportedFormat:
        return ErrorSeverity.medium;
      case TranscriptionErrorType.processingFailed:
        return ErrorSeverity.medium;
      case TranscriptionErrorType.memoryInsufficient:
        return ErrorSeverity.high;
      case TranscriptionErrorType.fileNotFound:
        return ErrorSeverity.high;
      case TranscriptionErrorType.unknown:
        return ErrorSeverity.medium;
    }
  }
}

enum TranscriptionErrorType {
  modelNotLoaded,
  unsupportedFormat,
  processingFailed,
  memoryInsufficient,
  fileNotFound,
  unknown,
}

/// Platform Errors
class PlatformFailure extends VoiceBridgeError {
  final String details;
  final PlatformErrorType type;

  const PlatformFailure({required this.details, required this.type});

  @override
  String get message => 'Platform error: $details';

  @override
  String get userMessage {
    switch (type) {
      case PlatformErrorType.methodNotImplemented:
        return 'This feature is not available on your device';
      case PlatformErrorType.nativeLibraryMissing:
        return 'Required components are missing';
      case PlatformErrorType.platformNotSupported:
        return 'Your device is not supported';
      case PlatformErrorType.communicationFailure:
        return 'Internal communication error occurred';
    }
  }

  @override
  String? get recoverySuggestion {
    switch (type) {
      case PlatformErrorType.methodNotImplemented:
        return 'Update the app to the latest version';
      case PlatformErrorType.nativeLibraryMissing:
        return 'Reinstall the app';
      case PlatformErrorType.platformNotSupported:
        return 'Check device compatibility requirements';
      case PlatformErrorType.communicationFailure:
        return 'Restart the app';
    }
  }

  @override
  ErrorSeverity get severity => ErrorSeverity.critical;
}

enum PlatformErrorType { methodNotImplemented, nativeLibraryMissing, platformNotSupported, communicationFailure }

/// Error Helper Functions
class ErrorHelpers {
  /// Converts generic exceptions to typed VoiceBridge errors
  static VoiceBridgeError fromException(Exception exception) {
    final String message = exception.toString().toLowerCase();

    // Recording permission errors
    if (message.contains('permission') || message.contains('denied')) {
      return const RecordingFailure(details: 'Microphone permission denied', type: RecordingErrorType.permissionDenied);
    }

    // Device busy errors
    if (message.contains('busy') || message.contains('in use')) {
      return const RecordingFailure(details: 'Audio device is busy', type: RecordingErrorType.deviceBusy);
    }

    // Storage errors
    if (message.contains('storage') || message.contains('space')) {
      return const RecordingFailure(
        details: 'Insufficient storage space',
        type: RecordingErrorType.insufficientStorage,
      );
    }

    // FFI/Transcription errors
    if (message.contains('whisper') || message.contains('transcription')) {
      return const TranscriptionFailure(
        details: 'Transcription processing failed',
        type: TranscriptionErrorType.processingFailed,
      );
    }

    // Platform channel errors
    if (message.contains('methodchannel') || message.contains('platform')) {
      return const PlatformFailure(
        details: 'Platform communication failed',
        type: PlatformErrorType.communicationFailure,
      );
    }

    // Default to unknown recording error
    return RecordingFailure(details: exception.toString(), type: RecordingErrorType.unknown);
  }

  /// Logs error with appropriate level based on severity
  static void logError(VoiceBridgeError error, {String? context}) {
    final String logName = context ?? 'VoiceBridge.Error';
    final String prefix = _getSeverityPrefix(error.severity);

    developer.log('$prefix ${error.message}', name: logName, error: error);

    // Additional logging for critical errors
    if (error.severity == ErrorSeverity.critical) {
      developer.log('🚨 CRITICAL ERROR - User Message: ${error.userMessage}', name: logName);

      if (error.recoverySuggestion != null) {
        developer.log('💡 Recovery: ${error.recoverySuggestion}', name: logName);
      }
    }
  }

  static String _getSeverityPrefix(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return 'ℹ️';
      case ErrorSeverity.medium:
        return '⚠️';
      case ErrorSeverity.high:
        return '❌';
      case ErrorSeverity.critical:
        return '🚨';
    }
  }
}
