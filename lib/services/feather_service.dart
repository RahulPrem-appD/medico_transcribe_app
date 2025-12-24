import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/report_template.dart';

/// Featherless AI Service for medical report generation
/// Uses Llama3-Med42-70B model for clinical documentation
class FeatherService {
  static final FeatherService _instance = FeatherService._internal();
  factory FeatherService() => _instance;
  FeatherService._internal();

  /// Standard patient details that should always be extracted
  static const String _patientDetailsInstruction = '''
IMPORTANT - ALWAYS EXTRACT PATIENT DETAILS:
Before the medical content, always try to extract these patient details from the conversation if mentioned:
- "patient_name": Patient's full name if mentioned
- "age": Patient's age (just the number, e.g., "45" or "45 years")
- "gender": Patient's gender (Male/Female/Other)
- "blood_group": Blood group if mentioned (e.g., "A+", "O-", "B+")
- "weight": Weight in kg if mentioned (just the number)
- "height": Height in cm if mentioned (just the number)
- "phone": Contact number if mentioned

If any of these are not mentioned in the conversation, simply omit that field from the response.
''';

  /// Generate system prompt based on template configuration
  String _buildSystemPrompt(ReportTemplateConfig? templateConfig) {
    if (templateConfig == null || templateConfig.sections.isEmpty) {
      // Default system prompt for backward compatibility
      return '''You are an expert medical assistant specialized in generating clinical consultation notes from patient-doctor conversation transcriptions.

Your task is to analyze the transcription and extract structured medical information in a professional clinical format.

$_patientDetailsInstruction

CRITICAL RESPONSE FORMAT - MUST FOLLOW EXACTLY:
1. Return ONLY a valid JSON object - NO markdown, NO code fences (```json), NO explanatory text
2. Each key MUST match exactly the keys shown in the example
3. Each value MUST be a simple STRING (not nested objects or arrays)
4. Use plain text with line breaks (\\n) for lists, NOT JSON arrays
5. For multiple items, use bullet points: "• Item 1\\n• Item 2\\n• Item 3"
6. Start response with { and end with }

Respond with this JSON structure (include patient details if found, plus these medical sections):
{
    "patient_name": "Name if mentioned",
    "age": "Age if mentioned",
    "gender": "Gender if mentioned",
    "patient_summary": "Brief summary in passive voice (e.g., Patient was diagnosed with... Patient was advised to...)",
    "chief_complaint": "Primary reason for the visit in 1-2 sentences",
    "symptoms": "• Symptom 1 with details\\n• Symptom 2 with details",
    "diagnosis": "Clinical assessment/diagnosis based on the presented symptoms",
    "prescription": "• Medication 1: dosage, frequency, duration\\n• Medication 2: dosage, frequency, duration",
    "additional_notes": "• Follow-up instructions\\n• Lifestyle modifications\\n• Red flags to watch for"
}

Clinical Guidelines:
- Use standard medical terminology appropriately
- Be thorough but concise in documentation
- If information is not explicitly mentioned, note "Not documented" rather than assuming
- Include relevant negatives when mentioned (e.g., "no fever", "denies chest pain")
- Format prescriptions clearly: Drug name, strength, route, frequency, duration
- Note any allergies or contraindications mentioned
- Include vital signs if mentioned in the conversation

PRIORITY DIRECTIVE:
- If additional instructions are provided by the doctor in the user prompt, follow them EXACTLY
- Doctor's instructions override default guidelines when there's a conflict
- Ensure all requested modifications, additions, or changes are incorporated''';
    }

    // Build dynamic JSON structure from sections
    final jsonStructure = <String, String>{};
    for (final section in templateConfig.sections) {
      final key = _sectionToKey(section.name);
      jsonStructure[key] = _getSectionDescription(section);
    }

    // Format instructions
    String formatInstructions = '';
    switch (templateConfig.format) {
      case 'concise':
        formatInstructions = 'Keep responses brief and to the point. Use short sentences.';
        break;
      case 'bullet_points':
        formatInstructions = 'Use bullet points for all content. Make it easy to scan quickly.';
        break;
      case 'detailed':
      default:
        formatInstructions = 'Provide comprehensive details for each section.';
    }

    // Tone instructions
    String toneInstructions = '';
    switch (templateConfig.tone) {
      case 'simple':
        toneInstructions = 'Use simple, easy-to-understand language. Avoid complex medical jargon. Explain terms when necessary.';
        break;
      case 'technical':
        toneInstructions = 'Use precise medical terminology and technical language appropriate for clinical documentation.';
        break;
      case 'formal':
      default:
        toneInstructions = 'Use professional medical language appropriate for clinical documentation.';
    }

    final jsonExample = jsonEncode(jsonStructure);

    return '''You are an expert medical assistant specialized in generating clinical consultation notes from patient-doctor conversation transcriptions.

Your task is to analyze the transcription and extract structured medical information based on the requested sections.

$_patientDetailsInstruction

CRITICAL RESPONSE FORMAT - MUST FOLLOW EXACTLY:
1. Return ONLY a valid JSON object - NO markdown, NO code fences (```json), NO explanatory text
2. Include patient details (patient_name, age, gender, blood_group, weight, height, phone) if mentioned
3. Include ALL these medical sections: $jsonExample
4. Each key MUST match exactly the keys shown
5. Each value MUST be a simple STRING (not nested objects or arrays)
6. Use plain text with line breaks (\\n) for lists, NOT JSON arrays
7. For multiple items, use bullet points: "• Item 1\\n• Item 2\\n• Item 3"
8. Start response with { and end with }
9. If information not found, use "Not documented" for that field

FORMAT STYLE: $formatInstructions
LANGUAGE TONE: $toneInstructions

EXAMPLE OUTPUT FORMAT:
{
  "patient_name": "John Smith",
  "age": "45",
  "gender": "Male",
  "chief_complaint": "Patient presents with headache and fever for 3 days",
  "symptoms": "• Headache - throbbing, frontal\\n• Fever - 101°F\\n• Fatigue",
  "diagnosis": "Viral upper respiratory infection",
  "prescription": "• Paracetamol 500mg - 1 tablet every 6 hours for fever\\n• Rest and hydration advised"
}

Clinical Guidelines:
- Use standard medical terminology appropriately based on the tone specified
- Be thorough but concise in documentation
- If information is not explicitly mentioned in the transcription, note "Not documented" rather than assuming
- Include relevant negatives when mentioned (e.g., "no fever", "denies chest pain")
- Format prescriptions clearly when applicable: Drug name, strength, route, frequency, duration
- Note any allergies or contraindications mentioned
- Include vital signs if mentioned in the conversation
- Include patient details AND the requested medical sections

PRIORITY DIRECTIVE:
- If additional instructions are provided by the doctor in the user prompt, follow them EXACTLY
- Doctor's instructions override default guidelines when there's a conflict
- Ensure all requested modifications, additions, or changes are incorporated
- Pay special attention to any instructions marked as CRITICAL or with ⚠️  symbols''';
  }

  /// Convert section name to a valid JSON key
  String _sectionToKey(String sectionName) {
    return sectionName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Get description for a section to use in JSON structure
  String _getSectionDescription(ReportSection section) {
    // Map common section names to descriptions
    final descriptions = {
      'patient_summary': 'Brief summary of the diagnosis and advice in passive voice (e.g., "Patient was diagnosed with... Patient was advised to...")',
      'chief_complaint': 'Primary reason for the visit in 1-2 sentences',
      'history': 'Detailed history of the present illness',
      'history_of_present_illness': 'Detailed history of the present illness',
      'past_medical': 'Previous medical conditions, surgeries, hospitalizations',
      'past_medical_history': 'Previous medical conditions, surgeries, hospitalizations',
      'family_history': 'Relevant family medical history',
      'social_history': 'Lifestyle, occupation, habits',
      'allergies': 'Known allergies and reactions',
      'current_medications': 'List of current medications with dosages',
      'vitals': 'Vital signs: BP, pulse, temperature, etc.',
      'vital_signs': 'Vital signs: BP, pulse, temperature, etc.',
      'physical_exam': 'Findings from physical examination',
      'physical_examination': 'Findings from physical examination',
      'symptoms': 'Patient reported symptoms with duration and severity',
      'diagnosis': 'Clinical diagnosis based on findings',
      'differential': 'Alternative possible diagnoses to consider',
      'differential_diagnosis': 'Alternative possible diagnoses to consider',
      'investigations': 'Lab tests, imaging, and other investigations ordered',
      'treatment_plan': 'Proposed treatment approach',
      'prescription': 'Medications: Drug, strength, route, frequency, duration',
      'advice': 'Patient instructions and lifestyle advice',
      'advice_instructions': 'Patient instructions and lifestyle advice',
      'follow_up': 'Next appointment and monitoring plan',
      'prognosis': 'Expected outcome and recovery timeline',
      'notes': 'Additional relevant information',
      'additional_notes': 'Additional relevant information',
      'subjective': 'Patient reported symptoms and concerns (SOAP)',
      'objective': 'Physical exam findings and vital signs (SOAP)',
      'assessment': 'Clinical assessment and diagnosis (SOAP)',
      'plan': 'Treatment plan and follow-up (SOAP)',
      'referral_reason': 'Reason for specialist referral',
      'reason_for_follow_up': 'Reason for this follow-up visit',
      'progress': 'Progress since last visit',
      'progress_since_last_visit': 'Changes in symptoms and condition since last visit',
      'plan_update': 'Updates to the treatment plan',
      'updated_treatment_plan': 'Updates to the treatment plan',
      'summary': 'Summary of findings in simple terms',
      'what_we_found': 'Summary of findings in simple terms',
      'medications': 'Medications to take and when',
      'your_medications': 'Medications to take and when',
      'instructions': 'Care instructions for the patient',
      'what_to_do': 'Care instructions for the patient',
      'warning_signs': 'Warning signs to watch for',
      'when_to_call': 'Warning signs that require immediate attention',
      'next_visit': 'When to come back for follow-up',
      'clinical_findings': 'Clinical examination findings',
      'provisional_diagnosis': 'Provisional diagnosis for referral',
      'specific_questions': 'Specific questions for the specialist',
      'specific_questions_for_specialist': 'Specific questions for the specialist',
    };

    final key = _sectionToKey(section.name);
    return descriptions[key] ?? section.description ?? 'Content for ${section.name}';
  }

  /// Generate medical report from transcription
  Future<ReportGenerationResult> generateReport({
    required String transcription,
    required String language,
    String? patientName,
    String? additionalInstructions,
    ReportTemplateConfig? templateConfig,
  }) async {
    try {
      // Handle empty transcription
      if (transcription.isEmpty || transcription.trim().isEmpty) {
        final defaultSections = <String, String>{
          'chief_complaint': 'Unable to determine - audio was silent or unclear',
          'symptoms': 'No symptoms recorded - transcription was empty',
          'diagnosis': 'Assessment pending - please re-record consultation with clear audio',
          'prescription': 'None prescribed at this time',
          'additional_notes': 'Recommendation: Re-record the consultation ensuring clear audio capture.',
        };
        return ReportGenerationResult.successWithSections(sections: defaultSections);
      }

      // Build system prompt based on template
      final systemPrompt = _buildSystemPrompt(templateConfig);

      // Build user prompt with optional additional instructions
      String instructionsSection = '';
      String instructionEmphasis = '';
      
      if (additionalInstructions != null && additionalInstructions.isNotEmpty) {
        instructionsSection = '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  CRITICAL: DOCTOR'S ADDITIONAL INSTRUCTIONS (MUST FOLLOW):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$additionalInstructions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        instructionEmphasis = '''

IMPORTANT: The doctor has provided specific instructions above. You MUST:
1. Follow these instructions precisely when generating the report
2. Incorporate all requested changes, additions, or modifications
3. Maintain consistency with the transcription while applying the instructions
4. If instructions conflict with transcription, follow the doctor's instructions
''';
      }

      if (templateConfig?.customInstructions != null && 
          templateConfig!.customInstructions!.isNotEmpty) {
        instructionsSection += '''

=== TEMPLATE CUSTOM INSTRUCTIONS ===
${templateConfig.customInstructions}
=== END TEMPLATE INSTRUCTIONS ===
''';
      }

      final userPrompt = '''Analyze the following medical consultation transcription and generate a comprehensive clinical report.

Patient Name: ${patientName ?? 'Not provided'}
Consultation Language: $language

=== TRANSCRIPTION START ===
$transcription
=== TRANSCRIPTION END ===$instructionsSection$instructionEmphasis

Generate a detailed medical consultation report in the specified JSON format. Ensure all clinical details from the conversation are captured accurately.''';

      // First attempt
      final first = await _callFeather(systemPrompt, userPrompt);
      final validation = _validateAndExtractSections(
        first,
        templateConfig: templateConfig,
      );

      if (validation.$1) {
        return ReportGenerationResult.successWithSections(sections: validation.$2);
      }

      // Retry once with explicit error instructions if validation failed
      print('⚠️ First attempt failed validation: ${validation.$3}');
      print('Retrying with stricter instructions...');
      
      final retrySystemPrompt = '''$systemPrompt

CRITICAL: Your previous response was INVALID. Error: ${validation.$3}

YOU MUST:
1. Return ONLY a JSON object starting with { and ending with }
2. NO code fences (```), NO markdown, NO explanatory text
3. Include ALL required keys from the template
4. Every value must be a simple string (use \\n for line breaks in lists)
5. Use "Not documented" for any field you cannot determine from the transcription''';

      final second = await _callFeather(
        retrySystemPrompt,
        userPrompt,
      );
      final retryValidation = _validateAndExtractSections(
        second,
        templateConfig: templateConfig,
      );

      if (retryValidation.$1) {
        return ReportGenerationResult.successWithSections(sections: retryValidation.$2);
      }

      // If still invalid, return raw for display to avoid full failure
      return ReportGenerationResult.successWithSections(
        sections: {'report': second},
      );
    } on http.ClientException catch (e) {
      return ReportGenerationResult.error('Network error: $e');
    } catch (e) {
      return ReportGenerationResult.error('Report generation error: $e');
    }
  }

  /// Wrapper to call Feather API
  Future<String> _callFeather(String systemPrompt, String userPrompt) async {
    final response = await http.post(
      Uri.parse('${AppConfig.featherApiUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AppConfig.featherApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConfig.featherModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.2,
        'max_tokens': 4096,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Report generation failed (HTTP ${response.statusCode}): ${response.body.substring(0, 200.clamp(0, response.body.length))}',
      );
    }

    final data = jsonDecode(response.body);
    return data['choices']?[0]?['message']?['content']?.toString() ?? '{}';
  }

  /// Validate JSON content and extract sections; returns (isValid, sections, error)
  (bool, Map<String, String>, String?) _validateAndExtractSections(
    String content, {
    ReportTemplateConfig? templateConfig,
  }) {
    try {
      // Clean the content first - remove code fences, extra whitespace
      String cleaned = content.trim();
      
      // Remove markdown code fences if present
      if (cleaned.startsWith('```')) {
        // Remove ```json or ``` at start
        cleaned = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*\n?'), '');
        // Remove ``` at end
        cleaned = cleaned.replaceFirst(RegExp(r'\n?```\s*$'), '');
        cleaned = cleaned.trim();
      }
      
      // Find JSON object boundaries if there's extra text
      final jsonMatch = RegExp(r'\{[\s\S]*\}', multiLine: true).firstMatch(cleaned);
      if (jsonMatch != null) {
        cleaned = jsonMatch.group(0)!;
      }

      // Try to decode
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map<String, dynamic>) {
        return (false, {}, 'Response is not a JSON object');
      }

      final sections = <String, String>{};
      decoded.forEach((key, value) {
        sections[key] = _toString(value, 'Not documented');
      });

      // Validate sections is not empty
      if (sections.isEmpty) {
        return (false, {}, 'No sections found in JSON');
      }

      // If a template is present, ensure expected keys exist
      if (templateConfig?.sections != null && templateConfig!.sections.isNotEmpty) {
        final missing = <String>[];
        for (final section in templateConfig.sections) {
          final key = _sectionToKey(section.name);
          if (!sections.containsKey(key) || sections[key] == 'Not documented') {
            missing.add(key);
          }
        }
        if (missing.isNotEmpty) {
          return (false, sections, 'Missing or empty required keys: ${missing.join(', ')}');
        }
      }

      print('✓ Validation passed: ${sections.length} sections extracted');
      return (true, sections, null);
    } catch (e) {
      print('✗ Validation failed: $e');
      return (false, {}, 'JSON parse error: $e');
    }
  }

  /// Convert any value to string (handles nested objects)
  String _toString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) {
      // Clean up any JSON artifacts or escape sequences
      String cleaned = value
          .replaceAll('\\n', '\n')
          .replaceAll('\\"', '"')
          .trim();
      return cleaned.isNotEmpty ? cleaned : defaultValue;
    }
    if (value is Map) {
      final lines = <String>[];
      value.forEach((k, v) {
        final formattedKey = _formatKey(k.toString());
        if (v is String) {
          lines.add('• $formattedKey: $v');
        } else if (v is List) {
          lines.add('• $formattedKey:');
          for (var item in v) {
            lines.add('  - ${item.toString()}');
          }
        } else if (v is Map) {
          lines.add('• $formattedKey:');
          v.forEach((subK, subV) {
            lines.add('  - ${_formatKey(subK.toString())}: $subV');
          });
        } else {
          lines.add('• $formattedKey: ${v.toString()}');
        }
      });
      return lines.isNotEmpty ? lines.join('\n') : defaultValue;
    }
    if (value is List) {
      if (value.isEmpty) return defaultValue;
      final lines = <String>[];
      for (var item in value) {
        if (item is String) {
          lines.add('• $item');
        } else if (item is Map) {
          // Format map items nicely
          final parts = <String>[];
          item.forEach((k, v) {
            parts.add('${_formatKey(k.toString())}: $v');
          });
          lines.add('• ${parts.join(', ')}');
        } else {
          lines.add('• ${item.toString()}');
        }
      }
      return lines.join('\n');
    }
    return value.toString();
  }

  /// Format a key to be more readable
  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' 
            : '')
        .join(' ');
  }

  /// Regenerate a specific section of the report
  Future<ReportGenerationResult> regenerateSection({
    required String transcription,
    required String sectionName,
    required String currentContent,
    String? feedback,
    ReportTemplateConfig? templateConfig,
  }) async {
    try {
      // Get tone from template config
      String toneInstruction = 'Use professional medical language.';
      if (templateConfig != null) {
        switch (templateConfig.tone) {
          case 'simple':
            toneInstruction = 'Use simple, easy-to-understand language.';
            break;
          case 'technical':
            toneInstruction = 'Use precise medical terminology.';
            break;
        }
      }

      final userPrompt = '''Based on the medical consultation transcription below, regenerate the "$sectionName" section.

Current content that needs improvement:
$currentContent

${feedback != null ? 'Doctor feedback: $feedback' : ''}

=== TRANSCRIPTION ===
$transcription
=== END TRANSCRIPTION ===

Instructions: Regenerate the "$sectionName" section. $toneInstruction

Provide only the content for this section, no JSON formatting needed.''';

      final response = await http.post(
        Uri.parse('${AppConfig.featherApiUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.featherApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConfig.featherModel,
          'messages': [
            {'role': 'system', 'content': 'You are an expert medical documentation assistant. Provide accurate, professional clinical documentation.'},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.2,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        
        // Return with the regenerated section
        return ReportGenerationResult.sectionRegenerated(
          sectionKey: _sectionToKey(sectionName),
          content: content.trim(),
        );
      } else {
        return ReportGenerationResult.error('Section regeneration failed: ${response.body.substring(0, 200.clamp(0, response.body.length))}');
      }
    } catch (e) {
      return ReportGenerationResult.error('Regeneration error: $e');
    }
  }
}

/// Result of report generation operation
class ReportGenerationResult {
  final bool success;
  final Map<String, String>? sections;
  final String? regeneratedSectionKey;
  final String? regeneratedContent;
  final String? error;

  ReportGenerationResult._({
    required this.success,
    this.sections,
    this.regeneratedSectionKey,
    this.regeneratedContent,
    this.error,
  });

  /// Create success result with dynamic sections
  factory ReportGenerationResult.successWithSections({
    required Map<String, String> sections,
  }) {
    return ReportGenerationResult._(
      success: true,
      sections: sections,
    );
  }

  /// Legacy success constructor for backward compatibility
  factory ReportGenerationResult.success({
    required String chiefComplaint,
    required String symptoms,
    required String diagnosis,
    required String prescription,
    required String additionalNotes,
  }) {
    return ReportGenerationResult._(
      success: true,
      sections: {
        'chief_complaint': chiefComplaint,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'prescription': prescription,
        'additional_notes': additionalNotes,
      },
    );
  }

  factory ReportGenerationResult.sectionRegenerated({
    required String sectionKey,
    required String content,
  }) {
    return ReportGenerationResult._(
      success: true,
      regeneratedSectionKey: sectionKey,
      regeneratedContent: content,
    );
  }

  factory ReportGenerationResult.error(String error) {
    return ReportGenerationResult._(
      success: false,
      error: error,
    );
  }

  // Legacy getters for backward compatibility
  String? get chiefComplaint => sections?['chief_complaint'];
  String? get symptoms => sections?['symptoms'];
  String? get diagnosis => sections?['diagnosis'];
  String? get prescription => sections?['prescription'];
  String? get additionalNotes => sections?['additional_notes'];
  
  // Legacy getter names
  String? get regeneratedSection => regeneratedSectionKey;
}
