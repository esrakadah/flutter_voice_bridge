import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di.dart';
import '../../core/theme/theme_provider.dart';
import 'home/home_cubit.dart';
import 'home/home_state.dart';
import '../components/audio_visualizer.dart';
import 'home/widgets/recording_status_widget.dart';
import 'home/widgets/gemma_chat_card.dart';
import 'home/widgets/home_hero_section.dart';
import 'home/widgets/platform_view_demo_card.dart';
import 'home/widgets/process_run_demo_card.dart';
import 'home/widgets/record_button.dart';
import 'home/widgets/recordings_section.dart';
import 'home/widgets/transcription_card.dart';
import 'home/widgets/transcription_status_cards.dart';
import '../../core/branding/branding_cubit.dart';
import '../components/dynamic_app_bar.dart';
import 'settings/settings_view.dart';
import '../components/confetti_overlay.dart';

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
  final ConfettiController _confettiController = ConfettiController();

  @override
  Widget build(BuildContext context) {
    // 🎨 REACTIVE UI PATTERN
    // BlocBuilder automatically rebuilds UI when HomeCubit emits new states
    // This creates a reactive programming model where UI is a function of state
    final themeCubit = context.read<ThemeCubit>();
    final branding = context.watch<BrandingCubit>().state;

    return ConfettiOverlay(
      controller: _confettiController,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: branding.isEventMode
            ? DynamicAppBar(
                themeCubit: themeCubit,
                confettiController: _confettiController,
                branding: branding,
                onSettingsPressed: () => _openSettings(context),
              )
            : AppBar(
                title: Text(
                  'Voice Bridge AI',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Settings',
                    onPressed: () => _openSettings(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ConfettiButton(controller: _confettiController, size: 36),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: ThemeToggleButton(themeCubit: themeCubit, size: 36),
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
                SliverToBoxAdapter(
                  child: HomeHeroSection(
                    state: state,
                    mode: _currentMode,
                    onModeChanged: (mode) => setState(() => _currentMode = mode),
                  ),
                ),

                // Current recording status
                SliverToBoxAdapter(child: RecordingStatusWidget(state: state)),

                // Transcription results
                if (state.transcriptionText != null) SliverToBoxAdapter(child: TranscriptionCard(state: state)),

                // Transcription status (in progress or error)
                if (state.isTranscribing) const SliverToBoxAdapter(child: TranscriptionProgressCard()),
                if (state.transcriptionError != null) SliverToBoxAdapter(child: TranscriptionErrorCard(state: state)),

                // Recordings list header
                SliverToBoxAdapter(child: RecordingsHeader(state: state)),

                // Recordings list
                RecordingsList(state: state),

                // Gemma AI Chat (iOS)
                if (Platform.isIOS) const SliverToBoxAdapter(child: GemmaChatCard()),

                // Platform View demonstration
                const SliverToBoxAdapter(child: PlatformViewDemoCard()),

                // Process.run demo
                const SliverToBoxAdapter(child: ProcessRunDemoCard()),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
        floatingActionButton: const RecordButton(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsView()));
  }
}
