import 'report.dart';

enum ConsultationStatus {
  pending,
  transcribing,
  generating_report,
  completed,
  failed,
}

class Consultation {
  final String id;
  final String? patientName;
  final String? audioFilePath;
  final int? audioDurationSeconds;
  final String language;
  final String? transcription;
  final ConsultationStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  Report? report;

  Consultation({
    required this.id,
    this.patientName,
    this.audioFilePath,
    this.audioDurationSeconds,
    required this.language,
    this.transcription,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.report,
  });

  factory Consultation.fromRow(Map<String, dynamic> row) {
    return Consultation(
      id: row['id'].toString(),
      patientName: row['patient_name'],
      audioFilePath: row['audio_file_path'],
      audioDurationSeconds: row['audio_duration_seconds'],
      language: row['language'] ?? 'Hindi',
      transcription: row['transcription'],
      status: _parseStatus(row['status']),
      errorMessage: row['error_message'],
      createdAt: row['created_at'] ?? DateTime.now(),
      updatedAt: row['updated_at'] ?? DateTime.now(),
    );
  }

  static ConsultationStatus _parseStatus(dynamic status) {
    if (status == null) return ConsultationStatus.pending;
    final statusStr = status.toString().toLowerCase();
    switch (statusStr) {
      case 'pending':
        return ConsultationStatus.pending;
      case 'transcribing':
        return ConsultationStatus.transcribing;
      case 'generating_report':
        return ConsultationStatus.generating_report;
      case 'completed':
        return ConsultationStatus.completed;
      case 'failed':
        return ConsultationStatus.failed;
      default:
        return ConsultationStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'audio_file_path': audioFilePath,
      'audio_duration_seconds': audioDurationSeconds,
      'language': language,
      'transcription': transcription,
      'status': status.name,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'report': report?.toJson(),
    };
  }

  String get statusDisplayText {
    switch (status) {
      case ConsultationStatus.pending:
        return 'Pending';
      case ConsultationStatus.transcribing:
        return 'Transcribing...';
      case ConsultationStatus.generating_report:
        return 'Generating Report...';
      case ConsultationStatus.completed:
        return 'Completed';
      case ConsultationStatus.failed:
        return 'Failed';
    }
  }

  String get formattedDuration {
    if (audioDurationSeconds == null) return '--:--';
    final minutes = audioDurationSeconds! ~/ 60;
    final seconds = audioDurationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

