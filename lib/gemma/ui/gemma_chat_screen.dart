import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';

import '../../di.dart';
import 'gemma_cubit.dart';
import 'gemma_settings_screen.dart';
import 'gemma_state.dart';

class GemmaChatScreen extends StatelessWidget {
  const GemmaChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<GemmaCubit>(),
      child: const _GemmaChatView(),
    );
  }
}

class _GemmaChatView extends StatefulWidget {
  const _GemmaChatView();

  @override
  State<_GemmaChatView> createState() => _GemmaChatViewState();
}

class _GemmaChatViewState extends State<_GemmaChatView> {
  final _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        final bytes = await pickedFile.readAsBytes();
        context.read<GemmaCubit>().selectImage(bytes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Chat with Gemma', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const GemmaSettingsScreen()));
                if (context.mounted) {
                  context.read<GemmaCubit>().resetChat();
                }
              },
              tooltip: 'Model Settings',
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary.withAlpha(26), colorScheme.secondary.withAlpha(13)],
            ),
          ),
        ),
      ),
      body: BlocConsumer<GemmaCubit, GemmaState>(
        listener: (context, state) {
          if (state.status == GemmaStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Failed: ${state.errorMessage}')),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == GemmaStatus.loading) {
            return _buildLoadingState(context, state, colorScheme, textTheme);
          }

          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyState(context, state, colorScheme, textTheme)
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[state.messages.length - 1 - index];
                          return ChatMessageWidget(message: message, colorScheme: colorScheme, textTheme: textTheme);
                        },
                      ),
              ),
              if (state.isAwaitingResponse) _buildThinkingIndicator(colorScheme, textTheme),
              _buildChatInputArea(context, state, colorScheme, textTheme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, GemmaState state, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        child: Card(
          elevation: 4,
          shadowColor: colorScheme.primary.withAlpha(13),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary)),
                const SizedBox(height: 24),
                Text(
                  state.loadingMessage,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                if (state.downloadProgress != null) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: state.downloadProgress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(state.downloadProgress! * 100).toStringAsFixed(1)}%',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, GemmaState state, ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Start a conversation',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask Gemma anything! I can help with questions, ideas, creative writing, and more.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
                if (state.modelSupportsImages) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_outlined, size: 16, color: colorScheme.tertiary),
                        const SizedBox(width: 6),
                        Text(
                          'Image analysis enabled',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Gemma is thinking...',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputArea(BuildContext context, GemmaState state, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(color: colorScheme.shadow.withAlpha(13), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.selectedImage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(state.selectedImage!, height: 120, width: 120, fit: BoxFit.cover),
                      ),
                      Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: colorScheme.error, borderRadius: BorderRadius.circular(20)),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: () {
                            context.read<GemmaCubit>().clearImage();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.image_outlined,
                      color: state.modelSupportsImages ? colorScheme.primary : colorScheme.outline,
                    ),
                    onPressed: state.modelSupportsImages ? () => _pickImage(context) : null,
                    tooltip: state.modelSupportsImages ? 'Add image' : 'Current model does not support images',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outline.withAlpha(39)),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Ask Gemma anything...',
                          hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(40),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: state.isAwaitingResponse
                          ? null
                          : () {
                              final text = _textController.text.trim();
                              context.read<GemmaCubit>().sendMessage(text);
                              _textController.clear();
                            },
                      padding: const EdgeInsets.all(12),
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
}

class ChatMessageWidget extends StatelessWidget {
  final Message message;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const ChatMessageWidget({super.key, required this.message, required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Card(
          elevation: 2,
          shadowColor: colorScheme.shadow.withAlpha(13),
          color: isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(message.imageBytes!, width: 200, height: 200, fit: BoxFit.cover),
                    ),
                  ),
                if (message.text.isNotEmpty)
                  MarkdownBody(
                    data: message.text.replaceAll(r'\n', '\n'),
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: textTheme.bodyLarge?.copyWith(
                        color: isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                      code: TextStyle(
                        color: isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                        backgroundColor: Colors.transparent,
                        fontFamily: 'monospace',
                      ),
                    ),
                    selectable: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
