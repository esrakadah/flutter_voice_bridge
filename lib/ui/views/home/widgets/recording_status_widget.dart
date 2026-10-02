import 'package:flutter/material.dart';
import '../../home/home_state.dart';

/// Widget that displays the current recording status
///
/// Shows a card for the recorder's phase (recording, completed, failed) and for playback errors;
/// shows nothing while idle.
class RecordingStatusWidget extends StatelessWidget {
  final HomeState state;

  const RecordingStatusWidget({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final playbackError = state.playbackError;
    final sections = [
      ?_buildPhaseContent(context),
      if (playbackError != null) _buildErrorRow(context, 'Playback Error', playbackError),
    ];
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: sections,
          ),
        ),
      ),
    );
  }

  /// The recorder's phase (recording, completed, failed), or null while idle.
  Widget? _buildPhaseContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state.isRecording) {
      return Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text('Recording in progress', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _formatDuration(state.recordingDuration),
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
              ),
            ],
          ),
        ],
      );
    }

    if (state.recordingPhase == RecordingPhase.completed) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withAlpha(26), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording completed',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.green),
                ),
                Text('Duration: ${_formatDuration(state.recordingDuration)}', style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
    }

    final recordingError = state.recordingError;
    if (state.recordingPhase == RecordingPhase.failed && recordingError != null) {
      return _buildErrorRow(context, 'Recording Error', recordingError);
    }

    return null;
  }

  Widget _buildErrorRow(BuildContext context, String title, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colorScheme.error.withAlpha(26), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.error, color: colorScheme.error, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.error),
              ),
              Text(message, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  /// Formats duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
