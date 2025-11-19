import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di.dart';
import '../../data/models/voice_memo.dart';
import '../../core/theme/theme_provider.dart';
import 'home/home_cubit.dart';
import 'home/home_state.dart';
import 'package:flutter/services.dart';
import '../components/audio_visualizer.dart';
import '../components/native_text_view.dart';
import 'animation_fullscreen_view.dart';
import '../../core/audio/audio_converter.dart';
import 'home/widgets/animation_controls_widget.dart';
import 'home/widgets/recording_status_widget.dart';

/// 🎓 **WORKSHOP MODULE 1.1: Clean Architecture UI Layer**
///
/// **Learning Objectives:**
/// - Understand separation between UI and business logic
/// - Learn reactive UI patterns with BLoC builders
/// - Practice custom widget composition and reusability
/// - Master dependency injection in widget trees
///
/// **Key Patterns Demonstrated:**
/// - Provider Pattern: BlocProvider for dependency injection
/// - Observer Pattern: BlocBuilder for reactive UI updates
/// - Composition: Breaking complex UI into smaller widgets
/// - State-Driven UI: UI changes based on business logic state
///
/// **Architecture Layer:** Presentation (top layer, user-facing)

// 🏗️ WIDGET COMPOSITION PATTERN
// Separating Provider setup from UI content makes the code more testable
// and allows for easier widget tree manipulation in tests

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // 💉 DEPENDENCY INJECTION PATTERN
    // BlocProvider creates and provides HomeCubit to the widget tree
    // getIt<HomeCubit>() uses service locator pattern to resolve dependencies
    // This creates a new instance each time (registered as Factory in DI)
    return BlocProvider(
      create: (_) => getIt<HomeCubit>(), // 🏭 Factory pattern creates new Cubit instance
      child: const HomeViewContent(), // 🎨 Separate content widget for cleaner separation
    );
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
    // 🎨 REACTIVE UI PATTERN
    // BlocBuilder automatically rebuilds UI when HomeCubit emits new states
    // This creates a reactive programming model where UI is a function of state
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Voice Bridge AI',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Theme toggle button
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ThemeToggleButton(themeCubit: context.read<ThemeCubit>(), size: 36),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withAlpha(26),
                Theme.of(context).colorScheme.secondary.withAlpha(13),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        // 🔄 REACTIVE UI BUILDER
        // This builder function is called every time HomeCubit emits a new state
        // The 'state' parameter contains the current application state
        // UI rebuilds are optimized - only changed widgets are rebuilt
        builder: (context, state) {
          // 📋 CUSTOM SCROLL VIEW PATTERN
          // Using CustomScrollView with Slivers provides better performance
          // for complex scrollable layouts with multiple sections
          return CustomScrollView(
            slivers: [
              // Hero section with recording interface
              SliverToBoxAdapter(child: _buildHeroSection(context, state)),

              // Current recording status
              SliverToBoxAdapter(child: RecordingStatusWidget(state: state)),

              // Transcription results
              if (state.transcriptionText != null) SliverToBoxAdapter(child: _buildTranscriptionCard(context, state)),

              // Transcription status (in progress or error)
              if (state.isTranscribing) SliverToBoxAdapter(child: _buildTranscriptionProgressCard(context, state)),
              if (state.transcriptionError != null)
                SliverToBoxAdapter(child: _buildTranscriptionErrorCard(context, state)),

              // Recordings list header
              SliverToBoxAdapter(child: _buildRecordingsHeader(context, state)),

              // Recordings list
              _buildRecordingsList(context, state),

              // Platform View demonstration
              SliverToBoxAdapter(child: _buildPlatformViewDemo(context)),

              // Process.run demo
              SliverToBoxAdapter(child: _buildProcessRunDemo(context)),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildHeroSection(BuildContext context, HomeState state) {
    final isRecording = state is RecordingInProgress || state is RecordingStarted;
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
            'AI Voice Memo',
            style: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Record, transcribe, and extract insights',
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
              secondaryColor: colorScheme.secondary,
              tertiaryColor: colorScheme.tertiary,
              mode: _currentMode,
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
              currentMode: _currentMode,
              onModeChanged: (mode) => setState(() => _currentMode = mode),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranscriptionCard(BuildContext context, HomeState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Ensure we have valid transcription text before building the card
    final transcriptionText = state.transcriptionText;
    if (transcriptionText == null || transcriptionText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Card(
        elevation: 6,
        shadowColor: colorScheme.primary.withAlpha(13),
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
                      gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.transcribe, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Transcription', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  _buildActionButtons(context, transcriptionText),
                ],
              ),
              const SizedBox(height: 20),

              // Transcription text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withAlpha(39)),
                ),
                child: Text(transcriptionText, style: textTheme.bodyLarge?.copyWith(height: 1.6)),
              ),

              // Keywords
              if (state.keywords.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.label_outline, size: 18, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Keywords',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.tertiary),
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
    // Add null safety check
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: () => _copyToClipboard(context, text),
          icon: const Icon(Icons.copy_outlined, size: 18),
          tooltip: 'Copy',
          style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(39))),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: () => _shareTranscription(context, text),
          icon: const Icon(Icons.share_outlined, size: 18),
          tooltip: 'Share',
          style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(39))),
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
            Theme.of(context).colorScheme.tertiary.withAlpha(10),
            Theme.of(context).colorScheme.secondary.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.tertiary.withAlpha(39)),
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
        ],
      ),
    );
  }

  Widget _buildRecordingsList(BuildContext context, HomeState state) {
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
    final isPlaying = state is PlaybackInProgress && state.filePath == recording.filePath;
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
                        onPressed: () => _copyToClipboard(context, recording.transcription!),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: recording.filePath.isNotEmpty
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
                      Theme.of(context).colorScheme.error.withAlpha(80),
                      Theme.of(context).colorScheme.error.withAlpha(90),
                    ]
                  : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary.withAlpha(80),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary)
                    .withAlpha(40),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: (isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary)
                    .withAlpha(20),
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

  void _retryTranscription(BuildContext context) {
    // Get the most recent recording file path for retry
    final state = context.read<HomeCubit>().state;
    if (state.recordings.isNotEmpty) {
      final latestRecording = state.recordings.first;
      // Add null safety check for file path
      if (latestRecording.filePath.isNotEmpty) {
        context.read<HomeCubit>().transcribeRecording(latestRecording.filePath);
      } else {
        // Show error if no valid file path
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('No valid recording file found to transcribe'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      // Show error if no recordings available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('No recordings available to transcribe'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildTranscriptionProgressCard(BuildContext context, HomeState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Card(
        elevation: 6,
        shadowColor: colorScheme.primary.withAlpha(13),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transcribing Audio...', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Converting speech to text using AI',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
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

  Widget _buildTranscriptionErrorCard(BuildContext context, HomeState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Card(
        elevation: 6,
        shadowColor: colorScheme.error.withAlpha(13),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Transcription Failed', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.error.withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.error.withAlpha(39)),
                ),
                child: Text(
                  state.transcriptionError ?? 'Unknown error occurred',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This might be due to audio format compatibility or missing native libraries. Check the debug logs for more details.',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              // Retry button
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _retryTranscription(context),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry Transcription'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📺 **Module 3: Platform Views Integration**
  ///
  /// Demonstrates embedding native UI components directly within Flutter.
  /// This shows how Platform Views bridge Flutter's widget tree with
  /// native platform UI components.
  Widget _buildPlatformViewDemo(BuildContext context) {
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

  /// 🔧 **Module 5: Process.run Integration Demo**
  ///
  /// Demonstrates external tool integration for specialized processing
  Widget _buildProcessRunDemo(BuildContext context) {
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
                      gradient: LinearGradient(colors: [colorScheme.secondary, colorScheme.tertiary]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.terminal, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Process.run Demo', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          'External tool integration with FFmpeg',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // FFmpeg availability check
              FutureBuilder<bool>(
                future: AudioConverter.isFFmpegAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Checking FFmpeg availability...'),
                      ],
                    );
                  }

                  final isAvailable = snapshot.data ?? false;
                  final icon = isAvailable ? Icons.check_circle : Icons.error;
                  final color = isAvailable ? Colors.green : Colors.orange;
                  final message = isAvailable
                      ? 'FFmpeg is available for audio processing'
                      : 'FFmpeg not found - install for audio conversion features';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                style: textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                              ),
                              if (isAvailable) ...[
                                const SizedBox(height: 4),
                                FutureBuilder<String>(
                                  future: AudioConverter.getFFmpegVersion(),
                                  builder: (context, versionSnapshot) {
                                    final version = versionSnapshot.data ?? 'Loading...';
                                    return Text(
                                      'Version: $version',
                                      style: textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8)),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

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
                      '💡 Process.run capabilities demonstrated:',
                      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• System command execution with Process.run()\n'
                      '• External tool integration (FFmpeg for audio conversion)\n'
                      '• Security: Command whitelisting and input validation\n'
                      '• Error handling: Graceful degradation when tools unavailable\n'
                      '• Output parsing: JSON processing from external tools',
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

  void _navigateToFullscreen(BuildContext context, ColorScheme colorScheme) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnimationFullscreenView(
          initialMode: _currentMode,
          primaryColor: colorScheme.primary,
          secondaryColor: colorScheme.secondary,
          tertiaryColor: colorScheme.tertiary,
        ),
      ),
    );
  }
}
