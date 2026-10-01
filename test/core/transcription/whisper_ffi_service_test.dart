import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/core/transcription/whisper_ffi_service.dart';

/// Runs only on a Mac that has run ./scripts/build_whisper.sh; CI skips it.
void main() {
  const libraryPath = 'native/whisper/build/lib/libwhisper_ffi.dylib';
  const modelPath = 'assets/models/${WhisperFFIService.modelFileName}';
  const samplePath = 'native/whisper/whisper.cpp/samples/jfk.wav';
  final nativeBuildMissing = ![libraryPath, modelPath, samplePath].every((file) => File(file).existsSync());
  final skipReason = nativeBuildMissing ? 'needs ./scripts/build_whisper.sh on macOS' : null;

  test(
    'transcribes the whisper.cpp sample without blocking the calling isolate',
    () async {
      final service = WhisperFFIService();
      await service.initialize();
      await service.initializeModel(modelPath);
      expect(service.isModelLoaded, isTrue);

      var ticks = 0;
      final ticker = Timer.periodic(const Duration(milliseconds: 50), (_) => ticks++);
      final transcription = await service.transcribeAudio(samplePath);
      ticker.cancel();

      expect(transcription.toLowerCase(), contains('ask not what your country can do for you'));
      expect(ticks, greaterThan(1), reason: 'the event loop kept running while whisper worked');

      await service.dispose();
      expect(service.isModelLoaded, isFalse);
    },
    skip: skipReason,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('rejects a missing model file before calling native code', () async {
    final service = WhisperFFIService();
    await service.initialize();
    expect(() => service.initializeModel('missing/model.bin'), throwsA(isA<FileSystemException>()));
  }, skip: skipReason);

  test('refuses to transcribe before a model is loaded', () async {
    final service = WhisperFFIService();
    expect(() => service.transcribeAudio(samplePath), throwsA(isA<StateError>()));
  });
}
