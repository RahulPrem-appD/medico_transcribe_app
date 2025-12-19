import 'dart:convert';

class Report {
  final String id;
  final String consultationId;
  final Map<String, String> sections;
  final String generatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.consultationId,
    required this.sections,
    this.generatedBy = 'feather_ai',
    required this.createdAt,
    required this.updatedAt,
  });

  // Legacy getters for backward compatibility
  String get chiefComplaint => sections['chief_complaint'] ?? '';
  String get symptoms => sections['symptoms'] ?? '';
  String get diagnosis => sections['diagnosis'] ?? '';
  String get prescription => sections['prescription'] ?? '';
  String get additionalNotes => sections['additional_notes'] ?? sections['notes'] ?? '';

  factory Report.fromRow(Map<String, dynamic> row) {
    // Parse sections from JSON string or build from legacy columns
    Map<String, String> sections = {};
    
    if (row['sections'] != null) {
      try {
        final sectionsData = row['sections'] is String 
            ? jsonDecode(row['sections']) 
            : row['sections'];
        if (sectionsData is Map) {
          sectionsData.forEach((key, value) {
            sections[key.toString()] = value?.toString() ?? '';
          });
        }
      } catch (e) {
        print('Error parsing sections: $e');
      }
    }
    
    // Fall back to legacy columns if sections is empty
    if (sections.isEmpty) {
      if (row['chief_complaint'] != null) sections['chief_complaint'] = row['chief_complaint'];
      if (row['symptoms'] != null) sections['symptoms'] = row['symptoms'];
      if (row['diagnosis'] != null) sections['diagnosis'] = row['diagnosis'];
      if (row['prescription'] != null) sections['prescription'] = row['prescription'];
      if (row['additional_notes'] != null) sections['additional_notes'] = row['additional_notes'];
    }

    return Report(
      id: row['id'].toString(),
      consultationId: row['consultation_id'].toString(),
      sections: sections,
      generatedBy: row['generated_by'] ?? 'feather_ai',
      createdAt: row['created_at'] ?? DateTime.now(),
      updatedAt: row['updated_at'] ?? DateTime.now(),
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    Map<String, String> sections = {};
    
    if (json['sections'] != null) {
      final sectionsData = json['sections'];
      if (sectionsData is Map) {
        sectionsData.forEach((key, value) {
          sections[key.toString()] = value?.toString() ?? '';
        });
      }
    }
    
    // Fall back to legacy fields if sections is empty
    if (sections.isEmpty) {
      if (json['chief_complaint'] != null) sections['chief_complaint'] = json['chief_complaint'];
      if (json['symptoms'] != null) sections['symptoms'] = json['symptoms'];
      if (json['diagnosis'] != null) sections['diagnosis'] = json['diagnosis'];
      if (json['prescription'] != null) sections['prescription'] = json['prescription'];
      if (json['additional_notes'] != null) sections['additional_notes'] = json['additional_notes'];
    }

    return Report(
      id: json['id'] ?? '',
      consultationId: json['consultation_id'] ?? '',
      sections: sections,
      generatedBy: json['generated_by'] ?? 'feather_ai',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  /// Create a Report from dynamic sections map
  factory Report.fromSections({
    required String id,
    required String consultationId,
    required Map<String, String> sections,
    String generatedBy = 'feather_ai',
  }) {
    return Report(
      id: id,
      consultationId: consultationId,
      sections: sections,
      generatedBy: generatedBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consultation_id': consultationId,
      'sections': sections,
      // Also include legacy fields for backward compatibility
      'chief_complaint': chiefComplaint,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'additional_notes': additionalNotes,
      'generated_by': generatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get a section by key with a formatted display name
  String? getSection(String key) => sections[key];

  /// Get all section keys in order
  List<String> get sectionKeys => sections.keys.toList();

  /// Convert a section key to a display name
  static String keyToDisplayName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
  }

  Report copyWith({
    String? id,
    String? consultationId,
    Map<String, String>? sections,
    String? generatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      consultationId: consultationId ?? this.consultationId,
      sections: sections ?? Map.from(this.sections),
      generatedBy: generatedBy ?? this.generatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
