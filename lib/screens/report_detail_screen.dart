import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/consultation.dart';
import '../models/report.dart';
import '../providers/consultation_provider.dart';

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
  }

  @override
  void dispose() {
    _animationController.dispose();
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
            onTap: () => Navigator.pop(context),
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
                Icons.arrow_back_rounded,
                color: AppTheme.darkSlate,
                size: 22,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Report Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
          ),
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
          // Dynamic report sections
          if (report != null && report.sections.isNotEmpty) ...[
            ...report.sectionKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final key = entry.value;
              final content = report.sections[key] ?? '';
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

  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryTeal, AppTheme.deepTeal],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withOpacity(0.3),
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
                    (_consultation.patientName ?? 'P')[0].toUpperCase(),
                    style: GoogleFonts.dmSans(
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
                      _consultation.patientName ?? 'Unknown Patient',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Print feature coming soon!',
                        style: GoogleFonts.dmSans(),
                      ),
                      backgroundColor: AppTheme.primaryTeal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.print_rounded, size: 20),
                label: Text(
                  'Print',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Share feature coming soon!',
                        style: GoogleFonts.dmSans(),
                      ),
                      backgroundColor: AppTheme.primaryTeal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  'Share',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryTeal,
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
              Icons.refresh_rounded,
              'Regenerate Report',
              'Generate a new AI report',
              AppTheme.primaryTeal,
              onTap: _regenerateReport,
            ),
            const SizedBox(height: 12),
            _buildOptionItem(
              Icons.download_rounded,
              'Export as PDF',
              'Download the report as PDF',
              AppTheme.successGreen,
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

  Future<void> _regenerateReport() async {
    Navigator.pop(context); // Close bottom sheet
    
    final provider = Provider.of<ConsultationProvider>(context, listen: false);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryTeal),
        ),
      ),
    );

    final result = await provider.regenerateReport(_consultation.id);
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (result.success && result.consultation != null) {
        setState(() {
          _consultation = result.consultation!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report regenerated successfully!',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.error ?? 'Failed to regenerate report',
              style: GoogleFonts.dmSans(),
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
