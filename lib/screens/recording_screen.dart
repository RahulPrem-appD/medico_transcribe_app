import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import 'processing_screen.dart';

class RecordingScreen extends StatefulWidget {
  final String language;
  final String? patientName;

  const RecordingScreen({
    super.key,
    required this.language,
    this.patientName,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  late final AudioRecorder _recorder;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasPermission = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _recordingPath;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  final List<double> _waveformData = List.generate(50, (_) => 0.3);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (!status.isGranted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Microphone Permission Required',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please grant microphone permission to record consultations.',
          style: GoogleFonts.dmSans(color: AppTheme.mediumGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppTheme.mediumGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.dmSans(
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      _showPermissionDialog();
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/recording_$timestamp.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
      });
      
      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
          // Simulate waveform data
          for (int i = 0; i < _waveformData.length; i++) {
            _waveformData[i] = 0.2 + _random.nextDouble() * 0.6;
          }
        });
      });
    } catch (e) {
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();
      setState(() {
        _isPaused = true;
      });
      _pulseController.stop();
      _timer?.cancel();
    } catch (e) {
      _showErrorSnackBar('Failed to pause recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resume();
      setState(() {
        _isPaused = false;
      });
      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
          for (int i = 0; i < _waveformData.length; i++) {
            _waveformData[i] = 0.2 + _random.nextDouble() * 0.6;
          }
        });
      });
    } catch (e) {
      _showErrorSnackBar('Failed to resume recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();

    try {
      final path = await _recorder.stop();
      
      if (path != null && mounted) {
        // Navigate to processing screen
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProcessingScreen(
                  audioFilePath: path,
                  language: widget.language,
                  patientName: widget.patientName,
                  duration: _formatDuration(_recordingSeconds),
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentCoral,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isRecording && !_isPaused
                ? [
                    AppTheme.primaryTeal.withOpacity(0.1),
                    AppTheme.warmCream,
                    AppTheme.accentCoral.withOpacity(0.05),
                  ]
                : [
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
                child: _buildContent(),
              ),
              _buildControls(),
              const SizedBox(height: 40),
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
            onTap: () {
              if (_isRecording) {
                _showExitDialog();
              } else {
                Navigator.pop(context);
              }
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
                Icons.close_rounded,
                color: AppTheme.darkSlate,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.translate_rounded,
                      color: AppTheme.primaryTeal,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.language,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Patient name if provided
          if (widget.patientName != null && widget.patientName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Patient: ${widget.patientName}',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: AppTheme.mediumGray,
                ),
              ),
            ),
          // Status indicator
          AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isRecording
              ? Container(
                  key: const ValueKey('recording'),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isPaused
                        ? AppTheme.warningAmber.withOpacity(0.1)
                        : AppTheme.accentCoral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isPaused
                              ? AppTheme.warningAmber
                              : AppTheme.accentCoral,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isPaused ? 'Paused' : 'Recording',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isPaused
                              ? AppTheme.warningAmber
                              : AppTheme.accentCoral,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  key: const ValueKey('ready'),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _hasPermission
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.accentCoral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _hasPermission
                              ? AppTheme.successGreen
                              : AppTheme.accentCoral,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _hasPermission ? 'Ready to record' : 'Permission required',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _hasPermission
                              ? AppTheme.successGreen
                              : AppTheme.accentCoral,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        // Timer display
        Text(
          _formatDuration(_recordingSeconds),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 52,
            fontWeight: FontWeight.w300,
            color: AppTheme.darkSlate,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Duration',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.mediumGray,
          ),
        ),
        const SizedBox(height: 30),
        // Waveform visualization
        SizedBox(
          height: 80,
          child: _buildWaveform(),
        ),
        const SizedBox(height: 30),
        // Instructions
        if (!_isRecording)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Container(
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
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        color: AppTheme.warningAmber,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tips for better transcription',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Speak clearly and keep the device close. Minimize background noise for accurate results.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppTheme.mediumGray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_waveformData.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 4,
            height: _isRecording && !_isPaused
                ? _waveformData[index] * 100
                : 20 + (index % 5) * 4.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isRecording && !_isPaused
                    ? [AppTheme.primaryTeal, AppTheme.accentCoral]
                    : [
                        AppTheme.primaryTeal.withOpacity(0.3),
                        AppTheme.primaryTeal.withOpacity(0.1),
                      ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cancel/Reset button
          if (_isRecording)
            GestureDetector(
              onTap: _showExitDialog,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.mediumGray,
                  size: 26,
                ),
              ),
            )
          else
            const SizedBox(width: 60),
          // Main record button
          GestureDetector(
            onTap: () {
              if (!_isRecording) {
                _startRecording();
              } else if (_isPaused) {
                _resumeRecording();
              } else {
                _pauseRecording();
              }
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording && !_isPaused ? _pulseAnimation.value : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: _isRecording && !_isPaused
                              ? AppTheme.accentCoral.withOpacity(0.4)
                              : AppTheme.primaryTeal.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isRecording && !_isPaused
                              ? [AppTheme.accentCoral, const Color(0xFFFF7B7B)]
                              : [AppTheme.primaryTeal, AppTheme.deepTeal],
                        ),
                      ),
                      child: Icon(
                        _isRecording
                            ? (_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded)
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Stop/Done button
          if (_isRecording)
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successGreen.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Discard Recording?',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to discard this recording? This action cannot be undone.',
          style: GoogleFonts.dmSans(
            color: AppTheme.mediumGray,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: AppTheme.mediumGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _recorder.stop();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Discard',
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
}
