import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/consultation.dart';
import '../models/report.dart';
import '../providers/consultation_provider.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Consultation consultation;

  const ResultsScreen({
    super.key,
    required this.consultation,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Consultation _consultation;
  bool _isRegenerating = false;
  Map<String, String> _editedSections = {};
  bool _hasUnsavedChanges = false;

  // Patient details - standard fields always shown
  late TextEditingController _patientNameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _phoneController;

  // Color palette for sections - vibrant colors for visual distinction
  final List<Color> _sectionColors = [
    const Color(0xFF5DB5FF), // Sky Blue
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFFE85D5D), // Coral Red
    const Color(0xFF9B59B6), // Purple
    const Color(0xFFFFB74D), // Amber
    const Color(0xFF26C6DA), // Cyan
    const Color(0xFF66BB6A), // Green
    const Color(0xFFFF7043), // Deep Orange
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFFEC407A), // Pink
  ];

  // Icon mapping for common sections
  final Map<String, IconData> _sectionIcons = {
    'patient_summary': Icons.person_rounded,
    'chief_complaint': Icons.report_problem_rounded,
    'reason_for_follow_up': Icons.report_problem_rounded,
    'symptoms': Icons.medical_information_rounded,
    'diagnosis': Icons.health_and_safety_rounded,
    'assessment': Icons.health_and_safety_rounded,
    'prescription': Icons.medication_rounded,
    'your_medications': Icons.medication_rounded,
    'medications': Icons.medication_rounded,
    'additional_notes': Icons.note_alt_rounded,
    'notes': Icons.note_alt_rounded,
    'history': Icons.history_rounded,
    'history_of_present_illness': Icons.history_rounded,
    'past_medical': Icons.folder_shared_rounded,
    'past_medical_history': Icons.folder_shared_rounded,
    'family_history': Icons.family_restroom_rounded,
    'social_history': Icons.people_rounded,
    'allergies': Icons.warning_rounded,
    'current_medications': Icons.medication_liquid_rounded,
    'vitals': Icons.monitor_heart_rounded,
    'vital_signs': Icons.monitor_heart_rounded,
    'physical_exam': Icons.person_search_rounded,
    'physical_examination': Icons.person_search_rounded,
    'differential': Icons.compare_arrows_rounded,
    'differential_diagnosis': Icons.compare_arrows_rounded,
    'investigations': Icons.science_rounded,
    'treatment_plan': Icons.healing_rounded,
    'plan': Icons.healing_rounded,
    'advice': Icons.tips_and_updates_rounded,
    'advice_instructions': Icons.tips_and_updates_rounded,
    'instructions': Icons.tips_and_updates_rounded,
    'what_to_do': Icons.tips_and_updates_rounded,
    'follow_up': Icons.event_rounded,
    'next_visit': Icons.event_rounded,
    'prognosis': Icons.trending_up_rounded,
    'subjective': Icons.record_voice_over_rounded,
    'objective': Icons.visibility_rounded,
    'summary': Icons.summarize_rounded,
    'what_we_found': Icons.summarize_rounded,
    'warning_signs': Icons.warning_amber_rounded,
    'when_to_call': Icons.warning_amber_rounded,
    'referral_reason': Icons.send_rounded,
    'progress': Icons.trending_up_rounded,
    'progress_since_last_visit': Icons.trending_up_rounded,
    'plan_update': Icons.update_rounded,
    'updated_treatment_plan': Icons.update_rounded,
    'clinical_findings': Icons.find_in_page_rounded,
    'provisional_diagnosis': Icons.pending_actions_rounded,
    'specific_questions': Icons.help_outline_rounded,
    'specific_questions_for_specialist': Icons.help_outline_rounded,
  };

  // Patient detail keys to exclude from dynamic sections (shown in patient details card)
  final Set<String> _patientDetailKeys = {
    'patient_name',
    'name',
    'age',
    'patient_age',
    'gender',
    'sex',
    'blood_group',
    'blood_type',
    'weight',
    'height',
    'phone',
    'phone_number',
    'contact',
    'patient_id',
  };

  @override
  void initState() {
    super.initState();
    _consultation = widget.consultation;
    // Initialize edited sections with current values
    if (_consultation.report != null) {
      _editedSections = Map.from(_consultation.report!.sections);
      _normalizeReportSections();
    }
    
    // Initialize patient detail controllers
    // Try to extract from report sections or use defaults
    _patientNameController = TextEditingController(
      text: _consultation.patientName ?? _editedSections['patient_name'] ?? '',
    );
    _ageController = TextEditingController(
      text: _editedSections['age'] ?? _editedSections['patient_age'] ?? '',
    );
    _genderController = TextEditingController(
      text: _editedSections['gender'] ?? _editedSections['sex'] ?? '',
    );
    _bloodGroupController = TextEditingController(
      text: _editedSections['blood_group'] ?? _editedSections['blood_type'] ?? '',
    );
    _weightController = TextEditingController(
      text: _editedSections['weight'] ?? '',
    );
    _heightController = TextEditingController(
      text: _editedSections['height'] ?? '',
    );
    _phoneController = TextEditingController(
      text: _editedSections['phone'] ?? _editedSections['contact'] ?? '',
    );
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _bloodGroupController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Color _getSectionColor(int index) {
    return _sectionColors[index % _sectionColors.length];
  }

  IconData _getSectionIcon(String key) {
    return _sectionIcons[key] ?? Icons.article_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.softSkyBg,
              AppTheme.paleBlue.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isRegenerating ? _buildRegeneratingView() : _buildResultsView(),
        ),
      ),
    );
  }

  Widget _buildRegeneratingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primarySkyBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primarySkyBlue),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Regenerating report...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is analyzing the transcription',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final report = _consultation.report;

    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Success header
                _buildSuccessHeader(),
                const SizedBox(height: 24),
                // Editable patient details card
                _buildPatientDetailsCard(),
                const SizedBox(height: 16),
                // Consultation info card (non-editable)
                _buildConsultationInfoCard(),
                const SizedBox(height: 16),
                // Dynamic report sections (excluding patient details already shown above)
                if (report != null) ...[
                  ...report.sectionKeys.asMap().entries
                      .where((entry) => !_patientDetailKeys.contains(entry.value))
                      .map((entry) {
                    final index = entry.key;
                    final key = entry.value;
                    // Use edited content if available, otherwise original
                    final content = _editedSections[key] ?? report.sections[key] ?? '';
                    final displayName = Report.keyToDisplayName(key);
                    final color = _getSectionColor(index);
                    final icon = _getSectionIcon(key);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildSectionCard(
                        key,
                        displayName,
                        icon,
                        content,
                        color,
                      ),
                    );
                  }),
                ] else
                  _buildNoReportCard(),
                const SizedBox(height: 16),
                // Transcription (collapsible) - moved to bottom
                if (_consultation.transcription != null)
                  _buildCollapsibleCard(
                    'Transcription',
                    Icons.record_voice_over_rounded,
                    _consultation.transcription!,
                    AppTheme.mediumGray,
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateHome(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppTheme.darkSlate,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Consultation Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  if (_hasUnsavedChanges)
                    Text(
                      'Unsaved changes',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.warningAmber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Share feature coming soon!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppTheme.primarySkyBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.share_rounded,
                color: AppTheme.primarySkyBlue,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    final sectionCount = _consultation.report?.sections.length ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primarySkyBlue, AppTheme.deepSkyBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes Generated Successfully',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sectionCount > 0 
                      ? '$sectionCount sections generated'
                      : 'Review the consultation notes below',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Editable patient details card - always shown
  Widget _buildPatientDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primarySkyBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.person_rounded, color: AppTheme.primarySkyBlue, size: 20),
              const SizedBox(width: 10),
              Text(
                'Patient Details',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Editable',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.successGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Patient details grid
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildPatientField(
                  'Name',
                  _patientNameController,
                  Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPatientField(
                  'Age',
                  _ageController,
                  Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPatientField(
                  'Gender',
                  _genderController,
                  Icons.wc_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPatientField(
                  'Blood Group',
                  _bloodGroupController,
                  Icons.bloodtype_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPatientField(
                  'Weight (kg)',
                  _weightController,
                  Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPatientField(
                  'Height (cm)',
                  _heightController,
                  Icons.height_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPatientField(
            'Phone',
            _phoneController,
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  /// Build individual patient detail field
  Widget _buildPatientField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (_) {
              if (!_hasUnsavedChanges) {
                setState(() => _hasUnsavedChanges = true);
              }
            },
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.darkSlate,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppTheme.mediumGray),
              hintText: 'Enter $label',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.mediumGray.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  /// Consultation info card (non-editable metadata)
  Widget _buildConsultationInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildInfoChip(Icons.language_rounded, _consultation.language),
          const SizedBox(width: 12),
          _buildInfoChip(Icons.timer_outlined, _consultation.formattedDuration),
          const SizedBox(width: 12),
          _buildInfoChip(Icons.calendar_today_outlined, _formatDate(_consultation.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppTheme.mediumGray),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkSlate,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleCard(
      String title, IconData icon, String content, Color accentColor) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
      ),
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          child: Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.darkSlate,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
      String sectionKey, String title, IconData icon, String content, Color accentColor) {
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple header row
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ),
              // Edit button
              GestureDetector(
                onTap: () => _showEditDialog(sectionKey, title, content, accentColor),
                child: Icon(
                  Icons.edit_outlined,
                  color: AppTheme.mediumGray,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Simple content
          _buildSimpleContent(content, sectionKey),
        ],
      ),
    );
  }

  /// Build simple, clean content display
  Widget _buildSimpleContent(String content, String sectionKey) {
    if (content.isEmpty || content.trim().isEmpty || content.trim() == 'Not documented') {
      return Text(
        'Not documented',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.mediumGray,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Clean content
    String cleanContent = content
        .replaceAll('\\n', '\n')
        .replaceAll('\\"', '"')
        .replaceAll('\\\\', '\\')
        .replaceAll('**', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('```', '')
        .trim();

    // Try to parse JSON
    if (cleanContent.startsWith('{') || cleanContent.startsWith('[')) {
      try {
        final parsed = jsonDecode(cleanContent);
        cleanContent = _jsonToPlainText(parsed);
      } catch (e) {
        // Not valid JSON
      }
    }

    // Check if content has bullet points
    final lines = cleanContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final hasBullets = lines.any((l) => 
        l.trim().startsWith('•') || 
        l.trim().startsWith('-') || 
        l.trim().startsWith('*') ||
        RegExp(r'^\d+\.').hasMatch(l.trim()));

    if (hasBullets || lines.length > 1) {
      // Show as bullet list
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          line = line.trim();
          // Remove bullet prefix
          if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
            line = line.substring(1).trim();
          } else if (RegExp(r'^\d+\.\s*').hasMatch(line)) {
            line = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGray,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.darkSlate,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Single text content
    return Text(
      cleanContent,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppTheme.darkSlate,
        height: 1.5,
      ),
    );
  }

  /// Convert JSON to plain text
  String _jsonToPlainText(dynamic json) {
    final lines = <String>[];
    
    if (json is Map) {
      json.forEach((key, value) {
        if (value == null || value.toString().isEmpty || value.toString() == 'Not documented') return;
        
        if (value is String) {
          if (value.contains('\n')) {
            lines.addAll(value.split('\n').where((l) => l.trim().isNotEmpty));
          } else {
            lines.add('• $value');
          }
        } else if (value is List) {
          for (var item in value) {
            if (item is String && item.isNotEmpty) {
              lines.add('• $item');
            } else if (item is Map) {
              final parts = item.entries
                  .where((e) => e.value != null && e.value.toString().isNotEmpty)
                  .map((e) => '${e.key}: ${e.value}')
                  .join(', ');
              if (parts.isNotEmpty) lines.add('• $parts');
            }
          }
        } else {
          lines.add('• $value');
        }
      });
    } else if (json is List) {
      for (var item in json) {
        if (item is String && item.isNotEmpty) {
          lines.add('• $item');
        }
      }
    }
    
    return lines.join('\n');
  }

  /// Check if content is list-type (has bullet points or multiple lines)
  bool _isListContent(String content, String sectionKey) {
    final lowerKey = sectionKey.toLowerCase();
    // These sections are typically lists
    final listSections = [
      'symptoms', 'prescription', 'medication', 'allergies', 
      'investigations', 'advice', 'instructions', 'notes',
      'current_medications', 'treatment_plan', 'follow_up',
      'warning_signs', 'differential'
    ];
    
    if (listSections.any((s) => lowerKey.contains(s))) {
      return true;
    }
    
    // Check if content has bullet points or multiple lines
    return content.contains('•') || 
           content.contains('\n-') || 
           content.split('\n').where((l) => l.trim().isNotEmpty).length > 1;
  }

  /// Parse content into list items
  List<String> _parseListItems(String content) {
    if (content.isEmpty) return [];
    
    final lines = content
        .replaceAll('\\n', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) {
          // Remove bullet point prefixes
          if (l.startsWith('•')) return l.substring(1).trim();
          if (l.startsWith('-')) return l.substring(1).trim();
          if (l.startsWith('*')) return l.substring(1).trim();
          if (RegExp(r'^\d+\.').hasMatch(l)) {
            return l.replaceFirst(RegExp(r'^\d+\.\s*'), '');
          }
          return l;
        })
        .where((l) => l.isNotEmpty)
        .toList();
    
    return lines;
  }

  /// Convert list items back to content string
  String _listItemsToContent(List<String> items) {
    return items.map((item) => '• $item').join('\n');
  }

  void _showEditDialog(String sectionKey, String title, String content, Color accentColor) {
    // Check if this is a list-type section
    if (_isListContent(content, sectionKey)) {
      _showListEditDialog(sectionKey, title, content, accentColor);
    } else {
      _showTextEditDialog(sectionKey, title, content, accentColor);
    }
  }

  /// Show list-based editor for list-type content
  void _showListEditDialog(String sectionKey, String title, String content, Color accentColor) {
    final items = _parseListItems(content);
    
    showDialog(
      context: context,
      builder: (context) => _ListEditDialog(
        title: title,
        items: items,
        accentColor: accentColor,
        sectionKey: sectionKey,
        onSave: (updatedItems) {
          setState(() {
            _editedSections[sectionKey] = _listItemsToContent(updatedItems);
            _hasUnsavedChanges = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Section updated',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  /// Show text-based editor for non-list content
  void _showTextEditDialog(String sectionKey, String title, String content, Color accentColor) {
    final controller = TextEditingController(text: content);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.1),
                      accentColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.edit_note_rounded, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Section',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.mediumGray,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text field
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    minLines: 8,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.darkSlate,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter content for this section...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.mediumGray.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGray.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: accentColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.mediumGray.withOpacity(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _editedSections[sectionKey] = controller.text;
                            _hasUnsavedChanges = true;
                          });
                          Navigator.pop(context);
                          // Show confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Section updated',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.successGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor, accentColor.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoReportCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 48,
            color: AppTheme.mediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            'No report generated yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the refresh button to generate a new report',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Regenerate button - icon only with tooltip
            GestureDetector(
              onTap: _showRegenerateDialog,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primarySkyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primarySkyBlue.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.primarySkyBlue,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Redo',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primarySkyBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Done button - main action
            Expanded(
              child: ElevatedButton(
                onPressed: _saveAndClose,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppTheme.primarySkyBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 22, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Save & Close',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegenerateDialog() {
    final instructionsController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySkyBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primarySkyBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Regenerate Report',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        Text(
                          'AI will create a new report based on your feedback',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Instructions label
              Text(
                'What would you like to change?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 8),
              
              // Quick suggestions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('More detailed', instructionsController),
                  _buildSuggestionChip('Simpler language', instructionsController),
                  _buildSuggestionChip('Add more sections', instructionsController),
                  _buildSuggestionChip('Focus on prescription', instructionsController),
                ],
              ),
              const SizedBox(height: 16),
              
              // Text input
              TextField(
                controller: instructionsController,
                maxLines: 3,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.darkSlate,
                ),
                decoration: InputDecoration(
                  hintText: 'E.g., "Include more details about the medication dosage" or "Make the diagnosis section more comprehensive"',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.mediumGray.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: AppTheme.lightGray.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primarySkyBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),
              
              // Optional note
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppTheme.mediumGray.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Leave empty to regenerate with default settings',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.mediumGray.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppTheme.mediumGray.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _regenerateReport(instructionsController.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primarySkyBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Regenerate',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSuggestionChip(String text, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        if (controller.text.isEmpty) {
          controller.text = text;
        } else {
          controller.text = '${controller.text}. $text';
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primarySkyBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primarySkyBlue.withOpacity(0.2)),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.primarySkyBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _regenerateReport(String? instructions) async {
    setState(() {
      _isRegenerating = true;
    });

    final provider = Provider.of<ConsultationProvider>(context, listen: false);
    final result = await provider.regenerateReport(
      _consultation.id,
      additionalInstructions: instructions,
    );

    if (mounted) {
      setState(() {
        _isRegenerating = false;
        if (result.success && result.consultation != null) {
          _consultation = result.consultation!;
        }
      });

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.error ?? 'Failed to regenerate report',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.accentCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _navigateHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  /// When the API returns a `report` field containing JSON, expand/merge it into section entries
  void _normalizeReportSections() {
    if (!_editedSections.containsKey('report')) return;

    final raw = _editedSections['report'] ?? '';
    if (raw.isEmpty) return;

    try {
      // Strip markdown fences if any
      String normalized = raw.trim();
      if (normalized.startsWith('```')) {
        final firstNewline = normalized.indexOf('\n');
        if (firstNewline != -1) {
          normalized = normalized.substring(firstNewline + 1);
        } else {
          normalized = normalized.replaceFirst('```', '');
        }
      }
      if (normalized.endsWith('```')) {
        normalized = normalized.substring(0, normalized.lastIndexOf('```')).trim();
      }

      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic>) {
        final merged = Map<String, String>.from(_editedSections);
        merged.remove('report'); // replace the raw blob

        decoded.forEach((key, value) {
          merged[key] = _valueToText(value);
        });

        if (merged.isNotEmpty) {
          _editedSections = merged;
          if (_consultation.report != null) {
            _consultation.report = _consultation.report!.copyWith(
              sections: merged,
            );
          }
        }
      }
    } catch (e) {
      // If parsing fails, keep the original so we still show something
      debugPrint('Normalize report sections failed: $e');
    }
  }

  /// Convert dynamic JSON values to readable text
  String _valueToText(dynamic value) {
    if (value == null) return 'Not documented';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      final items =
          value.map((v) => _valueToText(v)).where((v) => v.isNotEmpty).toList();
      return items.join('\n');
    }
    if (value is Map) {
      final lines = <String>[];
      value.forEach((k, v) {
        final text = _valueToText(v);
        if (text.isNotEmpty) {
          lines.add('$k: $text');
        }
      });
      return lines.join('\n');
    }
    return value.toString();
  }

  Future<void> _saveAndClose() async {
    // Show patient type selection dialog
    _showPatientTypeDialog();
  }

  /// Show dialog to choose new patient or existing patient
  void _showPatientTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primarySkyBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppTheme.primarySkyBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Save Report',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Is this a new patient or an existing patient?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 24),
              // New Patient Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleNewPatientSave();
                  },
                  icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                  label: Text(
                    'New Patient',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primarySkyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Existing Patient Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleExistingPatientSave();
                  },
                  icon: const Icon(Icons.person_search_outlined),
                  label: Text(
                    'Existing Patient',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primarySkyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primarySkyBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: AppTheme.mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Validate required fields for new patient
  String? _validateNewPatientFields() {
    if (_patientNameController.text.trim().isEmpty) {
      return 'name';
    }
    if (_ageController.text.trim().isEmpty) {
      return 'age';
    }
    if (_genderController.text.trim().isEmpty) {
      return 'gender';
    }
    return null; // All required fields are filled
  }

  /// Focus on the missing field
  void _focusField(String fieldName) {
    // Show error message
    String message = '';
    switch (fieldName) {
      case 'name':
        message = 'Please enter patient name';
        break;
      case 'age':
        message = 'Please enter patient age';
        break;
      case 'gender':
        message = 'Please enter patient gender';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppTheme.warningAmber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Handle save for new patient
  Future<void> _handleNewPatientSave() async {
    // Validate required fields
    final missingField = _validateNewPatientFields();
    if (missingField != null) {
      _focusField(missingField);
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primarySkyBlue),
              const SizedBox(height: 16),
              Text(
                'Saving report...',
                style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.darkSlate),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Generate patient ID
      final patientId = 'P${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final reportId = _consultation.report?.id ?? 'R${DateTime.now().millisecondsSinceEpoch}';

      // Prepare sections to save
      final sectionsToSave = Map<String, String>.from(_editedSections);
      sectionsToSave['patient_id'] = patientId;
      sectionsToSave['patient_name'] = _patientNameController.text.trim();
      sectionsToSave['age'] = _ageController.text.trim();
      sectionsToSave['gender'] = _genderController.text.trim();
      if (_bloodGroupController.text.isNotEmpty) {
        sectionsToSave['blood_group'] = _bloodGroupController.text.trim();
      }
      if (_weightController.text.isNotEmpty) {
        sectionsToSave['weight'] = _weightController.text.trim();
      }
      if (_heightController.text.isNotEmpty) {
        sectionsToSave['height'] = _heightController.text.trim();
      }
      if (_phoneController.text.isNotEmpty) {
        sectionsToSave['phone'] = _phoneController.text.trim();
      }

      // Save to database
      final dbService = DatabaseService();
      await dbService.updateReportSections(
        reportId: reportId,
        sections: sectionsToSave,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _ReportSavedScreen(
              patientId: patientId,
              reportId: reportId,
              patientName: _patientNameController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.accentCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Handle save for existing patient - show search dialog
  void _handleExistingPatientSave() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExistingPatientSearchSheet(
        onPatientSelected: (patient) {
          Navigator.pop(context);
          _saveToExistingPatient(patient);
        },
      ),
    );
  }

  /// Save report to existing patient
  Future<void> _saveToExistingPatient(Map<String, String> patient) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primarySkyBlue),
              const SizedBox(height: 16),
              Text(
                'Linking to patient...',
                style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.darkSlate),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final patientId = patient['id'] ?? '';
      final reportId = _consultation.report?.id ?? 'R${DateTime.now().millisecondsSinceEpoch}';

      // Prepare sections to save
      final sectionsToSave = Map<String, String>.from(_editedSections);
      sectionsToSave['patient_id'] = patientId;
      sectionsToSave['patient_name'] = patient['name'] ?? _patientNameController.text.trim();
      sectionsToSave['age'] = patient['age'] ?? _ageController.text.trim();
      sectionsToSave['gender'] = patient['gender'] ?? _genderController.text.trim();
      if (patient['blood_group']?.isNotEmpty == true || _bloodGroupController.text.isNotEmpty) {
        sectionsToSave['blood_group'] = patient['blood_group'] ?? _bloodGroupController.text.trim();
      }
      if (patient['phone']?.isNotEmpty == true || _phoneController.text.isNotEmpty) {
        sectionsToSave['phone'] = patient['phone'] ?? _phoneController.text.trim();
      }

      // Save to database
      final dbService = DatabaseService();
      await dbService.updateReportSections(
        reportId: reportId,
        sections: sectionsToSave,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Navigate to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _ReportSavedScreen(
              patientId: patientId,
              reportId: reportId,
              patientName: patient['name'] ?? _patientNameController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.accentCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

}

/// List Edit Dialog for editing list-type content
class _ListEditDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final Color accentColor;
  final String sectionKey;
  final Function(List<String>) onSave;

  const _ListEditDialog({
    required this.title,
    required this.items,
    required this.accentColor,
    required this.sectionKey,
    required this.onSave,
  });

  @override
  State<_ListEditDialog> createState() => _ListEditDialogState();
}

class _ListEditDialogState extends State<_ListEditDialog> {
  late List<String> _items;
  final TextEditingController _newItemController = TextEditingController();
  final FocusNode _newItemFocus = FocusNode();
  bool _isAddingNew = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    if (_items.isEmpty) {
      _items.add('');
      _isAddingNew = true;
    }
  }

  @override
  void dispose() {
    _newItemController.dispose();
    _newItemFocus.dispose();
    super.dispose();
  }

  void _addNewItem() {
    if (_newItemController.text.trim().isNotEmpty) {
      setState(() {
        _items.add(_newItemController.text.trim());
        _newItemController.clear();
        _isAddingNew = false;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, String value) {
    setState(() {
      _items[index] = value;
    });
  }

  void _showAddField() {
    setState(() {
      _isAddingNew = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _newItemFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMedication = widget.sectionKey.toLowerCase().contains('prescription') ||
                         widget.sectionKey.toLowerCase().contains('medication');
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.accentColor.withOpacity(0.15),
                    widget.accentColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isMedication ? Icons.medication_rounded : Icons.list_rounded,
                      color: widget.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit ${widget.title}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        Text(
                          '${_items.where((i) => i.isNotEmpty).length} items',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.mediumGray,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // List items
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Existing items
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildListItem(index, item, isMedication);
                    }),
                    // Add new item field
                    if (_isAddingNew)
                      _buildNewItemField(isMedication)
                    else
                      _buildAddButton(),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightGray.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.mediumGray.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        // Filter out empty items
                        final validItems = _items.where((i) => i.trim().isNotEmpty).toList();
                        widget.onSave(validItems);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.accentColor, widget.accentColor.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(int index, String item, bool isMedication) {
    final controller = TextEditingController(text: item);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accentColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Drag handle / bullet indicator
          Container(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isMedication ? Icons.medication_rounded : Icons.circle,
                  color: widget.accentColor,
                  size: isMedication ? 18 : 10,
                ),
              ),
            ),
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (value) => _updateItem(index, value),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.darkSlate,
              ),
              decoration: InputDecoration(
                hintText: isMedication 
                    ? 'e.g., Paracetamol 500mg - 1 tablet every 6 hours'
                    : 'Enter item...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.mediumGray.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: () => _removeItem(index),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentCoral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.accentCoral,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewItemField(bool isMedication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Plus icon
          Container(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.successGreen,
                size: 20,
              ),
            ),
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: _newItemController,
              focusNode: _newItemFocus,
              onSubmitted: (_) => _addNewItem(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.darkSlate,
              ),
              decoration: InputDecoration(
                hintText: isMedication 
                    ? 'Add medication with dosage...'
                    : 'Add new item...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.mediumGray.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // Add button
          GestureDetector(
            onTap: _addNewItem,
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          // Cancel button
          GestureDetector(
            onTap: () {
              setState(() {
                _isAddingNew = false;
                _newItemController.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.mediumGray,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddField,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.accentColor.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                color: widget.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Add New Item',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Report Saved Success Screen
class _ReportSavedScreen extends StatelessWidget {
  final String patientId;
  final String reportId;
  final String patientName;

  const _ReportSavedScreen({
    required this.patientId,
    required this.reportId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.successGreen.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Success animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: AppTheme.successGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Report Saved!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Patient record created successfully',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: 32),
                // ID Cards
                _buildIdCard(
                  context,
                  'Patient ID',
                  patientId,
                  Icons.person_rounded,
                  AppTheme.primarySkyBlue,
                ),
                const SizedBox(height: 16),
                _buildIdCard(
                  context,
                  'Report ID',
                  reportId,
                  Icons.description_rounded,
                  AppTheme.successGreen,
                ),
                const SizedBox(height: 16),
                // Patient name card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.lightGray),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.badge_rounded,
                          color: AppTheme.warningAmber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Name',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                          Text(
                            patientName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Copy IDs to clipboard
                          final text = 'Patient ID: $patientId\nReport ID: $reportId\nPatient: $patientName';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('IDs copied!', style: GoogleFonts.poppins()),
                              backgroundColor: AppTheme.successGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: Text('Copy IDs', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primarySkyBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.primarySkyBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home_rounded, color: Colors.white),
                        label: Text(
                          'Go Home',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primarySkyBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.mediumGray,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied!', style: GoogleFonts.poppins()),
                  backgroundColor: color,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.copy_rounded, color: color, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Existing Patient Search Sheet
class _ExistingPatientSearchSheet extends StatefulWidget {
  final Function(Map<String, String>) onPatientSelected;

  const _ExistingPatientSearchSheet({required this.onPatientSelected});

  @override
  State<_ExistingPatientSearchSheet> createState() => _ExistingPatientSearchSheetState();
}

class _ExistingPatientSearchSheetState extends State<_ExistingPatientSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  String _searchType = 'name'; // name, id, phone
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Search from database
      final results = await _dbService.searchPatients(
        query: query,
        searchType: _searchType,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _hasSearched = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySkyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: AppTheme.primarySkyBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Existing Patient',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      Text(
                        'Search by name, ID, or phone number',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: AppTheme.mediumGray),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Search type tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildSearchTypeChip('name', 'By Name', Icons.person_outline),
                const SizedBox(width: 8),
                _buildSearchTypeChip('id', 'By ID', Icons.badge_outlined),
                const SizedBox(width: 8),
                _buildSearchTypeChip('phone', 'By Phone', Icons.phone_outlined),
              ],
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _performSearch(),
              autofocus: true,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: InputDecoration(
                hintText: _getSearchHint(),
                hintStyle: GoogleFonts.poppins(color: AppTheme.mediumGray.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.mediumGray),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                        child: const Icon(Icons.clear_rounded, color: AppTheme.mediumGray),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primarySkyBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              keyboardType: _searchType == 'phone' ? TextInputType.phone : TextInputType.text,
            ),
          ),
          const SizedBox(height: 16),
          // Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTypeChip(String type, String label, IconData icon) {
    final isSelected = _searchType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _searchType = type;
            _searchResults = [];
            _hasSearched = false;
          });
          if (_searchController.text.isNotEmpty) {
            _performSearch();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primarySkyBlue : AppTheme.lightGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.mediumGray,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSearchHint() {
    switch (_searchType) {
      case 'name':
        return 'Enter patient name...';
      case 'id':
        return 'Enter patient ID (e.g., P10001)...';
      case 'phone':
        return 'Enter phone number...';
      default:
        return 'Search...';
    }
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primarySkyBlue),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: AppTheme.mediumGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Start typing to search',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 64,
              color: AppTheme.mediumGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final patient = _searchResults[index];
        return _buildPatientCard(patient);
      },
    );
  }

  Widget _buildPatientCard(Map<String, String> patient) {
    return GestureDetector(
      onTap: () => widget.onPatientSelected(patient),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.lightGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primarySkyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  patient['name']![0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primarySkyBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['name']!,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Show truncated ID (first 8 chars)
                      _buildPatientTag(
                        'ID: ${patient['id']!.length > 8 ? patient['id']!.substring(0, 8) : patient['id']!}',
                        AppTheme.primarySkyBlue,
                      ),
                      if (patient['age']?.isNotEmpty == true || patient['gender']?.isNotEmpty == true)
                        _buildPatientTag(
                          '${patient['age']?.isNotEmpty == true ? "${patient['age']}y" : ""}${patient['age']?.isNotEmpty == true && patient['gender']?.isNotEmpty == true ? ", " : ""}${patient['gender'] ?? ""}',
                          AppTheme.mediumGray,
                        ),
                      if (patient['blood_group']?.isNotEmpty == true)
                        _buildPatientTag(patient['blood_group']!, AppTheme.accentCoral),
                    ],
                  ),
                  if (patient['phone']?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 12, color: AppTheme.mediumGray),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            patient['phone']!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.mediumGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.successGreen,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

