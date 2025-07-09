import 'package:flutter/material.dart';

// Reusable voice recorder button widget
class VoiceRecorderButton extends StatefulWidget {
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final bool isRecording;
  final bool isEnabled;

  const VoiceRecorderButton({
    super.key,
    this.onStartRecording,
    this.onStopRecording,
    required this.isRecording,
    this.isEnabled = true,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isEnabled) return;

    if (widget.isRecording) {
      widget.onStopRecording?.call();
      _animationController.reset();
    } else {
      widget.onStartRecording?.call();
      _animationController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRecording ? _scaleAnimation.value : 1.0,
          child: FloatingActionButton.large(
            onPressed: widget.isEnabled ? _handleTap : null,
            backgroundColor: widget.isRecording
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            child: Icon(
              widget.isRecording ? Icons.stop : Icons.mic,
              size: 32,
              color: widget.isRecording
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }
}
