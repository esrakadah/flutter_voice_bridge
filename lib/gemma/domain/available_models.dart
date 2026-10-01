import 'download_model.dart';

/// Available Gemma models for download and use in the application.
///
/// This enum defines the different Gemma AI models that can be downloaded
/// and used for on-device inference. Each model has different characteristics
/// in terms of size, capabilities, and performance.
enum AvailableModel {
  /// Ultra-compact 270M parameter model.
  /// Not recommended for production use due to limited capabilities.
  gemma270m(
    displayName: 'Gemma 3 270M (Tiny)',
    size: '300MB',
    url:
        'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma3-270m-it-q8.task',
    filename: 'gemma3-270m-it-q8.task',
    description: 'Ultra-compact, limited capabilities (not recommended)',
    supportsImages: false,
  ),

  /// Recommended 1B parameter model with good balance of quality and performance.
  gemma1b(
    displayName: 'Gemma 3 1B ⭐ Recommended',
    size: '500MB',
    url:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
    filename: 'gemma3-1b-it-int4.task',
    description: 'Best balance: good quality, fits iPhone memory, fast',
    supportsImages: false,
  ),

  /// Multimodal 2B parameter model that supports both text and images.
  gemma2b(
    displayName: 'Gemma 3N E2B (Multimodal)',
    size: '3.1GB',
    url:
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    filename: 'gemma-3n-E2B-it-int4.task',
    description: 'Supports images, high quality (requires more memory)',
    supportsImages: true,
  );

  const AvailableModel({
    required this.displayName,
    required this.size,
    required this.url,
    required this.filename,
    required this.description,
    required this.supportsImages,
  });

  /// User-friendly display name for the model.
  final String displayName;

  /// Approximate file size as a string (e.g., "500MB").
  final String size;

  /// Direct download URL for the model file.
  final String url;

  /// Filename to use when saving the model locally.
  final String filename;

  /// Human-readable description of the model's characteristics.
  final String description;

  /// Whether this model supports multimodal inputs (images + text).
  final bool supportsImages;

  /// Converts this enum value to a [DownloadModel] for use with the downloader.
  DownloadModel toDownloadModel() {
    return DownloadModel(
      modelUrl: url,
      modelFilename: filename,
    );
  }
}

