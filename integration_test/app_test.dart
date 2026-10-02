import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/app.dart';
import 'package:flutter_voice_bridge/di.dart';
import 'package:integration_test/integration_test.dart';

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
}
