/// Model for a single report section
class ReportSection {
  final String id;
  final String name;
  final String? description;
  final bool isRequired;
  final int order;

  ReportSection({
    required this.id,
    required this.name,
    this.description,
    this.isRequired = false,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'isRequired': isRequired,
    'order': order,
  };

  factory ReportSection.fromJson(Map<String, dynamic> json) => ReportSection(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    isRequired: json['isRequired'] ?? false,
    order: json['order'] ?? 0,
  );

  ReportSection copyWith({
    String? id,
    String? name,
    String? description,
    bool? isRequired,
    int? order,
  }) => ReportSection(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    isRequired: isRequired ?? this.isRequired,
    order: order ?? this.order,
  );
}

/// Pre-defined sections that doctors can choose from
class PredefinedSections {
  static final List<ReportSection> all = [
    ReportSection(id: 'chief_complaint', name: 'Chief Complaint', description: 'Primary reason for visit', order: 1),
    ReportSection(id: 'history', name: 'History of Present Illness', description: 'Detailed history of current condition', order: 2),
    ReportSection(id: 'past_medical', name: 'Past Medical History', description: 'Previous medical conditions and surgeries', order: 3),
    ReportSection(id: 'family_history', name: 'Family History', description: 'Relevant family medical history', order: 4),
    ReportSection(id: 'social_history', name: 'Social History', description: 'Lifestyle, occupation, habits', order: 5),
    ReportSection(id: 'allergies', name: 'Allergies', description: 'Known allergies and reactions', order: 6),
    ReportSection(id: 'current_medications', name: 'Current Medications', description: 'Medications currently being taken', order: 7),
    ReportSection(id: 'vitals', name: 'Vital Signs', description: 'BP, pulse, temperature, etc.', order: 8),
    ReportSection(id: 'physical_exam', name: 'Physical Examination', description: 'Findings from physical exam', order: 9),
    ReportSection(id: 'symptoms', name: 'Symptoms', description: 'Patient reported symptoms', order: 10),
    ReportSection(id: 'diagnosis', name: 'Diagnosis', description: 'Clinical diagnosis', order: 11),
    ReportSection(id: 'differential', name: 'Differential Diagnosis', description: 'Alternative possible diagnoses', order: 12),
    ReportSection(id: 'investigations', name: 'Investigations', description: 'Lab tests, imaging ordered', order: 13),
    ReportSection(id: 'treatment_plan', name: 'Treatment Plan', description: 'Proposed treatment approach', order: 14),
    ReportSection(id: 'prescription', name: 'Prescription', description: 'Medications prescribed', order: 15),
    ReportSection(id: 'advice', name: 'Advice & Instructions', description: 'Patient instructions and lifestyle advice', order: 16),
    ReportSection(id: 'follow_up', name: 'Follow-up', description: 'Next appointment and monitoring plan', order: 17),
    ReportSection(id: 'prognosis', name: 'Prognosis', description: 'Expected outcome', order: 18),
    ReportSection(id: 'notes', name: 'Additional Notes', description: 'Any other relevant information', order: 19),
  ];

  static ReportSection? getById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Model for report templates
class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isBuiltIn;
  final DateTime createdAt;
  final ReportTemplateConfig config;

  ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.icon = 'description',
    this.isBuiltIn = false,
    DateTime? createdAt,
    required this.config,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'isBuiltIn': isBuiltIn,
    'createdAt': createdAt.toIso8601String(),
    'config': config.toJson(),
  };

  factory ReportTemplate.fromJson(Map<String, dynamic> json) => ReportTemplate(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    icon: json['icon'] ?? 'description',
    isBuiltIn: json['isBuiltIn'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    config: ReportTemplateConfig.fromJson(json['config']),
  );

  ReportTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? isBuiltIn,
    DateTime? createdAt,
    ReportTemplateConfig? config,
  }) => ReportTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    icon: icon ?? this.icon,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    createdAt: createdAt ?? this.createdAt,
    config: config ?? this.config,
  );
}

/// Configuration for what sections to include and how to format them
class ReportTemplateConfig {
  final List<ReportSection> sections;
  final String? customInstructions;
  final String format; // 'detailed', 'concise', 'bullet_points'
  final String tone; // 'formal', 'simple', 'technical'

  ReportTemplateConfig({
    required this.sections,
    this.customInstructions,
    this.format = 'detailed',
    this.tone = 'formal',
  });

  Map<String, dynamic> toJson() => {
    'sections': sections.map((s) => s.toJson()).toList(),
    'customInstructions': customInstructions,
    'format': format,
    'tone': tone,
  };

  factory ReportTemplateConfig.fromJson(Map<String, dynamic> json) {
    List<ReportSection> sections = [];
    if (json['sections'] != null) {
      sections = (json['sections'] as List)
          .map((s) => ReportSection.fromJson(s))
          .toList();
    }
    return ReportTemplateConfig(
      sections: sections,
      customInstructions: json['customInstructions'],
      format: json['format'] ?? 'detailed',
      tone: json['tone'] ?? 'formal',
    );
  }

  ReportTemplateConfig copyWith({
    List<ReportSection>? sections,
    String? customInstructions,
    String? format,
    String? tone,
  }) => ReportTemplateConfig(
    sections: sections ?? this.sections,
    customInstructions: customInstructions ?? this.customInstructions,
    format: format ?? this.format,
    tone: tone ?? this.tone,
  );

  /// Generate prompt instructions based on config
  String toPromptInstructions() {
    final sectionNames = sections.map((s) => s.name).toList();

    String formatInstructions = '';
    switch (format) {
      case 'concise':
        formatInstructions = 'Keep the report brief and to the point. Use short sentences.';
        break;
      case 'bullet_points':
        formatInstructions = 'Use bullet points for all sections. Make it easy to scan quickly.';
        break;
      case 'detailed':
      default:
        formatInstructions = 'Provide comprehensive details for each section.';
    }

    String toneInstructions = '';
    switch (tone) {
      case 'simple':
        toneInstructions = 'Use simple, easy-to-understand language. Avoid complex medical jargon.';
        break;
      case 'technical':
        toneInstructions = 'Use precise medical terminology and technical language.';
        break;
      case 'formal':
      default:
        toneInstructions = 'Use professional medical language appropriate for clinical documentation.';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== REPORT TEMPLATE INSTRUCTIONS ===');
    buffer.writeln('Include ONLY these sections in this exact order:');
    for (int i = 0; i < sectionNames.length; i++) {
      buffer.writeln('${i + 1}. ${sectionNames[i]}');
    }
    buffer.writeln('');
    buffer.writeln('Format: $formatInstructions');
    buffer.writeln('Tone: $toneInstructions');
    
    if (customInstructions != null && customInstructions!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Additional Instructions: $customInstructions');
    }
    
    buffer.writeln('=== END TEMPLATE INSTRUCTIONS ===');
    
    return buffer.toString();
  }
}

/// Pre-built templates
class BuiltInTemplates {
  static final List<ReportTemplate> templates = [
    // Standard Consultation - comprehensive
    ReportTemplate(
      id: 'standard',
      name: 'Standard Consultation',
      description: 'Complete consultation notes with essential sections',
      icon: 'description',
      isBuiltIn: true,
      config: ReportTemplateConfig(
        sections: [
          ReportSection(id: 'chief_complaint', name: 'Chief Complaint', order: 1),
          ReportSection(id: 'symptoms', name: 'Symptoms', order: 2),
          ReportSection(id: 'diagnosis', name: 'Diagnosis', order: 3),
          ReportSection(id: 'prescription', name: 'Prescription', order: 4),
          ReportSection(id: 'advice', name: 'Advice & Instructions', order: 5),
          ReportSection(id: 'follow_up', name: 'Follow-up', order: 6),
        ],
        format: 'detailed',
        tone: 'formal',
      ),
    ),

    // Quick Note - minimal
    ReportTemplate(
      id: 'quick_note',
      name: 'Quick Note',
      description: 'Brief summary for quick consultations',
      icon: 'bolt',
      isBuiltIn: true,
      config: ReportTemplateConfig(
        sections: [
          ReportSection(id: 'chief_complaint', name: 'Chief Complaint', order: 1),
          ReportSection(id: 'diagnosis', name: 'Diagnosis', order: 2),
          ReportSection(id: 'prescription', name: 'Prescription', order: 3),
        ],
        format: 'concise',
        tone: 'formal',
      ),
    ),

    // SOAP Note - standard medical format
    ReportTemplate(
      id: 'soap',
      name: 'SOAP Note',
      description: 'Standard Subjective-Objective-Assessment-Plan format',
      icon: 'assignment',
      isBuiltIn: true,
      config: ReportTemplateConfig(
        sections: [
          ReportSection(id: 'subjective', name: 'Subjective', description: 'Patient reported symptoms and history', order: 1),
          ReportSection(id: 'objective', name: 'Objective', description: 'Physical exam and vital signs', order: 2),
          ReportSection(id: 'assessment', name: 'Assessment', description: 'Diagnosis and clinical impression', order: 3),
          ReportSection(id: 'plan', name: 'Plan', description: 'Treatment plan and follow-up', order: 4),
        ],
        format: 'detailed',
        tone: 'formal',
        customInstructions: 'Follow standard SOAP note format strictly. Be thorough in each section.',
      ),
    ),

    // Comprehensive - full workup
    ReportTemplate(
      id: 'comprehensive',
      name: 'Comprehensive Workup',
      description: 'Full medical documentation with all details',
      icon: 'medical_services',
      isBuiltIn: true,
      config: ReportTemplateConfig(
        sections: [
          ReportSection(id: 'chief_complaint', name: 'Chief Complaint', order: 1),
          ReportSection(id: 'history', name: 'History of Present Illness', order: 2),
          ReportSection(id: 'past_medical', name: 'Past Medical History', order: 3),
          ReportSection(id: 'allergies', name: 'Allergies', order: 4),
          ReportSection(id: 'current_medications', name: 'Current Medications', order: 5),
          ReportSection(id: 'vitals', name: 'Vital Signs', order: 6),
          ReportSection(id: 'physical_exam', name: 'Physical Examination', order: 7),
          ReportSection(id: 'diagnosis', name: 'Diagnosis', order: 8),
          ReportSection(id: 'differential', name: 'Differential Diagnosis', order: 9),
          ReportSection(id: 'investigations', name: 'Investigations', order: 10),
          ReportSection(id: 'treatment_plan', name: 'Treatment Plan', order: 11),
          ReportSection(id: 'prescription', name: 'Prescription', order: 12),
          ReportSection(id: 'follow_up', name: 'Follow-up', order: 13),
        ],
        format: 'detailed',
        tone: 'technical',
      ),
    ),

    // Prescription Focus
    ReportTemplate(
      id: 'prescription_focus',
      name: 'Prescription Focus',
      description: 'Emphasizes medications and dosage',
      icon: 'medication',
      isBuiltIn: true,
      config: ReportTemplateConfig(
        sections: [
          ReportSection(id: 'chief_complaint', name: 'Chief Complaint', order: 1),
          ReportSection(id: 'diagnosis', name: 'Diagnosis', order: 2),
          ReportSection(id: 'current_medications', name: 'Current Medications', order: 3),
          ReportSection(id: 'allergies', name: 'Allergies', order: 4),
          ReportSection(id: 'prescription', name: 'Prescription', order: 5),
          ReportSection(id: 'advice', name: 'Advice & Instructions', order: 6),
        ],
        format: 'detailed',
        tone: 'formal',
        customInstructions: 'Focus on prescription details. Include drug interactions warnings if applicable. Provide clear dosage instructions with timing.',
      ),
    ),

    // Follow-up Visit
    ReportTemplate(
      id: 'follow_up',
      name: 'Follow-up Visit',
      description: 'For return visits and progress tracking',
      icon: 'update',
      isBuiltIn: true,
      config: ReportTemplateConfig(
        sections: [
          ReportSection(id: 'chief_complaint', name: 'Reason for Follow-up', order: 1),
          ReportSection(id: 'progress', name: 'Progress Since Last Visit', description: 'Changes in symptoms and condition', order: 2),
          ReportSection(id: 'current_medications', name: 'Current Medications', order: 3),
          ReportSection(id: 'physical_exam', name: 'Physical Examination', order: 4),
          ReportSection(id: 'assessment', name: 'Assessment', order: 5),
          ReportSection(id: 'plan_update', name: 'Updated Treatment Plan', order: 6),
          ReportSection(id: 'follow_up', name: 'Next Follow-up', order: 7),
        ],
        format: 'detailed',
        tone: 'formal',
        customInstructions: 'Compare with previous visit if mentioned. Note any improvements or changes in condition.',
      ),
    ),

    // Patient-Friendly Summary
    ReportTemplate(
      id: 'patient_friendly',
      name: 'Patient Summary',
      description: 'Simple language for patient copies',
      icon: 'people',
      isBuiltIn: true,
      config: ReportTemplateConfig(
        sections: [
          ReportSection(id: 'summary', name: 'What We Found', description: 'Simple explanation of diagnosis', order: 1),
          ReportSection(id: 'medications', name: 'Your Medications', description: 'What to take and when', order: 2),
          ReportSection(id: 'instructions', name: 'What To Do', description: 'Care instructions', order: 3),
          ReportSection(id: 'warning_signs', name: 'When To Call', description: 'Warning signs to watch for', order: 4),
          ReportSection(id: 'next_visit', name: 'Next Visit', order: 5),
        ],
        format: 'bullet_points',
        tone: 'simple',
        customInstructions: 'Use simple, non-medical terms. Explain any medical terms used. Make instructions very clear and actionable.',
      ),
    ),

    // Specialist Referral
    ReportTemplate(
      id: 'referral',
      name: 'Specialist Referral',
      description: 'Detailed notes for specialist referrals',
      icon: 'send',
      isBuiltIn: true,
      config: ReportTemplateConfig(
        sections: [
          ReportSection(id: 'referral_reason', name: 'Reason for Referral', order: 1),
          ReportSection(id: 'chief_complaint', name: 'Chief Complaint', order: 2),
          ReportSection(id: 'history', name: 'History of Present Illness', order: 3),
          ReportSection(id: 'past_medical', name: 'Past Medical History', order: 4),
          ReportSection(id: 'current_medications', name: 'Current Medications', order: 5),
          ReportSection(id: 'allergies', name: 'Allergies', order: 6),
          ReportSection(id: 'investigations', name: 'Investigations Done', order: 7),
          ReportSection(id: 'clinical_findings', name: 'Clinical Findings', order: 8),
          ReportSection(id: 'provisional_diagnosis', name: 'Provisional Diagnosis', order: 9),
          ReportSection(id: 'specific_questions', name: 'Specific Questions for Specialist', order: 10),
        ],
        format: 'detailed',
        tone: 'technical',
        customInstructions: 'Include comprehensive clinical details. Document all relevant findings for specialist review. Be specific about what opinion is sought.',
      ),
    ),
  ];
}
