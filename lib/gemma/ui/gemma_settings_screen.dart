import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/gemma_downloader_datasource.dart';
import '../domain/available_models.dart';

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

  Future<void> _loadSettings() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final selectedFilename = prefs.getString('selected_gemma_model');

    if (selectedFilename != null) {
      _selectedModel = AvailableModel.values.firstWhere(
        (m) => m.filename == selectedFilename,
        orElse: () => AvailableModel.gemma1b,
      );
    } else {
      _selectedModel = AvailableModel.gemma1b;
    }

    for (final model in AvailableModel.values) {
      final datasource = GemmaDownloaderDataSource(
        model: model.toDownloadModel(),
      );
      final exists = await datasource.checkModelExistence();
      _modelExistence[model] = exists;
    }

    setState(() => _loading = false);
  }

  Future<void> _selectModel(AvailableModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_gemma_model', model.filename);
    setState(() => _selectedModel = model);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Selected ${model.displayName}. Return to chat to reload.'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('${model.displayName} downloaded!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
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
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Failed to download: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _deleteModel(AvailableModel model) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete ${model.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
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
            content: Row(
              children: [
                const Icon(Icons.delete, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('${model.displayName} deleted'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Gemma Model Settings',
          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withAlpha(26),
                colorScheme.secondary.withAlpha(13),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                child: Card(
                  elevation: 4,
                  shadowColor: colorScheme.primary.withAlpha(13),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, colorScheme, textTheme)),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.builder(
                    itemCount: AvailableModel.values.length,
                    itemBuilder: (context, index) {
                      final model = AvailableModel.values[index];
                      return _buildModelCard(model, colorScheme, textTheme);
                    },
                  ),
                ),
                SliverToBoxAdapter(child: _buildInfoCard(colorScheme, textTheme)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Models',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 6),
                Text(
                  'Current: ${_selectedModel?.displayName ?? "None"}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(AvailableModel model, ColorScheme colorScheme, TextTheme textTheme) {
    final exists = _modelExistence[model] ?? false;
    final progress = _downloadProgress[model];
    final isSelected = model == _selectedModel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 6 : 3,
        shadowColor: isSelected ? colorScheme.primary.withAlpha(26) : colorScheme.shadow.withAlpha(13),
        color: isSelected ? colorScheme.primaryContainer.withAlpha(51) : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                            Expanded(
                              child: Text(
                                model.displayName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Selected',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Size: ${model.size}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        if (model.supportsImages) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.tertiary.withAlpha(26),
                                  colorScheme.secondary.withAlpha(13),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.tertiary.withAlpha(39),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image, size: 14, color: colorScheme.tertiary),
                                const SizedBox(width: 6),
                                Text(
                                  'Image Support',
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
                  const SizedBox(width: 12),
                  Icon(
                    exists ? Icons.download_done : Icons.cloud_download_outlined,
                    color: exists ? Colors.green : colorScheme.outline,
                    size: 28,
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Downloading: ${(progress * 100).toStringAsFixed(1)}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                if (!exists)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _downloadModel(model),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Model'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _selectModel(model),
                          icon: Icon(isSelected ? Icons.check : Icons.radio_button_unchecked),
                          label: Text(isSelected ? 'Currently Selected' : 'Use This Model'),
                          style: FilledButton.styleFrom(
                            backgroundColor: isSelected ? Colors.green : colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () => _deleteModel(model),
                        icon: const Icon(Icons.delete_outline),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.error.withAlpha(26),
                          foregroundColor: colorScheme.error,
                        ),
                        tooltip: 'Delete Model',
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shadowColor: colorScheme.primary.withAlpha(13),
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.tertiary, colorScheme.primary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'About Gemma Models',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.smartphone,
                text: 'Models run entirely on your device',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _buildInfoRow(
                icon: Icons.cloud_off,
                text: 'No internet required after download',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _buildInfoRow(
                icon: Icons.lock,
                text: 'Privacy-focused: data never leaves device',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _buildInfoRow(
                icon: Icons.trending_up,
                text: 'Larger models = better quality, more space',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              _buildInfoRow(
                icon: Icons.photo,
                text: 'Multimodal models can analyze images',
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
