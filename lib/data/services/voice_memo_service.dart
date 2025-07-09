import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import '../models/voice_memo.dart';

// Service for managing voice memo data persistence and operations
abstract class VoiceMemoService {
  Future<List<VoiceMemo>> getAllVoiceMemos();
  Future<VoiceMemo?> getVoiceMemoById(String id);
  Future<String> saveVoiceMemo(VoiceMemo voiceMemo);
  Future<void> deleteVoiceMemo(String id);
  Future<void> updateVoiceMemo(VoiceMemo voiceMemo);
  Future<List<VoiceMemo>> searchVoiceMemos(String query);

  // New methods for recording management
  Future<List<VoiceMemo>> listRecordings();
  Future<void> deleteRecording(String filePath);
}

class VoiceMemoServiceImpl implements VoiceMemoService {
  // File-based implementation using device storage

  @override
  Future<List<VoiceMemo>> getAllVoiceMemos() async {
    // For now, same as listRecordings - in future this could include database records
    return await listRecordings();
  }

  @override
  Future<VoiceMemo?> getVoiceMemoById(String id) async {
    // TODO: Implement single record retrieval
    throw UnimplementedError('Single record retrieval not implemented yet');
  }

  @override
  Future<String> saveVoiceMemo(VoiceMemo voiceMemo) async {
    // TODO: Implement database saving (currently just file-based)
    developer.log('📄 [VoiceMemoService] Memo saved (file-based): ${voiceMemo.title}', name: 'VoiceBridge.Service');
    return voiceMemo.id;
  }

  @override
  Future<void> deleteVoiceMemo(String id) async {
    // TODO: Implement database deletion
    throw UnimplementedError('Database deletion not implemented yet');
  }

  @override
  Future<void> updateVoiceMemo(VoiceMemo voiceMemo) async {
    // TODO: Implement data updates
    throw UnimplementedError('Data updates not implemented yet');
  }

  @override
  Future<List<VoiceMemo>> searchVoiceMemos(String query) async {
    // TODO: Implement search functionality
    throw UnimplementedError('Search functionality not implemented yet');
  }

  @override
  Future<List<VoiceMemo>> listRecordings() async {
    developer.log('📂 [VoiceMemoService] Listing recordings from device storage...', name: 'VoiceBridge.Service');

    try {
      // Get documents directory
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      developer.log('📁 [VoiceMemoService] Documents directory: ${documentsDir.path}', name: 'VoiceBridge.Service');

      // List all .m4a files
      final List<FileSystemEntity> entities = documentsDir.listSync();
      final List<File> audioFiles = entities
          .where((entity) => entity is File && entity.path.endsWith('.m4a'))
          .cast<File>()
          .toList();

      developer.log('🎵 [VoiceMemoService] Found ${audioFiles.length} .m4a files', name: 'VoiceBridge.Service');

      // Convert files to VoiceMemo objects
      final List<VoiceMemo> recordings = [];
      for (final File file in audioFiles) {
        try {
          final VoiceMemo memo = await _createVoiceMemoFromFile(file);
          recordings.add(memo);
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

  // Helper method to create VoiceMemo from file
  Future<VoiceMemo> _createVoiceMemoFromFile(File file) async {
    final FileStat stat = await file.stat();
    final String fileName = file.path.split('/').last;

    // Extract timestamp from filename (voice_memo_1234567890.m4a)
    DateTime createdAt = stat.modified;
    if (fileName.contains('voice_memo_')) {
      try {
        final String timestampStr = fileName.replaceAll('voice_memo_', '').replaceAll('.m4a', '');
        final int timestamp = int.parse(timestampStr);
        createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } catch (e) {
        // Use file modification time if timestamp parsing fails
        createdAt = stat.modified;
      }
    }

    // Generate friendly title
    final String title = _generateFriendlyTitle(createdAt);

    return VoiceMemo(
      id: fileName.replaceAll('.m4a', ''),
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
