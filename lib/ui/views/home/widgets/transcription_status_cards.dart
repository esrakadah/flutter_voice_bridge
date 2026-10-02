import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home_cubit.dart';
import '../home_state.dart';

/// Shown while a transcription runs.
class TranscriptionProgressCard extends StatelessWidget {
  const TranscriptionProgressCard({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
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
}

/// Shown when a transcription failed, with a retry button.
class TranscriptionErrorCard extends StatelessWidget {
  const TranscriptionErrorCard({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
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

  void _retryTranscription(BuildContext context) {
    context.read<HomeCubit>().retryLastTranscription();
  }
}
