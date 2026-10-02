import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/core/audio/audio_service.dart';
import 'package:flutter_voice_bridge/core/errors/voice_bridge_error.dart';
import 'package:flutter_voice_bridge/core/transcription/transcription_service.dart';
import 'package:flutter_voice_bridge/data/models/voice_memo.dart';
import 'package:flutter_voice_bridge/data/services/voice_memo_service.dart';
import 'package:flutter_voice_bridge/ui/views/home/home_cubit.dart';
import 'package:flutter_voice_bridge/ui/views/home/home_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioService extends Mock implements AudioService {}

class MockTranscriptionService extends Mock implements TranscriptionService {}

class MockVoiceMemoService extends Mock implements VoiceMemoService {}

class FakeVoiceMemo extends Fake implements VoiceMemo {}

VoiceMemo memo(String filePath) => VoiceMemo(
  id: filePath,
  filePath: filePath,
  title: filePath,
  keywords: const [],
  createdAt: DateTime(2026, 10, 2),
  durationSeconds: 0,
  fileSizeBytes: 0,
  isTranscribed: false,
  status: VoiceMemoStatus.completed,
);

void main() {
  late MockAudioService audioService;
  late MockTranscriptionService transcriptionService;
  late MockVoiceMemoService voiceMemoService;
  final existingMemo = memo('/recordings/existing.wav');

  setUpAll(() => registerFallbackValue(FakeVoiceMemo()));

  setUp(() {
    audioService = MockAudioService();
    transcriptionService = MockTranscriptionService();
    voiceMemoService = MockVoiceMemoService();

    when(() => transcriptionService.initialize(any())).thenAnswer((_) async {});
    when(() => transcriptionService.isInitialized()).thenAnswer((_) async => true);
    when(() => transcriptionService.extractKeywords(any())).thenAnswer((_) async => const ['hello']);
    when(() => voiceMemoService.listRecordings()).thenAnswer((_) async => [existingMemo]);
    when(() => voiceMemoService.saveVoiceMemo(any())).thenAnswer((_) async => '/recordings/new.wav');
    when(
      () => voiceMemoService.saveTranscription(
        any(),
        text: any(named: 'text'),
        keywords: any(named: 'keywords'),
      ),
    ).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      return memo(path).copyWith(
        transcription: invocation.namedArguments[#text] as String,
        isTranscribed: true,
      );
    });
    when(() => audioService.hasPermission()).thenAnswer((_) async => true);
  });

  HomeCubit buildCubit() => HomeCubit(
    audioService: audioService,
    transcriptionService: transcriptionService,
    voiceMemoService: voiceMemoService,
    clock: () => DateTime(2026, 10, 2, 12),
  );

  test('starts idle and loads the existing recordings', () async {
    final cubit = buildCubit();
    expect(cubit.state.recordingPhase, RecordingPhase.idle);

    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.recordings, [existingMemo]);
    expect(cubit.state.isLoadingRecordings, isFalse);
    await cubit.close();
  });

  group('startRecording', () {
    blocTest<HomeCubit, HomeState>(
      'enters the recording phase and keeps the recordings list',
      build: () {
        when(() => audioService.startRecording()).thenAnswer((_) async => '/recordings/new.wav');
        return buildCubit();
      },
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        await cubit.startRecording();
      },
      verify: (cubit) {
        expect(cubit.state.recordingPhase, RecordingPhase.recording);
        expect(cubit.state.recordings, [existingMemo]);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'requests permission when it is missing',
      build: () {
        when(() => audioService.hasPermission()).thenAnswer((_) async => false);
        when(() => audioService.requestPermission()).thenAnswer((_) async {});
        when(() => audioService.startRecording()).thenAnswer((_) async => '/recordings/new.wav');
        return buildCubit();
      },
      act: (cubit) => cubit.startRecording(),
      verify: (_) => verify(() => audioService.requestPermission()).called(1),
    );

    blocTest<HomeCubit, HomeState>(
      'maps a native PERMISSION_DENIED code to the permission message',
      build: () {
        when(() => audioService.startRecording()).thenThrow(
          RecordingFailure.fromPlatformException(PlatformException(code: 'PERMISSION_DENIED')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.startRecording(),
      verify: (cubit) {
        expect(cubit.state.recordingPhase, RecordingPhase.failed);
        expect(cubit.state.recordingError, 'Microphone permission is required to record audio');
      },
    );

    blocTest<HomeCubit, HomeState>(
      'still maps an untyped permission exception',
      build: () {
        when(() => audioService.startRecording()).thenThrow(Exception('Permission denied'));
        return buildCubit();
      },
      act: (cubit) => cubit.startRecording(),
      verify: (cubit) => expect(cubit.state.recordingError, 'Microphone permission is required to record audio'),
    );

    blocTest<HomeCubit, HomeState>(
      'a new recording clears the previous recording error',
      build: () {
        var attempts = 0;
        when(() => audioService.startRecording()).thenAnswer((_) async {
          attempts++;
          if (attempts == 1) throw Exception('device busy');
          return '/recordings/new.wav';
        });
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.startRecording();
        await cubit.startRecording();
      },
      verify: (cubit) {
        expect(cubit.state.recordingPhase, RecordingPhase.recording);
        expect(cubit.state.recordingError, isNull);
      },
    );
  });

  group('stopRecording', () {
    blocTest<HomeCubit, HomeState>(
      'saves a memo with the injected clock, completes, then transcribes',
      build: () {
        when(() => audioService.startRecording()).thenAnswer((_) async => '/recordings/new.wav');
        when(() => audioService.stopRecording()).thenAnswer((_) async => '/recordings/new.wav');
        when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => 'hello world');
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.startRecording();
        await cubit.stopRecording();
      },
      verify: (cubit) {
        expect(cubit.state.recordingPhase, RecordingPhase.completed);
        expect(cubit.state.lastRecordingPath, '/recordings/new.wav');
        expect(cubit.state.transcriptionText, 'hello world');
        expect(cubit.state.keywords, ['hello']);
        expect(cubit.state.isTranscribing, isFalse);
        final saved = verify(() => voiceMemoService.saveVoiceMemo(captureAny())).captured.single as VoiceMemo;
        expect(saved.createdAt, DateTime(2026, 10, 2, 12));
        expect(saved.title, 'Voice Memo, Oct 2, 12:00');
      },
    );

    blocTest<HomeCubit, HomeState>(
      'reports a failure to stop as a recording error',
      build: () {
        when(() => audioService.startRecording()).thenAnswer((_) async => '/recordings/new.wav');
        when(() => audioService.stopRecording()).thenThrow(Exception('no active recording'));
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.startRecording();
        await cubit.stopRecording();
      },
      verify: (cubit) => expect(cubit.state.recordingPhase, RecordingPhase.failed),
    );

    blocTest<HomeCubit, HomeState>(
      'stop without an active recording does nothing',
      build: buildCubit,
      act: (cubit) => cubit.stopRecording(),
      verify: (_) => verifyNever(() => audioService.stopRecording()),
    );
  });

  group('double taps', () {
    blocTest<HomeCubit, HomeState>(
      'a second start while the first is in flight never reaches the recorder',
      build: () {
        when(() => audioService.startRecording()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return '/recordings/new.wav';
        });
        return buildCubit();
      },
      act: (cubit) => Future.wait([cubit.startRecording(), cubit.startRecording()]),
      verify: (cubit) {
        verify(() => audioService.startRecording()).called(1);
        expect(cubit.state.recordingPhase, RecordingPhase.recording);
        expect(cubit.state.recordingError, isNull);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'ALREADY_RECORDING from the platform shows the recording so it can be stopped',
      build: () {
        when(() => audioService.startRecording()).thenThrow(
          RecordingFailure.fromPlatformException(PlatformException(code: 'ALREADY_RECORDING')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.startRecording(),
      verify: (cubit) {
        expect(cubit.state.recordingPhase, RecordingPhase.recording);
        expect(cubit.state.recordingError, isNull);
      },
    );
  });

  blocTest<HomeCubit, HomeState>(
    'a new recording clears the previous transcript',
    build: () {
      when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => 'old text');
      when(() => audioService.startRecording()).thenAnswer((_) async => '/recordings/new.wav');
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.transcribeRecording('/recordings/a.wav');
      await cubit.startRecording();
    },
    verify: (cubit) {
      expect(cubit.state.transcriptionText, isNull);
      expect(cubit.state.keywords, isEmpty);
    },
  );

  group('transcribeRecording', () {
    blocTest<HomeCubit, HomeState>(
      'a success after a failure clears the old error',
      build: () {
        var attempts = 0;
        when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async {
          attempts++;
          if (attempts == 1) throw Exception('model not loaded');
          return 'second try';
        });
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.transcribeRecording('/recordings/a.wav');
        expect(cubit.state.transcriptionError, contains('model not loaded'));
        await cubit.transcribeRecording('/recordings/a.wav');
      },
      verify: (cubit) {
        expect(cubit.state.transcriptionError, isNull);
        expect(cubit.state.transcriptionText, 'second try');
      },
    );

    blocTest<HomeCubit, HomeState>(
      'treats an empty transcript as a failure',
      build: () {
        when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => '');
        return buildCubit();
      },
      act: (cubit) => cubit.transcribeRecording('/recordings/a.wav'),
      verify: (cubit) {
        expect(cubit.state.transcriptionText, isNull);
        expect(cubit.state.transcriptionError, startsWith('Transcription failed: No speech detected'));
        expect('Transcription failed'.allMatches(cubit.state.transcriptionError ?? '').length, 1);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'initializes the service first when it is not ready',
      build: () {
        when(() => transcriptionService.isInitialized()).thenAnswer((_) async => false);
        when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => 'ok');
        return buildCubit();
      },
      act: (cubit) => cubit.transcribeRecording('/recordings/a.wav'),
      verify: (_) => verify(() => transcriptionService.initialize(any())).called(2),
    );

    blocTest<HomeCubit, HomeState>(
      'keeps the transcript when keyword extraction fails',
      build: () {
        when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => 'text');
        when(() => transcriptionService.extractKeywords(any())).thenThrow(Exception('nlp down'));
        return buildCubit();
      },
      act: (cubit) => cubit.transcribeRecording('/recordings/a.wav'),
      verify: (cubit) {
        expect(cubit.state.transcriptionText, 'text');
        expect(cubit.state.keywords, isEmpty);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'retry uses the newest recording in the list when nothing was recorded this session',
      build: () {
        when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => 'retried');
        return buildCubit();
      },
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        await cubit.retryLastTranscription();
      },
      verify: (_) => verify(() => transcriptionService.transcribeAudio(existingMemo.filePath)).called(1),
    );
  });

  group('stale and retried transcriptions', () {
    blocTest<HomeCubit, HomeState>(
      'a slower earlier transcription does not overwrite the newer one',
      build: () {
        when(() => transcriptionService.transcribeAudio('/recordings/a.wav')).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 'text of A';
        });
        when(() => transcriptionService.transcribeAudio('/recordings/b.wav')).thenAnswer((_) async => 'text of B');
        return buildCubit();
      },
      act: (cubit) => Future.wait([
        cubit.transcribeRecording('/recordings/a.wav'),
        cubit.transcribeRecording('/recordings/b.wav'),
      ]),
      verify: (cubit) {
        expect(cubit.state.transcriptionText, 'text of B');
        expect(cubit.state.transcriptionFilePath, '/recordings/b.wav');
      },
    );

    blocTest<HomeCubit, HomeState>(
      'retry transcribes the file that failed, not the newest recording',
      build: () {
        var attempts = 0;
        when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async {
          attempts++;
          if (attempts == 1) throw Exception('model busy');
          return 'second try';
        });
        return buildCubit();
      },
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        await cubit.transcribeRecording('/recordings/older.wav');
        await cubit.retryLastTranscription();
      },
      verify: (_) => verify(() => transcriptionService.transcribeAudio('/recordings/older.wav')).called(2),
    );

    blocTest<HomeCubit, HomeState>(
      'deleting the transcribed file clears its transcript and retry target',
      build: () {
        when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => 'text');
        when(() => voiceMemoService.deleteRecording(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.transcribeRecording(existingMemo.filePath);
        await cubit.deleteRecording(existingMemo.filePath);
      },
      verify: (cubit) {
        expect(cubit.state.transcriptionText, isNull);
        expect(cubit.state.transcriptionFilePath, isNull);
      },
    );
  });

  group('recordings list', () {
    blocTest<HomeCubit, HomeState>(
      'deleteRecording removes the memo optimistically',
      build: () {
        when(() => voiceMemoService.deleteRecording(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        await cubit.deleteRecording(existingMemo.filePath);
      },
      verify: (cubit) => expect(cubit.state.recordings, isEmpty),
    );

    blocTest<HomeCubit, HomeState>(
      'deleteAllRecordings reloads and reports an error when the service fails',
      build: () {
        when(() => voiceMemoService.deleteAllRecordings()).thenThrow(Exception('read-only'));
        return buildCubit();
      },
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        await cubit.deleteAllRecordings();
      },
      verify: (cubit) {
        expect(cubit.state.recordings, [existingMemo]);
        verify(() => voiceMemoService.listRecordings()).called(2);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'a failed load surfaces an error that the next load clears',
      build: () {
        var calls = 0;
        when(() => voiceMemoService.listRecordings()).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw Exception('disk error');
          return [existingMemo];
        });
        return buildCubit();
      },
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.recordingsError, contains('disk error'));
        await cubit.loadRecordings();
      },
      verify: (cubit) {
        expect(cubit.state.recordingsError, isNull);
        expect(cubit.state.recordings, [existingMemo]);
      },
    );
  });

  group('playRecording', () {
    blocTest<HomeCubit, HomeState>(
      'shows a playback error without touching the recordings',
      build: () {
        when(() => audioService.playRecording(any())).thenThrow(Exception('file missing'));
        return buildCubit();
      },
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        await cubit.playRecording(existingMemo.filePath);
      },
      verify: (cubit) {
        expect(cubit.state.playingFilePath, isNull);
        expect(cubit.state.playbackError, isNotNull);
        expect(cubit.state.recordings, [existingMemo]);
      },
    );
  });

  test('closing the cubit does not dispose the shared transcription service', () async {
    final cubit = buildCubit();
    await cubit.close();
    verifyNever(() => transcriptionService.dispose());
  });

  blocTest<HomeCubit, HomeState>(
    'a finished transcription is saved and shown on its recording',
    build: () {
      when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => 'saved text');
      return buildCubit();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      await cubit.transcribeRecording(existingMemo.filePath);
    },
    verify: (cubit) {
      verify(
        () => voiceMemoService.saveTranscription(existingMemo.filePath, text: 'saved text', keywords: ['hello']),
      ).called(1);
      expect(cubit.state.recordings.single.transcription, 'saved text');
      expect(cubit.state.recordings.single.isTranscribed, isTrue);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'a failed save still shows the transcript',
    build: () {
      when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async => 'text');
      when(
        () => voiceMemoService.saveTranscription(
          any(),
          text: any(named: 'text'),
          keywords: any(named: 'keywords'),
        ),
      ).thenThrow(const FileSystemException('read-only'));
      return buildCubit();
    },
    act: (cubit) => cubit.transcribeRecording(existingMemo.filePath),
    verify: (cubit) => expect(cubit.state.transcriptionText, 'text'),
  );

  blocTest<HomeCubit, HomeState>(
    'a transcription that finishes after a newer one still marks its own recording as transcribed',
    build: () {
      final second = memo('/recordings/second.wav');
      when(() => voiceMemoService.listRecordings()).thenAnswer((_) async => [existingMemo, second]);
      when(() => transcriptionService.transcribeAudio(existingMemo.filePath)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'first text';
      });
      when(() => transcriptionService.transcribeAudio(second.filePath)).thenAnswer((_) async => 'second text');
      return buildCubit();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      await Future.wait([
        cubit.transcribeRecording(existingMemo.filePath),
        cubit.transcribeRecording('/recordings/second.wav'),
      ]);
    },
    verify: (cubit) {
      expect(cubit.state.transcriptionText, 'second text');
      final first = cubit.state.recordings.firstWhere((recording) => recording.filePath == existingMemo.filePath);
      expect(first.isTranscribed, isTrue);
      expect(first.transcription, 'first text');
    },
  );

  blocTest<HomeCubit, HomeState>(
    'deleting a recording mid-transcription ends the progress and drops its result',
    build: () {
      when(() => voiceMemoService.deleteRecording(any())).thenAnswer((_) async {});
      when(() => transcriptionService.transcribeAudio(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'late text';
      });
      return buildCubit();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      final transcription = cubit.transcribeRecording(existingMemo.filePath);
      await cubit.deleteRecording(existingMemo.filePath);
      expect(cubit.state.isTranscribing, isFalse);
      await transcription;
    },
    verify: (cubit) {
      expect(cubit.state.transcriptionText, isNull);
      expect(cubit.state.recordings, isEmpty);
    },
  );
}
