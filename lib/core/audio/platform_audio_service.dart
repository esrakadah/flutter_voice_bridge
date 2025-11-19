import 'audio_service.dart';
import '../platform/platform_channels.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

// Platform-specific implementation of AudioService
// This wraps the platform channels for native audio recording

class PlatformAudioService implements AudioService {
  @override
  Future<String> startRecording() async {
    try {
      final String filePath = await PlatformChannels.startRecording();
      return filePath;
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  @override
  Future<String> stopRecording() async {
    try {
      final String filePath = await PlatformChannels.stopRecording();
      return filePath;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  @override
  Future<String> playRecording(String filePath) async {
    try {
      final String result = await PlatformChannels.playRecording(filePath);
      return result;
    } catch (e) {
      throw Exception('Failed to play recording: $e');
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final status = await Permission.microphone.status;
      developer.log('🔐 [PlatformAudioService] Microphone permission status: $status', name: 'VoiceBridge.Audio');
      return status.isGranted;
    } catch (e) {
      // Fallback: If permission_handler plugin is missing, assume true 
      // and let the native recording method handle the permission request/error.
      if (e.toString().contains('MissingPluginException')) {
        developer.log('⚠️ [PlatformAudioService] Permission plugin missing, assuming permission granted for fallback', name: 'VoiceBridge.Audio');
        return true;
      }
      developer.log('❌ [PlatformAudioService] Error checking permission: $e', name: 'VoiceBridge.Audio', error: e);
      // Return false if we can't determine permission status
      return false;
    }
  }

  @override
  Future<void> requestPermission() async {
    try {
      developer.log('🔐 [PlatformAudioService] Requesting microphone permission...', name: 'VoiceBridge.Audio');
      final status = await Permission.microphone.request();
      
      developer.log('🔐 [PlatformAudioService] Permission status: $status', name: 'VoiceBridge.Audio');
      
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          developer.log('🚫 [PlatformAudioService] Permission permanently denied. User must enable in settings.', name: 'VoiceBridge.Audio');
        }
        throw Exception('Microphone permission denied (Status: $status)');
      }
    } catch (e) {
      // Fallback: If permission_handler plugin is missing (common in dev),
      // let the native recording attempt trigger the OS dialog.
      if (e.toString().contains('MissingPluginException')) {
        developer.log('⚠️ [PlatformAudioService] Permission plugin missing, falling back to native OS handling', name: 'VoiceBridge.Audio');
        return;
      }
      
      developer.log('❌ [PlatformAudioService] Error requesting permission: $e', name: 'VoiceBridge.Audio', error: e);
      rethrow;
    }
  }
}
