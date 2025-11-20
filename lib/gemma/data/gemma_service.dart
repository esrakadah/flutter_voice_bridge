import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

import '../domain/available_models.dart';
import 'gemma_constants.dart';
import 'gemma_downloader_datasource.dart';

class GemmaService {
  InferenceModel? _inferenceModel;
  InferenceChat? _chat;
  bool _isInitialized = false;

  // Get the currently selected model from preferences
  Future<AvailableModel> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedFilename = prefs.getString(GemmaConstants.prefsSelectedModelKey);

    if (selectedFilename != null) {
      return AvailableModel.values.firstWhere(
        (m) => m.filename == selectedFilename,
        orElse: () => AvailableModel.gemma1b,
      );
    }
    return AvailableModel.gemma1b;
  }

  // Save the selected model to preferences
  Future<void> setSelectedModel(AvailableModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GemmaConstants.prefsSelectedModelKey, model.filename);
  }

  // Check if a model is downloaded and valid
  Future<bool> isModelDownloaded(AvailableModel model) async {
    if (kIsWeb) return true; // Web doesn't need local download in the same way
    
    final datasource = GemmaDownloaderDataSource(model: model.toDownloadModel());
    return await datasource.checkModelExistence();
  }

  // Download a model with progress updates
  Future<void> downloadModel(AvailableModel model, Function(double) onProgress) async {
    if (kIsWeb) return;

    final datasource = GemmaDownloaderDataSource(model: model.toDownloadModel());
    await datasource.downloadModel(
      token: GemmaConstants.huggingFaceAccessToken,
      onProgress: onProgress,
    );
  }

  // Delete a model
  Future<void> deleteModel(AvailableModel model) async {
    if (kIsWeb) return;

    final datasource = GemmaDownloaderDataSource(model: model.toDownloadModel());
    // We need to manually implement delete since datasource only has deleteOldModels
    // But we can reuse the logic or add a method to datasource.
    // For now, let's implement it here using the path logic from datasource
    
    // Ideally, we should add deleteModel to GemmaDownloaderDataSource.
    // I will add a TODO and implement a basic deletion here for now.
    // Or better, let's just use the file API directly as we know the path.
    final path = await datasource.getFilePath();
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${GemmaConstants.prefsModelDownloadedPrefix}${model.filename}');
  }

  // Initialize the chat engine with the selected model
  Future<void> initializeChat() async {
    try {
      final gemma = FlutterGemmaPlugin.instance;
      final selectedModel = await getSelectedModel();

      if (!kIsWeb) {
        final datasource = GemmaDownloaderDataSource(model: selectedModel.toDownloadModel());
        
        // Ensure old models are cleaned up
        await datasource.deleteOldModels();
        
        final isInstalled = await datasource.checkModelExistence();
        if (!isInstalled) {
          throw Exception('Model not downloaded: ${selectedModel.displayName}');
        }

        final modelPath = await datasource.getFilePath();
        await gemma.modelManager.setModelPath(modelPath);
      }

      final supportsImages = selectedModel.supportsImages;

      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: supportsImages,
        maxTokens: 2048,
      );

      _chat = await _inferenceModel!.createChat(supportImage: supportsImages);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  // Send a message and get a stream of response chunks
  Stream<String> sendMessage(String text, {Uint8List? imageBytes}) async* {
    if (!_isInitialized || _chat == null) {
      await initializeChat();
    }

    final Message userMessage;
    if (imageBytes != null) {
      final prompt = text.isNotEmpty ? text : "What's in this image?";
      userMessage = Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true);
    } else {
      userMessage = Message(text: text, isUser: true);
    }

    await _chat!.addQueryChunk(userMessage);
    
    // Yield empty string to signal start? Not strictly needed but good for UI
    yield* _chat!.generateChatResponseAsync();
  }
  
  bool get isInitialized => _isInitialized;
}
