import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'language_selection_screen.dart';
import 'reports_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.warmCream,
              AppTheme.softMint.withOpacity(0.5),
              AppTheme.warmCream,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Header with animated entrance
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildHeader(),
                  ),
                ),
                const SizedBox(height: 60),
                // Main action cards
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildActionCards(),
                    ),
                  ),
                ),
                // Bottom decoration
                _buildBottomDecoration(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: AppTheme.primaryTeal,
                size: 32,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Welcome,',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            color: AppTheme.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dr. Vyshali',
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkSlate,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ready to assist your patients today',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            color: AppTheme.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        // New Consultation Card
        Expanded(
          child: _ActionCard(
            title: 'New Consultation',
            subtitle: 'Start recording a patient consultation',
            icon: Icons.mic_rounded,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryTeal, AppTheme.deepTeal],
            ),
            iconBackground: Colors.white.withOpacity(0.2),
            textColor: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LanguageSelectionScreen(),
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
          ),
        ),
        const SizedBox(height: 20),
        // Browse Reports Card
        Expanded(
          child: _ActionCard(
            title: 'Browse Reports',
            subtitle: 'View and manage previous consultations',
            icon: Icons.folder_open_rounded,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            iconBackground: AppTheme.softMint,
            textColor: AppTheme.darkSlate,
            borderColor: Colors.grey.shade200,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ReportsHistoryScreen(),
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
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDecoration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.accentCoral.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color iconBackground;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.iconBackground,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(24),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: widget.borderColor != null
                    ? Colors.black.withOpacity(0.04)
                    : AppTheme.primaryTeal.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.borderColor != null
                      ? AppTheme.primaryTeal
                      : Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: widget.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: widget.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.borderColor != null
                      ? AppTheme.primaryTeal.withOpacity(0.1)
                      : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.borderColor != null
                      ? AppTheme.primaryTeal
                      : Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

