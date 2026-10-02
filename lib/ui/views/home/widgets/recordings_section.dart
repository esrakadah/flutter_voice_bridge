import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/voice_memo.dart';
import '../home_cubit.dart';
import '../home_state.dart';
import 'transcript_actions.dart';

/// Title row of the recordings list with refresh and delete-all.
class RecordingsHeader extends StatelessWidget {
  const RecordingsHeader({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.recordings.isEmpty && !state.isLoadingRecordings) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Row(
        children: [
          Text(
            'Previous Recordings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (state.recordings.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.recordings.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton.outlined(
            onPressed: () => context.read<HomeCubit>().loadRecordings(),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(39))),
          ),
          if (state.recordings.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () => _showDeleteAllDialog(context),
              icon: Icon(Icons.delete_sweep_outlined, size: 20, color: Theme.of(context).colorScheme.error),
              tooltip: 'Delete All',
              style: IconButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.error.withAlpha(128)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDeleteAllDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Recordings'),
        content: const Text('Are you sure you want to delete ALL recordings? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<HomeCubit>().deleteAllRecordings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All recordings deleted'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

/// The recordings as a sliver: loading, empty or one tile per memo.
class RecordingsList extends StatelessWidget {
  const RecordingsList({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingRecordings) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(32),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('Loading recordings...', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (state.recordings.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(32),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.mic_none_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start recording to see your voice memos here',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: state.recordings.length,
      itemBuilder: (context, index) {
        final recording = state.recordings[index];
        return _buildRecordingTile(context, recording, state);
      },
    );
  }

  Widget _buildRecordingTile(BuildContext context, VoiceMemo recording, HomeState state) {
    final isPlaying = state.playingFilePath == recording.filePath;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: Card(
        elevation: 3,
        shadowColor: colorScheme.primary.withAlpha(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPlaying
                            ? [colorScheme.primary, colorScheme.secondary]
                            : [colorScheme.outline.withAlpha(51), colorScheme.outline.withAlpha(39)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isPlaying
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recording.title,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (recording.isTranscribed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.transcribe, color: Colors.green, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Transcribed',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(_formatFileSize(recording.fileSizeBytes), style: textTheme.bodySmall),
                            const SizedBox(width: 8),
                            Text('•', style: textTheme.bodySmall),
                            const SizedBox(width: 8),
                            Text(_formatDateTime(recording.createdAt), style: textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () => _showDeleteDialog(context, recording),
                    icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                    tooltip: 'Delete',
                    style: IconButton.styleFrom(side: BorderSide(color: colorScheme.error.withAlpha(178))),
                  ),
                ],
              ),

              // Action buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isPlaying ? null : () => context.read<HomeCubit>().playRecording(recording.filePath),
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(isPlaying ? 'Playing...' : 'Play'),
                      style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (recording.isTranscribed && recording.transcription != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => copyTranscriptToClipboard(context, recording.transcription!),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: recording.filePath.isNotEmpty && !state.isTranscribing
                            ? () => context.read<HomeCubit>().transcribeRecording(recording.filePath)
                            : null,
                        icon: const Icon(Icons.transcribe),
                        label: const Text('Transcribe'),
                      ),
                    ),
                ],
              ),

              // Transcription preview
              if (recording.isTranscribed && recording.transcription != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline.withAlpha(39)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording.transcription!,
                        style: textTheme.bodyMedium?.copyWith(height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (recording.keywords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: recording.keywords
                              .take(3)
                              .map(
                                (keyword) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiary.withAlpha(10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    keyword,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.tertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, VoiceMemo recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Recording'),
        content: Text('Are you sure you want to delete "${recording.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<HomeCubit>().deleteRecording(recording.filePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${recording.title}"'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _formatFileSize(double bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordingDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (recordingDate == today) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (recordingDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
