import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di.dart';
import '../../data/models/voice_memo.dart';
import 'home/home_cubit.dart';
import 'home/home_state.dart';

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.mic, size: 100, color: Colors.deepPurple),
                const SizedBox(height: 24),
                const Text('AI-Powered Voice Memo App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Workshop: Bridging the Gap', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 32),
                // State-based UI updates
                _buildStateContent(state),
                const SizedBox(height: 24),
                // Play button for completed recordings
                _buildPlayButton(context, state),
                const SizedBox(height: 32),
                // Recordings list
                _buildRecordingsList(context, state),
              ],
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

  Widget _buildStateContent(HomeState state) {
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
    } else if (state is PlaybackInProgress) {
      return const Column(
        children: [
          Text(
            'Playing audio...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.blue),
          ),
          SizedBox(height: 8),
          CircularProgressIndicator(),
        ],
      );
    } else if (state is PlaybackCompleted) {
      return const Text(
        'Playback completed!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.blue),
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
      return const Text('Ready to record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500));
    }
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
          ? Theme.of(context).colorScheme.secondary.withOpacity(0.6)
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
        child: ListTile(
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
          title: Text(recording.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatFileSize(recording.fileSizeBytes)),
              Text(_formatDateTime(recording.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          trailing: IconButton(
            onPressed: () async {
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
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete recording',
          ),
          onTap: isPlaying
              ? null
              : () {
                  context.read<HomeCubit>().playRecording(recording.filePath);
                },
        ),
      ),
    );
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
