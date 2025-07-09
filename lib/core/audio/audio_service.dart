// Abstract Audio Service interface for voice recording and playback functionality
// This defines the contract for audio operations

abstract class AudioService {
  /// Starts audio recording and returns the file path where recording will be saved
  Future<String> startRecording();

  /// Stops audio recording and returns the final file path
  Future<String> stopRecording();

  /// Plays an audio file at the given path
  /// Returns a success message or throws an exception
  Future<String> playRecording(String filePath);

  /// Checks if microphone permission is granted
  Future<bool> hasPermission();

  /// Requests microphone permission
  Future<void> requestPermission();
}
