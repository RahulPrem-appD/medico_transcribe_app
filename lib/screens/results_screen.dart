import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/consultation.dart';
import '../models/report.dart';
import '../providers/consultation_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _consultation = widget.consultation;
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
                // Patient info card
                _buildInfoCard(
                  'Patient Information',
                  Icons.person_rounded,
                  [
                    _InfoRow('Name', _consultation.patientName ?? 'Not provided'),
                    _InfoRow('Language', _consultation.language),
                    _InfoRow('Duration', _consultation.formattedDuration),
                    _InfoRow('Date', _formatDate(_consultation.createdAt)),
                  ],
                ),
                const SizedBox(height: 16),
                // Transcription (collapsible)
                if (_consultation.transcription != null)
                  _buildCollapsibleCard(
                    'Transcription',
                    Icons.record_voice_over_rounded,
                    _consultation.transcription!,
                    AppTheme.mediumGray,
                  ),
                const SizedBox(height: 16),
                // Dynamic report sections
                if (report != null) ...[
                  ...report.sectionKeys.asMap().entries.map((entry) {
                    final index = entry.key;
                    final key = entry.value;
                    final content = report.sections[key] ?? '';
                    final displayName = Report.keyToDisplayName(key);
                    final color = _getSectionColor(index);
                    final icon = _getSectionIcon(key);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildSectionCard(
                        displayName,
                        icon,
                        content,
                        color,
                      ),
                    );
                  }),
                ] else
                  _buildNoReportCard(),
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
          const Expanded(
            child: Center(
              child: Text(
                'Consultation Notes',
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
          colors: [AppTheme.successGreen, Color(0xFF34D399)],
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

  Widget _buildInfoCard(String title, IconData icon, List<_InfoRow> rows) {
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
                  color: AppTheme.primarySkyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primarySkyBlue, size: 22),
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
          const SizedBox(height: 16),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        row.label,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
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
      String title, IconData icon, String content, Color accentColor) {
    // Format the content for better display
    final formattedContent = _formatSectionContent(content);
    
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
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
            child: _buildFormattedContent(formattedContent, accentColor),
          ),
        ],
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Report saved successfully!',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  _navigateHome();
                },
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format section content for better display
  String _formatSectionContent(String content) {
    if (content.isEmpty) return 'Not documented';
    
    String formatted = content;
    
    // Try to parse as JSON if it looks like JSON
    if (formatted.trim().startsWith('{') || formatted.trim().startsWith('[')) {
      try {
        final parsed = jsonDecode(formatted);
        formatted = _jsonToReadableText(parsed);
      } catch (e) {
        // Not valid JSON, continue with string processing
      }
    }
    
    // Clean up common formatting issues
    formatted = formatted
        .replaceAll('\\n', '\n')
        .replaceAll('\\"', '"')
        .replaceAll('**', '')  // Remove markdown bold
        .replaceAll('###', '')  // Remove markdown headers
        .replaceAll('##', '')
        .replaceAll('```', '')  // Remove code blocks
        .trim();
    
    // Convert markdown-style lists to clean format
    formatted = formatted
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '• ');
    
    return formatted.isNotEmpty ? formatted : 'Not documented';
  }

  /// Convert JSON object to readable text
  String _jsonToReadableText(dynamic json, {int indent = 0}) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    
    if (json is Map) {
      json.forEach((key, value) {
        final formattedKey = _formatKeyName(key.toString());
        if (value is String) {
          if (value.isNotEmpty) {
            buffer.writeln('$indentStr• $formattedKey: $value');
          }
        } else if (value is List) {
          buffer.writeln('$indentStr• $formattedKey:');
          for (var item in value) {
            if (item is String) {
              buffer.writeln('$indentStr  - $item');
            } else if (item is Map) {
              final parts = <String>[];
              item.forEach((k, v) {
                if (v != null && v.toString().isNotEmpty) {
                  parts.add('${_formatKeyName(k.toString())}: $v');
                }
              });
              if (parts.isNotEmpty) {
                buffer.writeln('$indentStr  - ${parts.join(', ')}');
              }
            } else {
              buffer.writeln('$indentStr  - $item');
            }
          }
        } else if (value is Map) {
          buffer.writeln('$indentStr• $formattedKey:');
          buffer.write(_jsonToReadableText(value, indent: indent + 1));
        } else if (value != null) {
          buffer.writeln('$indentStr• $formattedKey: $value');
        }
      });
    } else if (json is List) {
      for (var item in json) {
        if (item is String) {
          buffer.writeln('$indentStr• $item');
        } else if (item is Map) {
          buffer.write(_jsonToReadableText(item, indent: indent));
        } else {
          buffer.writeln('$indentStr• $item');
        }
      }
    } else {
      buffer.write(json.toString());
    }
    
    return buffer.toString().trim();
  }

  /// Format a key name to be more readable
  String _formatKeyName(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' 
            : '')
        .join(' ');
  }

  /// Build formatted content widget with proper styling for bullet points
  Widget _buildFormattedContent(String content, Color accentColor) {
    if (content.isEmpty || content == 'Not documented') {
      return Text(
        'Not documented',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.mediumGray,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Check if content has bullet points
    final hasBullets = content.contains('•') || content.contains('- ');
    
    if (hasBullets) {
      // Parse and display as structured list
      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          final trimmedLine = line.trim();
          final isBullet = trimmedLine.startsWith('•') || trimmedLine.startsWith('- ');
          final isSubItem = line.startsWith('  ') || line.startsWith('\t');
          
          String displayText = trimmedLine;
          if (isBullet) {
            displayText = trimmedLine.substring(1).trim();
            if (displayText.startsWith(' ')) {
              displayText = displayText.substring(1);
            }
          }
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: 8,
              left: isSubItem ? 16 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBullet) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSubItem ? accentColor.withOpacity(0.5) : accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    isBullet ? displayText : trimmedLine,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.darkSlate,
                      height: 1.5,
                      fontWeight: isSubItem ? FontWeight.normal : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
    
    // Regular text without bullets
    return Text(
      content,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppTheme.darkSlate,
        height: 1.6,
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}
