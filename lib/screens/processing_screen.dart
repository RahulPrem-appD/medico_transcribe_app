import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/consultation_provider.dart';
import '../models/consultation.dart';
import '../models/report_template.dart';
import 'transcription_review_screen.dart';
import 'results_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String audioFilePath;
  final String language;
  final String? patientName;
  final String duration;

  const ProcessingScreen({
    super.key,
    required this.audioFilePath,
    required this.language,
    this.patientName,
    required this.duration,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  String? _errorMessage;
  bool _isProcessing = false;
  String? _transcription;
  String? _consultationId;
  List<dynamic>? _diarization;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isProcessing) {
        _isProcessing = true;
        _transcribeAudio();
      }
    });
  }

  Future<void> _transcribeAudio() async {
    final provider = Provider.of<ConsultationProvider>(context, listen: false);

    final result = await provider.transcribeOnly(
      audioFilePath: widget.audioFilePath,
      language: widget.language,
      patientName: widget.patientName,
    );

    if (!mounted) return;

    if (result.success && result.transcription != null) {
      print('Processing screen - Diarization received: ${result.diarization}');
      print(
        'Processing screen - Diarization length: ${result.diarization?.length ?? 0}',
      );
      setState(() {
        _transcription = result.transcription;
        _consultationId = result.consultationId;
        _diarization = result.diarization;
      });

      // Navigate to transcription review screen
      _showTranscriptionReview();
    } else {
      setState(() {
        _errorMessage =
            result.error ?? 'Transcription failed. Please try again.';
      });
    }
  }

  void _showTranscriptionReview() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TranscriptionReviewScreen(
              transcription: _transcription!,
              language: widget.language,
              patientName: widget.patientName,
              duration: widget.duration,
              consultationId: _consultationId!,
              diarization: _diarization,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
            colors: [AppTheme.softSkyBg, AppTheme.paleBlue.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: _errorMessage != null
              ? _buildErrorView()
              : _buildProcessingView(),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Consumer<ConsultationProvider>(
      builder: (context, provider, _) {
        final status = provider.processingStatus;
        final message = provider.processingMessage;

        String displayMessage = message ?? 'Preparing audio...';
        double progress = 0.0;

        switch (status) {
          case ConsultationStatus.pending:
            progress = 0.2;
            break;
          case ConsultationStatus.transcribing:
            progress = 0.6;
            break;
          case ConsultationStatus.generating_report:
            progress = 0.9;
            break;
          case ConsultationStatus.completed:
            progress = 1.0;
            break;
          default:
            progress = 0.1;
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated processing indicator
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: 3.14 * 2 * _progressAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [
                              AppTheme.primarySkyBlue,
                              AppTheme.deepSkyBlue,
                              AppTheme.lightSkyBlue,
                              AppTheme.primarySkyBlue,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primarySkyBlue.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            size: 60,
                            color: AppTheme.primarySkyBlue,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                // Status message
                Text(
                  displayMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Progress bar
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySkyBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 200 * progress,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primarySkyBlue,
                            AppTheme.deepSkyBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Info cards
                _buildInfoCard(
                  icon: Icons.translate_rounded,
                  label: 'Language',
                  value: widget.language,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.timer_rounded,
                  label: 'Duration',
                  value: widget.duration,
                ),
                if (widget.patientName != null &&
                    widget.patientName!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.person_rounded,
                    label: 'Patient',
                    value: widget.patientName!,
                  ),
                ],
                const SizedBox(height: 48),
                // Processing steps
                _buildProcessingSteps(status),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(ConsultationStatus? status) {
    switch (status) {
      case ConsultationStatus.transcribing:
        return Icons.hearing_rounded;
      case ConsultationStatus.generating_report:
        return Icons.description_rounded;
      case ConsultationStatus.completed:
        return Icons.check_circle_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primarySkyBlue, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingSteps(ConsultationStatus? currentStatus) {
    final steps = [
      ('Uploading audio', ConsultationStatus.pending),
      ('Transcribing speech', ConsultationStatus.transcribing),
    ];

    int currentIndex = 0;
    if (currentStatus != null) {
      currentIndex = steps.indexWhere((s) => s.$2 == currentStatus);
      if (currentIndex == -1) currentIndex = 0;
    }

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppTheme.successGreen
                      : isCurrent
                      ? AppTheme.primarySkyBlue
                      : AppTheme.lightGray,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : isCurrent
                      ? Icons.more_horiz_rounded
                      : Icons.circle_outlined,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                step.$1,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isCompleted || isCurrent
                      ? AppTheme.darkSlate
                      : AppTheme.mediumGray,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentCoral.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: AppTheme.accentCoral,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Transcription Failed',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppTheme.mediumGray),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isProcessing = false;
                    });
                    _transcribeAudio();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primarySkyBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Separate screen for report generation after transcription review
class ReportGenerationScreen extends StatefulWidget {
  final String consultationId;
  final String transcription;
  final String language;
  final String? patientName;
  final String duration;
  final ReportTemplate? template;

  const ReportGenerationScreen({
    super.key,
    required this.consultationId,
    required this.transcription,
    required this.language,
    this.patientName,
    required this.duration,
    this.template,
  });

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isProcessing) {
        _isProcessing = true;
        _generateReport();
      }
    });
  }

  Future<void> _generateReport() async {
    final provider = Provider.of<ConsultationProvider>(context, listen: false);

    final result = await provider.generateReportFromTranscription(
      consultationId: widget.consultationId,
      transcription: widget.transcription,
      language: widget.language,
      patientName: widget.patientName,
      templateConfig: widget.template?.config,
    );

    if (!mounted) return;

    if (result.success && result.consultation != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ResultsScreen(consultation: result.consultation!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      setState(() {
        _errorMessage =
            result.error ?? 'Report generation failed. Please try again.';
      });
    }
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
            colors: [AppTheme.softSkyBg, AppTheme.paleBlue.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: _errorMessage != null
              ? _buildErrorView()
              : _buildProcessingView(),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Consumer<ConsultationProvider>(
      builder: (context, provider, _) {
        final message = provider.processingMessage ?? 'Generating report...';

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated processing indicator
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: 3.14 * 2 * _progressAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [
                              AppTheme.successGreen,
                              AppTheme.primarySkyBlue,
                              AppTheme.lightSkyBlue,
                              AppTheme.successGreen,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.successGreen.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 60,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'AI is analyzing the transcription...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: 32),
                // Progress indicator
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: AppTheme.successGreen.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(
                      AppTheme.successGreen,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 48),
                // Info cards
                _buildInfoCard(
                  icon: Icons.description_rounded,
                  label: 'Creating',
                  value: 'Medical Report',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.text_fields_rounded,
                  label: 'Words',
                  value: '${widget.transcription.split(RegExp(r'\s+')).length}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.successGreen, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentCoral.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: AppTheme.accentCoral,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Report Generation Failed',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppTheme.mediumGray),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isProcessing = false;
                    });
                    _generateReport();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primarySkyBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
