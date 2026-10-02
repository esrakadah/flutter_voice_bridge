import 'package:flutter/material.dart';

import '../../../../core/audio/audio_converter.dart';

/// 🔧 **Module 5: Process.run Integration Demo**
///
/// Demonstrates external tool integration for specialized processing
///
/// Demo card that runs `ffmpeg -version` through Process.run when tapped.
class ProcessRunDemoCard extends StatefulWidget {
  const ProcessRunDemoCard({super.key});

  @override
  State<ProcessRunDemoCard> createState() => _ProcessRunDemoCardState();
}

class _ProcessRunDemoCardState extends State<ProcessRunDemoCard> {
  /// Started on demand so a rebuild never spawns another ffmpeg process.
  Future<String?>? _ffmpegVersionProbe;

  /// Returns the ffmpeg version, or null when ffmpeg is not reachable.
  Future<String?> _probeFfmpeg() async {
    final isAvailable = await AudioConverter.isFFmpegAvailable();
    if (!isAvailable) return null;
    return AudioConverter.getFFmpegVersion();
  }

  @override
  Widget build(BuildContext context) {
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

              // FFmpeg availability check, run only when asked
              if (_ffmpegVersionProbe == null)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _ffmpegVersionProbe = _probeFfmpeg()),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run ffmpeg -version'),
                )
              else
                FutureBuilder<String?>(
                  future: _ffmpegVersionProbe,
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

                    final version = snapshot.data;
                    final isAvailable = version != null;
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
                                  Text(
                                    'Version: $version',
                                    style: textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8)),
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
}
