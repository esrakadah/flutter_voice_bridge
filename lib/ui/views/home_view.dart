import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di.dart';
import '../../data/models/voice_memo.dart';
import 'home/home_cubit.dart';
import 'home/home_state.dart';
import 'package:flutter/services.dart';
import '../components/audio_visualizer.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<HomeCubit>(), child: const HomeViewContent());
  }
}

class HomeViewContent extends StatefulWidget {
  const HomeViewContent({super.key});

  @override
  State<HomeViewContent> createState() => _HomeViewContentState();
}

class _HomeViewContentState extends State<HomeViewContent> {
  AudioVisualizationMode _currentMode = AudioVisualizationMode.waveform;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Voice Bridge AI',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // Hero section with recording interface
              SliverToBoxAdapter(child: _buildHeroSection(context, state)),

              // Current recording status
              SliverToBoxAdapter(child: _buildRecordingStatusCard(context, state)),

              // Transcription results
              if (state.transcriptionText != null) SliverToBoxAdapter(child: _buildTranscriptionCard(context, state)),

              // Recordings list header
              SliverToBoxAdapter(child: _buildRecordingsHeader(context, state)),

              // Recordings list
              _buildRecordingsList(context, state),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildVisualizationModeChips(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeChip(context, 'Waveform', AudioVisualizationMode.waveform),
        const SizedBox(width: 8),
        _buildModeChip(context, 'Spectrum', AudioVisualizationMode.spectrum),
        const SizedBox(width: 8),
        _buildModeChip(context, 'Particles', AudioVisualizationMode.particles),
        const SizedBox(width: 8),
        _buildModeChip(context, 'Radial', AudioVisualizationMode.radial),
      ],
    );
  }

  Widget _buildModeChip(BuildContext context, String label, AudioVisualizationMode mode) {
    final isSelected = _currentMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                )
              : null,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onBackground.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, HomeState state) {
    final isRecording = state is RecordingInProgress || state is RecordingStarted;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // App title and subtitle
          Text(
            'AI Voice Memo',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Record, transcribe, and extract insights',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
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
              primaryColor: Theme.of(context).colorScheme.primary,
              secondaryColor: Theme.of(context).colorScheme.secondary,
              tertiaryColor: Theme.of(context).colorScheme.tertiary,
              mode: _currentMode,
            ),
          ),
          const SizedBox(height: 24),

          // Ready state message and mode switcher
          if (!isRecording) ...[
            Text(
              'Tap the microphone to start recording',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onBackground.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildVisualizationModeChips(context),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingStatusCard(BuildContext context, HomeState state) {
    if (state is HomeInitial) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        child: Padding(padding: const EdgeInsets.all(20), child: _buildStatusContent(context, state)),
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context, HomeState state) {
    if (state is RecordingInProgress) {
      return Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                'Recording in progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _formatDuration(state.recordingDuration),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (state is RecordingCompleted) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording completed',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.green),
                ),
                Text(
                  'Duration: ${_formatDuration(state.recordingDuration)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state is TranscriptionInProgress) {
      return Row(
        children: [
          Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transcribing audio...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text('This may take a few moments', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
    }

    if (state is RecordingError) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording error',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Text(state.errorMessage, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTranscriptionCard(BuildContext context, HomeState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Card(
        elevation: 6,
        shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.transcribe, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Transcription',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  _buildActionButtons(context, state.transcriptionText!),
                ],
              ),
              const SizedBox(height: 20),

              // Transcription text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
                child: Text(
                  state.transcriptionText!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ),

              // Keywords
              if (state.keywords.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.label_outline, size: 18, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Keywords',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.keywords.map((keyword) => _buildKeywordChip(context, keyword)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: () => _copyToClipboard(context, text),
          icon: const Icon(Icons.copy_outlined, size: 18),
          tooltip: 'Copy',
          style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: () => _shareTranscription(context, text),
          icon: const Icon(Icons.share_outlined, size: 18),
          tooltip: 'Share',
          style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
        ),
      ],
    );
  }

  Widget _buildKeywordChip(BuildContext context, String keyword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Text(
        keyword,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.tertiary),
      ),
    );
  }

  Widget _buildRecordingsHeader(BuildContext context, HomeState state) {
    if (state.recordings.isEmpty && !state.isLoadingRecordings) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 16),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
            style: IconButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsList(BuildContext context, HomeState state) {
    if (state.isLoadingRecordings) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(20),
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
          margin: const EdgeInsets.all(20),
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
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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
    final isPlaying = state is PlaybackInProgress && state.filePath == recording.filePath;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Card(
        elevation: 3,
        shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
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
                            ? [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]
                            : [
                                Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ],
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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (recording.isTranscribed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.transcribe, color: Colors.green, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Transcribed',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _formatFileSize(recording.fileSizeBytes),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Text('•', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(width: 8),
                            Text(_formatDateTime(recording.createdAt), style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () => _showDeleteDialog(context, recording),
                    icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                    tooltip: 'Delete',
                    style: IconButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                    ),
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
                      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (recording.isTranscribed && recording.transcription != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(context, recording.transcription!),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<HomeCubit>().transcribeRecording(recording.filePath),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording.transcription!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
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
                                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    keyword,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.tertiary,
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

  Widget _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final isRecording = state is RecordingInProgress || state is RecordingStarted;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isRecording
                  ? [
                      Theme.of(context).colorScheme.error,
                      Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                      Theme.of(context).colorScheme.error.withValues(alpha: 0.9),
                    ]
                  : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary)
                    .withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: (isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary)
                    .withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: FloatingActionButton.large(
            onPressed: () {
              if (isRecording) {
                context.read<HomeCubit>().stopRecording();
              } else {
                context.read<HomeCubit>().startRecording();
              }
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded, size: 32, color: Colors.white),
          ),
        );
      },
    );
  }

  // Helper methods
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _shareTranscription(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Share feature coming soon!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
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
