import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

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
  /// One download per model: the chat and the settings screen can both ask for the same model, and two
  /// downloads appending to one `.part` file would corrupt it. Every caller shares the download and its progress.
  final Map<AvailableModel, Future<void>> _downloads = {};
  final Map<AvailableModel, List<void Function(double)>> _progressListeners = {};

  Future<void> downloadModel(AvailableModel model, void Function(double) onProgress) {
    if (kIsWeb) return Future<void>.value();
    _progressListeners.putIfAbsent(model, () => []).add(onProgress);
    return _downloads[model] ??= _download(model).whenComplete(() {
      _downloads.remove(model);
      _progressListeners.remove(model);
    });
  }

  Future<void> _download(AvailableModel model) {
    return GemmaDownloaderDataSource(model: model.toDownloadModel()).downloadModel(
      token: GemmaConstants.huggingFaceAccessToken,
      onProgress: (progress) {
        for (final listener in List.of(_progressListeners[model] ?? const <void Function(double)>[])) {
          listener(progress);
        }
      },
    );
  }

  // Delete a model
  Future<void> deleteModel(AvailableModel model) async {
    if (kIsWeb) return;

    final datasource = GemmaDownloaderDataSource(model: model.toDownloadModel());
    final path = await datasource.getFilePath();
    for (final file in [File(path), File('$path.part')]) {
      if (file.existsSync()) {
        await file.delete();
      }
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

      // Re-initialising (model switch, chat reset) must release the previous native model first.
      await _inferenceModel?.close();
      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: supportsImages,
        maxTokens: GemmaConstants.maxTokens,
      );

      _chat = await _inferenceModel!.createChat(supportImage: supportsImages);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  // Send a message and get a stream of response chunks
  /// Sends a message the cubit has already built (text, or image with prompt) and streams the reply.
  Stream<String> sendMessage(Message userMessage) async* {
    if (!_isInitialized || _chat == null) {
      await initializeChat();
    }
    final chat = _chat;
    if (chat == null) {
      throw StateError('Gemma chat could not be initialised');
    }
    await chat.addQueryChunk(userMessage);
    yield* chat.generateChatResponseAsync();
  }

  bool get isInitialized => _isInitialized;
}
