import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/gemma_downloader_datasource.dart';
import '../domain/available_models.dart';

/// Settings screen for managing Gemma AI models.
///
/// This screen allows users to:
/// - View available models
/// - Download new models
/// - Select which model to use
/// - Delete models to free up space
/// - See model status and characteristics
class GemmaSettingsScreen extends StatefulWidget {
  const GemmaSettingsScreen({super.key});

  @override
  State<GemmaSettingsScreen> createState() => _GemmaSettingsScreenState();
}

class _GemmaSettingsScreenState extends State<GemmaSettingsScreen> {
  AvailableModel? _selectedModel;
  final Map<AvailableModel, bool> _modelExistence = {};
  final Map<AvailableModel, double?> _downloadProgress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads the current settings and model availability status.
  Future<void> _loadSettings() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final selectedFilename = prefs.getString('selected_gemma_model');

    // Find selected model
    if (selectedFilename != null) {
      _selectedModel = AvailableModel.values.firstWhere(
        (m) => m.filename == selectedFilename,
        orElse: () => AvailableModel.gemma1b,
      );
    } else {
      _selectedModel = AvailableModel.gemma1b; // Default to recommended
    }

    // Check which models exist
    for (final model in AvailableModel.values) {
      final datasource = GemmaDownloaderDataSource(
        model: model.toDownloadModel(),
      );
      final exists = await datasource.checkModelExistence();
      _modelExistence[model] = exists;
    }

    setState(() => _loading = false);
  }

  /// Selects a model and saves the preference.
  Future<void> _selectModel(AvailableModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_gemma_model', model.filename);
    setState(() => _selectedModel = model);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected ${model.displayName}. Return to chat to reload.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Downloads a model with progress tracking.
  Future<void> _downloadModel(AvailableModel model) async {
    setState(() {
      _downloadProgress[model] = 0.0;
    });

    try {
      final datasource = GemmaDownloaderDataSource(
        model: model.toDownloadModel(),
      );

      await datasource.downloadModel(
        token: accessToken,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[model] = progress;
          });
        },
      );

      setState(() {
        _modelExistence[model] = true;
        _downloadProgress[model] = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.displayName} downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadProgress[model] = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Deletes a model from local storage.
  Future<void> _deleteModel(AvailableModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text(
          'Are you sure you want to delete ${model.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${model.filename}');

      if (file.existsSync()) {
        await file.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('model_downloaded_${model.filename}');

      setState(() {
        _modelExistence[model] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.displayName} deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma Model Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Available Models',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current: ${_selectedModel?.displayName ?? "None"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                ...AvailableModel.values.map((model) {
                  final exists = _modelExistence[model] ?? false;
                  final progress = _downloadProgress[model];
                  final isSelected = model == _selectedModel;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isSelected ? 4 : 1,
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          model.displayName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Size: ${model.size}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      model.description,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (model.supportsImages) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '📸 Image Support',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                exists
                                    ? Icons.download_done
                                    : Icons.cloud_download,
                                color: exists ? Colors.green : Colors.grey,
                              ),
                            ],
                          ),
                          if (progress != null) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 4),
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (!exists) ...[
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _downloadModel(model),
                                      icon: const Icon(Icons.download),
                                      label: const Text('Download'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _selectModel(model),
                                      icon: const Icon(Icons.check),
                                      label: Text(
                                        isSelected ? 'Selected' : 'Use This',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? Colors.green
                                            : Colors.grey.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _deleteModel(model),
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'About Gemma Models',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Models run entirely on your device\n'
                        '• No internet required after download\n'
                        '• Privacy-focused: data never leaves device\n'
                        '• Larger models = better quality, more space\n'
                        '• Multimodal models can analyze images',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

