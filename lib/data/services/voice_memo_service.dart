import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import '../models/voice_memo.dart';

// Service for managing voice memo data persistence and operations
abstract class VoiceMemoService {
  /// Save a voice memo and return its ID
  Future<String> saveVoiceMemo(VoiceMemo voiceMemo);

  /// List all recordings from file system
  Future<List<VoiceMemo>> listRecordings();
  
  /// Delete a recording by file path
  Future<void> deleteRecording(String filePath);

  /// Delete all recordings
  Future<void> deleteAllRecordings();
}

class VoiceMemoServiceImpl implements VoiceMemoService {
  @override
  Future<String> saveVoiceMemo(VoiceMemo voiceMemo) async {
    // Currently just logs - in future this could save to database
    developer.log('📄 [VoiceMemoService] Saving memo: ${voiceMemo.title}', name: 'VoiceBridge.Service');
    developer.log('📁 [VoiceMemoService] File path: ${voiceMemo.filePath}', name: 'VoiceBridge.Service');
    developer.log('🆔 [VoiceMemoService] ID: ${voiceMemo.id}', name: 'VoiceBridge.Service');
    developer.log('📅 [VoiceMemoService] Created at: ${voiceMemo.createdAt}', name: 'VoiceBridge.Service');

    // Verify the file actually exists
    final File file = File(voiceMemo.filePath);
    if (await file.exists()) {
      developer.log('✅ [VoiceMemoService] File exists, memo saved successfully', name: 'VoiceBridge.Service');
    } else {
      developer.log('❌ [VoiceMemoService] WARNING: File does not exist!', name: 'VoiceBridge.Service');
    }

    return voiceMemo.id;
  }

  @override
  Future<List<VoiceMemo>> listRecordings() async {
    developer.log('📂 [VoiceMemoService] Listing recordings from device storage...', name: 'VoiceBridge.Service');

    try {
      // Get documents directory
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      developer.log('📁 [VoiceMemoService] Documents directory: ${documentsDir.path}', name: 'VoiceBridge.Service');

      // Check audio subdirectory (where recordings are actually saved)
      final Directory audioDir = Directory('${documentsDir.path}/audio');
      developer.log('📁 [VoiceMemoService] Audio directory: ${audioDir.path}', name: 'VoiceBridge.Service');

      if (!await audioDir.exists()) {
        developer.log('📁 [VoiceMemoService] Audio directory does not exist yet', name: 'VoiceBridge.Service');
        return [];
      }

      // List all audio files (.m4a and .wav) in the audio directory
      final List<FileSystemEntity> entities = audioDir.listSync();
      final List<File> audioFiles = entities
          .where((entity) => entity is File && (entity.path.endsWith('.m4a') || entity.path.endsWith('.wav')))
          .cast<File>()
          .toList();

      developer.log(
        '🎵 [VoiceMemoService] Found ${audioFiles.length} audio files (.m4a/.wav)',
        name: 'VoiceBridge.Service',
      );

      // Convert files to VoiceMemo objects
      final List<VoiceMemo> recordings = [];
      for (final File file in audioFiles) {
        try {
          final VoiceMemo memo = await _createVoiceMemoFromFile(file);
          recordings.add(memo);
          developer.log('✅ [VoiceMemoService] Processed: ${file.path}', name: 'VoiceBridge.Service');
        } catch (e) {
          developer.log('⚠️ [VoiceMemoService] Error processing file ${file.path}: $e', name: 'VoiceBridge.Service');
        }
      }

      // Sort by creation date (newest first)
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      developer.log(
        '✅ [VoiceMemoService] Successfully loaded ${recordings.length} recordings',
        name: 'VoiceBridge.Service',
      );
      return recordings;
    } catch (e) {
      developer.log('❌ [VoiceMemoService] Error listing recordings: $e', name: 'VoiceBridge.Service', error: e);
      return [];
    }
  }

  @override
  Future<void> deleteRecording(String filePath) async {
    developer.log('🗑️ [VoiceMemoService] Deleting recording: $filePath', name: 'VoiceBridge.Service');

    try {
      final File file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        developer.log('✅ [VoiceMemoService] Recording deleted successfully', name: 'VoiceBridge.Service');
      } else {
        developer.log('⚠️ [VoiceMemoService] File not found, may already be deleted', name: 'VoiceBridge.Service');
      }
    } catch (e) {
      developer.log('❌ [VoiceMemoService] Error deleting recording: $e', name: 'VoiceBridge.Service', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteAllRecordings() async {
    developer.log('🗑️ [VoiceMemoService] Deleting ALL recordings', name: 'VoiceBridge.Service');

    try {
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      final Directory audioDir = Directory('${documentsDir.path}/audio');

      if (await audioDir.exists()) {
        final List<FileSystemEntity> entities = audioDir.listSync();
        int deletedCount = 0;
        
        for (final entity in entities) {
          if (entity is File && (entity.path.endsWith('.m4a') || entity.path.endsWith('.wav'))) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (e) {
              developer.log('⚠️ [VoiceMemoService] Failed to delete file: ${entity.path}', name: 'VoiceBridge.Service');
            }
          }
        }
        
        developer.log('✅ [VoiceMemoService] Deleted $deletedCount recordings', name: 'VoiceBridge.Service');
      } else {
        developer.log('⚠️ [VoiceMemoService] Audio directory not found', name: 'VoiceBridge.Service');
      }
    } catch (e) {
      developer.log('❌ [VoiceMemoService] Error deleting all recordings: $e', name: 'VoiceBridge.Service', error: e);
      rethrow;
    }
  }

  // Helper method to create VoiceMemo from file
  Future<VoiceMemo> _createVoiceMemoFromFile(File file) async {
    final FileStat stat = await file.stat();
    final String fileName = file.path.split('/').last;

    // Extract timestamp from filename (voice_memo_1234567890123.m4a or .wav)
    DateTime createdAt = stat.modified;
    if (fileName.contains('voice_memo_')) {
      try {
        String timestampStr = fileName.replaceAll('voice_memo_', '');
        // Remove file extension (.m4a or .wav)
        timestampStr = timestampStr.replaceAll('.m4a', '').replaceAll('.wav', '');
        final int timestamp = int.parse(timestampStr);
        // The timestamp in filename is already in milliseconds
        createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (e) {
        // Use file modification time if timestamp parsing fails
        developer.log(
          '⚠️ [VoiceMemoService] Failed to parse timestamp from $fileName: $e',
          name: 'VoiceBridge.Service',
        );
        createdAt = stat.modified;
      }
    }

    // Generate friendly title
    final String title = _generateFriendlyTitle(createdAt);

    return VoiceMemo(
      id: fileName.replaceAll('.m4a', '').replaceAll('.wav', ''),
      filePath: file.path,
      title: title,
      keywords: const [],
      createdAt: createdAt,
      durationSeconds: 0, // TODO: Get duration from file metadata
      fileSizeBytes: stat.size.toDouble(),
      isTranscribed: false,
      status: VoiceMemoStatus.completed,
    );
  }

  // Helper method to generate friendly titles
  String _generateFriendlyTitle(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final String month = months[dateTime.month - 1];
    final String day = dateTime.day.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return 'Voice Memo – $month $day, $hour:$minute';
  }
}
