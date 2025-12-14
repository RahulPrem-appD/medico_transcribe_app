import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/consultation.dart';
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

  @override
  void initState() {
    super.initState();
    _consultation = widget.consultation;
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
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryTeal),
          ),
          const SizedBox(height: 24),
          Text(
            'Regenerating report...',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
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
                // Chief complaint
                if (report != null) ...[
                  _buildSectionCard(
                    'Chief Complaint',
                    Icons.report_problem_rounded,
                    report.chiefComplaint,
                    AppTheme.accentCoral,
                  ),
                  const SizedBox(height: 16),
                  // Symptoms
                  _buildSectionCard(
                    'Symptoms',
                    Icons.medical_information_rounded,
                    report.symptoms,
                    AppTheme.warningAmber,
                  ),
                  const SizedBox(height: 16),
                  // Diagnosis
                  _buildSectionCard(
                    'Diagnosis',
                    Icons.health_and_safety_rounded,
                    report.diagnosis,
                    AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 16),
                  // Prescription
                  _buildSectionCard(
                    'Prescription',
                    Icons.medication_rounded,
                    report.prescription,
                    AppTheme.successGreen,
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  _buildSectionCard(
                    'Additional Notes',
                    Icons.note_alt_rounded,
                    report.additionalNotes,
                    AppTheme.deepTeal,
                  ),
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
                color: AppTheme.primaryTeal,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
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
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review the consultation notes below',
                  style: GoogleFonts.dmSans(
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
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryTeal, size: 22),
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
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        row.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: GoogleFonts.dmSans(
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
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
            style: GoogleFonts.dmSans(
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
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Regenerate" to generate a new report',
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
              child: OutlinedButton(
                onPressed: _regenerateReport,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Regenerate',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Report saved successfully!',
                        style: GoogleFonts.dmSans(),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Done',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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

  Future<void> _regenerateReport() async {
    setState(() {
      _isRegenerating = true;
    });

    final provider = Provider.of<ConsultationProvider>(context, listen: false);
    final result = await provider.regenerateReport(_consultation.id);

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
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}
