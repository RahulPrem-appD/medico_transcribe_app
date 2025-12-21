import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/consultation_service.dart';
import 'providers/consultation_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final consultationService = ConsultationService();
  final themeProvider = ThemeProvider();

  // Initialize theme preferences
  await themeProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConsultationProvider(consultationService),
        ),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const DoctorScribeApp(),
    ),
  );
}

class DoctorScribeApp extends StatefulWidget {
  const DoctorScribeApp({super.key});

  @override
  State<DoctorScribeApp> createState() => _DoctorScribeAppState();
}

class _DoctorScribeAppState extends State<DoctorScribeApp> {
  bool _isInitialized = false;
  String? _initError;
  bool _initStarted = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initStarted) {
      _initStarted = true;
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    try {
      final provider = Provider.of<ConsultationProvider>(
        context,
        listen: false,
      );
      await provider.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  void _onSplashComplete() {
    _navigatorKey.currentState?.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _updateSystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark
            ? AppTheme.darkBackground
            : Colors.white,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Update system UI based on theme
        final isDark =
            themeProvider.themeMode == AppThemeMode.dark ||
            (themeProvider.themeMode == AppThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateSystemUI(isDark);
        });

        return MaterialApp(
          title: 'Doctor Scribe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(
            primaryColor: themeProvider.primaryColor,
            secondaryColor: themeProvider.secondaryColor,
          ),
          darkTheme: AppTheme.darkTheme(
            primaryColor: themeProvider.primaryColor,
            secondaryColor: themeProvider.secondaryColor,
          ),
          themeMode: themeProvider.materialThemeMode,
          navigatorKey: _navigatorKey,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == AppThemeMode.dark;

    if (_initError != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.darkBackground, AppTheme.darkSurface],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.softSkyBg,
                      AppTheme.paleBlue.withOpacity(0.5),
                      Colors.white,
                    ],
                  ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCoral.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.accentCoral,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Initialization Error',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkText : AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _initError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.mediumGray,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initError = null;
                        _initStarted = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.darkBackground, AppTheme.darkSurface],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.softSkyBg,
                      AppTheme.paleBlue.withOpacity(0.5),
                      Colors.white,
                    ],
                  ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeProvider.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.mediumGray,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show splash screen which will navigate to home screen
    return SplashScreen(onComplete: _onSplashComplete);
  }
}
