import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/gemma/data/gemma_service.dart';
import 'package:flutter_voice_bridge/gemma/domain/available_models.dart';
import 'package:flutter_voice_bridge/gemma/ui/gemma_cubit.dart';
import 'package:flutter_voice_bridge/gemma/ui/gemma_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGemmaService extends Mock implements GemmaService {}

void main() {
  late MockGemmaService gemmaService;

  setUpAll(() {
    registerFallbackValue(Message(text: '', isUser: true));
    registerFallbackValue(AvailableModel.gemma1b);
  });

  setUp(() {
    gemmaService = MockGemmaService();
    when(() => gemmaService.getSelectedModel()).thenAnswer((_) async => AvailableModel.gemma1b);
    when(() => gemmaService.isModelDownloaded(any())).thenAnswer((_) async => true);
    when(() => gemmaService.initializeChat()).thenAnswer((_) async {});
  });

  GemmaCubit buildCubit() => GemmaCubit(gemmaService: gemmaService);

  blocTest<GemmaCubit, GemmaState>(
    'initialize reaches ready and clears an earlier error',
    build: () {
      var attempts = 0;
      when(() => gemmaService.initializeChat()).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) throw Exception('model missing');
      });
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.initialize();
      expect(cubit.state.status, GemmaStatus.error);
      await cubit.initialize();
    },
    verify: (cubit) {
      expect(cubit.state.status, GemmaStatus.ready);
      expect(cubit.state.errorMessage, isNull);
    },
  );

  blocTest<GemmaCubit, GemmaState>(
    'streams the reply into the last message',
    build: () {
      when(() => gemmaService.sendMessage(any())).thenAnswer((_) => Stream.fromIterable(['Hel', 'lo']));
      return buildCubit();
    },
    act: (cubit) => cubit.sendMessage('Hi'),
    verify: (cubit) {
      expect(cubit.state.messages.map((message) => message.text), ['Hi', 'Hello']);
      expect(cubit.state.isAwaitingResponse, isFalse);
      expect(cubit.state.sendError, isNull);
    },
  );

  blocTest<GemmaCubit, GemmaState>(
    'a failed send removes the placeholder and exposes sendError while staying ready',
    build: () {
      when(() => gemmaService.sendMessage(any())).thenAnswer((_) => Stream.error(Exception('out of memory')));
      return buildCubit();
    },
    seed: () => const GemmaState(status: GemmaStatus.ready),
    act: (cubit) => cubit.sendMessage('Hi'),
    verify: (cubit) {
      expect(cubit.state.messages.map((message) => message.text), ['Hi']);
      expect(cubit.state.sendError, contains('out of memory'));
      expect(cubit.state.status, GemmaStatus.ready);
    },
  );

  blocTest<GemmaCubit, GemmaState>(
    'an image without text is sent with the default prompt and the image is cleared',
    build: () {
      when(() => gemmaService.sendMessage(any())).thenAnswer((_) => const Stream.empty());
      return buildCubit();
    },
    act: (cubit) async {
      cubit.selectImage(Uint8List.fromList([1, 2, 3]));
      await cubit.sendMessage('');
    },
    verify: (cubit) {
      final sent = verify(() => gemmaService.sendMessage(captureAny())).captured.single as Message;
      expect(sent.text, GemmaCubit.defaultImagePrompt);
      expect(sent.imageBytes, isNotNull);
      expect(cubit.state.selectedImage, isNull);
    },
  );

  blocTest<GemmaCubit, GemmaState>(
    'ignores an empty message without an image',
    build: buildCubit,
    act: (cubit) => cubit.sendMessage(''),
    expect: () => <GemmaState>[],
  );
}
