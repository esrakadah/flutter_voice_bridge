import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/core/errors/voice_bridge_error.dart';
import 'package:flutter_voice_bridge/core/platform/voice_bridge_channels.dart';

void main() {
  RecordingErrorType typeFor(String code) => RecordingFailure.fromPlatformException(PlatformException(code: code)).type;

  test('maps native recorder codes to failure types', () {
    expect(typeFor(VoiceBridgeErrorCodes.permissionDenied), RecordingErrorType.permissionDenied);
    expect(typeFor(VoiceBridgeErrorCodes.alreadyRecording), RecordingErrorType.deviceBusy);
    expect(typeFor(VoiceBridgeErrorCodes.alreadyPending), RecordingErrorType.deviceBusy);
    expect(typeFor(VoiceBridgeErrorCodes.recordingFailed), RecordingErrorType.hardwareFailure);
    expect(typeFor('SOMETHING_NEW'), RecordingErrorType.unknown);
  });

  test('keeps the native message as details', () {
    final failure = RecordingFailure.fromPlatformException(
      PlatformException(code: VoiceBridgeErrorCodes.audioFocus, message: 'focus lost'),
    );
    expect(failure.details, 'focus lost');
    expect(failure.userMessage, 'Audio device is currently busy. Please try again');
  });
}
