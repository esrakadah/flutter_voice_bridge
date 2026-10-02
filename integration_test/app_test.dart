import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/app.dart';
import 'package:flutter_voice_bridge/core/transcription/whisper_ffi_service.dart';
import 'package:flutter_voice_bridge/di.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Smoke test on a real device or desktop: `flutter test integration_test -d macos`.
/// Not run in CI, because transcription needs the native library from scripts/build_whisper.sh.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(DependencyInjection.init);
  tearDownAll(getIt.reset);

  testWidgets('app starts on the home screen with a record button', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsWidgets);
  });

  testWidgets('macOS: the bundled library transcribes silence to empty text on a background isolate', (
    tester,
  ) async {
    final service = WhisperFFIService();
    await service.initialize();
    await service.initializeModel(await WhisperFFIService.getDefaultModelPath());

    final silence = File('${(await getTemporaryDirectory()).path}/silence.wav');
    await silence.writeAsBytes(_silentWav(sampleRate: 16000, seconds: 1));
    final transcription = await service.transcribeAudio(silence.path);

    expect(transcription, isEmpty, reason: 'silence must not come back as a hallucinated word or a marker');
    await service.dispose();
  }, skip: !Platform.isMacOS);
}

/// A minimal 16-bit mono PCM WAV of zeros.
Uint8List _silentWav({required int sampleRate, required int seconds}) {
  const bytesPerSample = 2;
  const headerBytes = 44;
  final dataBytes = sampleRate * seconds * bytesPerSample;
  final header = ByteData(headerBytes)
    ..setUint32(0, 0x52494646) // RIFF
    ..setUint32(4, headerBytes - 8 + dataBytes, Endian.little)
    ..setUint32(8, 0x57415645) // WAVE
    ..setUint32(12, 0x666d7420) // fmt
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * bytesPerSample, Endian.little)
    ..setUint16(32, bytesPerSample, Endian.little)
    ..setUint16(34, bytesPerSample * 8, Endian.little)
    ..setUint32(36, 0x64617461) // data
    ..setUint32(40, dataBytes, Endian.little);
  return Uint8List(headerBytes + dataBytes)..setRange(0, headerBytes, header.buffer.asUint8List());
}
