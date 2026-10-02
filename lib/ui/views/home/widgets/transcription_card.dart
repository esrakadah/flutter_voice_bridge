import 'package:flutter/material.dart';

import '../home_state.dart';
import 'transcript_actions.dart';

/// The latest transcript with its keywords and copy and share actions.
class TranscriptionCard extends StatelessWidget {
  const TranscriptionCard({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => copyTranscriptToClipboard(context, text),
          icon: const Icon(Icons.copy_outlined, size: 18),
          tooltip: 'Copy',
          style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(39))),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: () => shareTranscript(context, text),
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
}
