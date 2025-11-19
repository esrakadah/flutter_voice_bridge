import 'package:flutter/material.dart';
import '../../home/home_state.dart';

/// Widget that displays the current recording status
///
/// Shows different UI based on the recording state:
/// - RecordingInProgress: Shows recording indicator with duration
/// - RecordingCompleted: Shows success message with final duration
/// - RecordingError: Shows error message
/// - HomeInitial: Shows nothing (hidden)
class RecordingStatusWidget extends StatelessWidget {
  final HomeState state;

  const RecordingStatusWidget({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    if (state is HomeInitial) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Card(
        child: Padding(padding: const EdgeInsets.all(20), child: _buildStatusContent(context)),
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state is RecordingInProgress) {
      final recordingState = state as RecordingInProgress;
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
                _formatDuration(recordingState.recordingDuration),
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
              ),
            ],
          ),
        ],
      );
    }

    if (state is RecordingCompleted) {
      final completedState = state as RecordingCompleted;
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
                Text('Duration: ${_formatDuration(completedState.recordingDuration)}', style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
    }

    if (state is RecordingError) {
      final errorState = state as RecordingError;
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
                  'Recording Error',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.error),
                ),
                Text(errorState.errorMessage, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Formats duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}


