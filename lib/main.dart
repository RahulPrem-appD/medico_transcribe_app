import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
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
      child: const MedicoTranscribeApp(),
    ),
  );
}

class MedicoTranscribeApp extends StatefulWidget {
  const MedicoTranscribeApp({super.key});

  @override
  State<MedicoTranscribeApp> createState() => _MedicoTranscribeAppState();
}

class _MedicoTranscribeAppState extends State<MedicoTranscribeApp> {
  bool _isInitialized = false;
  String? _initError;
  bool _initStarted = false;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Scribe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initError = null;
                      _initStarted = false;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}
