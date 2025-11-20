import 'package:flutter/material.dart';
import '../../../components/audio_visualizer.dart';

/// Widget for controlling audio visualization modes
///
/// Displays chips for selecting different visualization modes:
/// - Waveform
/// - Spectrum
/// - Particles
/// - Radial
class AnimationControlsWidget extends StatelessWidget {
  final AudioVisualizationMode currentMode;
  final ValueChanged<AudioVisualizationMode> onModeChanged;

  const AnimationControlsWidget({required this.currentMode, required this.onModeChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
      ),
    );
  }

  Widget _buildModeChip(BuildContext context, String label, AudioVisualizationMode mode) {
    final bool isSelected = currentMode == mode;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onModeChanged(mode),
      selectedColor: Theme.of(context).colorScheme.primary.withAlpha(128),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withAlpha(64),
        width: isSelected ? 2 : 1,
      ),
    );
  }
}


