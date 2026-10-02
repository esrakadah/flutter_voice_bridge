import 'package:flutter/material.dart';

import '../../../components/native_text_view.dart';

/// Demo card embedding a native text view.
class PlatformViewDemoCard extends StatelessWidget {
  const PlatformViewDemoCard({super.key});

  /// 📺 **Module 3: Platform Views Integration**
  ///
  /// Demonstrates embedding native UI components directly within Flutter.
  /// This shows how Platform Views bridge Flutter's widget tree with
  /// native platform UI components.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Card(
        elevation: 4,
        shadowColor: colorScheme.primary.withAlpha(13),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorScheme.tertiary, colorScheme.primary]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.integration_instructions, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Platform View Demo', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          'Native UI component embedded in Flutter',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Native text view demonstration
              const NativeTextView(text: '🔗 Hello from Native Platform UI!', backgroundColor: Colors.deepPurple),

              const SizedBox(height: 12),

              // Information text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 This text is rendered by native platform UI:',
                      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• iOS: Uses UILabel with native typography\n'
                      '• Android: Uses TextView with platform theming\n'
                      '• Desktop: Fallback to Flutter implementation',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
