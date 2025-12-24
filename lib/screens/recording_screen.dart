import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/analog_timer.dart';
import 'processing_screen.dart';

class RecordingScreen extends StatefulWidget {
  final String language;
  final String? patientName;
  final String? templateId;

  const RecordingScreen({
    super.key,
    required this.language,
    this.patientName,
    this.templateId,
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
  late Animation<double> _pulseAnimation;
  final List<double> _waveformData = List.generate(40, (_) => 0.3);
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please grant microphone permission to record consultations.',
          style: GoogleFonts.poppins(color: AppTheme.mediumGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.mediumGray),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.poppins(
                color: AppTheme.primarySkyBlue,
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
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProcessingScreen(
              audioFilePath: path,
              language: widget.language,
              patientName: widget.patientName,
              duration: _formatDuration(_recordingSeconds),
              templateId: widget.templateId,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
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
                    AppTheme.softSkyBg,
                    AppTheme.paleBlue.withOpacity(0.3),
                    AppTheme.accentCoral.withOpacity(0.05),
                  ]
                : [
                    AppTheme.softSkyBg,
                    AppTheme.paleBlue.withOpacity(0.5),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primarySkyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: AppTheme.primarySkyBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.language,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primarySkyBlue,
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
          const SizedBox(height: 16),
          // Patient name if provided
          if (widget.patientName != null && widget.patientName!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_rounded,
                    color: AppTheme.primarySkyBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.patientName!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ],
              ),
            ),
          // Analog Timer
          AnalogTimer(
            seconds: _recordingSeconds,
            isRecording: _isRecording,
            isPaused: _isPaused,
            size: 260,
          ),
          const SizedBox(height: 32),
          // Waveform visualization
          SizedBox(
            height: 60,
            child: _buildWaveform(),
          ),
          const SizedBox(height: 24),
          // Instructions or status
          if (!_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
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
                    Icon(
                      _hasPermission
                          ? Icons.tips_and_updates_rounded
                          : Icons.mic_off_rounded,
                      color: _hasPermission
                          ? AppTheme.warningAmber
                          : AppTheme.accentCoral,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasPermission
                          ? 'Tips for better transcription'
                          : 'Microphone permission required',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasPermission
                          ? 'Speak clearly and keep the device close. Minimize background noise for accurate results.'
                          : 'Please grant microphone permission to start recording consultations.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.mediumGray,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_waveformData.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 3,
            height: _isRecording && !_isPaused
                ? _waveformData[index] * 60
                : 12 + (index % 5) * 3.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isRecording && !_isPaused
                    ? [AppTheme.primarySkyBlue, AppTheme.accentCoral]
                    : [
                        AppTheme.primarySkyBlue.withOpacity(0.3),
                        AppTheme.primarySkyBlue.withOpacity(0.1),
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
            const SizedBox(width: 62),
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
                  scale:
                      _isRecording && !_isPaused ? _pulseAnimation.value : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: _isRecording && !_isPaused
                              ? AppTheme.accentCoral.withOpacity(0.4)
                              : AppTheme.primarySkyBlue.withOpacity(0.3),
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
                              ? [AppTheme.accentCoral, AppTheme.accentCoral.withOpacity(0.8)]
                              : [
                                  AppTheme.primarySkyBlue,
                                  AppTheme.deepSkyBlue
                                ],
                        ),
                      ),
                      child: Icon(
                        _isRecording
                            ? (_isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded)
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
            const SizedBox(width: 62),
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to discard this recording? This action cannot be undone.',
          style: GoogleFonts.poppins(color: AppTheme.mediumGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
