// HomeCubit Unit Tests
// Tests for the main business logic of the home screen
//
// TESTING STRATEGY:
// ==================
// These are UNIT tests that verify business logic in isolation using mocks.
// They test state transitions, error handling, and service orchestration.
//
// ✅ What these tests DO verify:
//   - State transition logic (RecordingStarted → RecordingInProgress)
//   - Error handling flows (exceptions → error states)
//   - Service call sequences (permission check → start recording)
//   - Business logic correctness
//
// ❌ What these tests DO NOT verify:
//   - Actual platform channel integration
//   - Real file system operations
//   - Actual transcription with Whisper.cpp
//   - UI widget interactions
//   - Timer behavior and memory management
//
// 📋 TODO - Integration Tests Required:
//   Integration tests should be added to verify end-to-end flows on real devices.
//   See: integration_test/README.md for implementation plan
//   Priority scenarios to test:
//   1. Complete recording flow (tap → record → stop → save)
//   2. Permission denial handling on real device
//   3. Transcription with actual audio file
//   4. Memory cleanup and resource management

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_voice_bridge/ui/views/home/home_cubit.dart';
import 'package:flutter_voice_bridge/ui/views/home/home_state.dart';
import 'package:flutter_voice_bridge/core/audio/audio_service.dart';
import 'package:flutter_voice_bridge/core/transcription/transcription_service.dart';
import 'package:flutter_voice_bridge/data/services/voice_memo_service.dart';
import 'package:flutter_voice_bridge/data/models/voice_memo.dart';

// Mock classes
class MockAudioService extends Mock implements AudioService {}

class MockTranscriptionService extends Mock implements TranscriptionService {}

class MockVoiceMemoService extends Mock implements VoiceMemoService {}

// Fake classes for fallback values
class FakeVoiceMemo extends Fake implements VoiceMemo {}

void main() {
  group('HomeCubit', () {
    late HomeCubit cubit;
    late MockAudioService mockAudioService;
    late MockTranscriptionService mockTranscriptionService;
    late MockVoiceMemoService mockVoiceMemoService;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(FakeVoiceMemo());
    });

    setUp(() {
      mockAudioService = MockAudioService();
      mockTranscriptionService = MockTranscriptionService();
      mockVoiceMemoService = MockVoiceMemoService();

      // Setup default behaviors that are called during initialization
      when(() => mockTranscriptionService.initialize(any())).thenAnswer((_) async {});
      when(() => mockVoiceMemoService.listRecordings()).thenAnswer((_) async => []);
      when(() => mockAudioService.hasPermission()).thenAnswer((_) async => true);

      cubit = HomeCubit(
        audioService: mockAudioService,
        transcriptionService: mockTranscriptionService,
        voiceMemoService: mockVoiceMemoService,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is HomeInitial', () {
      expect(cubit.state, isA<HomeInitial>());
    });

    group('startRecording', () {
      blocTest<HomeCubit, HomeState>(
        'emits RecordingStarted and RecordingInProgress when recording starts successfully',
        build: () {
          when(() => mockAudioService.hasPermission()).thenAnswer((_) async => true);
          when(() => mockAudioService.startRecording()).thenAnswer((_) async => '/path/to/recording.wav');
          return cubit;
        },
        act: (cubit) => cubit.startRecording(),
        expect: () => [
          isA<RecordingStarted>().having((s) => s.recordingPath, 'recordingPath', '/path/to/recording.wav'),
          isA<RecordingInProgress>(),
        ],
        verify: (_) {
          verify(() => mockAudioService.hasPermission()).called(1);
          verify(() => mockAudioService.startRecording()).called(1);
        },
      );

      blocTest<HomeCubit, HomeState>(
        'emits RecordingError when recording fails',
        build: () {
          when(() => mockAudioService.hasPermission()).thenAnswer((_) async => true);
          when(() => mockAudioService.startRecording()).thenThrow(Exception('Permission denied'));
          return cubit;
        },
        act: (cubit) => cubit.startRecording(),
        expect: () => [
          isA<RecordingError>().having(
            (s) => s.errorMessage, 
            'errorMessage', 
            'Microphone permission is required to record audio',  // User-friendly message from VoiceBridgeError
          ),
        ],
      );
    });

    // Note: Additional tests for stopRecording, transcribeRecording, and other methods
    // will be added incrementally. Current tests demonstrate:
    // 1. Test infrastructure is working
    // 2. Mocking is properly configured
    // 3. BLoC testing patterns are established
    //
    // Complex scenarios require additional mocking of:
    // - TranscriptionService.isInitialized()
    // - AudioConverter for file conversion
    // - Timer management in stopRecording
    // These will be addressed in the comprehensive test suite.
  });
}
