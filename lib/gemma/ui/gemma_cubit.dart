import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../data/gemma_service.dart';
import 'gemma_state.dart';

class GemmaCubit extends Cubit<GemmaState> {
  final GemmaService _gemmaService;

  GemmaCubit({required GemmaService gemmaService})
      : _gemmaService = gemmaService,
        super(const GemmaState());

  Future<void> initialize() async {
    emit(state.copyWith(
      status: GemmaStatus.loading,
      loadingMessage: 'Initializing...',
    ));

    try {
      final selectedModel = await _gemmaService.getSelectedModel();
      
      // Check if download is needed (only relevant for non-web)
      final isDownloaded = await _gemmaService.isModelDownloaded(selectedModel);
      
      if (!isDownloaded) {
        emit(state.copyWith(
          loadingMessage: 'Downloading ${selectedModel.displayName}...',
        ));
        
        await _gemmaService.downloadModel(selectedModel, (progress) {
          emit(state.copyWith(downloadProgress: progress));
        });
      }

      emit(state.copyWith(
        loadingMessage: 'Loading model...',
        downloadProgress: null,
      ));

      await _gemmaService.initializeChat();

      emit(state.copyWith(
        status: GemmaStatus.ready,
        modelSupportsImages: selectedModel.supportsImages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GemmaStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectImage(Uint8List imageBytes) {
    emit(state.copyWith(selectedImage: imageBytes));
  }

  void clearImage() {
    emit(state.copyWith(clearSelectedImage: true));
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty && state.selectedImage == null) return;
    if (state.isAwaitingResponse) return;

    final image = state.selectedImage;
    final currentMessages = List<Message>.from(state.messages);

    final Message userMessage;
    if (image != null) {
      final prompt = text.isNotEmpty ? text : "What's in this image?";
      userMessage = Message.withImage(text: prompt, imageBytes: image, isUser: true);
    } else {
      userMessage = Message(text: text, isUser: true);
    }

    currentMessages.add(userMessage);
    
    // Add placeholder for response
    currentMessages.add(Message(text: '', isUser: false));

    emit(state.copyWith(
      messages: currentMessages,
      isAwaitingResponse: true,
      clearSelectedImage: true,
    ));

    try {
      final stream = _gemmaService.sendMessage(text, imageBytes: image);
      
      String fullResponse = '';
      
      await for (final chunk in stream) {
        fullResponse += chunk;
        
        // Update the last message (which is the bot response placeholder)
        final updatedMessages = List<Message>.from(state.messages);
        if (updatedMessages.isNotEmpty && !updatedMessages.last.isUser) {
           updatedMessages.last = Message(text: fullResponse, isUser: false);
        }
        
        emit(state.copyWith(messages: updatedMessages));
      }
    } catch (e) {
      // Remove the placeholder if it failed completely or show error
      final updatedMessages = List<Message>.from(state.messages);
      if (updatedMessages.isNotEmpty && !updatedMessages.last.isUser) {
         // Optionally remove or mark as error
         updatedMessages.removeLast();
      }
      
      emit(state.copyWith(
        messages: updatedMessages,
        errorMessage: 'Failed to generate response: $e',
      ));
    } finally {
      emit(state.copyWith(isAwaitingResponse: false));
    }
  }
  
  void resetChat() {
    emit(const GemmaState());
    initialize();
  }
}
