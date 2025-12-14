import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/consultation.dart';
import '../models/report.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// SQLite Database Service
/// Handles all local database operations for consultations and reports
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  bool _isInitialized = false;

  /// Initialize database connection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'medico_transcribe.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
      );

      _isInitialized = true;
      print('Database connected successfully');
    } catch (e) {
      print('Database connection error: $e');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Create consultations table
    await db.execute('''
      CREATE TABLE consultations (
        id TEXT PRIMARY KEY,
        patient_name TEXT,
        audio_file_path TEXT,
        audio_duration_seconds INTEGER,
        language TEXT NOT NULL,
        transcription TEXT,
        status TEXT DEFAULT 'pending',
        error_message TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create reports table
    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        consultation_id TEXT NOT NULL,
        chief_complaint TEXT,
        symptoms TEXT,
        diagnosis TEXT,
        prescription TEXT,
        additional_notes TEXT,
        generated_by TEXT DEFAULT 'feather_ai',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
      )
    ''');

    print('Database tables created');
  }

  /// Create a new consultation
  Future<Consultation> createConsultation({
    String? patientName,
    required String language,
    String? audioFilePath,
  }) async {
    await _ensureConnection();

    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _database!.insert('consultations', {
      'id': id,
      'patient_name': patientName,
      'language': language,
      'audio_file_path': audioFilePath,
      'status': 'pending',
      'created_at': now,
      'updated_at': now,
    });

    final result = await _database!.query(
      'consultations',
      where: 'id = ?',
      whereArgs: [id],
    );

    return Consultation.fromRow(_convertRow(result.first));
  }

  /// Update consultation status
  Future<void> updateConsultationStatus(
    String id,
    ConsultationStatus status, {
    String? errorMessage,
  }) async {
    await _ensureConnection();

    await _database!.update(
      'consultations',
      {
        'status': status.name,
        'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update consultation transcription
  Future<void> updateConsultationTranscription(
    String id,
    String transcription,
  ) async {
    await _ensureConnection();

    await _database!.update(
      'consultations',
      {
        'transcription': transcription,
        'status': 'generating_report',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Create a report for a consultation
  Future<Report> createReport({
    required String consultationId,
    required String chiefComplaint,
    required String symptoms,
    required String diagnosis,
    required String prescription,
    required String additionalNotes,
  }) async {
    await _ensureConnection();

    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _database!.insert('reports', {
      'id': id,
      'consultation_id': consultationId,
      'chief_complaint': chiefComplaint,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'additional_notes': additionalNotes,
      'generated_by': 'feather_ai',
      'created_at': now,
      'updated_at': now,
    });

    // Update consultation status to completed
    await _database!.update(
      'consultations',
      {
        'status': 'completed',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [consultationId],
    );

    final result = await _database!.query(
      'reports',
      where: 'id = ?',
      whereArgs: [id],
    );

    return Report.fromRow(_convertRow(result.first));
  }

  /// Get all consultations
  Future<List<Consultation>> getConsultations({
    int limit = 50,
    int offset = 0,
  }) async {
    await _ensureConnection();

    final consultationsResult = await _database!.query(
      'consultations',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    final consultations = <Consultation>[];

    for (final row in consultationsResult) {
      final consultation = Consultation.fromRow(_convertRow(row));

      // Get associated report if exists
      final reportResult = await _database!.query(
        'reports',
        where: 'consultation_id = ?',
        whereArgs: [consultation.id],
      );

      if (reportResult.isNotEmpty) {
        final reportRow = _convertRow(reportResult.first);
        consultation.report = Report(
          id: reportRow['id'].toString(),
          consultationId: consultation.id,
          chiefComplaint: reportRow['chief_complaint'] ?? '',
          symptoms: reportRow['symptoms'] ?? '',
          diagnosis: reportRow['diagnosis'] ?? '',
          prescription: reportRow['prescription'] ?? '',
          additionalNotes: reportRow['additional_notes'] ?? '',
          generatedBy: reportRow['generated_by'] ?? 'feather_ai',
          createdAt: _parseDateTime(reportRow['created_at']),
          updatedAt: _parseDateTime(reportRow['updated_at']),
        );
      }

      consultations.add(consultation);
    }

    return consultations;
  }

  /// Get a single consultation by ID
  Future<Consultation?> getConsultation(String id) async {
    await _ensureConnection();

    final result = await _database!.query(
      'consultations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    final consultation = Consultation.fromRow(_convertRow(result.first));

    // Get associated report if exists
    final reportResult = await _database!.query(
      'reports',
      where: 'consultation_id = ?',
      whereArgs: [id],
    );

    if (reportResult.isNotEmpty) {
      final reportRow = _convertRow(reportResult.first);
      consultation.report = Report(
        id: reportRow['id'].toString(),
        consultationId: consultation.id,
        chiefComplaint: reportRow['chief_complaint'] ?? '',
        symptoms: reportRow['symptoms'] ?? '',
        diagnosis: reportRow['diagnosis'] ?? '',
        prescription: reportRow['prescription'] ?? '',
        additionalNotes: reportRow['additional_notes'] ?? '',
        generatedBy: reportRow['generated_by'] ?? 'feather_ai',
        createdAt: _parseDateTime(reportRow['created_at']),
        updatedAt: _parseDateTime(reportRow['updated_at']),
      );
    }

    return consultation;
  }

  /// Delete a consultation
  Future<void> deleteConsultation(String id) async {
    await _ensureConnection();

    // Delete associated reports first
    await _database!.delete(
      'reports',
      where: 'consultation_id = ?',
      whereArgs: [id],
    );

    // Delete consultation
    await _database!.delete(
      'consultations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ensure database connection is active
  Future<void> _ensureConnection() async {
    if (_database == null || !_isInitialized) {
      await initialize();
    }
  }

  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInitialized = false;
  }

  /// Convert SQLite row to Map with proper types
  Map<String, dynamic> _convertRow(Map<String, dynamic> row) {
    return {
      ...row,
      'created_at': _parseDateTime(row['created_at']),
      'updated_at': _parseDateTime(row['updated_at']),
    };
  }

  /// Parse datetime from string
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
