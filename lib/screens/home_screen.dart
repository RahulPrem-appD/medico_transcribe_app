import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/elephant_logo.dart';
import 'language_selection_screen.dart';
import 'reports_history_screen.dart';
import 'template_manager_screen.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Continuous pulse for mic button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Floating animation for decorative elements
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background with subtle pattern
          _buildBackground(size),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top section with header
                _buildTopSection(),

                // Main content area
                Expanded(child: _buildMainContent(size)),
              ],
            ),
          ),

          // Floating decorative orbs
          _buildFloatingOrbs(size),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FBFF), Color(0xFFEDF5FF), Color(0xFFF0F4F8)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: CustomPaint(size: size, painter: _GridPatternPainter()),
    );
  }

  Widget _buildFloatingOrbs(Size size) {
    return IgnorePointer(
      // IMPORTANT: Prevents orbs from blocking touch events
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Top right orb
              Positioned(
                top: -60 + _floatAnimation.value,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primarySkyBlue.withOpacity(0.15),
                        AppTheme.primarySkyBlue.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom left orb
              Positioned(
                bottom: 100 - _floatAnimation.value,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.deepSkyBlue.withOpacity(0.1),
                        AppTheme.deepSkyBlue.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          children: [
            // Logo and branding
            Hero(
              tag: 'app_logo',
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primarySkyBlue.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const ElephantLogo(size: 44),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doctor Scribe',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSlate,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.successGreen.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Ready',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Settings/Profile button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.tune_rounded,
                color: AppTheme.mediumGray,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(Size size) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Welcome message
              _buildWelcomeSection(),

              const SizedBox(height: 40),

              // Main CTA - New Consultation
              _buildMainCTA(),

              const Spacer(),

              // Quick actions grid
              _buildQuickActions(),

              const SizedBox(height: 24),

              // Bottom stats bar
              _buildStatsBar(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_rounded;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(greetingIcon, color: AppTheme.warningAmber, size: 20),
            const SizedBox(width: 8),
            Text(
              greeting,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Dr. Vyshali',
          style: GoogleFonts.outfit(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkSlate,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ready to capture your consultations',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: AppTheme.mediumGray,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCTA() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LanguageSelectionScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primarySkyBlue.withOpacity(0.15),
                    AppTheme.deepSkyBlue.withOpacity(0.08),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primarySkyBlue.withOpacity(0.25),
                      AppTheme.deepSkyBlue.withOpacity(0.15),
                    ],
                  ),
                ),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5B9EE1),
                        AppTheme.primarySkyBlue,
                        AppTheme.deepSkyBlue,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primarySkyBlue.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: AppTheme.deepSkyBlue.withOpacity(0.2),
                        blurRadius: 60,
                        offset: const Offset(0, 25),
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'START',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 130, // Fixed height to ensure buttons are visible and fit content
      child: Row(
        children: [
          Expanded(
            child: _QuickActionTile(
              icon: Icons.folder_copy_rounded,
              label: 'Reports',
              sublabel: 'View history',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsHistoryScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _QuickActionTile(
              icon: Icons.article_rounded,
              label: 'Templates',
              sublabel: 'Customize',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateManagerScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _QuickActionTile(
              icon: Icons.sticky_note_2_rounded,
              label: 'Notes',
              sublabel: 'Quick notes',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotesScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Today', '0', Icons.calendar_today_rounded),
          _buildStatDivider(),
          _buildStatItem('This Week', '0', Icons.date_range_rounded),
          _buildStatDivider(),
          _buildStatItem('Total', '0', Icons.bar_chart_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primarySkyBlue),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 30, color: AppTheme.lightGray);
  }
}

/// Quick action tile widget
class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  final bool isDisabled;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isDisabled
        ? AppTheme.mediumGray.withOpacity(0.5)
        : widget.color;

    return InkWell(
      onTap: widget.isDisabled ? null : widget.onTap,
      onTapDown: widget.isDisabled
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isDisabled
          ? null
          : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.isDisabled
          ? null
          : () => setState(() => _isPressed = false),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: widget.isDisabled ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: effectiveColor.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: effectiveColor, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.sublabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.mediumGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for subtle grid pattern
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primarySkyBlue.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 30.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
