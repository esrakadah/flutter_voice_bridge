import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/download_model.dart';

/// TODO: Replace with your actual Hugging Face access token.
/// Get your token from https://huggingface.co/settings/tokens
const String accessToken = 'YOUR_HUGGING_FACE_TOKEN_HERE';

/// Data source responsible for downloading and managing Gemma AI models.
///
/// This class handles:
/// - Checking if models exist locally
/// - Downloading models from Hugging Face
/// - Tracking download progress
/// - Managing model file lifecycle
/// - Cleaning up old/unused models
class GemmaDownloaderDataSource {
  final DownloadModel model;

  GemmaDownloaderDataSource({required this.model});

  /// SharedPreferences key for tracking model download status.
  String get _preferenceKey => 'model_downloaded_${model.modelFilename}';

  /// Gets the full file path where the model should be stored.
  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${model.modelFilename}';
  }

  /// Checks if the model exists locally and is valid.
  ///
  /// This method performs multiple checks:
  /// 1. Checks SharedPreferences for a cached download status
  /// 2. Verifies the file exists on disk
  /// 3. Validates file size matches remote file (if possible)
  ///
  /// Returns `true` if the model is available and valid, `false` otherwise.
  Future<bool> checkModelExistence() async {
    final prefs = await SharedPreferences.getInstance();

    // Quick check: if we've marked it as downloaded before
    if (prefs.getBool(_preferenceKey) ?? false) {
      final filePath = await getFilePath();
      final file = File(filePath);
      if (file.existsSync()) {
        return true;
      }
    }

    // Detailed check: verify file size matches remote
    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      final Map<String, String> headers = accessToken.isNotEmpty ? {'Authorization': 'Bearer $accessToken'} : {};

      final headResponse = await http.head(Uri.parse(model.modelUrl), headers: headers);

      if (headResponse.statusCode == 200) {
        final contentLengthHeader = headResponse.headers['content-length'];
        if (contentLengthHeader != null) {
          final remoteFileSize = int.parse(contentLengthHeader);
          if (file.existsSync() && await file.length() == remoteFileSize) {
            await prefs.setBool(_preferenceKey, true);
            return true;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking model existence: $e');
      }
    }

    await prefs.setBool(_preferenceKey, false);
    return false;
  }

  /// Deletes old model files from disk to free up space.
  ///
  /// This method removes models that are no longer in use,
  /// while preserving the currently selected model.
  Future<void> deleteOldModels() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();

      // Get currently selected model to avoid deleting it
      final selectedFilename = prefs.getString('selected_gemma_model');

      // List of old/unused model files to potentially delete
      final oldModels = ['gemma-3n-E4B-it-int4.task', 'gemma-3n-E2B-it-int4.task', 'gemma3-270m-it-q8.task'];

      for (final filename in oldModels) {
        // Skip if this is the currently selected model
        if (filename == selectedFilename) {
          if (kDebugMode) {
            print('Skipping deletion of selected model: $filename');
          }
          continue;
        }

        final file = File('${directory.path}/$filename');
        if (file.existsSync()) {
          await file.delete();
          if (kDebugMode) {
            print('Deleted old model: $filename');
          }
        }

        // Clean up SharedPreferences for deleted model
        await prefs.remove('model_downloaded_$filename');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting old models: $e');
      }
    }
  }

  /// Downloads the model file from Hugging Face with progress tracking.
  ///
  /// This method supports resumable downloads and provides progress updates
  /// through the [onProgress] callback.
  ///
  /// Parameters:
  /// - [token]: Hugging Face access token for authentication
  /// - [onProgress]: Callback function that receives download progress (0.0 to 1.0)
  ///
  /// Throws an exception if the download fails.
  Future<void> downloadModel({required String token, required Function(double) onProgress}) async {
    http.StreamedResponse? response;
    IOSink? fileSink;
    final prefs = await SharedPreferences.getInstance();

    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      // Check for existing partial download
      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
      }

      final request = http.Request('GET', Uri.parse(model.modelUrl));
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Resume download if partially downloaded
      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      response = await request.send();

      // HTTP 200 (full content) or 206 (partial content) are both valid
      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;
        fileSink = file.openWrite(mode: FileMode.append);

        int received = downloadedBytes;

        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          received += chunk.length;
          onProgress(totalBytes > 0 ? received / totalBytes : 0.0);
        }

        await prefs.setBool(_preferenceKey, true);
      } else {
        await prefs.setBool(_preferenceKey, false);
        if (kDebugMode) {
          print('Failed to download model. Status code: ${response.statusCode}');
          print('Headers: ${response.headers}');
          try {
            final errorBody = await response.stream.bytesToString();
            print('Error body: $errorBody');
          } catch (e) {
            print('Could not read error body: $e');
          }
        }
        throw Exception('Failed to download the model. Status: ${response.statusCode}');
      }
    } catch (e) {
      await prefs.setBool(_preferenceKey, false);
      if (kDebugMode) {
        print('Error downloading model: $e');
      }
      rethrow;
    } finally {
      if (fileSink != null) await fileSink.close();
    }
  }
}
