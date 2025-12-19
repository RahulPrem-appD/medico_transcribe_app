import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'processing_screen.dart';

class TranscriptionReviewScreen extends StatefulWidget {
  final String transcription;
  final String language;
  final String? patientName;
  final String duration;
  final String consultationId;
  final List<dynamic>? diarization;

  const TranscriptionReviewScreen({
    super.key,
    required this.transcription,
    required this.language,
    this.patientName,
    required this.duration,
    required this.consultationId,
    this.diarization,
  });

  @override
  State<TranscriptionReviewScreen> createState() =>
      _TranscriptionReviewScreenState();
}

class _TranscriptionReviewScreenState extends State<TranscriptionReviewScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _transcriptionController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isEditing = false;
  bool _hasChanges = false;
  final FocusNode _focusNode = FocusNode();

  // Parsed diarization data
  List<Map<String, dynamic>> _parsedDiarization = [];

  // Custom speaker names (user can rename these)
  Map<String, String> _speakerNames = {};

  // Speaker colors for chat display
  static const Map<int, Color> _speakerColors = {
    1: Color(0xFF4A90D9), // Speaker 1 - Sky Blue
    2: Color(0xFF34D399), // Speaker 2 - Green
    3: Color(0xFFF59E0B), // Speaker 3 - Amber
    4: Color(0xFF8B5CF6), // Speaker 4 - Purple
  };

  // Default speaker labels
  static const Map<int, String> _defaultSpeakerLabels = {
    1: 'Speaker 1',
    2: 'Speaker 2',
    3: 'Speaker 3',
    4: 'Speaker 4',
  };

  @override
  void initState() {
    super.initState();

    // Parse diarization data first
    _parseDiarization();

    // Initialize transcription controller with formatted diarization text
    _transcriptionController = TextEditingController(
      text: _getFormattedTranscription(),
    );
    _transcriptionController.addListener(_onTextChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _parseDiarization() {
    if (widget.diarization != null && widget.diarization!.isNotEmpty) {
      _parsedDiarization = widget.diarization!.map((d) {
        return Map<String, dynamic>.from(d as Map);
      }).toList();

      // Initialize default speaker names
      final speakers = _parsedDiarization
          .map((d) => (d['speaker_id'] ?? d['speaker']) as String?)
          .whereType<String>()
          .toSet();

      for (final speaker in speakers) {
        final num = _getSpeakerNumber(speaker);
        _speakerNames[speaker] = _defaultSpeakerLabels[num] ?? 'Speaker $num';
      }
    }
  }

  // Get formatted transcription text for editing
  String _getFormattedTranscription() {
    if (_parsedDiarization.isEmpty) {
      return widget.transcription;
    }

    // Format as conversation text
    final buffer = StringBuffer();
    for (final segment in _parsedDiarization) {
      final speakerId =
          (segment['speaker_id'] ?? segment['speaker']) as String?;
      final text = (segment['transcript'] ?? segment['text'] ?? '')
          .toString()
          .trim();
      final label = _getSpeakerLabel(speakerId);
      buffer.writeln('$label: $text');
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  // Update transcription text when speaker names change
  void _updateTranscriptionText() {
    final newText = _getFormattedTranscription();
    _transcriptionController.text = newText;
  }

  int _getSpeakerNumber(String? speakerId) {
    if (speakerId == null) return 1;
    // Handle speaker_1, speaker_2 format from API
    if (speakerId == 'speaker_1') return 1;
    if (speakerId == 'speaker_2') return 2;
    // Try to extract number from string
    final match = RegExp(r'(\d+)').firstMatch(speakerId);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    final lowerSpeaker = speakerId.toLowerCase();
    if (lowerSpeaker.contains('doctor') || lowerSpeaker.contains('1')) return 1;
    if (lowerSpeaker.contains('patient') || lowerSpeaker.contains('2'))
      return 2;
    return 1;
  }

  Color _getSpeakerColor(String? speakerId) {
    final num = _getSpeakerNumber(speakerId);
    return _speakerColors[num] ?? _speakerColors[1]!;
  }

  String _getSpeakerLabel(String? speakerId) {
    if (speakerId == null) return 'Unknown';
    // Return custom name if set, otherwise default
    return _speakerNames[speakerId] ??
        _defaultSpeakerLabels[_getSpeakerNumber(speakerId)] ??
        'Speaker';
  }

  void _showRenameSpeakerDialog(String speakerId) {
    final currentName = _speakerNames[speakerId] ?? '';
    final controller = TextEditingController(text: currentName);
    final color = _getSpeakerColor(speakerId);

    // Preset options
    final presetNames = [
      'Doctor',
      'Patient',
      'Nurse',
      'Family Member',
      'Speaker 1',
      'Speaker 2',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rename Speaker',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Preset buttons
              Text(
                'Quick Select',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presetNames.map((name) {
                  final isSelected = controller.text == name;
                  return GestureDetector(
                    onTap: () {
                      controller.text = name;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : AppTheme.lightGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? color : AppTheme.darkSlate,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Custom input
              Text(
                'Or enter custom name',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: false,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.darkSlate,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter speaker name...',
                  hintStyle: GoogleFonts.poppins(
                    color: AppTheme.mediumGray.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppTheme.lightGray.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppTheme.mediumGray.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() {
                            _speakerNames[speakerId] = controller.text.trim();
                            _updateTranscriptionText();
                          });
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTextChanged() {
    final hasChanges = _transcriptionController.text != widget.transcription;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _transcriptionController.removeListener(_onTextChanged);
    _transcriptionController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
      }
    });
  }

  void _resetTranscription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Reset Changes?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will discard all your edits and restore the original transcription.',
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
              setState(() {
                _transcriptionController.text = widget.transcription;
                _hasChanges = false;
                _isEditing = false;
              });
            },
            child: Text(
              'Reset',
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

  int get _wordCount {
    final text = _transcriptionController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
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
              AppTheme.softSkyBg,
              AppTheme.paleBlue.withOpacity(0.3),
              Colors.white,
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
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitDialog(),
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
                'Review Transcription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleEditing,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isEditing ? AppTheme.primarySkyBlue : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _isEditing
                        ? AppTheme.primarySkyBlue.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                color: _isEditing ? Colors.white : AppTheme.primarySkyBlue,
                size: 22,
              ),
            ),
          ),
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
          const SizedBox(height: 8),
          // Success header
          _buildSuccessHeader(),
          const SizedBox(height: 20),
          // Info cards row
          _buildInfoCards(),
          const SizedBox(height: 20),
          // Transcription section
          _buildTranscriptionSection(),
          const SizedBox(height: 20),
          // Tips card
          _buildTipsCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.successGreen, const Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
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
                  'Transcription Complete',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and edit before generating report',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.translate_rounded,
            label: 'Language',
            value: widget.language,
            color: AppTheme.primarySkyBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.timer_rounded,
            label: 'Duration',
            value: widget.duration,
            color: AppTheme.deepSkyBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.text_fields_rounded,
            label: 'Words',
            value: _wordCount.toString(),
            color: AppTheme.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionSection() {
    final hasDiarization = _parsedDiarization.isNotEmpty && !_isEditing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primarySkyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasDiarization
                    ? Icons.chat_rounded
                    : Icons.record_voice_over_rounded,
                color: AppTheme.primarySkyBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDiarization ? 'Conversation' : 'Transcription',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  if (widget.patientName != null &&
                      widget.patientName!.isNotEmpty)
                    Text(
                      'Patient: ${widget.patientName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                ],
              ),
            ),
            if (_hasChanges)
              GestureDetector(
                onTap: _resetTranscription,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.warningAmber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.warningAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        // Speaker legend if diarization available
        if (hasDiarization) ...[
          const SizedBox(height: 12),
          _buildSpeakerLegend(),
        ],
        const SizedBox(height: 16),
        // Transcription text area
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isEditing ? AppTheme.primarySkyBlue : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isEditing
                    ? AppTheme.primarySkyBlue.withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isEditing ? 20 : 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Editing indicator
              if (_isEditing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySkyBlue.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primarySkyBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Editing Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primarySkyBlue,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap ✓ when done',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.primarySkyBlue.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              // Content - Chat view or Text field
              if (hasDiarization)
                _buildChatContent()
              else
                Padding(
                  padding: EdgeInsets.all(_isEditing ? 16 : 20),
                  child: TextField(
                    controller: _transcriptionController,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 8,
                    readOnly: !_isEditing,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppTheme.darkSlate,
                      height: 1.7,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Transcription will appear here...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppTheme.mediumGray.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Character count
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_transcriptionController.text.length} characters',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.mediumGray,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerLegend() {
    // Handle both 'speaker_id' (API format) and 'speaker' (fallback)
    final speakers = _parsedDiarization
        .map((d) => (d['speaker_id'] ?? d['speaker']) as String?)
        .whereType<String>()
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tap to rename speakers',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.mediumGray,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_rounded, size: 12, color: AppTheme.mediumGray),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: speakers.map((speakerId) {
            final color = _getSpeakerColor(speakerId);
            final label = _getSpeakerLabel(speakerId);

            return GestureDetector(
              onTap: () => _showRenameSpeakerDialog(speakerId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChatContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parsedDiarization.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          // Handle both 'speaker_id' (API format) and 'speaker' (fallback)
          final speakerId =
              (segment['speaker_id'] ?? segment['speaker']) as String?;
          // Handle both 'transcript' (API format) and 'text' (fallback)
          final text = (segment['transcript'] ?? segment['text'] ?? '')
              .toString()
              .trim();
          final color = _getSpeakerColor(speakerId);
          final label = _getSpeakerLabel(speakerId);

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _parsedDiarization.length - 1 ? 20 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speaker indicator dot
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Speaker label
                      Text(
                        '$label:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Message text
                      Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppTheme.darkSlate,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningAmber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warningAmber.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: AppTheme.warningAmber,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips for better reports',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Correct any misheard medical terms\n'
                  '• Add missing symptoms or details\n'
                  '• Remove any irrelevant conversation',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.mediumGray,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
        child: Row(
          children: [
            // Discard button
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showExitDialog(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: AppTheme.mediumGray.withOpacity(0.3),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Discard',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Generate Report button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _transcriptionController.text.trim().isNotEmpty
                    ? _navigateToReportGeneration
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primarySkyBlue,
                  disabledBackgroundColor: AppTheme.primarySkyBlue.withOpacity(
                    0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Generate Report',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReportGeneration() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReportGenerationScreen(
              consultationId: widget.consultationId,
              transcription: _transcriptionController.text,
              language: widget.language,
              patientName: widget.patientName,
              duration: widget.duration,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Discard Transcription?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to discard this transcription? You will need to record again.',
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
            onPressed: () {
              Navigator.pop(context);
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
