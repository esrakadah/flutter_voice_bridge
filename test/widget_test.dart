// Flutter Voice Bridge Widget Tests
// Basic smoke tests - comprehensive tests will be added incrementally

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/di.dart';
import 'package:flutter_voice_bridge/core/audio/audio_service.dart';
import 'package:flutter_voice_bridge/core/transcription/transcription_service.dart';

void main() {
  group('Dependency Injection', () {
    setUpAll(() async {
      // Initialize dependencies for testing
      await DependencyInjection.init();
    });

    test('AudioService is registered', () {
      expect(getIt.isRegistered<AudioService>(), isTrue);
    });

    test('TranscriptionService is registered', () {
      expect(getIt.isRegistered<TranscriptionService>(), isTrue);
    });
  });

  // Note: Full widget and integration tests will be added in next phase
  // Currently blocked by Process.run timer issue in home_view.dart:1220
  // This will be fixed during the refactoring phase
}
