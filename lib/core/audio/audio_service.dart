// Abstract Audio Service interface for voice recording functionality
// This defines the contract for audio recording operations

abstract class AudioService {
  /// Starts audio recording and returns the file path where recording will be saved
  Future<String> startRecording();

  /// Stops audio recording and returns the final file path
  Future<String> stopRecording();

  /// Checks if microphone permission is granted
  Future<bool> hasPermission();

  /// Requests microphone permission
  Future<void> requestPermission();
}
