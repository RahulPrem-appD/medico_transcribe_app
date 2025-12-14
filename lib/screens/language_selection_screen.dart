import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'recording_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedLanguage;
  final TextEditingController _patientNameController = TextEditingController();
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
      duration: const Duration(milliseconds: 800),
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
    _patientNameController.dispose();
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
      bottomNavigationBar: _buildBottomBar(),
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
          const SizedBox(width: 46), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Patient name input
          Container(
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
          ),
          const SizedBox(height: 24),
          // Language selection header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryTeal, AppTheme.deepTeal],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
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
                        'Choose Language',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the language for this consultation',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Popular languages section
          Text(
            'Popular Languages',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 16),
          _buildLanguageGrid(_languages.take(4).toList()),
          const SizedBox(height: 28),
          // All languages section
          Text(
            'All Languages',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 16),
          _buildLanguageGrid(_languages.skip(4).toList()),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildLanguageGrid(List<Map<String, dynamic>> languages) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final language = languages[index];
        final isSelected = _selectedLanguage == language['name'];
        return _LanguageCard(
          name: language['name'],
          nativeName: language['native'],
          speakers: language['speakers'],
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedLanguage = language['name'];
            });
          },
          delay: Duration(milliseconds: 50 * index),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          opacity: _selectedLanguage != null ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: _selectedLanguage != null
                ? () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            RecordingScreen(
                              language: _selectedLanguage!,
                              patientName: _patientNameController.text.isNotEmpty
                                  ? _patientNameController.text
                                  : null,
                            ),
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
                  }
                : null,
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
                  _selectedLanguage != null
                      ? 'Start Recording'
                      : 'Select a language',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedLanguage != null) ...[
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
}

class _LanguageCard extends StatefulWidget {
  final String name;
  final String nativeName;
  final String speakers;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration delay;

  const _LanguageCard({
    required this.name,
    required this.nativeName,
    required this.speakers,
    required this.isSelected,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
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

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isSelected ? AppTheme.primaryTeal : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isSelected
                    ? AppTheme.primaryTeal
                    : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? AppTheme.primaryTeal.withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: widget.isSelected ? 15 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.nativeName,
                        style: GoogleFonts.notoSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? Colors.white
                              : AppTheme.darkSlate,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppTheme.primaryTeal,
                          size: 14,
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.9)
                            : AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.speakers} speakers',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.7)
                            : AppTheme.mediumGray.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
