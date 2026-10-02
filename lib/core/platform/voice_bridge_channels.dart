/// The platform channel contract, in one place on the Dart side.
///
/// The same names are written in ios/Runner/AppDelegate.swift, macos/Runner/MainFlutterWindow.swift and
/// android/app/src/main/kotlin/com/example/flutter_voice_bridge/MainActivity.kt; each of those points back here.
abstract final class VoiceBridgeChannels {
  static const String audio = 'voice.bridge/audio';
}

/// Error codes the native recorders send in PlatformException.code.
abstract final class VoiceBridgeErrorCodes {
  static const String permissionDenied = 'PERMISSION_DENIED';
  static const String permissionUnknown = 'PERMISSION_UNKNOWN';
  static const String alreadyRecording = 'ALREADY_RECORDING';
  static const String alreadyPending = 'ALREADY_PENDING';
  static const String audioFocus = 'AUDIO_FOCUS_ERROR';
  static const String audioSession = 'AUDIO_SESSION_ERROR';
  static const String recordingError = 'RECORDING_ERROR';
  static const String recordingFailed = 'RECORDING_FAILED';
  static const String instanceError = 'INSTANCE_ERROR';
}
