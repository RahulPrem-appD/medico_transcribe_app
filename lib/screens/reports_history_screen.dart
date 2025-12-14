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
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];

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

  List<Consultation> _filterConsultations(List<Consultation> consultations) {
    var filtered = consultations;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        final searchLower = _searchQuery.toLowerCase();
        return (c.patientName?.toLowerCase().contains(searchLower) ?? false) ||
            (c.report?.chiefComplaint.toLowerCase().contains(searchLower) ?? false) ||
            (c.report?.diagnosis.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }
    
    // Filter by time
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        filtered = filtered.where((c) =>
            c.createdAt.day == now.day &&
            c.createdAt.month == now.month &&
            c.createdAt.year == now.year).toList();
        break;
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((c) => c.createdAt.isAfter(weekAgo)).toList();
        break;
      case 'This Month':
        filtered = filtered.where((c) =>
            c.createdAt.month == now.month && c.createdAt.year == now.year).toList();
        break;
    }
    
    return filtered;
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
                'Previous Reports',
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
                color: AppTheme.primaryTeal,
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
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryTeal),
            ),
          );
        }

        final filteredConsultations = _filterConsultations(provider.consultations);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${filteredConsultations.length} ${filteredConsultations.length == 1 ? 'Report' : 'Reports'}',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        color: AppTheme.primaryTeal,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recent',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredConsultations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredConsultations.length,
                      itemBuilder: (context, index) {
                        return _ConsultationCard(
                          consultation: filteredConsultations[index],
                          delay: Duration(milliseconds: 100 * index),
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    ReportDetailScreen(consultation: filteredConsultations[index]),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
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
                          onDelete: () async {
                            final confirmed = await _showDeleteConfirmation();
                            if (confirmed == true) {
                              await provider.deleteConsultation(filteredConsultations[index].id);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
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
  }

  Widget _buildSearchBar() {
    return Container(
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
        style: GoogleFonts.dmSans(
          fontSize: 16,
          color: AppTheme.darkSlate,
        ),
        decoration: InputDecoration(
          hintText: 'Search by patient, complaint, or diagnosis...',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.mediumGray.withOpacity(0.7),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.mediumGray,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryTeal : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryTeal : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.mediumGray,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
              color: AppTheme.primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: AppTheme.primaryTeal,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Reports Found',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Start a new consultation to create your first report',
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
}

class _ConsultationCard extends StatefulWidget {
  final Consultation consultation;
  final Duration delay;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConsultationCard({
    required this.consultation,
    required this.delay,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ConsultationCard> createState() => _ConsultationCardState();
}

class _ConsultationCardState extends State<_ConsultationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dateTime.day} ${months[dateTime.month - 1]}';
    }
  }

  Color _getLanguageColor(String language) {
    final colors = {
      'Hindi': const Color(0xFFFF6B6B),
      'Tamil': const Color(0xFF4ECDC4),
      'Telugu': const Color(0xFFFFE66D),
      'Kannada': const Color(0xFF95E1D3),
      'Malayalam': const Color(0xFFF38181),
      'Bengali': const Color(0xFFAA96DA),
      'Marathi': const Color(0xFFFFAA64),
      'Gujarati': const Color(0xFF81C784),
      'Punjabi': const Color(0xFF64B5F6),
      'English': const Color(0xFF90A4AE),
    };
    return colors[language] ?? AppTheme.primaryTeal;
  }

  Color _getStatusColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.completed:
        return AppTheme.successGreen;
      case ConsultationStatus.failed:
        return AppTheme.accentCoral;
      case ConsultationStatus.transcribing:
      case ConsultationStatus.generating_report:
        return AppTheme.warningAmber;
      default:
        return AppTheme.mediumGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;
    final report = consultation.report;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          onLongPress: widget.onDelete,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                      // Patient avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryTeal.withOpacity(0.8),
                              AppTheme.deepTeal,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            (consultation.patientName ?? 'P')[0].toUpperCase(),
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              consultation.patientName ?? 'Unknown Patient',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getLanguageColor(consultation.language)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    consultation.language,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getLanguageColor(consultation.language),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(consultation.status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    consultation.statusDisplayText,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(consultation.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDateTime(consultation.createdAt),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.mediumGray,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (report != null) ...[
                    const SizedBox(height: 16),
                    // Chief complaint preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCoral.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: AppTheme.accentCoral,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chief Complaint',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  report.chiefComplaint.isNotEmpty 
                                      ? report.chiefComplaint 
                                      : 'Not documented',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Diagnosis preview
                    Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppTheme.primaryTeal,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report.diagnosis.isNotEmpty 
                                ? report.diagnosis 
                                : 'Diagnosis pending',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (consultation.status == ConsultationStatus.failed) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCoral.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.accentCoral,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              consultation.errorMessage ?? 'Processing failed',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.accentCoral,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
