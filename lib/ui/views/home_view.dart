import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di.dart';
import '../../data/models/voice_memo.dart';
import 'home/home_cubit.dart';
import 'home/home_state.dart';
import 'package:flutter/services.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<HomeCubit>(), child: const HomeViewContent());
  }
}

class HomeViewContent extends StatelessWidget {
  const HomeViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Bridge AI'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.mic, size: 100, color: Colors.deepPurple),
                  const SizedBox(height: 24),
                  const Text('AI-Powered Voice Memo App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Workshop: Bridging the Gap', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 32),
                  // State-based UI updates
                  _buildStateContent(context, state),
                  const SizedBox(height: 24),
                  // Play button for completed recordings
                  _buildPlayButton(context, state),
                  const SizedBox(height: 32),
                  // Recordings list
                  _buildRecordingsList(context, state),
                  // Add bottom padding for better scrolling
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final bool isRecording = state is RecordingInProgress || state is RecordingStarted;

          return FloatingActionButton(
            onPressed: () {
              if (isRecording) {
                context.read<HomeCubit>().stopRecording();
              } else {
                context.read<HomeCubit>().startRecording();
              }
            },
            tooltip: isRecording ? 'Stop Recording' : 'Start Recording',
            backgroundColor: isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
            child: Icon(
              isRecording ? Icons.stop : Icons.mic,
              color: isRecording ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onPrimary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, HomeState state) {
    if (state is RecordingInProgress) {
      return Column(
        children: [
          const Text('Recording in progress...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Duration: ${_formatDuration(state.recordingDuration)}', style: const TextStyle(fontSize: 16)),
        ],
      );
    } else if (state is RecordingStarted) {
      return const Text('Recording started!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500));
    } else if (state is RecordingCompleted) {
      return Column(
        children: [
          const Text(
            'Recording completed!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text('Duration: ${_formatDuration(state.recordingDuration)}', style: const TextStyle(fontSize: 16)),
        ],
      );
    } else if (state is TranscriptionInProgress) {
      return Column(
        children: [
          const Text(
            'Recording completed!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text(
                'Transcribing audio...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue),
              ),
            ],
          ),
        ],
      );
    } else if (state is TranscriptionCompleted) {
      return Column(
        children: [
          const Text(
            'Recording completed!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Transcription completed!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTranscriptionDisplay(context, state.transcribedText, state.extractedKeywords),
        ],
      );
    } else if (state is TranscriptionError) {
      return Column(
        children: [
          const Text(
            'Recording completed!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Transcription failed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage,
            style: const TextStyle(fontSize: 14, color: Colors.orange),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (state is PlaybackInProgress) {
      return Column(
        children: [
          const Text(
            'Playing audio...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          // Show transcription if available
          if (state.transcriptionText != null) ...[
            const SizedBox(height: 16),
            _buildTranscriptionDisplay(context, state.transcriptionText!, state.keywords),
          ],
        ],
      );
    } else if (state is PlaybackCompleted) {
      return Column(
        children: [
          const Text(
            'Playback completed!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.blue),
          ),
          // Show transcription if available
          if (state.transcriptionText != null) ...[
            const SizedBox(height: 16),
            _buildTranscriptionDisplay(context, state.transcriptionText!, state.keywords),
          ],
        ],
      );
    } else if (state is PlaybackError) {
      return Column(
        children: [
          const Text(
            'Playback error!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage,
            style: const TextStyle(fontSize: 14, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (state is RecordingError) {
      return Column(
        children: [
          const Text(
            'Recording error!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage,
            style: const TextStyle(fontSize: 14, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      // Show transcription if available in any other state
      if (state.transcriptionText != null) {
        return Column(
          children: [
            const Text('Ready to record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _buildTranscriptionDisplay(context, state.transcriptionText!, state.keywords),
          ],
        );
      }
      return const Text('Ready to record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500));
    }
  }

  Widget _buildTranscriptionDisplay(BuildContext context, String transcriptionText, List<String> keywords) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.transcribe, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Transcription',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyToClipboard(context, transcriptionText),
                    tooltip: 'Copy transcription',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    onPressed: () => _shareTranscription(context, transcriptionText),
                    tooltip: 'Share transcription',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(transcriptionText, style: const TextStyle(fontSize: 14, height: 1.4)),
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.label, color: Colors.deepOrange, size: 16),
                SizedBox(width: 6),
                Text(
                  'Keywords',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: keywords.map((keyword) => _buildKeywordChip(keyword)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildKeywordChip(String keyword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepOrange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange[200]!),
      ),
      child: Text(
        keyword,
        style: TextStyle(fontSize: 12, color: Colors.deepOrange[700], fontWeight: FontWeight.w500),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcription copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareTranscription(BuildContext context, String text) {
    // We'll need to add share_plus package for this functionality
    // For now, just show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, HomeState state) {
    final cubit = context.read<HomeCubit>();
    final bool hasRecording = cubit.hasRecordingToPlay;
    final bool isRecording = state is RecordingInProgress || state is RecordingStarted;
    final bool isPlaying = state is PlaybackInProgress;

    // Don't show play button if recording or no recording available
    if (isRecording || !hasRecording) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: isPlaying
          ? null
          : () async {
              try {
                await cubit.playLastRecording();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback error: $e')));
                }
              }
            },
      icon: isPlaying
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.play_arrow),
      label: Text(isPlaying ? 'Playing...' : 'Play Recording'),
      backgroundColor: isPlaying
          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6)
          : Theme.of(context).colorScheme.secondary,
    );
  }

  Widget _buildRecordingsList(BuildContext context, HomeState state) {
    if (state.isLoadingRecordings) {
      return const Column(
        children: [
          Text('Loading recordings...', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          CircularProgressIndicator(),
        ],
      );
    }

    if (state.recordingsError != null) {
      return Column(
        children: [
          const Text('Error loading recordings', style: TextStyle(fontSize: 16, color: Colors.red)),
          Text(state.recordingsError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => context.read<HomeCubit>().loadRecordings(), child: const Text('Retry')),
        ],
      );
    }

    if (state.recordings.isEmpty) {
      return const Column(
        children: [
          Icon(Icons.mic_none, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No recordings yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
          Text('Record your first voice memo above', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Previous Recordings (${state.recordings.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => context.read<HomeCubit>().loadRecordings(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh recordings',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: state.recordings.length,
            itemBuilder: (context, index) {
              final recording = state.recordings[index];
              return _buildRecordingTile(context, recording, state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingTile(BuildContext context, VoiceMemo recording, HomeState state) {
    final bool isPlaying = state is PlaybackInProgress && state.filePath == recording.filePath;

    return Dismissible(
      key: Key(recording.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Recording'),
                content: Text('Are you sure you want to delete "${recording.title}"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        context.read<HomeCubit>().deleteRecording(recording.filePath);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${recording.title}"')));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: isPlaying ? Colors.blue : Theme.of(context).primaryColor,
            child: isPlaying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow, color: Colors.white),
          ),
          title: Row(
            children: [
              Expanded(child: Text(recording.title)),
              if (recording.isTranscribed)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.transcribe, color: Colors.green, size: 18),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatFileSize(recording.fileSizeBytes)),
              Text(_formatDateTime(recording.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (recording.isTranscribed && recording.transcription != null) ...[
                const SizedBox(height: 4),
                Text(
                  _truncateText(recording.transcription!, 60),
                  style: const TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else if (!recording.isTranscribed) ...[
                const SizedBox(height: 4),
                const Text('No transcription available', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
          trailing: IconButton(
            onPressed: () => _showDeleteRecordingDialog(context, recording),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete recording',
          ),
          onExpansionChanged: (expanded) {
            if (!expanded && !isPlaying) {
              // Only play when collapsed to expanded, not when collapsing
            }
          },
          children: [
            if (recording.isTranscribed && recording.transcription != null)
              Padding(padding: const EdgeInsets.all(16), child: _buildRecordingTranscriptionDisplay(context, recording))
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('This recording has not been transcribed yet.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.read<HomeCubit>().transcribeRecording(recording.filePath),
                      icon: const Icon(Icons.transcribe, size: 18),
                      label: const Text('Transcribe Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isPlaying ? null : () => context.read<HomeCubit>().playRecording(recording.filePath),
                    icon: isPlaying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow),
                    label: Text(isPlaying ? 'Playing...' : 'Play'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                  if (recording.isTranscribed && recording.transcription != null)
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(context, recording.transcription!),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingTranscriptionDisplay(BuildContext context, VoiceMemo recording) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.transcribe, color: Colors.blue, size: 16),
              SizedBox(width: 6),
              Text(
                'Transcription',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(recording.transcription!, style: const TextStyle(fontSize: 13, height: 1.3)),
          if (recording.keywords.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.label, color: Colors.orange, size: 14),
                SizedBox(width: 4),
                Text(
                  'Keywords',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: recording.keywords.map((keyword) => _buildSmallKeywordChip(keyword)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallKeywordChip(String keyword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Text(
        keyword,
        style: TextStyle(fontSize: 10, color: Colors.orange[700], fontWeight: FontWeight.w500),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _showDeleteRecordingDialog(BuildContext context, VoiceMemo recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text('Are you sure you want to delete "${recording.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<HomeCubit>().deleteRecording(recording.filePath);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${recording.title}"')));
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(double bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
