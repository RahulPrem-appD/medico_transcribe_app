import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/consultation_service.dart';
import 'providers/consultation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize services
  final consultationService = ConsultationService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConsultationProvider(consultationService),
        ),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Scribe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: _navigatorKey,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_initError != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
                  const Text(
                    'Initialization Error',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.mediumGray,
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
                      backgroundColor: AppTheme.primarySkyBlue,
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
            gradient: LinearGradient(
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
                    AppTheme.primarySkyBlue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Initializing...',
                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 16),
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
