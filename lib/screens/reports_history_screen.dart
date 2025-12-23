import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/consultation.dart';
import '../providers/consultation_provider.dart';
import 'report_detail_screen.dart';

class ReportsHistoryScreen extends StatefulWidget {
  const ReportsHistoryScreen({super.key});

  @override
  State<ReportsHistoryScreen> createState() => _ReportsHistoryScreenState();
}

class _ReportsHistoryScreenState extends State<ReportsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    // Load consultations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConsultationProvider>(context, listen: false).loadConsultations();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Group consultations by patient
  Map<String, List<Consultation>> _groupByPatient(List<Consultation> consultations) {
    final Map<String, List<Consultation>> grouped = {};
    
    for (final consultation in consultations) {
      // Get patient name from consultation or report sections
      String patientName = consultation.patientName ?? '';
      
      // Try to get from report sections if empty
      if (patientName.isEmpty && consultation.report != null) {
        final sections = consultation.report!.sections;
        patientName = sections['patient_name'] ?? '';
      }
      
      // Default name if still empty
      if (patientName.isEmpty) {
        patientName = 'Unknown Patient';
      }
      
      // Create unique key using name (normalized)
      final key = patientName.trim().toLowerCase();
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(consultation);
    }
    
    return grouped;
  }

  /// Get patient details from their consultations
  Map<String, String> _getPatientDetails(List<Consultation> consultations) {
    // Use the most recent consultation for details
    for (final consultation in consultations) {
      if (consultation.report != null) {
        final sections = consultation.report!.sections;
        return {
          'name': sections['patient_name'] ?? consultation.patientName ?? 'Unknown Patient',
          'age': sections['age'] ?? '',
          'gender': sections['gender'] ?? '',
          'blood_group': sections['blood_group'] ?? '',
          'phone': sections['phone'] ?? '',
        };
      }
    }
    
    // Fallback to consultation data
    final first = consultations.first;
    return {
      'name': first.patientName ?? 'Unknown Patient',
      'age': '',
      'gender': '',
      'blood_group': '',
      'phone': '',
    };
  }

  /// Check if a consultation matches the search query
  bool _consultationMatchesQuery(Consultation c, String query) {
    final report = c.report;
    if (report == null) return false;
    
    final sections = report.sections;
    
    // Search in all section values
    for (final value in sections.values) {
      if (value.toLowerCase().contains(query)) {
        return true;
      }
    }
    
    // Also check legacy fields
    if (report.chiefComplaint.toLowerCase().contains(query)) return true;
    if (report.diagnosis.toLowerCase().contains(query)) return true;
    if (report.symptoms.toLowerCase().contains(query)) return true;
    if (report.prescription.toLowerCase().contains(query)) return true;
    if (report.additionalNotes.toLowerCase().contains(query)) return true;
    
    // Check transcription
    if (c.transcription?.toLowerCase().contains(query) ?? false) return true;
    
    // Check consultation ID
    if (c.id.toLowerCase().contains(query)) return true;
    
    // Check language
    if (c.language.toLowerCase().contains(query)) return true;
    
    return false;
  }

  List<MapEntry<String, List<Consultation>>> _filterPatients(
    Map<String, List<Consultation>> grouped,
  ) {
    if (_searchQuery.isEmpty) {
      return grouped.entries.toList()
        ..sort((a, b) {
          // Sort by most recent consultation
          final aLatest = a.value.first.createdAt;
          final bLatest = b.value.first.createdAt;
          return bLatest.compareTo(aLatest);
        });
    }
    
    final query = _searchQuery.toLowerCase();
    return grouped.entries.where((entry) {
      final details = _getPatientDetails(entry.value);
      
      // Search in patient details
      if (details['name']!.toLowerCase().contains(query)) return true;
      if (details['phone']!.contains(query)) return true;
      if (details['age']!.contains(query)) return true;
      if (details['gender']!.toLowerCase().contains(query)) return true;
      if (details['blood_group']!.toLowerCase().contains(query)) return true;
      
      // Search in any of the patient's consultations
      return entry.value.any((c) => _consultationMatchesQuery(c, query));
    }).toList()
      ..sort((a, b) {
        final aLatest = a.value.first.createdAt;
        final bLatest = b.value.first.createdAt;
        return bLatest.compareTo(aLatest);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softSkyBg,
      body: SafeArea(
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
          Expanded(
            child: Center(
              child: Text(
                'Patient Reports',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Provider.of<ConsultationProvider>(context, listen: false).loadConsultations();
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
                Icons.refresh_rounded,
                color: AppTheme.primarySkyBlue,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<ConsultationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primarySkyBlue),
            ),
          );
        }

        final grouped = _groupByPatient(provider.consultations);
        final filteredPatients = _filterPatients(grouped);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySkyBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      color: AppTheme.primarySkyBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${filteredPatients.length} ${filteredPatients.length == 1 ? 'Patient' : 'Patients'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${provider.consultations.length} total reports',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredPatients.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        final entry = filteredPatients[index];
                        final patientDetails = _getPatientDetails(entry.value);
                        return _PatientCard(
                          patientDetails: patientDetails,
                          consultations: entry.value,
                          delay: Duration(milliseconds: 80 * index),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppTheme.darkSlate,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name, diagnosis, symptoms...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.mediumGray.withOpacity(0.7),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.mediumGray,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: const Icon(
                        Icons.clear_rounded,
                        color: AppTheme.mediumGray,
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_searchQuery.isEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildSearchHint('Name'),
                _buildSearchHint('Phone'),
                _buildSearchHint('Diagnosis'),
                _buildSearchHint('Symptoms'),
                _buildSearchHint('Prescription'),
                _buildSearchHint('Language'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchHint(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: AppTheme.mediumGray,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primarySkyBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: AppTheme.primarySkyBlue,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Patients Found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Start a new consultation to create your first report',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient Card - Shows patient info and expands to show reports
class _PatientCard extends StatefulWidget {
  final Map<String, String> patientDetails;
  final List<Consultation> consultations;
  final Duration delay;

  const _PatientCard({
    required this.patientDetails,
    required this.consultations,
    required this.delay,
  });

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'P';
  }

  // Helper to check if a value is valid (not empty and not "Not documented")
  bool _isValidValue(String value) {
    return value.isNotEmpty && 
           value.toLowerCase() != 'not documented' && 
           value.toLowerCase() != 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.patientDetails['name'] ?? 'Unknown';
    final rawAge = widget.patientDetails['age'] ?? '';
    final rawGender = widget.patientDetails['gender'] ?? '';
    final rawBloodGroup = widget.patientDetails['blood_group'] ?? '';
    final rawPhone = widget.patientDetails['phone'] ?? '';
    final reportCount = widget.consultations.length;
    
    // Filter out "Not documented" values
    final age = _isValidValue(rawAge) ? rawAge : '';
    final gender = _isValidValue(rawGender) ? rawGender : '';
    final bloodGroup = _isValidValue(rawBloodGroup) ? rawBloodGroup : '';
    final phone = _isValidValue(rawPhone) ? rawPhone : '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
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
              // Patient Header
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primarySkyBlue,
                              AppTheme.deepSkyBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(name),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (age.isNotEmpty || gender.isNotEmpty)
                                  _buildTag(
                                    '${age.isNotEmpty ? "${age}y" : ""}${age.isNotEmpty && gender.isNotEmpty ? ", " : ""}$gender',
                                    AppTheme.mediumGray,
                                  ),
                                if (bloodGroup.isNotEmpty)
                                  _buildTag(bloodGroup, AppTheme.accentCoral),
                              ],
                            ),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 12, color: AppTheme.mediumGray),
                                  const SizedBox(width: 4),
                                  Text(
                                    phone,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Report count & expand icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_rounded,
                                  size: 14,
                                  color: AppTheme.successGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$reportCount',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.mediumGray,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded Reports List
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildReportsList(),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildReportsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Divider(height: 1, color: AppTheme.lightGray),
          ...widget.consultations.asMap().entries.map((entry) {
            final index = entry.key;
            final consultation = entry.value;
            return _buildReportItem(consultation, index == widget.consultations.length - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildReportItem(Consultation consultation, bool isLast) {
    final report = consultation.report;
    final chiefComplaint = report?.chiefComplaint ?? 
                           report?.sections['chief_complaint'] ?? 
                           'No complaint recorded';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ReportDetailScreen(consultation: consultation),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            // Date indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${consultation.createdAt.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSlate,
                      height: 1,
                    ),
                  ),
                  Text(
                    _getMonthAbbr(consultation.createdAt.month),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mediumGray,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Report details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chiefComplaint.length > 50 
                        ? '${chiefComplaint.substring(0, 50)}...'
                        : chiefComplaint,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: AppTheme.mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(consultation.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getLanguageColor(consultation.language).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          consultation.language,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _getLanguageColor(consultation.language),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.mediumGray,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Color _getLanguageColor(String language) {
    final colors = {
      'Hindi': AppTheme.primarySkyBlue,
      'Tamil': AppTheme.deepSkyBlue,
      'Telugu': AppTheme.lightSkyBlue,
      'Kannada': AppTheme.accentBlue,
      'Malayalam': AppTheme.primarySkyBlue,
      'Bengali': AppTheme.deepSkyBlue,
      'Marathi': AppTheme.lightSkyBlue,
      'Gujarati': AppTheme.accentBlue,
      'Punjabi': AppTheme.primarySkyBlue,
      'English': AppTheme.deepSkyBlue,
    };
    return colors[language] ?? AppTheme.primarySkyBlue;
  }
}
