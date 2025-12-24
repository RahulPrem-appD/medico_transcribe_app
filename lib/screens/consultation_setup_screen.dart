import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/report_template.dart';
import '../services/template_service.dart';
import 'consent_screen.dart';

class ConsultationSetupScreen extends StatefulWidget {
  const ConsultationSetupScreen({super.key});

  @override
  State<ConsultationSetupScreen> createState() => _ConsultationSetupScreenState();
}

class _ConsultationSetupScreenState extends State<ConsultationSetupScreen>
    with SingleTickerProviderStateMixin {
  final TemplateService _templateService = TemplateService();
  final TextEditingController _patientNameController = TextEditingController();
  
  String? _selectedLanguage;
  String? _selectedTemplateId;
  String? _lastUsedLanguage;
  String? _lastUsedTemplateId;
  
  List<ReportTemplate> _builtInTemplates = [];
  List<ReportTemplate> _customTemplates = [];
  bool _isLoading = true;
  bool _isLanguageExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _languages = [
    {'name': 'Hindi', 'native': 'हिन्दी', 'code': 'hi', 'speakers': '600M+'},
    {'name': 'Tamil', 'native': 'தமிழ்', 'code': 'ta', 'speakers': '80M+'},
    {'name': 'Telugu', 'native': 'తెలుగు', 'code': 'te', 'speakers': '85M+'},
    {'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'code': 'kn', 'speakers': '45M+'},
    {'name': 'Malayalam', 'native': 'മലയാളം', 'code': 'ml', 'speakers': '38M+'},
    {'name': 'Bengali', 'native': 'বাংলা', 'code': 'bn', 'speakers': '230M+'},
    {'name': 'Marathi', 'native': 'मराठी', 'code': 'mr', 'speakers': '95M+'},
    {'name': 'Gujarati', 'native': 'ગુજરાતી', 'code': 'gu', 'speakers': '55M+'},
    {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'code': 'pa', 'speakers': '125M+'},
    {'name': 'Odia', 'native': 'ଓଡ଼ିଆ', 'code': 'or', 'speakers': '38M+'},
    {'name': 'Assamese', 'native': 'অসমীয়া', 'code': 'as', 'speakers': '15M+'},
    {'name': 'English', 'native': 'English', 'code': 'en', 'speakers': '125M+'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    await _templateService.initialize();
    final customTemplates = await _templateService.getCustomTemplates();
    final lastUsedTemplateId = await _templateService.getLastUsedTemplateId();
    final lastUsedLanguage = await _templateService.getLastUsedLanguage();

    setState(() {
      _builtInTemplates = BuiltInTemplates.templates;
      _customTemplates = customTemplates;
      _lastUsedTemplateId = lastUsedTemplateId;
      _lastUsedLanguage = lastUsedLanguage;
      _selectedTemplateId = lastUsedTemplateId ?? 'standard';
      _selectedLanguage = lastUsedLanguage;
      _isLoading = false;
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedLanguageData {
    if (_selectedLanguage == null) return null;
    try {
      return _languages.firstWhere((l) => l['name'] == _selectedLanguage);
    } catch (e) {
      return null;
    }
  }

  Future<void> _startRecording() async {
    if (_selectedLanguage == null || _selectedTemplateId == null) return;

    // Save last used selections
    await _templateService.setLastUsedLanguage(_selectedLanguage!);
    await _templateService.setLastUsedTemplateId(_selectedTemplateId!);

    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ConsentScreen(
          language: _selectedLanguage!,
          patientName: _patientNameController.text.isNotEmpty
              ? _patientNameController.text
              : null,
          templateId: _selectedTemplateId,
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildContent(),
                      ),
                    ),
                    if (isKeyboardOpen) _buildBottomBar(),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: isKeyboardOpen ? null : _buildBottomBar(),
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
                'New Consultation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
          ),
          const SizedBox(width: 46),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Patient name input
          _buildPatientNameSection(),
          const SizedBox(height: 20),
          
          // Language selection
          _buildLanguageSection(),
          const SizedBox(height: 20),
          
          // Template selection
          _buildTemplateSection(),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPatientNameSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Patient Name',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(Optional)',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _patientNameController,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: AppTheme.darkSlate,
            ),
            decoration: InputDecoration(
              hintText: 'Enter patient name',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 16,
                color: AppTheme.mediumGray.withOpacity(0.6),
              ),
              filled: true,
              fillColor: AppTheme.lightGray.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    final selectedData = _selectedLanguageData;
    final isLastUsed = _selectedLanguage == _lastUsedLanguage && _lastUsedLanguage != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - always visible
          GestureDetector(
            onTap: () {
              setState(() {
                _isLanguageExpanded = !_isLanguageExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primarySkyBlue, AppTheme.deepSkyBlue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Language',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                            if (isLastUsed) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Last used',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (selectedData != null)
                          Text(
                            '${selectedData['native']} (${selectedData['name']})',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppTheme.primarySkyBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            'Tap to select language',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isLanguageExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.mediumGray,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable language list
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildLanguageList(),
            crossFadeState: _isLanguageExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppTheme.lightGray.withOpacity(0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages.map((language) {
              final isSelected = _selectedLanguage == language['name'];
              final isLastUsedLang = language['name'] == _lastUsedLanguage;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLanguage = language['name'];
                    _isLanguageExpanded = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primarySkyBlue 
                        : AppTheme.lightGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: isLastUsedLang && !isSelected
                        ? Border.all(color: AppTheme.successGreen.withOpacity(0.5), width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        language['native'],
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        language['name'],
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: isSelected 
                              ? Colors.white.withOpacity(0.8) 
                              : AppTheme.mediumGray,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accentCoral, AppTheme.accentCoral.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Template',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose format for the medical report',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Template options
          ..._builtInTemplates.map((template) => _buildTemplateOption(template)),
          
          if (_customTemplates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'My Templates',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: 8),
            ..._customTemplates.map((template) => _buildTemplateOption(template, isCustom: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateOption(ReportTemplate template, {bool isCustom = false}) {
    final isSelected = _selectedTemplateId == template.id;
    final isLastUsed = template.id == _lastUsedTemplateId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplateId = template.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryTeal.withOpacity(0.08) 
              : AppTheme.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryTeal.withOpacity(0.15) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(template.icon),
                color: isSelected ? AppTheme.primaryTeal : AppTheme.mediumGray,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                      ),
                      if (isLastUsed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Last used',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.mediumGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.primaryTeal 
                      : AppTheme.mediumGray.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canProceed = _selectedLanguage != null && _selectedTemplateId != null;

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
        child: AnimatedOpacity(
          opacity: canProceed ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: canProceed ? _startRecording : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primaryTeal.withOpacity(0.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  canProceed ? 'Start Recording' : 'Select language & template',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (canProceed) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.mic_rounded, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'description':
        return Icons.description_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'update':
        return Icons.update_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'send':
        return Icons.send_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}

