import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/download_model.dart';

import 'gemma_constants.dart';

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
  String get _preferenceKey => '${GemmaConstants.prefsModelDownloadedPrefix}${model.modelFilename}';

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

      final Map<String, String> headers = GemmaConstants.huggingFaceAccessToken.isNotEmpty
          ? {'Authorization': 'Bearer ${GemmaConstants.huggingFaceAccessToken}'}
          : {};

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
      final oldModels = GemmaConstants.oldModels;

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
        await prefs.remove('${GemmaConstants.prefsModelDownloadedPrefix}$filename');
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
  /// Downloads to `<model>.part` and renames it only when complete, so an interrupted download is resumed
  /// rather than mistaken for a finished model.
  ///
  /// Resume rules: 206 appends to the partial file; 200 means the server ignored `Range`, so the file is
  /// rewritten from the start; 416 means the partial file already holds every byte.
  Future<void> downloadModel({required String token, required Function(double) onProgress}) async {
    final prefs = await SharedPreferences.getInstance();
    final finalFile = File(await getFilePath());
    final partialFile = File('${finalFile.path}.part');
    IOSink? fileSink;

    try {
      final resumeFrom = partialFile.existsSync() ? await partialFile.length() : 0;
      final request = http.Request('GET', Uri.parse(model.modelUrl));
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (resumeFrom > 0) {
        request.headers['Range'] = 'bytes=$resumeFrom-';
      }

      final response = await request.send();
      final int alreadyHave;
      switch (response.statusCode) {
        case HttpStatus.partialContent:
          alreadyHave = resumeFrom;
          fileSink = partialFile.openWrite(mode: FileMode.append);
        case HttpStatus.ok:
          alreadyHave = 0;
          fileSink = partialFile.openWrite();
        case HttpStatus.requestedRangeNotSatisfiable when resumeFrom > 0:
          await response.stream.drain<void>();
          await _completeDownload(partialFile, finalFile, prefs);
          onProgress(1);
          return;
        default:
          await response.stream.drain<void>();
          throw HttpException('Model download failed with status ${response.statusCode}', uri: request.url);
      }

      final contentLength = response.contentLength;
      final expectedTotal = contentLength == null ? null : alreadyHave + contentLength;
      var received = alreadyHave;
      await for (final chunk in response.stream) {
        fileSink.add(chunk);
        received += chunk.length;
        onProgress(expectedTotal != null && expectedTotal > 0 ? received / expectedTotal : 0.0);
      }
      await fileSink.close();
      fileSink = null;

      if (expectedTotal != null && received != expectedTotal) {
        throw HttpException('Model download ended early: $received of $expectedTotal bytes', uri: request.url);
      }
      await _completeDownload(partialFile, finalFile, prefs);
    } catch (error) {
      await prefs.setBool(_preferenceKey, false);
      if (kDebugMode) {
        print('Error downloading model: $error');
      }
      rethrow;
    } finally {
      await fileSink?.close();
    }
  }

  Future<void> _completeDownload(File partialFile, File finalFile, SharedPreferences prefs) async {
    await partialFile.rename(finalFile.path);
    await prefs.setBool(_preferenceKey, true);
  }
}
