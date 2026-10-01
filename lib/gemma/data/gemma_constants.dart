class GemmaConstants {
  /// Optional token for gated Hugging Face models: `flutter run --dart-define=HF_TOKEN=hf_...`.
  /// Empty by default, so public models download without an Authorization header.
  static const String huggingFaceAccessToken = String.fromEnvironment('HF_TOKEN');

  static const String prefsSelectedModelKey = 'selected_gemma_model';
  static const String prefsModelDownloadedPrefix = 'model_downloaded_';

  static const List<String> oldModels = [
    'gemma-3n-E4B-it-int4.task',
    'gemma-3n-E2B-it-int4.task',
    'gemma3-270m-it-q8.task',
  ];
}
