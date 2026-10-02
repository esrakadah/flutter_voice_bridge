import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import '../models/voice_memo.dart';

// Service for managing voice memo data persistence and operations
abstract class VoiceMemoService {
  /// Stores the memo's details next to its audio file as `<audio>.json`.
  Future<String> saveVoiceMemo(VoiceMemo voiceMemo);

  /// Records a finished transcription for the audio file, so it survives an app restart.
  Future<VoiceMemo> saveTranscription(String filePath, {required String text, required List<String> keywords});

  Future<List<VoiceMemo>> listRecordings();

  Future<void> deleteRecording(String filePath);

  Future<void> deleteAllRecordings();
}

/// Keeps recordings in `<documents>/audio`. Each audio file may have a JSON sidecar (`memo.wav.json`) holding
/// the title, duration and transcript; files without one (older recordings) are listed from the file itself.
class VoiceMemoServiceImpl implements VoiceMemoService {
  VoiceMemoServiceImpl({Future<Directory> Function()? documentsDirectory, DateTime Function()? clock})
    : _documentsDirectory = documentsDirectory ?? getApplicationDocumentsDirectory,
      _clock = clock ?? DateTime.now;

  static const String _logName = 'VoiceBridge.Service';
  static const String _sidecarExtension = '.json';
  static const String _partialExtension = '.part';
  static const int _uint32Bytes = 4;
  static const List<String> _audioExtensions = ['.m4a', '.wav'];
  static const int _wavHeaderBytes = 44;
  static const int _wavByteRateOffset = 28;

  final Future<Directory> Function() _documentsDirectory;
  final DateTime Function() _clock;

  static File _sidecarFor(String audioPath) => File('$audioPath$_sidecarExtension');

  static bool _isAudio(String path) => _audioExtensions.any(path.endsWith);

  @override
  Future<String> saveVoiceMemo(VoiceMemo voiceMemo) async {
    await _writeSidecar(voiceMemo);
    return voiceMemo.id;
  }

  @override
  Future<VoiceMemo> saveTranscription(String filePath, {required String text, required List<String> keywords}) async {
    // The recording may have been deleted while it was being transcribed; never write its words back.
    if (!File(filePath).existsSync()) {
      throw StateError('Recording no longer exists: $filePath');
    }
    final existing = await _readSidecar(filePath) ?? await _memoFromAudioFile(File(filePath));
    final updated = existing.copyWith(
      transcription: text,
      keywords: keywords,
      isTranscribed: true,
      lastModified: _clock(),
    );
    await _writeSidecar(updated);
    return updated;
  }

  @override
  Future<List<VoiceMemo>> listRecordings() async {
    try {
      final audioDir = await _audioDirectory();
      if (!audioDir.existsSync()) return [];

      final recordings = <VoiceMemo>[];
      for (final file in audioDir.listSync().whereType<File>().where((file) => _isAudio(file.path))) {
        try {
          recordings.add(await _readSidecar(file.path) ?? await _memoFromAudioFile(file));
        } catch (error) {
          developer.log('⚠️ [VoiceMemoService] Skipping ${file.path}: $error', name: _logName);
        }
      }
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return recordings;
    } catch (error) {
      developer.log('❌ [VoiceMemoService] Error listing recordings: $error', name: _logName, error: error);
      return [];
    }
  }

  @override
  Future<void> deleteRecording(String filePath) async {
    for (final file in [
      File(filePath),
      _sidecarFor(filePath),
      File('${_sidecarFor(filePath).path}$_partialExtension'),
    ]) {
      if (file.existsSync()) await file.delete();
    }
  }

  @override
  Future<void> deleteAllRecordings() async {
    final audioDir = await _audioDirectory();
    if (!audioDir.existsSync()) return;
    for (final file in audioDir.listSync().whereType<File>()) {
      if (_isAudio(file.path) ||
          file.path.endsWith(_sidecarExtension) ||
          file.path.endsWith('$_sidecarExtension$_partialExtension')) {
        try {
          await file.delete();
        } catch (error) {
          developer.log('⚠️ [VoiceMemoService] Failed to delete ${file.path}: $error', name: _logName);
        }
      }
    }
  }

  Future<Directory> _audioDirectory() async => Directory('${(await _documentsDirectory()).path}/audio');

  Future<void> _writeSidecar(VoiceMemo memo) async {
    final sidecar = _sidecarFor(memo.filePath);
    final partial = File('${sidecar.path}$_partialExtension');
    await partial.writeAsString(jsonEncode(memo.toJson()));
    await partial.rename(sidecar.path);
  }

  /// The saved memo, with the path and size taken from the audio file in case the app's container moved.
  Future<VoiceMemo?> _readSidecar(String audioPath) async {
    final sidecar = _sidecarFor(audioPath);
    if (!sidecar.existsSync()) return null;
    try {
      final memo = VoiceMemo.fromJson(jsonDecode(await sidecar.readAsString()) as Map<String, dynamic>);
      return memo.copyWith(filePath: audioPath, fileSizeBytes: File(audioPath).lengthSync().toDouble());
    } on Object catch (error) {
      developer.log('⚠️ [VoiceMemoService] Ignoring unreadable $sidecar: $error', name: _logName);
      return null;
    }
  }

  Future<VoiceMemo> _memoFromAudioFile(File file) async {
    final stat = await file.stat();
    final fileName = file.uri.pathSegments.last;
    final id = _audioExtensions.fold(fileName, (name, extension) => name.replaceAll(extension, ''));
    final timestamp = int.tryParse(id.replaceAll('voice_memo_', ''));
    final createdAt = timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : stat.modified;

    return VoiceMemo(
      id: id,
      filePath: file.path,
      title: VoiceMemo.defaultTitle(createdAt),
      keywords: const [],
      createdAt: createdAt,
      durationSeconds: file.path.endsWith('.wav') ? _wavDurationSeconds(file, stat.size) : 0,
      fileSizeBytes: stat.size.toDouble(),
      isTranscribed: false,
      status: VoiceMemoStatus.completed,
    );
  }

  /// Duration from the WAV header's byte rate; 0 when the header is unreadable.
  static int _wavDurationSeconds(File file, int fileSize) {
    if (fileSize <= _wavHeaderBytes) return 0;
    final handle = file.openSync();
    try {
      handle.setPositionSync(_wavByteRateOffset);
      final bytes = handle.readSync(_uint32Bytes);
      if (bytes.length < _uint32Bytes) return 0;
      final byteRate = ByteData.sublistView(bytes).getUint32(0, Endian.little);
      return byteRate == 0 ? 0 : (fileSize - _wavHeaderBytes) ~/ byteRate;
    } finally {
      handle.closeSync();
    }
  }
}
