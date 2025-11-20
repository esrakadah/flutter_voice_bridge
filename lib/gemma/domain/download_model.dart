/// Model representing a downloadable AI model configuration.
///
/// This class encapsulates the essential information needed to download
/// and manage AI models for on-device inference.
class DownloadModel {
  /// The URL from which the model file can be downloaded.
  final String modelUrl;

  /// The filename to use when saving the model locally.
  final String modelFilename;

  const DownloadModel({
    required this.modelUrl,
    required this.modelFilename,
  });
}

