import 'package:flutter/material.dart';

// Audio visualizer component for displaying audio waveforms
class AudioVisualizer extends StatelessWidget {
  final List<double> audioData;
  final Color barColor;
  final double barWidth;
  final double barSpacing;
  final double maxHeight;

  const AudioVisualizer({
    super.key,
    required this.audioData,
    this.barColor = Colors.blue,
    this.barWidth = 4.0,
    this.barSpacing = 2.0,
    this.maxHeight = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: audioData.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;

          return Container(
            width: barWidth,
            height: value * maxHeight,
            margin: EdgeInsets.only(right: index < audioData.length - 1 ? barSpacing : 0),
            decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(barWidth / 2)),
          );
        }).toList(),
      ),
    );
  }
}

// Animated audio visualizer for real-time audio display
class AnimatedAudioVisualizer extends StatefulWidget {
  final int barCount;
  final Color barColor;
  final double barWidth;
  final double barSpacing;
  final double maxHeight;
  final bool isAnimating;

  const AnimatedAudioVisualizer({
    super.key,
    this.barCount = 20,
    this.barColor = Colors.blue,
    this.barWidth = 4.0,
    this.barSpacing = 2.0,
    this.maxHeight = 100.0,
    this.isAnimating = false,
  });

  @override
  State<AnimatedAudioVisualizer> createState() => _AnimatedAudioVisualizerState();
}

class _AnimatedAudioVisualizerState extends State<AnimatedAudioVisualizer> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(widget.barCount, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();
  }

  @override
  void didUpdateWidget(AnimatedAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: widget.barWidth,
                height: widget.isAnimating ? _animations[index].value * widget.maxHeight : widget.maxHeight * 0.1,
                margin: EdgeInsets.only(right: index < widget.barCount - 1 ? widget.barSpacing : 0),
                decoration: BoxDecoration(
                  color: widget.barColor,
                  borderRadius: BorderRadius.circular(widget.barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
