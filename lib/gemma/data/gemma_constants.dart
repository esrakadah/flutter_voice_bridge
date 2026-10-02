class GemmaConstants {
  /// Optional token for gated Hugging Face models: `flutter run --dart-define=HF_TOKEN=hf_...`.
  /// Empty by default, so public models download without an Authorization header.
  static const String huggingFaceAccessToken = String.fromEnvironment('HF_TOKEN');

  static const String prefsSelectedModelKey = 'selected_gemma_model';
  static const String prefsModelDownloadedPrefix = 'model_downloaded_';

  /// Context window for the on-device chat (prompt plus reply).
  static const int maxTokens = 2048;

  /// Retired model files that may still sit on devices from earlier versions. Never list a model that
  /// AvailableModel still offers: initializeChat deletes these on every start.
  static const List<String> oldModels = ['gemma-3n-E4B-it-int4.task'];
}
