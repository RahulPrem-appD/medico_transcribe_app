class Report {
  final String id;
  final String consultationId;
  final String chiefComplaint;
  final String symptoms;
  final String diagnosis;
  final String prescription;
  final String additionalNotes;
  final String generatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.consultationId,
    required this.chiefComplaint,
    required this.symptoms,
    required this.diagnosis,
    required this.prescription,
    required this.additionalNotes,
    this.generatedBy = 'feather_ai',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromRow(Map<String, dynamic> row) {
    return Report(
      id: row['id'].toString(),
      consultationId: row['consultation_id'].toString(),
      chiefComplaint: row['chief_complaint'] ?? '',
      symptoms: row['symptoms'] ?? '',
      diagnosis: row['diagnosis'] ?? '',
      prescription: row['prescription'] ?? '',
      additionalNotes: row['additional_notes'] ?? '',
      generatedBy: row['generated_by'] ?? 'feather_ai',
      createdAt: row['created_at'] ?? DateTime.now(),
      updatedAt: row['updated_at'] ?? DateTime.now(),
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      consultationId: json['consultation_id'] ?? '',
      chiefComplaint: json['chief_complaint'] ?? '',
      symptoms: json['symptoms'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      prescription: json['prescription'] ?? '',
      additionalNotes: json['additional_notes'] ?? '',
      generatedBy: json['generated_by'] ?? 'feather_ai',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consultation_id': consultationId,
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
}

