import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/consultation.dart';
import '../models/report.dart';
import '../models/note.dart';
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
        version: 3, // Increment version for notes table
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
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

    // Create reports table with sections column for dynamic sections
    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        consultation_id TEXT NOT NULL,
        sections TEXT,
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

    // Create notes table for quick notes
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        patient_name TEXT,
        color TEXT,
        is_pinned INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    print('Database tables created');
  }

  /// Handle database migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add sections column if not exists
      try {
        await db.execute('ALTER TABLE reports ADD COLUMN sections TEXT');
        print('Added sections column to reports table');
      } catch (e) {
        // Column might already exist
        print('Migration note: $e');
      }
    }
    if (oldVersion < 3) {
      // Create notes table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT,
            patient_name TEXT,
            color TEXT,
            is_pinned INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        print('Created notes table');
      } catch (e) {
        print('Migration note (notes table): $e');
      }
    }
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

  /// Create a report for a consultation with dynamic sections
  Future<Report> createReportWithSections({
    required String consultationId,
    required Map<String, String> sections,
  }) async {
    await _ensureConnection();

    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    // Store sections as JSON and also extract legacy fields for backward compatibility
    await _database!.insert('reports', {
      'id': id,
      'consultation_id': consultationId,
      'sections': jsonEncode(sections),
      'chief_complaint': sections['chief_complaint'] ?? '',
      'symptoms': sections['symptoms'] ?? '',
      'diagnosis': sections['diagnosis'] ?? sections['assessment'] ?? '',
      'prescription': sections['prescription'] ?? sections['your_medications'] ?? '',
      'additional_notes': sections['additional_notes'] ?? sections['notes'] ?? '',
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

  /// Create a report for a consultation (legacy method for backward compatibility)
  Future<Report> createReport({
    required String consultationId,
    required String chiefComplaint,
    required String symptoms,
    required String diagnosis,
    required String prescription,
    required String additionalNotes,
  }) async {
    return createReportWithSections(
      consultationId: consultationId,
      sections: {
        'chief_complaint': chiefComplaint,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'prescription': prescription,
        'additional_notes': additionalNotes,
      },
    );
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
        consultation.report = Report.fromRow(_convertRow(reportResult.first));
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
      consultation.report = Report.fromRow(_convertRow(reportResult.first));
    }

    return consultation;
  }

  /// Update a report's sections
  Future<Report> updateReportSections({
    required String reportId,
    required Map<String, String> sections,
  }) async {
    await _ensureConnection();

    final now = DateTime.now().toIso8601String();

    // Update sections as JSON and also update legacy fields for backward compatibility
    await _database!.update(
      'reports',
      {
        'sections': jsonEncode(sections),
        'chief_complaint': sections['chief_complaint'] ?? '',
        'symptoms': sections['symptoms'] ?? '',
        'diagnosis': sections['diagnosis'] ?? sections['assessment'] ?? '',
        'prescription': sections['prescription'] ?? sections['your_medications'] ?? '',
        'additional_notes': sections['additional_notes'] ?? sections['notes'] ?? '',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [reportId],
    );

    final result = await _database!.query(
      'reports',
      where: 'id = ?',
      whereArgs: [reportId],
    );

    return Report.fromRow(_convertRow(result.first));
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

  /// Search for existing patients by various criteria
  /// Returns unique patients based on their name, extracting details from reports
  Future<List<Map<String, String>>> searchPatients({
    required String query,
    required String searchType, // 'name', 'id', 'phone'
  }) async {
    await _ensureConnection();

    final List<Map<String, String>> patients = [];
    final Set<String> seenPatients = {}; // To avoid duplicates

    // Get all consultations with their reports
    final consultationsResult = await _database!.query(
      'consultations',
      orderBy: 'created_at DESC',
    );

    for (final row in consultationsResult) {
      final consultationId = row['id'] as String;
      final patientName = row['patient_name'] as String? ?? '';

      // Get associated report
      final reportResult = await _database!.query(
        'reports',
        where: 'consultation_id = ?',
        whereArgs: [consultationId],
      );

      if (reportResult.isEmpty) continue;

      // Parse sections from report
      final sectionsJson = reportResult.first['sections'] as String?;
      Map<String, dynamic> sections = {};
      if (sectionsJson != null && sectionsJson.isNotEmpty) {
        try {
          sections = jsonDecode(sectionsJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      // Extract patient details
      final name = sections['patient_name']?.toString() ?? patientName;
      final age = sections['age']?.toString() ?? '';
      final gender = sections['gender']?.toString() ?? '';
      final bloodGroup = sections['blood_group']?.toString() ?? '';
      final phone = sections['phone']?.toString() ?? '';
      final weight = sections['weight']?.toString() ?? '';
      final height = sections['height']?.toString() ?? '';

      // Skip if no name
      if (name.isEmpty) continue;

      // Create a unique key for this patient
      final patientKey = '${name.toLowerCase()}_${phone}_${age}';
      if (seenPatients.contains(patientKey)) continue;

      // Check if matches search criteria
      bool matches = false;
      final queryLower = query.toLowerCase();

      switch (searchType) {
        case 'name':
          matches = name.toLowerCase().contains(queryLower);
          break;
        case 'id':
          matches = consultationId.toLowerCase().contains(queryLower);
          break;
        case 'phone':
          matches = phone.contains(query);
          break;
      }

      if (matches) {
        seenPatients.add(patientKey);
        patients.add({
          'id': consultationId, // Use consultation ID as patient reference
          'name': name,
          'age': age,
          'gender': gender,
          'blood_group': bloodGroup,
          'phone': phone,
          'weight': weight,
          'height': height,
        });
      }
    }

    return patients;
  }

  /// Get all unique patients (for listing)
  Future<List<Map<String, String>>> getAllPatients() async {
    await _ensureConnection();

    final List<Map<String, String>> patients = [];
    final Set<String> seenPatients = {}; // To avoid duplicates

    // Get all consultations with their reports
    final consultationsResult = await _database!.query(
      'consultations',
      orderBy: 'created_at DESC',
    );

    for (final row in consultationsResult) {
      final consultationId = row['id'] as String;
      final patientName = row['patient_name'] as String? ?? '';

      // Get associated report
      final reportResult = await _database!.query(
        'reports',
        where: 'consultation_id = ?',
        whereArgs: [consultationId],
      );

      if (reportResult.isEmpty) continue;

      // Parse sections from report
      final sectionsJson = reportResult.first['sections'] as String?;
      Map<String, dynamic> sections = {};
      if (sectionsJson != null && sectionsJson.isNotEmpty) {
        try {
          sections = jsonDecode(sectionsJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      // Extract patient details
      final name = sections['patient_name']?.toString() ?? patientName;
      final age = sections['age']?.toString() ?? '';
      final gender = sections['gender']?.toString() ?? '';
      final bloodGroup = sections['blood_group']?.toString() ?? '';
      final phone = sections['phone']?.toString() ?? '';

      // Skip if no name
      if (name.isEmpty) continue;

      // Create a unique key for this patient
      final patientKey = '${name.toLowerCase()}_${phone}_${age}';
      if (seenPatients.contains(patientKey)) continue;

      seenPatients.add(patientKey);
      patients.add({
        'id': consultationId,
        'name': name,
        'age': age,
        'gender': gender,
        'blood_group': bloodGroup,
        'phone': phone,
      });
    }

    return patients;
  }

  // ==================== NOTES METHODS ====================

  /// Create a new note
  Future<Note> createNote({
    required String title,
    required String content,
    String? patientName,
    String? color,
  }) async {
    await _ensureConnection();

    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _database!.insert('notes', {
      'id': id,
      'title': title,
      'content': content,
      'patient_name': patientName,
      'color': color,
      'is_pinned': 0,
      'created_at': now,
      'updated_at': now,
    });

    final result = await _database!.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    return Note.fromRow(_convertRow(result.first));
  }

  /// Update an existing note
  Future<Note> updateNote({
    required String id,
    String? title,
    String? content,
    String? patientName,
    String? color,
    bool? isPinned,
  }) async {
    await _ensureConnection();

    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'updated_at': now,
    };

    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;
    if (patientName != null) updates['patient_name'] = patientName;
    if (color != null) updates['color'] = color;
    if (isPinned != null) updates['is_pinned'] = isPinned ? 1 : 0;

    await _database!.update(
      'notes',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );

    final result = await _database!.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    return Note.fromRow(_convertRow(result.first));
  }

  /// Toggle note pinned status
  Future<Note> toggleNotePin(String id) async {
    await _ensureConnection();

    // Get current pin status
    final result = await _database!.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) throw Exception('Note not found');

    final currentPinned = (result.first['is_pinned'] as int?) == 1;
    
    return updateNote(id: id, isPinned: !currentPinned);
  }

  /// Get all notes
  Future<List<Note>> getNotes({
    String? searchQuery,
    bool pinnedFirst = true,
  }) async {
    await _ensureConnection();

    String orderBy = pinnedFirst 
        ? 'is_pinned DESC, updated_at DESC' 
        : 'updated_at DESC';

    List<Map<String, dynamic>> result;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      result = await _database!.query(
        'notes',
        where: 'title LIKE ? OR content LIKE ? OR patient_name LIKE ?',
        whereArgs: ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%'],
        orderBy: orderBy,
      );
    } else {
      result = await _database!.query(
        'notes',
        orderBy: orderBy,
      );
    }

    return result.map((row) => Note.fromRow(_convertRow(row))).toList();
  }

  /// Get a single note by ID
  Future<Note?> getNote(String id) async {
    await _ensureConnection();

    final result = await _database!.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return Note.fromRow(_convertRow(result.first));
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    await _ensureConnection();

    await _database!.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get notes count
  Future<int> getNotesCount() async {
    await _ensureConnection();

    final result = await _database!.rawQuery('SELECT COUNT(*) as count FROM notes');
    return result.first['count'] as int;
  }

  // ==================== END NOTES METHODS ====================

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
