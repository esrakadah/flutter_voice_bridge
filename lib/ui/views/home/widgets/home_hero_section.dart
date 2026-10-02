import 'package:flutter/material.dart';

import '../../../components/audio_visualizer.dart';
import '../../animation_fullscreen_view.dart';
import '../home_state.dart';
import 'animation_controls_widget.dart';

/// The recorder hero: live visualizer, mode controls and the fullscreen entry.
class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({super.key, required this.state, required this.mode, required this.onModeChanged});

  final HomeState state;
  final AudioVisualizationMode mode;
  final ValueChanged<AudioVisualizationMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isRecording = state.isRecording;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(32, 16, 32, 20),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withAlpha(26),
            colorScheme.secondary.withAlpha(26),
            colorScheme.tertiary.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withAlpha(51)),
      ),
      child: Column(
        children: [
          // App title and subtitle
          Text(
            'Flutter Voice Bridge',
            style: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Record, transcribe, and extract insights. Enjoy the design elements.',
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Advanced Audio visualizer
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AdvancedAudioVisualizer(
              isRecording: isRecording,
              height: 80,
              primaryColor: colorScheme.primary,
              secondaryColor: colorScheme.tertiary,
              tertiaryColor: colorScheme.secondary,
              quaternaryColor: colorScheme.error,
              mode: mode,
              onTap: () => _navigateToFullscreen(context, colorScheme),
            ),
          ),
          const SizedBox(height: 24),

          // Ready state message and mode switcher
          if (!isRecording) ...[
            Text(
              'Tap the microphone to start recording',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withAlpha(60)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AnimationControlsWidget(
              currentMode: mode,
              onModeChanged: onModeChanged,
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToFullscreen(BuildContext context, ColorScheme colorScheme) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnimationFullscreenView(
          initialMode: mode,
          primaryColor: colorScheme.primary,
          secondaryColor: colorScheme.tertiary,
          tertiaryColor: colorScheme.secondary,
          quaternaryColor: colorScheme.error,
        ),
      ),
    );
  }
}
