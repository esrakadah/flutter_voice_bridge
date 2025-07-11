import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// 📺 **Module 3: Platform Views Implementation**
///
/// Demonstrates embedding native UI components directly within Flutter.
/// This shows a simple native text view that's rendered by the platform's
/// native UI toolkit rather than Flutter's rendering engine.
///
/// **Learning Objectives:**
/// - Understand Platform View integration patterns
/// - See hybrid composition in action
/// - Compare native vs Flutter rendering
/// - Observe performance characteristics
class NativeTextView extends StatelessWidget {
  final String text;
  final Color backgroundColor;

  const NativeTextView({super.key, required this.text, this.backgroundColor = Colors.blue});

  @override
  Widget build(BuildContext context) {
    // Platform view creation parameters
    final Map<String, dynamic> creationParams = {'text': text, 'backgroundColor': backgroundColor.value};

    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildPlatformView(creationParams)),
    );
  }

  Widget _buildPlatformView(Map<String, dynamic> creationParams) {
    // Platform-specific view implementation
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: 'native-text-view',
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
          },
        );

      case TargetPlatform.android:
        return AndroidView(
          viewType: 'native-text-view',
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
          },
        );

      default:
        // Fallback for unsupported platforms (web, desktop)
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: backgroundColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            '$text\n(Platform Views not supported on this platform)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: backgroundColor, fontWeight: FontWeight.w500),
          ),
        );
    }
  }
}
