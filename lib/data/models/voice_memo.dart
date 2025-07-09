// Voice Memo data model
// Represents a recorded voice memo with transcription and metadata

class VoiceMemo {
  final String id;
  final String filePath;
  final String title;
  final String? transcription;
  final List<String> keywords;
  final DateTime createdAt;
  final DateTime? lastModified;
  final int durationSeconds;
  final double fileSizeBytes;
  final bool isTranscribed;
  final VoiceMemoStatus status;

  const VoiceMemo({
    required this.id,
    required this.filePath,
    required this.title,
    this.transcription,
    required this.keywords,
    required this.createdAt,
    this.lastModified,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.isTranscribed,
    required this.status,
  });

  // Factory constructor for creating from JSON
  factory VoiceMemo.fromJson(Map<String, dynamic> json) {
    return VoiceMemo(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      transcription: json['transcription'] as String?,
      keywords: List<String>.from(json['keywords'] as List<dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified'] as String) : null,
      durationSeconds: json['durationSeconds'] as int,
      fileSizeBytes: (json['fileSizeBytes'] as num).toDouble(),
      isTranscribed: json['isTranscribed'] as bool,
      status: VoiceMemoStatus.fromString(json['status'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'transcription': transcription,
      'keywords': keywords,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'fileSizeBytes': fileSizeBytes,
      'isTranscribed': isTranscribed,
      'status': status.toString(),
    };
  }

  // Copy with method for immutable updates
  VoiceMemo copyWith({
    String? id,
    String? filePath,
    String? title,
    String? transcription,
    List<String>? keywords,
    DateTime? createdAt,
    DateTime? lastModified,
    int? durationSeconds,
    double? fileSizeBytes,
    bool? isTranscribed,
    VoiceMemoStatus? status,
  }) {
    return VoiceMemo(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      transcription: transcription ?? this.transcription,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      isTranscribed: isTranscribed ?? this.isTranscribed,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'VoiceMemo(id: $id, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceMemo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum for voice memo status
enum VoiceMemoStatus {
  recording,
  processing,
  completed,
  error;

  static VoiceMemoStatus fromString(String value) {
    return VoiceMemoStatus.values.firstWhere(
      (status) => status.toString().split('.').last == value,
      orElse: () => VoiceMemoStatus.error,
    );
  }

  @override
  String toString() => name;
}
