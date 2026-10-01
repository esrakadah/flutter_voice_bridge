import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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

  group('malformed WAV files fail cleanly instead of reading out of bounds', () {
    final service = WhisperFFIService();
    late Directory scratch;

    setUpAll(() async {
      if (nativeBuildMissing) return;
      await service.initialize();
      await service.initializeModel(modelPath);
      scratch = Directory.systemTemp.createTempSync('wav_cases');
    });

    tearDownAll(() async {
      if (nativeBuildMissing) return;
      await service.dispose();
      scratch.deleteSync(recursive: true);
    });

    Future<void> expectRejected(String name, List<int> bytes) async {
      final file = File('${scratch.path}/$name.wav')..writeAsBytesSync(bytes);
      await expectLater(service.transcribeAudio(file.path), throwsA(isA<StateError>()));
    }

    test(
      'random bytes',
      () => expectRejected('garbage', List.generate(64, (index) => index * 37 % 256)),
      skip: skipReason,
    );

    test('header only, fmt chunk claims more bytes than exist', () {
      final header = _wavHeader(channels: 1, dataBytes: 0)..setUint32(16, 0x7FFFFFFF, Endian.little);
      return expectRejected('huge_fmt', header.buffer.asUint8List(0, 36));
    }, skip: skipReason);

    test('stereo audio', () {
      final header = _wavHeader(channels: 2, dataBytes: 3200);
      return expectRejected('stereo', [...header.buffer.asUint8List(), ...List.filled(3200, 0)]);
    }, skip: skipReason);
  });

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

ByteData _wavHeader({required int channels, required int dataBytes}) {
  const sampleRate = 16000;
  const bytesPerSample = 2;
  return ByteData(44)
    ..setUint32(0, 0x52494646)
    ..setUint32(4, 36 + dataBytes, Endian.little)
    ..setUint32(8, 0x57415645)
    ..setUint32(12, 0x666d7420)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, channels, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * bytesPerSample * channels, Endian.little)
    ..setUint16(32, bytesPerSample * channels, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x64617461)
    ..setUint32(40, dataBytes, Endian.little);
}
