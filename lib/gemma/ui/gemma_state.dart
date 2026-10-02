import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

enum GemmaStatus { initial, loading, ready, error }

/// Nullable fields are cleared through [copyWith] by passing a getter that returns null,
/// for example `state.copyWith(sendError: () => null)`. Omitting an argument keeps the value.
@immutable
class GemmaState extends Equatable {
  const GemmaState({
    this.status = GemmaStatus.initial,
    this.messages = const [],
    this.loadingMessage = '',
    this.downloadProgress,
    this.isAwaitingResponse = false,
    this.errorMessage,
    this.sendError,
    this.selectedImage,
    this.modelSupportsImages = false,
  });

  final GemmaStatus status;
  final List<Message> messages;
  final String loadingMessage;
  final double? downloadProgress;
  final bool isAwaitingResponse;

  /// Why the model could not be prepared; shown instead of the chat.
  final String? errorMessage;

  /// Why the last message got no reply; shown once as a snackbar while the chat stays usable.
  final String? sendError;
  final Uint8List? selectedImage;
  final bool modelSupportsImages;

  GemmaState copyWith({
    GemmaStatus? status,
    List<Message>? messages,
    String? loadingMessage,
    ValueGetter<double?>? downloadProgress,
    bool? isAwaitingResponse,
    ValueGetter<String?>? errorMessage,
    ValueGetter<String?>? sendError,
    ValueGetter<Uint8List?>? selectedImage,
    bool? modelSupportsImages,
  }) {
    return GemmaState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      downloadProgress: downloadProgress != null ? downloadProgress() : this.downloadProgress,
      isAwaitingResponse: isAwaitingResponse ?? this.isAwaitingResponse,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      sendError: sendError != null ? sendError() : this.sendError,
      selectedImage: selectedImage != null ? selectedImage() : this.selectedImage,
      modelSupportsImages: modelSupportsImages ?? this.modelSupportsImages,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    loadingMessage,
    downloadProgress,
    isAwaitingResponse,
    errorMessage,
    sendError,
    selectedImage,
    modelSupportsImages,
  ];
}
