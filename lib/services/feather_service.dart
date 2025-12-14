import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Featherless AI Service for medical report generation
/// Uses Llama3-Med42-70B model for clinical documentation
class FeatherService {
  static final FeatherService _instance = FeatherService._internal();
  factory FeatherService() => _instance;
  FeatherService._internal();

  static const String _systemPrompt = '''You are an expert medical assistant specialized in generating clinical consultation notes from patient-doctor conversation transcriptions.

Your task is to analyze the transcription and extract structured medical information in a professional clinical format.

Always respond in valid JSON format with the following structure:
{
    "chief_complaint": "Primary reason for the visit in 1-2 sentences",
    "symptoms": "Detailed symptoms as bullet points, including duration, severity, and associated factors",
    "diagnosis": "Clinical assessment/diagnosis based on the presented symptoms",
    "prescription": "Medications with dosage, frequency, and duration as numbered list",
    "additional_notes": "Follow-up instructions, lifestyle modifications, red flags to watch for, and when to return"
}

Clinical Guidelines:
- Use standard medical terminology appropriately
- Be thorough but concise in documentation
- If information is not explicitly mentioned, note "Not documented" rather than assuming
- Include relevant negatives when mentioned (e.g., "no fever", "denies chest pain")
- Format prescriptions clearly: Drug name, strength, route, frequency, duration
- Note any allergies or contraindications mentioned
- Include vital signs if mentioned in the conversation''';

  /// Generate medical report from transcription
  Future<ReportGenerationResult> generateReport({
    required String transcription,
    required String language,
    String? patientName,
  }) async {
    try {
      // Handle empty transcription
      if (transcription.isEmpty || transcription.trim().isEmpty) {
        return ReportGenerationResult.success(
          chiefComplaint: 'Unable to determine - audio was silent or unclear',
          symptoms: 'No symptoms recorded - transcription was empty',
          diagnosis: 'Assessment pending - please re-record consultation with clear audio',
          prescription: 'None prescribed at this time',
          additionalNotes: 'Recommendation: Re-record the consultation ensuring clear audio capture.',
        );
      }

      final userPrompt = '''Analyze the following medical consultation transcription and generate a comprehensive clinical report.

Patient Name: ${patientName ?? 'Not provided'}
Consultation Language: $language

=== TRANSCRIPTION START ===
$transcription
=== TRANSCRIPTION END ===

Generate a detailed medical consultation report in the specified JSON format. Ensure all clinical details from the conversation are captured accurately.''';

      final response = await http.post(
        Uri.parse('${AppConfig.featherApiUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.featherApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConfig.featherModel,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.2,
          'max_tokens': 4096,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '{}';

        try {
          final reportData = jsonDecode(content);
          return ReportGenerationResult.success(
            chiefComplaint: _toString(reportData['chief_complaint'], 'Not documented'),
            symptoms: _toString(reportData['symptoms'], 'Not documented'),
            diagnosis: _toString(reportData['diagnosis'], 'Assessment pending'),
            prescription: _toString(reportData['prescription'], 'None prescribed'),
            additionalNotes: _toString(reportData['additional_notes'], ''),
          );
        } catch (jsonError) {
          // Try to extract fields from malformed response
          print('Non-JSON response, attempting field extraction: ${content.substring(0, 200.clamp(0, content.length))}');
          return ReportGenerationResult.success(
            chiefComplaint: _extractField(content, 'chief_complaint') ?? content.substring(0, 500.clamp(0, content.length)),
            symptoms: _extractField(content, 'symptoms') ?? 'Please review transcription for symptoms',
            diagnosis: _extractField(content, 'diagnosis') ?? 'Assessment pending - please review',
            prescription: _extractField(content, 'prescription') ?? 'Please add prescriptions as needed',
            additionalNotes: _extractField(content, 'additional_notes') ?? 'Auto-generated report may need manual review.',
          );
        }
      } else {
        return ReportGenerationResult.error('Report generation failed (HTTP ${response.statusCode}): ${response.body.substring(0, 200.clamp(0, response.body.length))}');
      }
    } on http.ClientException catch (e) {
      return ReportGenerationResult.error('Network error: $e');
    } catch (e) {
      return ReportGenerationResult.error('Report generation error: $e');
    }
  }

  /// Convert any value to string (handles nested objects)
  String _toString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map) {
      final lines = <String>[];
      value.forEach((k, v) {
        if (v is String) {
          lines.add('- $k: $v');
        } else {
          lines.add('- $k: ${jsonEncode(v)}');
        }
      });
      return lines.isNotEmpty ? lines.join('\n') : defaultValue;
    }
    if (value is List) {
      return value.isNotEmpty ? value.map((item) => '- $item').join('\n') : defaultValue;
    }
    return value.toString();
  }

  /// Extract field from potentially malformed JSON or text
  String? _extractField(String text, String fieldName) {
    // Try JSON-like format
    final jsonPattern = RegExp('"$fieldName"\\s*:\\s*"([^"]*)"', caseSensitive: false);
    final jsonMatch = jsonPattern.firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(1);
    }

    // Try plain text format
    final textPattern = RegExp('$fieldName[:\\s]+([^\\n]+)', caseSensitive: false);
    final textMatch = textPattern.firstMatch(text);
    if (textMatch != null) {
      return textMatch.group(1)?.trim();
    }

    return null;
  }

  /// Regenerate a specific section of the report
  Future<ReportGenerationResult> regenerateSection({
    required String transcription,
    required String section,
    required String currentContent,
    String? feedback,
  }) async {
    try {
      final sectionPrompts = {
        'chief_complaint': 'Provide a concise 1-2 sentence summary of the primary reason for this visit.',
        'symptoms': 'List all symptoms mentioned, including duration, severity, and any associated factors. Use bullet points.',
        'diagnosis': 'Provide a clinical assessment/diagnosis based on the symptoms presented.',
        'prescription': 'List all medications with proper format: Drug name, strength, route, frequency, duration.',
        'additional_notes': 'Include follow-up instructions, lifestyle advice, warning signs, and when to return.',
      };

      final sectionInstruction = sectionPrompts[section] ?? 'Regenerate the $section section.';

      final userPrompt = '''Based on the medical consultation transcription below, regenerate the "$section" section.

Current content that needs improvement:
$currentContent

${feedback != null ? 'Doctor feedback: $feedback' : ''}

=== TRANSCRIPTION ===
$transcription
=== END TRANSCRIPTION ===

Instructions: $sectionInstruction

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
          section: section,
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
  final String? chiefComplaint;
  final String? symptoms;
  final String? diagnosis;
  final String? prescription;
  final String? additionalNotes;
  final String? regeneratedSection;
  final String? regeneratedContent;
  final String? error;

  ReportGenerationResult._({
    required this.success,
    this.chiefComplaint,
    this.symptoms,
    this.diagnosis,
    this.prescription,
    this.additionalNotes,
    this.regeneratedSection,
    this.regeneratedContent,
    this.error,
  });

  factory ReportGenerationResult.success({
    required String chiefComplaint,
    required String symptoms,
    required String diagnosis,
    required String prescription,
    required String additionalNotes,
  }) {
    return ReportGenerationResult._(
      success: true,
      chiefComplaint: chiefComplaint,
      symptoms: symptoms,
      diagnosis: diagnosis,
      prescription: prescription,
      additionalNotes: additionalNotes,
    );
  }

  factory ReportGenerationResult.sectionRegenerated({
    required String section,
    required String content,
  }) {
    return ReportGenerationResult._(
      success: true,
      regeneratedSection: section,
      regeneratedContent: content,
    );
  }

  factory ReportGenerationResult.error(String error) {
    return ReportGenerationResult._(
      success: false,
      error: error,
    );
  }
}

