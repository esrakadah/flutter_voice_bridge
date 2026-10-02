import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home_cubit.dart';
import '../home_state.dart';

/// The large record and stop button.
class RecordButton extends StatelessWidget {
  const RecordButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final isRecording = state.isRecording;

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
}
