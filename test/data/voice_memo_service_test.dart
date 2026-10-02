import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/data/models/voice_memo.dart';
import 'package:flutter_voice_bridge/data/services/voice_memo_service.dart';

void main() {
  const sampleRate = 16000;
  const bytesPerSample = 2;
  late Directory documents;
  late Directory audio;

  VoiceMemoServiceImpl serviceAt(Directory directory) =>
      VoiceMemoServiceImpl(documentsDirectory: () async => directory, clock: () => DateTime(2026, 10, 2, 15));

  File writeWav(String name, {required int seconds}) {
    final dataBytes = sampleRate * bytesPerSample * seconds;
    final header = ByteData(44)
      ..setUint32(0, 0x52494646)
      ..setUint32(4, 36 + dataBytes, Endian.little)
      ..setUint32(8, 0x57415645)
      ..setUint32(12, 0x666d7420)
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * bytesPerSample, Endian.little)
      ..setUint16(32, bytesPerSample, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint32(36, 0x64617461)
      ..setUint32(40, dataBytes, Endian.little);
    return File('${audio.path}/$name')
      ..writeAsBytesSync([...header.buffer.asUint8List(), ...List.filled(dataBytes, 0)]);
  }

  setUp(() {
    documents = Directory.systemTemp.createTempSync('voice_memos');
    audio = Directory('${documents.path}/audio')..createSync();
  });

  tearDown(() => documents.deleteSync(recursive: true));

  test('lists an old recording without a sidecar, with its duration from the WAV header', () async {
    writeWav('voice_memo_1790928942699.wav', seconds: 3);

    final memo = (await serviceAt(documents).listRecordings()).single;

    expect(memo.durationSeconds, 3);
    expect(memo.isTranscribed, isFalse);
    expect(memo.title, startsWith('Voice Memo, '));
  });

  test('a saved transcription survives a restart', () async {
    final file = writeWav('voice_memo_1790928942699.wav', seconds: 2);
    await serviceAt(documents).saveTranscription(file.path, text: 'Hello from the stage', keywords: ['stage']);

    final reloaded = (await serviceAt(documents).listRecordings()).single;

    expect(reloaded.transcription, 'Hello from the stage');
    expect(reloaded.keywords, ['stage']);
    expect(reloaded.isTranscribed, isTrue);
    expect(reloaded.lastModified, DateTime(2026, 10, 2, 15));
  });

  test('saveVoiceMemo keeps the title and duration the recorder measured', () async {
    final file = writeWav('voice_memo_1.wav', seconds: 1);
    final memo = VoiceMemo(
      id: 'voice_memo_1',
      filePath: file.path,
      title: 'Keynote rehearsal',
      keywords: const [],
      createdAt: DateTime(2026, 10, 2, 9),
      durationSeconds: 42,
      fileSizeBytes: 0,
      isTranscribed: false,
      status: VoiceMemoStatus.completed,
    );

    await serviceAt(documents).saveVoiceMemo(memo);
    final listed = (await serviceAt(documents).listRecordings()).single;

    expect(listed.title, 'Keynote rehearsal');
    expect(listed.durationSeconds, 42);
    expect(listed.fileSizeBytes, file.lengthSync());
  });

  test('deleting a recording also deletes its sidecar', () async {
    final file = writeWav('voice_memo_1.wav', seconds: 1);
    await serviceAt(documents).saveTranscription(file.path, text: 'x', keywords: const []);

    await serviceAt(documents).deleteRecording(file.path);

    expect(audio.listSync(), isEmpty);
  });

  test('delete all removes audio and sidecars', () async {
    final first = writeWav('voice_memo_1.wav', seconds: 1);
    writeWav('voice_memo_2.wav', seconds: 1);
    await serviceAt(documents).saveTranscription(first.path, text: 'x', keywords: const []);

    await serviceAt(documents).deleteAllRecordings();

    expect(audio.listSync(), isEmpty);
  });

  test('an unreadable sidecar falls back to the audio file instead of hiding the recording', () async {
    final file = writeWav('voice_memo_1.wav', seconds: 1);
    File('${file.path}.json').writeAsStringSync('{not json');

    final listed = await serviceAt(documents).listRecordings();

    expect(listed, hasLength(1));
    expect(listed.single.isTranscribed, isFalse);
  });

  test('saving a transcript for a deleted recording throws and writes nothing', () async {
    final file = writeWav('voice_memo_1.wav', seconds: 1);
    file.deleteSync();

    await expectLater(
      serviceAt(documents).saveTranscription(file.path, text: 'private words', keywords: const []),
      throwsA(isA<StateError>()),
    );
    expect(audio.listSync(), isEmpty);
  });
}
