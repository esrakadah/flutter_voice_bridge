import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

enum GemmaStatus { initial, loading, ready, error }

class GemmaState extends Equatable {
  final GemmaStatus status;
  final List<Message> messages;
  final String loadingMessage;
  final double? downloadProgress;
  final bool isAwaitingResponse;
  final String? errorMessage;
  final Uint8List? selectedImage;
  final bool modelSupportsImages;

  const GemmaState({
    this.status = GemmaStatus.initial,
    this.messages = const [],
    this.loadingMessage = '',
    this.downloadProgress,
    this.isAwaitingResponse = false,
    this.errorMessage,
    this.selectedImage,
    this.modelSupportsImages = false,
  });

  GemmaState copyWith({
    GemmaStatus? status,
    List<Message>? messages,
    String? loadingMessage,
    double? downloadProgress,
    bool? isAwaitingResponse,
    String? errorMessage,
    Uint8List? selectedImage,
    bool? modelSupportsImages,
    bool clearSelectedImage = false,
  }) {
    return GemmaState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isAwaitingResponse: isAwaitingResponse ?? this.isAwaitingResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedImage: clearSelectedImage ? null : (selectedImage ?? this.selectedImage),
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
        selectedImage,
        modelSupportsImages,
      ];
}
