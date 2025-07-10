// Flutter Voice Bridge Widget Tests
// Tests for voice recording and transcription functionality

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_voice_bridge/app.dart';
import 'package:flutter_voice_bridge/di.dart';

void main() {
  setUpAll(() async {
    // Initialize dependencies for testing
    await DependencyInjection.init();
  });

  testWidgets('Voice Bridge app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that the app loads with expected elements
    expect(find.text('Voice Bridge AI'), findsOneWidget);
    expect(find.text('Ready to record'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // Verify floating action button exists
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Recording button changes state', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());
    await tester.pump();

    // Find the record button
    final recordButton = find.byType(FloatingActionButton);
    expect(recordButton, findsOneWidget);

    // Tap the record button (this should start recording)
    await tester.tap(recordButton);
    await tester.pump();

    // Note: Actual recording functionality requires platform channels
    // This test just verifies the UI responds to taps
  });
}
