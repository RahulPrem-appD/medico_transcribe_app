import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/consultation.dart';
import '../models/report_template.dart';
import 'database_service.dart';
import 'sarvam_service.dart';
import 'feather_service.dart';

/// Consultation Service - orchestrates the entire consultation workflow
/// 1. Create consultation in database
/// 2. Transcribe audio using Sarvam AI
/// 3. Generate report using Featherless AI
/// 4. Save report to database
class ConsultationService {
  static final ConsultationService _instance = ConsultationService._internal();
  factory ConsultationService() => _instance;
  ConsultationService._internal();

  final DatabaseService _db = DatabaseService();
  final SarvamService _sarvam = SarvamService();
  final FeatherService _feather = FeatherService();

  /// Initialize all services
  Future<void> initialize() async {
    await _db.initialize();
  }

  /// Transcribe audio only (without report generation)
  Future<TranscriptionResult> transcribeOnly({
    required String audioFilePath,
    required String language,
    String? patientName,
    Function(ConsultationStatus status, String? message)? onStatusChange,
  }) async {
    Consultation? consultation;

    try {
      // Step 1: Create consultation record
      onStatusChange?.call(
        ConsultationStatus.pending,
        'Creating consultation...',
      );

      consultation = await _db.createConsultation(
        patientName: patientName,
        language: language,
        audioFilePath: audioFilePath,
      );

      print('Consultation created: ${consultation.id}');

      // Step 2: Transcribe audio
      onStatusChange?.call(
        ConsultationStatus.transcribing,
        'Transcribing audio...',
      );
      await _db.updateConsultationStatus(
        consultation.id,
        ConsultationStatus.transcribing,
      );

      final transcriptionResult = await _sarvam.transcribeAudio(
        audioFilePath: audioFilePath,
        language: language,
      );

      if (!transcriptionResult.success) {
        await _db.updateConsultationStatus(
          consultation.id,
          ConsultationStatus.failed,
          errorMessage: transcriptionResult.error,
        );
        return TranscriptionResult.error(
          consultationId: consultation.id,
          error: transcriptionResult.error ?? 'Transcription failed',
        );
      }

      // Update transcription in database
      await _db.updateConsultationTranscription(
        consultation.id,
        transcriptionResult.transcription!,
      );

      print(
        'Transcription completed: ${transcriptionResult.transcription!.length} chars',
      );

      return TranscriptionResult.success(
        consultationId: consultation.id,
        transcription: transcriptionResult.transcription!,
        diarization: transcriptionResult.diarization,
      );
    } catch (e) {
      print('Transcription error: $e');

      if (consultation != null) {
        await _db.updateConsultationStatus(
          consultation.id,
          ConsultationStatus.failed,
          errorMessage: e.toString(),
        );
      }

      return TranscriptionResult.error(
        consultationId: consultation?.id,
        error: e.toString(),
      );
    }
  }

  /// Generate report from transcription (after user review/edit)
  Future<ProcessingResult> generateReportFromTranscription({
    required String consultationId,
    required String transcription,
    required String language,
    String? patientName,
    String? additionalInstructions,
    ReportTemplateConfig? templateConfig,
    Function(ConsultationStatus status, String? message)? onStatusChange,
  }) async {
    try {
      // Update transcription in database (in case user edited it)
      await _db.updateConsultationTranscription(consultationId, transcription);

      // Generate report
      onStatusChange?.call(
        ConsultationStatus.generating_report,
        'Generating medical report...',
      );
      await _db.updateConsultationStatus(
        consultationId,
        ConsultationStatus.generating_report,
      );

      final reportResult = await _feather.generateReport(
        transcription: transcription,
        language: language,
        patientName: patientName,
        additionalInstructions: additionalInstructions,
        templateConfig: templateConfig,
      );

      if (!reportResult.success) {
        await _db.updateConsultationStatus(
          consultationId,
          ConsultationStatus.failed,
          errorMessage: reportResult.error,
        );
        return ProcessingResult.error(
          consultationId: consultationId,
          error: reportResult.error ?? 'Report generation failed',
        );
      }

      // Save report to database with dynamic sections
      if (reportResult.sections != null) {
        await _db.createReportWithSections(
          consultationId: consultationId,
          sections: reportResult.sections!,
        );
      } else {
        // Fallback for legacy response
        await _db.createReport(
          consultationId: consultationId,
          chiefComplaint: reportResult.chiefComplaint ?? '',
          symptoms: reportResult.symptoms ?? '',
          diagnosis: reportResult.diagnosis ?? '',
          prescription: reportResult.prescription ?? '',
          additionalNotes: reportResult.additionalNotes ?? '',
        );
      }

      print('Report created successfully');
      onStatusChange?.call(
        ConsultationStatus.completed,
        'Consultation completed!',
      );

      // Fetch complete consultation with report
      final completedConsultation = await _db.getConsultation(consultationId);

      return ProcessingResult.success(consultation: completedConsultation!);
    } catch (e) {
      print('Report generation error: $e');

      await _db.updateConsultationStatus(
        consultationId,
        ConsultationStatus.failed,
        errorMessage: e.toString(),
      );

      return ProcessingResult.error(
        consultationId: consultationId,
        error: e.toString(),
      );
    }
  }

  /// Process a new consultation (legacy - transcribe + generate report in one go)
  Future<ProcessingResult> processConsultation({
    required String audioFilePath,
    required String language,
    String? patientName,
    Function(ConsultationStatus status, String? message)? onStatusChange,
  }) async {
    Consultation? consultation;

    try {
      // Step 1: Create consultation record
      onStatusChange?.call(
        ConsultationStatus.pending,
        'Creating consultation...',
      );

      consultation = await _db.createConsultation(
        patientName: patientName,
        language: language,
        audioFilePath: audioFilePath,
      );

      print('Consultation created: ${consultation.id}');

      // Step 2: Transcribe audio
      onStatusChange?.call(
        ConsultationStatus.transcribing,
        'Transcribing audio...',
      );
      await _db.updateConsultationStatus(
        consultation.id,
        ConsultationStatus.transcribing,
      );

      final transcriptionResult = await _sarvam.transcribeAudio(
        audioFilePath: audioFilePath,
        language: language,
      );

      if (!transcriptionResult.success) {
        await _db.updateConsultationStatus(
          consultation.id,
          ConsultationStatus.failed,
          errorMessage: transcriptionResult.error,
        );
        return ProcessingResult.error(
          consultationId: consultation.id,
          error: transcriptionResult.error ?? 'Transcription failed',
        );
      }

      // Update transcription in database
      await _db.updateConsultationTranscription(
        consultation.id,
        transcriptionResult.transcription!,
      );

      print(
        'Transcription completed: ${transcriptionResult.transcription!.length} chars',
      );

      // Step 3: Generate report
      onStatusChange?.call(
        ConsultationStatus.generating_report,
        'Generating medical report...',
      );

      final reportResult = await _feather.generateReport(
        transcription: transcriptionResult.transcription!,
        language: language,
        patientName: patientName,
      );

      if (!reportResult.success) {
        await _db.updateConsultationStatus(
          consultation.id,
          ConsultationStatus.failed,
          errorMessage: reportResult.error,
        );
        return ProcessingResult.error(
          consultationId: consultation.id,
          error: reportResult.error ?? 'Report generation failed',
        );
      }

      // Step 4: Save report to database
      await _db.createReport(
        consultationId: consultation.id,
        chiefComplaint: reportResult.chiefComplaint!,
        symptoms: reportResult.symptoms!,
        diagnosis: reportResult.diagnosis!,
        prescription: reportResult.prescription!,
        additionalNotes: reportResult.additionalNotes!,
      );

      print('Report created successfully');
      onStatusChange?.call(
        ConsultationStatus.completed,
        'Consultation completed!',
      );

      // Fetch complete consultation with report
      final completedConsultation = await _db.getConsultation(consultation.id);

      return ProcessingResult.success(consultation: completedConsultation!);
    } catch (e) {
      print('Consultation processing error: $e');

      if (consultation != null) {
        await _db.updateConsultationStatus(
          consultation.id,
          ConsultationStatus.failed,
          errorMessage: e.toString(),
        );
      }

      return ProcessingResult.error(
        consultationId: consultation?.id,
        error: e.toString(),
      );
    }
  }

  /// Get all consultations
  Future<List<Consultation>> getConsultations({
    int limit = 50,
    int offset = 0,
  }) async {
    return await _db.getConsultations(limit: limit, offset: offset);
  }

  /// Get a single consultation
  Future<Consultation?> getConsultation(String id) async {
    return await _db.getConsultation(id);
  }

  /// Delete a consultation
  Future<void> deleteConsultation(String id) async {
    await _db.deleteConsultation(id);
  }

  /// Regenerate report for existing consultation
  Future<ProcessingResult> regenerateReport({
    required String consultationId,
    String? additionalInstructions,
    ReportTemplateConfig? templateConfig,
    Function(ConsultationStatus status, String? message)? onStatusChange,
  }) async {
    try {
      final consultation = await _db.getConsultation(consultationId);

      if (consultation == null) {
        return ProcessingResult.error(
          consultationId: consultationId,
          error: 'Consultation not found',
        );
      }

      if (consultation.transcription == null ||
          consultation.transcription!.isEmpty) {
        return ProcessingResult.error(
          consultationId: consultationId,
          error: 'No transcription available to generate report',
        );
      }

      onStatusChange?.call(
        ConsultationStatus.generating_report,
        'Regenerating report...',
      );
      await _db.updateConsultationStatus(
        consultationId,
        ConsultationStatus.generating_report,
      );

      final reportResult = await _feather.generateReport(
        transcription: consultation.transcription!,
        language: consultation.language,
        patientName: consultation.patientName,
        additionalInstructions: additionalInstructions,
        templateConfig: templateConfig,
      );

      if (!reportResult.success) {
        await _db.updateConsultationStatus(
          consultationId,
          ConsultationStatus.failed,
          errorMessage: reportResult.error,
        );
        return ProcessingResult.error(
          consultationId: consultationId,
          error: reportResult.error ?? 'Report regeneration failed',
        );
      }

      // Delete existing report and create new one with dynamic sections
      if (reportResult.sections != null) {
        await _db.createReportWithSections(
          consultationId: consultationId,
          sections: reportResult.sections!,
        );
      } else {
        await _db.createReport(
          consultationId: consultationId,
          chiefComplaint: reportResult.chiefComplaint ?? '',
          symptoms: reportResult.symptoms ?? '',
          diagnosis: reportResult.diagnosis ?? '',
          prescription: reportResult.prescription ?? '',
          additionalNotes: reportResult.additionalNotes ?? '',
        );
      }

      onStatusChange?.call(ConsultationStatus.completed, 'Report regenerated!');

      final updatedConsultation = await _db.getConsultation(consultationId);
      return ProcessingResult.success(consultation: updatedConsultation!);
    } catch (e) {
      return ProcessingResult.error(
        consultationId: consultationId,
        error: e.toString(),
      );
    }
  }

  /// Save audio file to app directory
  Future<String> saveAudioFile(String tempPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/recordings');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = '${audioDir.path}/recording_$timestamp.wav';

    final tempFile = File(tempPath);
    await tempFile.copy(newPath);

    return newPath;
  }

  /// Close all services
  Future<void> close() async {
    await _db.close();
  }
}

/// Result of consultation processing
class ProcessingResult {
  final bool success;
  final String? consultationId;
  final Consultation? consultation;
  final String? error;

  ProcessingResult._({
    required this.success,
    this.consultationId,
    this.consultation,
    this.error,
  });

  factory ProcessingResult.success({required Consultation consultation}) {
    return ProcessingResult._(
      success: true,
      consultationId: consultation.id,
      consultation: consultation,
    );
  }

  factory ProcessingResult.error({
    String? consultationId,
    required String error,
  }) {
    return ProcessingResult._(
      success: false,
      consultationId: consultationId,
      error: error,
    );
  }
}

/// Result of transcription only
class TranscriptionResult {
  final bool success;
  final String? consultationId;
  final String? transcription;
  final List<dynamic>? diarization;
  final String? error;

  TranscriptionResult._({
    required this.success,
    this.consultationId,
    this.transcription,
    this.diarization,
    this.error,
  });

  factory TranscriptionResult.success({
    required String consultationId,
    required String transcription,
    List<dynamic>? diarization,
  }) {
    return TranscriptionResult._(
      success: true,
      consultationId: consultationId,
      transcription: transcription,
      diarization: diarization,
    );
  }

  factory TranscriptionResult.error({
    String? consultationId,
    required String error,
  }) {
    return TranscriptionResult._(
      success: false,
      consultationId: consultationId,
      error: error,
    );
  }
}
