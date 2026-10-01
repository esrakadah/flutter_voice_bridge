class GemmaConstants {
  // TODO: Move this to a secure configuration or environment variable
  static const String huggingFaceAccessToken = 'SET_YOUR_HUGGING_FACE_ACCESS_TOKEN_HERE';

  static const String prefsSelectedModelKey = 'selected_gemma_model';
  static const String prefsModelDownloadedPrefix = 'model_downloaded_';

  static const List<String> oldModels = [
    'gemma-3n-E4B-it-int4.task',
    'gemma-3n-E2B-it-int4.task',
    'gemma3-270m-it-q8.task',
  ];
}
