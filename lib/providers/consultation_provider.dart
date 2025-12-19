import 'package:flutter/foundation.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';

/// Provider for managing consultation state
class ConsultationProvider extends ChangeNotifier {
  final ConsultationService _service;

  List<Consultation> _consultations = [];
  Consultation? _currentConsultation;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  ConsultationStatus? _processingStatus;
  String? _processingMessage;

  ConsultationProvider(this._service);

  // Getters
  List<Consultation> get consultations => _consultations;
  Consultation? get currentConsultation => _currentConsultation;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  ConsultationStatus? get processingStatus => _processingStatus;
  String? get processingMessage => _processingMessage;

  /// Initialize the provider and load consultations
  Future<void> initialize() async {
    await _service.initialize();
    await loadConsultations();
  }

  /// Load all consultations from database
  Future<void> loadConsultations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _consultations = await _service.getConsultations();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Transcribe audio only (without report generation)
  Future<TranscriptionResult> transcribeOnly({
    required String audioFilePath,
    required String language,
    String? patientName,
  }) async {
    _isProcessing = true;
    _error = null;
    _processingStatus = ConsultationStatus.pending;
    _processingMessage = 'Starting...';
    notifyListeners();

    try {
      final savedPath = await _service.saveAudioFile(audioFilePath);

      final result = await _service.transcribeOnly(
        audioFilePath: savedPath,
        language: language,
        patientName: patientName,
        onStatusChange: (status, message) {
          _processingStatus = status;
          _processingMessage = message;
          notifyListeners();
        },
      );

      return result;
    } catch (e) {
      _error = e.toString();
      return TranscriptionResult.error(error: e.toString());
    } finally {
      _isProcessing = false;
      _processingStatus = null;
      _processingMessage = null;
      notifyListeners();
    }
  }

  /// Generate report from edited transcription
  Future<ProcessingResult> generateReportFromTranscription({
    required String consultationId,
    required String transcription,
    required String language,
    String? patientName,
  }) async {
    _isProcessing = true;
    _error = null;
    _processingStatus = ConsultationStatus.generating_report;
    _processingMessage = 'Generating medical report...';
    notifyListeners();

    try {
      final result = await _service.generateReportFromTranscription(
        consultationId: consultationId,
        transcription: transcription,
        language: language,
        patientName: patientName,
        onStatusChange: (status, message) {
          _processingStatus = status;
          _processingMessage = message;
          notifyListeners();
        },
      );

      if (result.success) {
        _currentConsultation = result.consultation;
        await loadConsultations();
      } else {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return ProcessingResult.error(
        consultationId: consultationId,
        error: e.toString(),
      );
    } finally {
      _isProcessing = false;
      _processingStatus = null;
      _processingMessage = null;
      notifyListeners();
    }
  }

  /// Process a new consultation (transcribe + generate report) - legacy method
  Future<ProcessingResult> processConsultation({
    required String audioFilePath,
    required String language,
    String? patientName,
  }) async {
    _isProcessing = true;
    _error = null;
    _processingStatus = ConsultationStatus.pending;
    _processingMessage = 'Starting...';
    notifyListeners();

    try {
      // Save audio file to app directory
      final savedPath = await _service.saveAudioFile(audioFilePath);

      final result = await _service.processConsultation(
        audioFilePath: savedPath,
        language: language,
        patientName: patientName,
        onStatusChange: (status, message) {
          _processingStatus = status;
          _processingMessage = message;
          notifyListeners();
        },
      );

      if (result.success) {
        _currentConsultation = result.consultation;
        // Reload consultations list
        await loadConsultations();
      } else {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return ProcessingResult.error(error: e.toString());
    } finally {
      _isProcessing = false;
      _processingStatus = null;
      _processingMessage = null;
      notifyListeners();
    }
  }

  /// Get a specific consultation
  Future<Consultation?> getConsultation(String id) async {
    try {
      _currentConsultation = await _service.getConsultation(id);
      notifyListeners();
      return _currentConsultation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Delete a consultation
  Future<bool> deleteConsultation(String id) async {
    try {
      await _service.deleteConsultation(id);
      _consultations.removeWhere((c) => c.id == id);
      if (_currentConsultation?.id == id) {
        _currentConsultation = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Regenerate report for a consultation
  Future<ProcessingResult> regenerateReport(
    String consultationId, {
    String? additionalInstructions,
  }) async {
    _isProcessing = true;
    _error = null;
    _processingStatus = ConsultationStatus.generating_report;
    _processingMessage = 'Regenerating report...';
    notifyListeners();

    try {
      final result = await _service.regenerateReport(
        consultationId: consultationId,
        additionalInstructions: additionalInstructions,
        onStatusChange: (status, message) {
          _processingStatus = status;
          _processingMessage = message;
          notifyListeners();
        },
      );

      if (result.success) {
        _currentConsultation = result.consultation;
        await loadConsultations();
      } else {
        _error = result.error;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return ProcessingResult.error(
        consultationId: consultationId,
        error: e.toString(),
      );
    } finally {
      _isProcessing = false;
      _processingStatus = null;
      _processingMessage = null;
      notifyListeners();
    }
  }

  /// Set current consultation
  void setCurrentConsultation(Consultation? consultation) {
    _currentConsultation = consultation;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }
}
