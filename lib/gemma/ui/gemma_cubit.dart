import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../data/gemma_service.dart';
import 'gemma_state.dart';

class GemmaCubit extends Cubit<GemmaState> {
  GemmaCubit({required GemmaService gemmaService}) : _gemmaService = gemmaService, super(const GemmaState());

  static const String defaultImagePrompt = "What's in this image?";

  final GemmaService _gemmaService;

  Future<void> initialize() async {
    emit(
      state.copyWith(
        status: GemmaStatus.loading,
        loadingMessage: 'Initializing...',
        errorMessage: () => null,
        downloadProgress: () => null,
      ),
    );

    try {
      final selectedModel = await _gemmaService.getSelectedModel();
      if (!await _gemmaService.isModelDownloaded(selectedModel)) {
        emit(state.copyWith(loadingMessage: 'Downloading ${selectedModel.displayName}...'));
        await _gemmaService.downloadModel(selectedModel, (progress) {
          emit(state.copyWith(downloadProgress: () => progress));
        });
      }

      emit(state.copyWith(loadingMessage: 'Loading model...', downloadProgress: () => null));
      await _gemmaService.initializeChat();
      emit(state.copyWith(status: GemmaStatus.ready, modelSupportsImages: selectedModel.supportsImages));
    } catch (error) {
      emit(state.copyWith(status: GemmaStatus.error, errorMessage: () => error.toString()));
    }
  }

  void selectImage(Uint8List imageBytes) => emit(state.copyWith(selectedImage: () => imageBytes));

  void clearImage() => emit(state.copyWith(selectedImage: () => null));

  Future<void> sendMessage(String text) async {
    final image = state.selectedImage;
    if (text.isEmpty && image == null) return;
    if (state.isAwaitingResponse) return;

    final userMessage = image != null
        ? Message.withImage(text: text.isNotEmpty ? text : defaultImagePrompt, imageBytes: image, isUser: true)
        : Message(text: text, isUser: true);
    final replyPlaceholder = Message(text: '', isUser: false);

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage, replyPlaceholder],
        isAwaitingResponse: true,
        selectedImage: () => null,
        sendError: () => null,
      ),
    );

    try {
      var fullResponse = '';
      await for (final chunk in _gemmaService.sendMessage(userMessage)) {
        fullResponse += chunk;
        emit(state.copyWith(messages: _withReply(Message(text: fullResponse, isUser: false))));
      }
    } catch (error) {
      emit(
        state.copyWith(messages: _withoutReplyPlaceholder(), sendError: () => 'Failed to generate response: $error'),
      );
    } finally {
      emit(state.copyWith(isAwaitingResponse: false));
    }
  }

  Future<void> resetChat() async {
    emit(const GemmaState());
    await initialize();
  }

  /// A reply can still be streaming when the chat screen's owner closes the cubit; drop those late updates.
  @override
  void emit(GemmaState state) {
    if (isClosed) return;
    super.emit(state);
  }

  List<Message> _withReply(Message reply) {
    final messages = List<Message>.from(state.messages);
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = reply;
    }
    return messages;
  }

  List<Message> _withoutReplyPlaceholder() {
    final messages = List<Message>.from(state.messages);
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages.removeLast();
    }
    return messages;
  }
}
