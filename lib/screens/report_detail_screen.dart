import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/consultation.dart';
import '../models/report.dart';
import '../providers/consultation_provider.dart';
import '../services/database_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final Consultation consultation;

  const ReportDetailScreen({super.key, required this.consultation});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Consultation _consultation;
  
  // Edit mode state
  bool _isEditMode = false;
  bool _isSaving = false;
  late Map<String, TextEditingController> _sectionControllers;
  
  // Patient details controllers
  late TextEditingController _patientNameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _phoneController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _consultation = widget.consultation;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    // Initialize controllers
    _initializeControllers();
  }
  
  void _initializeControllers() {
    final sections = _consultation.report?.sections ?? {};
    
    // Initialize patient detail controllers
    _patientNameController = TextEditingController(
      text: sections['patient_name']?.toString() ?? _consultation.patientName ?? '',
    );
    _ageController = TextEditingController(text: sections['age']?.toString() ?? '');
    _genderController = TextEditingController(text: sections['gender']?.toString() ?? '');
    _bloodGroupController = TextEditingController(text: sections['blood_group']?.toString() ?? '');
    _phoneController = TextEditingController(text: sections['phone']?.toString() ?? '');
    _weightController = TextEditingController(text: sections['weight']?.toString() ?? '');
    _heightController = TextEditingController(text: sections['height']?.toString() ?? '');
    
    // Initialize section controllers
    _sectionControllers = {};
    for (final key in sections.keys) {
      if (!_excludedSectionKeys.contains(key.toLowerCase())) {
        _sectionControllers[key] = TextEditingController(text: sections[key]?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    
    // Dispose controllers
    _patientNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _bloodGroupController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    
    for (final controller in _sectionControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
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
              AppTheme.softMint,
              AppTheme.warmCream,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isEditMode) {
                _showDiscardChangesDialog();
              } else {
                Navigator.pop(context);
              }
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
              child: Icon(
                _isEditMode ? Icons.close_rounded : Icons.arrow_back_rounded,
                color: AppTheme.darkSlate,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _isEditMode ? 'Edit Report' : 'Report Details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
          ),
          if (_isEditMode)
            GestureDetector(
              onTap: _isSaving ? null : _saveChanges,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                _showOptionsMenu();
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
                  Icons.more_vert_rounded,
                  color: AppTheme.darkSlate,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showDiscardChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Discard Changes?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: GoogleFonts.poppins(color: AppTheme.mediumGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Editing',
              style: GoogleFonts.poppins(
                color: AppTheme.primarySkyBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _isEditMode = false;
                _initializeControllers(); // Reset controllers
              });
            },
            child: Text(
              'Discard',
              style: GoogleFonts.poppins(
                color: AppTheme.accentCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveChanges() async {
    if (_consultation.report == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Build updated sections map
      final updatedSections = <String, String>{
        'patient_name': _patientNameController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _genderController.text.trim(),
        'blood_group': _bloodGroupController.text.trim(),
        'phone': _phoneController.text.trim(),
        'weight': _weightController.text.trim(),
        'height': _heightController.text.trim(),
      };
      
      // Add other sections
      for (final entry in _sectionControllers.entries) {
        updatedSections[entry.key] = entry.value.text.trim();
      }
      
      // Update in database
      final dbService = DatabaseService();
      final updatedReport = await dbService.updateReportSections(
        reportId: _consultation.report!.id,
        sections: updatedSections,
      );
      
      // Update local state
      setState(() {
        _consultation.report = updatedReport;
        _isEditMode = false;
        _isSaving = false;
      });
      
      // Refresh the provider
      if (mounted) {
        Provider.of<ConsultationProvider>(context, listen: false).loadConsultations();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report updated successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save changes: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.accentCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // Color palette for sections
  final List<Color> _sectionColors = [
    AppTheme.accentCoral,
    AppTheme.warningAmber,
    AppTheme.primarySkyBlue,
    AppTheme.successGreen,
    AppTheme.deepSkyBlue,
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF97316), // Orange
    const Color(0xFF6366F1), // Indigo
  ];

  // Icon mapping for common sections
  final Map<String, IconData> _sectionIcons = {
    'chief_complaint': Icons.report_problem_rounded,
    'symptoms': Icons.medical_information_rounded,
    'diagnosis': Icons.health_and_safety_rounded,
    'assessment': Icons.health_and_safety_rounded,
    'prescription': Icons.medication_rounded,
    'medications': Icons.medication_rounded,
    'additional_notes': Icons.note_alt_rounded,
    'notes': Icons.note_alt_rounded,
    'history': Icons.history_rounded,
    'allergies': Icons.warning_rounded,
    'vitals': Icons.monitor_heart_rounded,
    'physical_exam': Icons.person_search_rounded,
    'treatment_plan': Icons.healing_rounded,
    'plan': Icons.healing_rounded,
    'follow_up': Icons.event_rounded,
    'summary': Icons.summarize_rounded,
  };

  Color _getSectionColor(int index) {
    return _sectionColors[index % _sectionColors.length];
  }

  IconData _getSectionIcon(String key) {
    final lowerKey = key.toLowerCase();
    for (final entry in _sectionIcons.entries) {
      if (lowerKey.contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.article_rounded;
  }

  Widget _buildContent() {
    final report = _consultation.report;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Patient header card
          _buildPatientHeader(),
          const SizedBox(height: 20),
          // Transcription (collapsible)
          if (_consultation.transcription != null && _consultation.transcription!.isNotEmpty)
            _buildCollapsibleCard(
              'Transcription',
              Icons.record_voice_over_rounded,
              _consultation.transcription!,
              AppTheme.mediumGray,
            ),
          // Dynamic report sections (excluding patient details which are shown in header)
          if (report != null && report.sections.isNotEmpty) ...[
            ...report.sectionKeys
                .where((key) => !_excludedSectionKeys.contains(key.toLowerCase()))
                .toList()
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final key = entry.value;
              final content = report.sections[key] ?? '';
              
              // Skip empty content
              if (content.trim().isEmpty) return const SizedBox.shrink();
              
              final displayName = Report.keyToDisplayName(key);
              final color = _getSectionColor(index);
              final icon = _getSectionIcon(key);
              
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildDynamicSectionCard(
                  key,
                  displayName,
                  icon,
                  content,
                  color,
                ),
              );
            }),
          ] else if (report != null) ...[
            // Fallback to legacy fields if sections is empty
            const SizedBox(height: 16),
            if (report.chiefComplaint.isNotEmpty)
            _buildSectionCard(
              'Chief Complaint',
              Icons.report_problem_rounded,
              report.chiefComplaint,
              AppTheme.accentCoral,
            ),
            if (report.symptoms.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'Symptoms',
              Icons.medical_information_rounded,
              report.symptoms,
              AppTheme.warningAmber,
            ),
            ],
            if (report.diagnosis.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'Diagnosis',
              Icons.health_and_safety_rounded,
              report.diagnosis,
              AppTheme.primaryTeal,
            ),
            ],
            if (report.prescription.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'Prescription',
              Icons.medication_rounded,
              report.prescription,
              AppTheme.successGreen,
            ),
            ],
            if (report.additionalNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'Additional Notes',
              Icons.note_alt_rounded,
              report.additionalNotes,
              AppTheme.deepTeal,
            ),
            ],
          ] else
            _buildNoReportCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Build dynamic section card - simple and clean
  Widget _buildDynamicSectionCard(
      String sectionKey, String title, IconData icon, String content, Color accentColor) {
    
    if (_isEditMode) {
      return _buildEditableSectionCard(sectionKey, title, icon, accentColor);
    }
    
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
            ],
          ),
          const SizedBox(height: 12),
          // Simple content
          _buildSimpleContent(content),
        ],
      ),
    );
  }
  
  Widget _buildEditableSectionCard(String sectionKey, String title, IconData icon, Color accentColor) {
    // Ensure controller exists
    _sectionControllers[sectionKey] ??= TextEditingController(
      text: _consultation.report?.sections[sectionKey]?.toString() ?? '',
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
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
          // Header row with edit indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
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
              Icon(Icons.edit_rounded, color: accentColor.withOpacity(0.5), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          // Editable text field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _sectionControllers[sectionKey],
              maxLines: null,
              minLines: 3,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.darkSlate,
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter $title...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.mediumGray,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build simple, clean content display
  Widget _buildSimpleContent(String content) {
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

  // Get patient name from report sections or consultation
  String get _patientName {
    final sections = _consultation.report?.sections ?? {};
    final nameFromSections = sections['patient_name']?.toString().trim() ?? '';
    if (nameFromSections.isNotEmpty) return nameFromSections;
    return _consultation.patientName ?? 'Unknown Patient';
  }

  // Get patient details from report sections
  Map<String, String> get _patientDetails {
    final sections = _consultation.report?.sections ?? {};
    return {
      'age': sections['age']?.toString().trim() ?? '',
      'gender': sections['gender']?.toString().trim() ?? '',
      'blood_group': sections['blood_group']?.toString().trim() ?? '',
      'phone': sections['phone']?.toString().trim() ?? '',
      'weight': sections['weight']?.toString().trim() ?? '',
      'height': sections['height']?.toString().trim() ?? '',
    };
  }

  // Keys to exclude from report sections (patient details shown in header)
  static const _excludedSectionKeys = {
    'patient_name',
    'age',
    'gender',
    'blood_group',
    'phone',
    'weight',
    'height',
    'patient_id',
  };

  Widget _buildPatientHeader() {
    if (_isEditMode) {
      return _buildEditablePatientHeader();
    }
    
    final details = _patientDetails;
    final hasDetails = details.values.any((v) => v.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primarySkyBlue, AppTheme.deepSkyBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySkyBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Patient avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    _patientName[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (hasDetails) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (details['age']!.isNotEmpty || details['gender']!.isNotEmpty)
                            _buildHeaderTag(
                              '${details['age']!.isNotEmpty ? "${details['age']}y" : ""}${details['age']!.isNotEmpty && details['gender']!.isNotEmpty ? ", " : ""}${details['gender']!}',
                            ),
                          if (details['blood_group']!.isNotEmpty)
                            _buildHeaderTag(details['blood_group']!),
                        ],
                      ),
                    ] else ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _consultation.statusDisplayText,
                          style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Info row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.calendar_today_rounded,
                  'Date',
                  _formatDate(_consultation.createdAt),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildInfoItem(
                  Icons.translate_rounded,
                  'Language',
                  _consultation.language,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildInfoItem(
                  Icons.timer_rounded,
                  'Duration',
                  _consultation.formattedDuration,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditablePatientHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primarySkyBlue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, color: AppTheme.primarySkyBlue, size: 22),
              const SizedBox(width: 10),
              Text(
                'Patient Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primarySkyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Editing',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primarySkyBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEditableField('Patient Name', _patientNameController, Icons.badge_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildEditableField('Age', _ageController, Icons.cake_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildEditableField('Gender', _genderController, Icons.wc_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildEditableField('Blood Group', _bloodGroupController, Icons.bloodtype_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildEditableField('Phone', _phoneController, Icons.phone_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildEditableField('Weight', _weightController, Icons.monitor_weight_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildEditableField('Height', _heightController, Icons.height_rounded)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditableField(String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.mediumGray, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.darkSlate,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: label,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.mediumGray,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTag(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCollapsibleCard(
      String title, IconData icon, String content, Color accentColor) {
    return Container(
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
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
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withOpacity(0.1),
              ),
            ),
            child: Text(
              content,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.darkSlate,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      String title, IconData icon, String content, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withOpacity(0.1),
              ),
            ),
            child: Text(
              content.isNotEmpty ? content : 'Not documented',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.darkSlate,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoReportCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
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
            'No report generated',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The report was not generated for this consultation',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    // Hide bottom actions in edit mode
    if (_isEditMode) {
      return const SizedBox.shrink();
    }
    
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportAsPdf,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: Text(
                  'Export PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppTheme.primarySkyBlue,
                  side: const BorderSide(color: AppTheme.primarySkyBlue, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareReport,
                icon: const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  'Share',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primarySkyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionItem(
              Icons.edit_rounded,
              'Edit Report',
              'Modify report details and sections',
              AppTheme.primarySkyBlue,
              onTap: () {
                Navigator.pop(context);
                setState(() => _isEditMode = true);
              },
            ),
            const SizedBox(height: 12),
            _buildOptionItem(
              Icons.picture_as_pdf_rounded,
              'Export as PDF',
              'Download the report as PDF',
              AppTheme.successGreen,
              onTap: () => _exportAsPdf(fromBottomSheet: true),
            ),
            const SizedBox(height: 12),
            _buildOptionItem(
              Icons.share_rounded,
              'Share Report',
              'Share the report with others',
              const Color(0xFF8B5CF6),
              onTap: () => _shareReport(fromBottomSheet: true),
            ),
            const SizedBox(height: 12),
            _buildOptionItem(
              Icons.delete_outline_rounded,
              'Delete Report',
              'Permanently remove this report',
              AppTheme.accentCoral,
              onTap: _deleteReport,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Generate PDF document
  Future<Uint8List> _generatePdf() async {
    debugPrint('Starting PDF generation...');
    final pdf = pw.Document();
    final report = _consultation.report;
    
    // Get patient details
    final sections = report?.sections ?? {};
    final patientName = sections['patient_name']?.toString().trim() ?? 
                        _consultation.patientName ?? 'Unknown Patient';
    final age = sections['age']?.toString().trim() ?? '';
    final gender = sections['gender']?.toString().trim() ?? '';
    final bloodGroup = sections['blood_group']?.toString().trim() ?? '';
    final phone = sections['phone']?.toString().trim() ?? '';

    debugPrint('Building PDF page for: $patientName');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(patientName, age, gender, bloodGroup, phone),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => _buildPdfContent(report, sections),
      ),
    );

    debugPrint('Saving PDF...');
    final result = pdf.save();
    debugPrint('PDF generation complete');
    return result;
  }

  pw.Widget _buildPdfHeader(String name, String age, String gender, String bloodGroup, String phone) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'MEDICAL REPORT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Doctor Scribe',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Patient Information',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Name: $name', style: const pw.TextStyle(fontSize: 11)),
                      if (age.isNotEmpty || gender.isNotEmpty)
                        pw.Text(
                          '${age.isNotEmpty ? "Age: $age" : ""}${age.isNotEmpty && gender.isNotEmpty ? "  |  " : ""}${gender.isNotEmpty ? "Gender: $gender" : ""}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      if (bloodGroup.isNotEmpty)
                        pw.Text('Blood Group: $bloodGroup', style: const pw.TextStyle(fontSize: 11)),
                      if (phone.isNotEmpty)
                        pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Consultation Details',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Date: ${_formatDate(_consultation.createdAt)}', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('Language: ${_consultation.language}', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('Duration: ${_consultation.formattedDuration}', style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Doctor Scribe',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildPdfContent(Report? report, Map<String, String> sections) {
    final List<pw.Widget> widgets = [];
    
    if (report == null) {
      widgets.add(
        pw.Center(
          child: pw.Text('No report data available'),
        ),
      );
      return widgets;
    }

    // Filter out patient details from sections
    final excludedKeys = {'patient_name', 'age', 'gender', 'blood_group', 'phone', 'weight', 'height', 'patient_id'};
    
    // Add each section
    for (final key in report.sectionKeys) {
      if (excludedKeys.contains(key.toLowerCase())) continue;
      
      final content = sections[key] ?? '';
      if (content.trim().isEmpty) continue;
      
      final displayName = Report.keyToDisplayName(key);
      widgets.add(_buildPdfSection(displayName, content));
      widgets.add(pw.SizedBox(height: 15));
    }

    // Fallback to legacy fields if sections is empty
    if (widgets.isEmpty) {
      if (report.chiefComplaint.isNotEmpty) {
        widgets.add(_buildPdfSection('Chief Complaint', report.chiefComplaint));
        widgets.add(pw.SizedBox(height: 15));
      }
      if (report.symptoms.isNotEmpty) {
        widgets.add(_buildPdfSection('Symptoms', report.symptoms));
        widgets.add(pw.SizedBox(height: 15));
      }
      if (report.diagnosis.isNotEmpty) {
        widgets.add(_buildPdfSection('Diagnosis', report.diagnosis));
        widgets.add(pw.SizedBox(height: 15));
      }
      if (report.prescription.isNotEmpty) {
        widgets.add(_buildPdfSection('Prescription', report.prescription));
        widgets.add(pw.SizedBox(height: 15));
      }
      if (report.additionalNotes.isNotEmpty) {
        widgets.add(_buildPdfSection('Additional Notes', report.additionalNotes));
        widgets.add(pw.SizedBox(height: 15));
      }
    }

    return widgets;
  }

  pw.Widget _buildPdfSection(String title, String content) {
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

    // Split into lines for bullet formatting
    final lines = cleanContent.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...lines.map((line) {
            line = line.trim();
            // Remove bullet prefix
            if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
              line = line.substring(1).trim();
            } else if (RegExp(r'^\d+\.\s*').hasMatch(line)) {
              line = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
            }
            
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 4,
                    height: 4,
                    margin: const pw.EdgeInsets.only(top: 5, right: 8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue600,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Export report as PDF
  Future<void> _exportAsPdf({bool fromBottomSheet = false}) async {
    debugPrint('_exportAsPdf called, fromBottomSheet: $fromBottomSheet');
    
    // Close bottom sheet if called from there
    if (fromBottomSheet && mounted) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (!mounted) {
      debugPrint('Widget not mounted, returning');
      return;
    }

    try {
      debugPrint('Generating PDF...');
      // Generate PDF
      final pdfData = await _generatePdf();
      
      debugPrint('PDF generated, size: ${pdfData.length} bytes');
      
      if (!mounted) {
        debugPrint('Widget not mounted after PDF generation');
        return;
      }
      
      debugPrint('Opening print dialog...');
      // Show print/share dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'Report_${_patientName.replaceAll(' ', '_')}_${_formatDateForFile(_consultation.createdAt)}.pdf',
      );
      debugPrint('Print dialog closed');
    } catch (e, stackTrace) {
      debugPrint('PDF Export Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.accentCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Share report
  Future<void> _shareReport({bool fromBottomSheet = false}) async {
    // Close bottom sheet if called from there
    if (fromBottomSheet && mounted) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (!mounted) return;

    try {
      final pdfData = await _generatePdf();
      
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Report_${_patientName.replaceAll(' ', '_')}_${_formatDateForFile(_consultation.createdAt)}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfData);
      
      if (!mounted) return;
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Medical Report - $_patientName',
        text: 'Medical consultation report for $_patientName dated ${_formatDate(_consultation.createdAt)}',
      );
    } catch (e) {
      debugPrint('Share Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.accentCoral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _formatDateForFile(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteReport() async {
    Navigator.pop(context); // Close bottom sheet
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Delete Report?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this report? This action cannot be undone.',
          style: GoogleFonts.dmSans(color: AppTheme.mediumGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: AppTheme.mediumGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(
                color: AppTheme.accentCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<ConsultationProvider>(context, listen: false);
      await provider.deleteConsultation(_consultation.id);
      Navigator.pop(context);
    }
  }

  Widget _buildOptionItem(
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$title feature coming soon!',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
