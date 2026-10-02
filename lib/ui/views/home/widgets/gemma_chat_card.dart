import 'package:flutter/material.dart';

import '../../../../gemma/ui/gemma_chat_screen.dart';

/// Entry card for the experimental Gemma chat (iOS).
class GemmaChatCard extends StatelessWidget {
  const GemmaChatCard({super.key});

  /// 🤖 **Gemma AI Chat Card**
  ///
  /// Navigation card to access on-device AI chat powered by Gemma.
  /// Only available on iOS platform.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Card(
        elevation: 4,
        shadowColor: colorScheme.primary.withAlpha(13),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GemmaChatScreen()));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [colorScheme.tertiary, colorScheme.primary]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat with Gemma AI',
                            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'On-device AI assistant',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: colorScheme.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
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
                        '✨ Features:',
                        style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Natural conversations with AI\n'
                        '• Image analysis with multimodal models\n'
                        '• 100% offline & privacy-focused\n'
                        '• Multiple model options available',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GemmaChatScreen()));
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Start Chatting'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
