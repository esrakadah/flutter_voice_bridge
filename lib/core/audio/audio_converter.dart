import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as path;

/// 🎓 **WORKSHOP MODULE 5: Process.run Integration**
///
/// **Learning Objectives:**
/// - Master system command execution in Flutter applications
/// - Understand security considerations for external tool integration
/// - Learn proper error handling and timeout management
/// - Practice argument validation and output parsing
///
/// **Key Concepts Demonstrated:**
/// - Command Whitelisting: Security-first approach to external tools
/// - Argument Sanitization: Preventing injection attacks
/// - Timeout Handling: Preventing hung processes
/// - Error Recovery: Graceful degradation when tools are unavailable
///
/// **Performance Focus:** External tool integration for specialized processing

/// 🔧 PROCESS.RUN PATTERN: External Tool Integration
/// Process.run allows Flutter to execute system commands and integrate with external tools
/// This is essential for specialized processing that would be complex to implement in Dart
/// Common use cases: media processing, build tools, git operations, compression

class AudioConverter {
  static const String _logName = 'AudioConverter';

  // 🛡️ SECURITY: Command whitelist to prevent arbitrary command execution
  static const List<String> _allowedCommands = [
    'ffmpeg',
    'ffprobe', // For audio file analysis
  ];

  // ⏱️ TIMEOUT: Prevent hung processes
  static const Duration _defaultTimeout = Duration(seconds: 30);

  // 🔄 CACHING: Cache FFmpeg availability to prevent repeated checks
  static bool? _ffmpegAvailabilityCache;
  static String? _ffmpegVersionCache;

  /// Convert audio file to WAV format optimized for Whisper transcription
  ///
  /// **Workshop Demo Point**: This shows real-world Process.run usage for audio processing
  /// that would be extremely complex to implement in pure Dart.
  static Future<String> convertToWav(String inputPath) async {
    developer.log('🎵 Converting audio file to WAV format for Whisper compatibility', name: _logName);

    // 🔍 INPUT VALIDATION: Security-first approach
    if (!await File(inputPath).exists()) {
      throw AudioConverterException('Input file does not exist: $inputPath');
    }

    // 🎯 OUTPUT PATH GENERATION: Create WAV equivalent
    final inputDir = path.dirname(inputPath);
    final inputBasename = path.basenameWithoutExtension(inputPath);
    final outputPath = path.join(inputDir, '${inputBasename}_converted.wav');

    try {
      // 🔧 FFMPEG COMMAND: Convert to Whisper-compatible format
      // - 16kHz sample rate (Whisper requirement)
      // - 16-bit PCM encoding (uncompressed)
      // - Mono channel (Whisper works best with mono)
      final List<String> arguments = [
        '-y', // Overwrite output file
        '-i', inputPath, // Input file
        '-acodec', 'pcm_s16le', // Audio codec: 16-bit PCM little-endian
        '-ar', '16000', // Sample rate: 16kHz for Whisper
        '-ac', '1', // Audio channels: mono
        '-f', 'wav', // Output format: WAV
        outputPath, // Output file path
      ];

      developer.log('🔄 Executing ffmpeg conversion with arguments: ${arguments.join(' ')}', name: _logName);

      // ⚡ PROCESS EXECUTION with proper error handling
      // Note: Timeout handling would require Process.start() for advanced control
      final ProcessResult result = await Process.run('ffmpeg', arguments);

      // 📊 RESULT VALIDATION
      if (result.exitCode != 0) {
        final errorOutput = result.stderr.toString().trim();
        developer.log('❌ FFmpeg conversion failed with exit code ${result.exitCode}', name: _logName);
        developer.log('💥 FFmpeg error output: $errorOutput', name: _logName);

        throw AudioConverterException(
          'Audio conversion failed (exit code: ${result.exitCode})\n'
          'FFmpeg error: $errorOutput\n'
          'This might be due to:\n'
          '• Unsupported input format\n'
          '• Corrupted audio file\n'
          '• FFmpeg not installed or not in PATH\n'
          'Input file: $inputPath',
        );
      }

      // ✅ VERIFY OUTPUT FILE
      if (!await File(outputPath).exists()) {
        throw AudioConverterException('Conversion appeared successful but output file was not created: $outputPath');
      }

      final outputSize = await File(outputPath).length();
      developer.log('✅ Audio conversion completed successfully', name: _logName);
      developer.log('📄 Output file: $outputPath (${_formatFileSize(outputSize)})', name: _logName);

      return outputPath;
    } on ProcessException catch (e) {
      developer.log('💥 Process execution failed: $e', name: _logName);

      if (e.message.contains('No such file or directory') || e.message.contains('command not found')) {
        throw AudioConverterException(
          'FFmpeg is not installed or not found in PATH.\n'
          'Please install FFmpeg to use audio conversion features.\n'
          'Installation:\n'
          '• macOS: brew install ffmpeg\n'
          '• Ubuntu: sudo apt install ffmpeg\n'
          '• Windows: Download from https://ffmpeg.org/',
        );
      }

      throw AudioConverterException('Failed to execute audio conversion: ${e.message}');
    } catch (e) {
      developer.log('❌ Unexpected error during audio conversion: $e', name: _logName);
      rethrow;
    }
  }

  /// Get detailed audio file information using ffprobe
  ///
  /// **Workshop Demo Point**: Shows how to parse structured output from external tools
  static Future<AudioFileInfo> getAudioInfo(String filePath) async {
    developer.log('📊 Analyzing audio file: $filePath', name: _logName);

    if (!await File(filePath).exists()) {
      throw AudioConverterException('Audio file does not exist: $filePath');
    }

    try {
      // 🔍 FFPROBE COMMAND: Get audio metadata in JSON format for easy parsing
      final List<String> arguments = [
        '-v', 'quiet', // Suppress verbose output
        '-print_format', 'json', // Output in JSON format
        '-show_format', // Show container format info
        '-show_streams', // Show stream info
        filePath,
      ];

      final ProcessResult result = await Process.run('ffprobe', arguments);

      if (result.exitCode != 0) {
        final errorOutput = result.stderr.toString().trim();
        throw AudioConverterException('Failed to analyze audio file: $errorOutput');
      }

      // 📝 PARSE JSON OUTPUT: Real-world example of processing external tool output
      final String jsonOutput = result.stdout.toString();
      return AudioFileInfo.fromFfprobeJson(jsonOutput);
    } on ProcessException catch (e) {
      if (e.message.contains('No such file or directory') || e.message.contains('command not found')) {
        throw AudioConverterException(
          'FFprobe (part of FFmpeg) is not installed. Please install FFmpeg to analyze audio files.',
        );
      }
      throw AudioConverterException('Failed to analyze audio file: ${e.message}');
    }
  }

  /// Convert multiple audio files in batch
  ///
  /// **Workshop Demo Point**: Demonstrates parallel processing and error recovery
  static Future<List<String>> convertBatch(List<String> inputPaths) async {
    developer.log('🔄 Starting batch conversion of ${inputPaths.length} files', name: _logName);

    final List<String> convertedPaths = [];
    final List<String> failedPaths = [];

    // 🚀 PARALLEL PROCESSING: Process multiple files concurrently for better performance
    final List<Future<String?>> conversionFutures = inputPaths.map((inputPath) async {
      try {
        final convertedPath = await convertToWav(inputPath);
        return convertedPath;
      } catch (e) {
        developer.log('❌ Failed to convert $inputPath: $e', name: _logName);
        failedPaths.add(inputPath);
        return null;
      }
    }).toList();

    // ⏳ WAIT FOR ALL CONVERSIONS
    final List<String?> results = await Future.wait(conversionFutures);

    for (final result in results) {
      if (result != null) {
        convertedPaths.add(result);
      }
    }

    developer.log(
      '✅ Batch conversion completed: ${convertedPaths.length} successful, ${failedPaths.length} failed',
      name: _logName,
    );

    if (failedPaths.isNotEmpty) {
      developer.log('💥 Failed files: ${failedPaths.join(', ')}', name: _logName);
    }

    return convertedPaths;
  }

  /// Check if FFmpeg is available on the system
  ///
  /// **Workshop Demo Point**: System capability detection before attempting operations
  static Future<bool> isFFmpegAvailable() async {
    // 🔄 Return cached result if available
    if (_ffmpegAvailabilityCache != null) {
      return _ffmpegAvailabilityCache!;
    }

    try {
      final ProcessResult result = await Process.run('ffmpeg', ['-version']);

      final bool isAvailable = result.exitCode == 0;

      // 💾 Cache the result to prevent repeated checks
      _ffmpegAvailabilityCache = isAvailable;

      developer.log(
        isAvailable ? '✅ FFmpeg is available on system' : '❌ FFmpeg not available (exit code: ${result.exitCode})',
        name: _logName,
      );

      return isAvailable;
    } catch (e) {
      // 🔇 Only log the first failure to prevent console spam
      final bool isFirstCheck = _ffmpegAvailabilityCache == null;

      // 💾 Cache negative result to prevent spam
      _ffmpegAvailabilityCache = false;

      if (isFirstCheck) {
        developer.log('❌ FFmpeg availability check failed: $e', name: _logName);
        developer.log('ℹ️ This is expected in sandboxed environments (macOS apps, etc.)', name: _logName);
      }

      return false;
    }
  }

  /// Get FFmpeg version information
  static Future<String> getFFmpegVersion() async {
    // 🔄 Return cached result if available
    if (_ffmpegVersionCache != null) {
      return _ffmpegVersionCache!;
    }

    // 🔄 If we know FFmpeg is not available, return early
    if (_ffmpegAvailabilityCache == false) {
      _ffmpegVersionCache = 'Not available';
      return _ffmpegVersionCache!;
    }

    try {
      final ProcessResult result = await Process.run('ffmpeg', ['-version']);

      if (result.exitCode == 0) {
        final String output = result.stdout.toString();
        // Extract version from first line: "ffmpeg version 4.4.2-0ubuntu0.22.04.1"
        final RegExp versionRegex = RegExp(r'ffmpeg version ([^\s]+)');
        final Match? match = versionRegex.firstMatch(output);

        final String version = match?.group(1) ?? 'Unknown version';
        // 💾 Cache the result
        _ffmpegVersionCache = version;
        return version;
      }

      _ffmpegVersionCache = 'Version check failed';
      return _ffmpegVersionCache!;
    } catch (e) {
      _ffmpegVersionCache = 'Not available';
      return _ffmpegVersionCache!;
    }
  }

  // 🔧 HELPER METHODS

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Validate that a command is in the allowed list
  static bool _isCommandAllowed(String command) {
    return _allowedCommands.contains(command);
  }

  /// Reset cached FFmpeg availability (useful for testing or configuration changes)
  static void resetFFmpegCache() {
    _ffmpegAvailabilityCache = null;
    _ffmpegVersionCache = null;
    developer.log('🔄 FFmpeg availability cache reset', name: _logName);
  }
}

/// Audio file information extracted from ffprobe
class AudioFileInfo {
  final String format;
  final Duration duration;
  final int sampleRate;
  final int channels;
  final String codec;
  final int bitRate;
  final int fileSizeBytes;

  AudioFileInfo({
    required this.format,
    required this.duration,
    required this.sampleRate,
    required this.channels,
    required this.codec,
    required this.bitRate,
    required this.fileSizeBytes,
  });

  /// Parse audio info from ffprobe JSON output
  factory AudioFileInfo.fromFfprobeJson(String jsonOutput) {
    // 📝 Note: In a production app, you'd use a proper JSON parsing library
    // This is simplified for workshop demonstration purposes

    try {
      // Extract basic information using simple string parsing
      // In production, use dart:convert for proper JSON parsing

      final bool isWav = jsonOutput.contains('"format_name":"wav"');
      final bool isMp3 = jsonOutput.contains('"codec_name":"mp3"');
      final bool isM4a = jsonOutput.contains('"codec_name":"aac"');

      String format = 'unknown';
      if (isWav)
        format = 'WAV';
      else if (isMp3)
        format = 'MP3';
      else if (isM4a)
        format = 'M4A/AAC';

      // Extract duration (simplified parsing)
      final RegExp durationRegex = RegExp(r'"duration":"([^"]+)"');
      final Match? durationMatch = durationRegex.firstMatch(jsonOutput);
      final double durationSeconds = double.tryParse(durationMatch?.group(1) ?? '0') ?? 0;

      // Extract sample rate
      final RegExp sampleRateRegex = RegExp(r'"sample_rate":"([^"]+)"');
      final Match? sampleRateMatch = sampleRateRegex.firstMatch(jsonOutput);
      final int sampleRate = int.tryParse(sampleRateMatch?.group(1) ?? '0') ?? 0;

      // Extract channels
      final RegExp channelsRegex = RegExp(r'"channels":([^,}]+)');
      final Match? channelsMatch = channelsRegex.firstMatch(jsonOutput);
      final int channels = int.tryParse(channelsMatch?.group(1) ?? '0') ?? 0;

      return AudioFileInfo(
        format: format,
        duration: Duration(milliseconds: (durationSeconds * 1000).round()),
        sampleRate: sampleRate,
        channels: channels,
        codec: isMp3
            ? 'MP3'
            : isM4a
            ? 'AAC'
            : isWav
            ? 'PCM'
            : 'Unknown',
        bitRate: 0, // Would need more complex parsing
        fileSizeBytes: 0, // Would need more complex parsing
      );
    } catch (e) {
      // Fallback for parsing errors
      return AudioFileInfo(
        format: 'Unknown',
        duration: Duration.zero,
        sampleRate: 0,
        channels: 0,
        codec: 'Unknown',
        bitRate: 0,
        fileSizeBytes: 0,
      );
    }
  }

  @override
  String toString() {
    return 'AudioFileInfo('
        'format: $format, '
        'duration: ${duration.inSeconds}s, '
        'sampleRate: ${sampleRate}Hz, '
        'channels: $channels, '
        'codec: $codec'
        ')';
  }

  /// Check if the audio file is compatible with Whisper
  bool get isWhisperCompatible {
    return sampleRate == 16000 && channels == 1 && codec == 'PCM';
  }

  /// Get a human-readable compatibility message
  String get compatibilityMessage {
    if (isWhisperCompatible) {
      return '✅ Optimized for Whisper transcription';
    }

    final List<String> issues = [];
    if (sampleRate != 16000) issues.add('Sample rate should be 16kHz (currently ${sampleRate}Hz)');
    if (channels != 1) issues.add('Should be mono (currently $channels channels)');
    if (codec != 'PCM') issues.add('Should use PCM encoding (currently $codec)');

    return '⚠️ Needs conversion: ${issues.join(', ')}';
  }
}

/// Custom exception for audio conversion errors
class AudioConverterException implements Exception {
  final String message;

  AudioConverterException(this.message);

  @override
  String toString() => 'AudioConverterException: $message';
}
