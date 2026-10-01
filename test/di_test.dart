import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/core/audio/audio_service.dart';
import 'package:flutter_voice_bridge/core/transcription/transcription_service.dart';
import 'package:flutter_voice_bridge/data/services/voice_memo_service.dart';
import 'package:flutter_voice_bridge/di.dart';

void main() {
  group('DependencyInjection', () {
    setUpAll(DependencyInjection.init);
    tearDownAll(getIt.reset);

    test('registers the services HomeCubit depends on', () {
      expect(getIt.isRegistered<AudioService>(), isTrue);
      expect(getIt.isRegistered<TranscriptionService>(), isTrue);
      expect(getIt.isRegistered<VoiceMemoService>(), isTrue);
    });
  });
}
