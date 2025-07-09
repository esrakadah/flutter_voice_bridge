import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di.dart';
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
