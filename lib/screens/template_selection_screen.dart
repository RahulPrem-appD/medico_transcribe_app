import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/report_template.dart';
import '../services/template_service.dart';
import 'processing_screen.dart';

class TemplateSelectionScreen extends StatefulWidget {
  final String transcription;
  final String language;
  final String? patientName;
  final String duration;
  final String consultationId;

  const TemplateSelectionScreen({
    super.key,
    required this.transcription,
    required this.language,
    this.patientName,
    required this.duration,
    required this.consultationId,
  });

  @override
  State<TemplateSelectionScreen> createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen>
    with SingleTickerProviderStateMixin {
  final TemplateService _templateService = TemplateService();
  List<ReportTemplate> _builtInTemplates = [];
  List<ReportTemplate> _customTemplates = [];
  String? _selectedTemplateId;
  String? _lastUsedTemplateId;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    await _templateService.initialize();
    final customTemplates = await _templateService.getCustomTemplates();
    final lastUsedId = await _templateService.getLastUsedTemplateId();

    setState(() {
      _builtInTemplates = BuiltInTemplates.templates;
      _customTemplates = customTemplates;
      _lastUsedTemplateId = lastUsedId;
      _selectedTemplateId = lastUsedId ?? 'standard';
      _isLoading = false;
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectTemplate(String templateId) {
    setState(() {
      _selectedTemplateId = templateId;
    });
  }

  Future<void> _proceedWithTemplate() async {
    if (_selectedTemplateId == null) return;

    // Save last used template
    await _templateService.setLastUsedTemplateId(_selectedTemplateId!);

    // Get the selected template
    final template = await _templateService.getTemplateById(_selectedTemplateId!);
    if (template == null) return;

    if (!mounted) return;

    // Navigate to report generation with template
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReportGenerationScreen(
          consultationId: widget.consultationId,
          transcription: widget.transcription,
          language: widget.language,
          patientName: widget.patientName,
          duration: widget.duration,
          template: template,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showCreateTemplateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateTemplateSheet(
        onSave: (template) async {
          await _templateService.saveCustomTemplate(template);
          await _loadTemplates();
          if (mounted) {
            setState(() {
              _selectedTemplateId = template.id;
            });
          }
        },
      ),
    );
  }

  void _showEditTemplateDialog(ReportTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateTemplateSheet(
        existingTemplate: template,
        onSave: (updatedTemplate) async {
          await _templateService.saveCustomTemplate(updatedTemplate);
          await _loadTemplates();
        },
        onDelete: () async {
          await _templateService.deleteCustomTemplate(template.id);
          await _loadTemplates();
          if (_selectedTemplateId == template.id) {
            setState(() {
              _selectedTemplateId = 'standard';
            });
          }
        },
      ),
    );
  }

  void _showTemplateDetails(ReportTemplate template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplateDetailsSheet(
        template: template,
        onSelect: () {
          Navigator.pop(context);
          _selectTemplate(template.id);
        },
        onEdit: template.isBuiltIn ? null : () {
          Navigator.pop(context);
          _showEditTemplateDialog(template);
        },
      ),
    );
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildAppBar(),
                      Expanded(child: _buildContent()),
                      _buildBottomBar(),
                    ],
                  ),
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
                'Choose Template',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showCreateTemplateDialog,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primarySkyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primarySkyBlue,
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
          // Header info
          _buildHeaderCard(),
          const SizedBox(height: 24),

          // Built-in templates
          Text(
            'Standard Templates',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 12),
          ..._builtInTemplates.map((template) => _buildTemplateCard(template)),

          // Custom templates
          if (_customTemplates.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Templates',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
                Text(
                  '${_customTemplates.length} saved',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._customTemplates.map((template) => _buildTemplateCard(
                  template,
                  isCustom: true,
                )),
          ],

          // Create new template card
          const SizedBox(height: 16),
          _buildCreateNewCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primarySkyBlue, AppTheme.deepSkyBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySkyBlue.withOpacity(0.3),
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
              Icons.article_rounded,
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
                  'Select Report Format',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a template or create your own',
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

  Widget _buildTemplateCard(ReportTemplate template, {bool isCustom = false}) {
    final isSelected = _selectedTemplateId == template.id;
    final isLastUsed = _lastUsedTemplateId == template.id;
    final sectionCount = template.config.sections.length;

    return GestureDetector(
      onTap: () => _selectTemplate(template.id),
      onLongPress: () => _showTemplateDetails(template),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primarySkyBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primarySkyBlue.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primarySkyBlue.withOpacity(0.1)
                    : AppTheme.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconData(template.icon),
                color: isSelected ? AppTheme.primarySkyBlue : AppTheme.mediumGray,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Last used',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ),
                      if (isCustom && !isLastUsed)
                        GestureDetector(
                          onTap: () => _showEditTemplateDialog(template),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: AppTheme.mediumGray.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.mediumGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Tags
                  Row(
                    children: [
                      _buildTag('$sectionCount sections'),
                      const SizedBox(width: 6),
                      _buildTag(template.config.format.replaceAll('_', ' ')),
                      const SizedBox(width: 6),
                      _buildTag(template.config.tone),
                    ],
                  ),
                ],
              ),
            ),
            // Selection indicator
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primarySkyBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primarySkyBlue
                      : AppTheme.mediumGray.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTheme.mediumGray,
        ),
      ),
    );
  }

  Widget _buildCreateNewCard() {
    return GestureDetector(
      onTap: _showCreateTemplateDialog,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primarySkyBlue.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primarySkyBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppTheme.primarySkyBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Create Custom Template',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primarySkyBlue,
              ),
            ),
          ],
        ),
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
        child: ElevatedButton(
          onPressed: _selectedTemplateId != null ? _proceedWithTemplate : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: AppTheme.primarySkyBlue,
            disabledBackgroundColor: AppTheme.primarySkyBlue.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Generate Report',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
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

// Template Details Sheet
class _TemplateDetailsSheet extends StatelessWidget {
  final ReportTemplate template;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;

  const _TemplateDetailsSheet({
    required this.template,
    required this.onSelect,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    color: AppTheme.primarySkyBlue,
                  ),
              ],
            ),
          ),
          // Sections list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sections (${template.config.sections.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...template.config.sections.map((section) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySkyBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${section.order}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primarySkyBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  // Format & Tone
                  Row(
                    children: [
                      _buildInfoChip('Format', template.config.format.replaceAll('_', ' ')),
                      const SizedBox(width: 12),
                      _buildInfoChip('Tone', template.config.tone),
                    ],
                  ),
                  if (template.config.customInstructions != null &&
                      template.config.customInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Custom Instructions',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        template.config.customInstructions!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Select button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primarySkyBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Select This Template',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.mediumGray,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
        ],
      ),
    );
  }
}

// Create/Edit Template Sheet
class _CreateTemplateSheet extends StatefulWidget {
  final ReportTemplate? existingTemplate;
  final Function(ReportTemplate) onSave;
  final VoidCallback? onDelete;

  const _CreateTemplateSheet({
    this.existingTemplate,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<_CreateTemplateSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _customSectionController = TextEditingController();

  List<ReportSection> _selectedSections = [];
  String _format = 'detailed';
  String _tone = 'formal';

  @override
  void initState() {
    super.initState();
    if (widget.existingTemplate != null) {
      final t = widget.existingTemplate!;
      _nameController.text = t.name;
      _descriptionController.text = t.description;
      _instructionsController.text = t.config.customInstructions ?? '';
      _selectedSections = List.from(t.config.sections);
      _format = t.config.format;
      _tone = t.config.tone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _customSectionController.dispose();
    super.dispose();
  }

  void _addSection(ReportSection section) {
    if (!_selectedSections.any((s) => s.id == section.id)) {
      setState(() {
        _selectedSections.add(section.copyWith(order: _selectedSections.length + 1));
      });
    }
  }

  void _removeSection(String sectionId) {
    setState(() {
      _selectedSections.removeWhere((s) => s.id == sectionId);
      // Reorder remaining sections
      for (int i = 0; i < _selectedSections.length; i++) {
        _selectedSections[i] = _selectedSections[i].copyWith(order: i + 1);
      }
    });
  }

  void _reorderSections(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final section = _selectedSections.removeAt(oldIndex);
      _selectedSections.insert(newIndex, section);
      // Update order values
      for (int i = 0; i < _selectedSections.length; i++) {
        _selectedSections[i] = _selectedSections[i].copyWith(order: i + 1);
      }
    });
  }

  void _addCustomSection() {
    final name = _customSectionController.text.trim();
    if (name.isEmpty) return;

    final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    _addSection(ReportSection(
      id: customId,
      name: name,
      order: _selectedSections.length + 1,
    ));
    _customSectionController.clear();
    Navigator.pop(context);
  }

  void _showAddSectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSectionSheet(
        availableSections: PredefinedSections.all
            .where((s) => !_selectedSections.any((sel) => sel.id == s.id))
            .toList(),
        onSelectSection: (section) {
          _addSection(section);
          Navigator.pop(context);
        },
        onAddCustom: () {
          Navigator.pop(context);
          _showCustomSectionDialog();
        },
      ),
    );
  }

  void _showCustomSectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Custom Section',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: _customSectionController,
          autofocus: true,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Section name',
            hintStyle: GoogleFonts.poppins(color: AppTheme.mediumGray),
            filled: true,
            fillColor: AppTheme.lightGray.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
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
            onPressed: _addCustomSection,
            child: Text(
              'Add',
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

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a template name', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.accentCoral,
        ),
      );
      return;
    }

    if (_selectedSections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one section', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.accentCoral,
        ),
      );
      return;
    }

    final template = ReportTemplate(
      id: widget.existingTemplate?.id ?? TemplateService().generateTemplateId(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? 'Custom template with ${_selectedSections.length} sections'
          : _descriptionController.text.trim(),
      isBuiltIn: false,
      createdAt: widget.existingTemplate?.createdAt ?? DateTime.now(),
      config: ReportTemplateConfig(
        sections: _selectedSections,
        customInstructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        format: _format,
        tone: _tone,
      ),
    );

    widget.onSave(template);
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Template?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will permanently delete "${_nameController.text}". This action cannot be undone.',
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
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            child: Text(
              'Delete',
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTemplate != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Edit Template' : 'Create Template',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const Spacer(),
                if (isEditing && widget.onDelete != null)
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppTheme.accentCoral,
                  ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Template Name',
                    hint: 'e.g., My Quick Notes',
                  ),
                  const SizedBox(height: 16),
                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description (optional)',
                    hint: 'Brief description of this template',
                  ),
                  const SizedBox(height: 24),

                  // Sections
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Report Sections',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAddSectionDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySkyBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: AppTheme.primarySkyBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Add Section',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primarySkyBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selected sections list
                  if (_selectedSections.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightGray,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              size: 32,
                              color: AppTheme.mediumGray.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No sections added yet',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Add Section" to get started',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.mediumGray.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedSections.length,
                      onReorder: _reorderSections,
                      itemBuilder: (context, index) {
                        final section = _selectedSections[index];
                        return _buildSectionItem(section, index, key: ValueKey(section.id));
                      },
                    ),

                  const SizedBox(height: 24),

                  // Format
                  Text(
                    'Report Format',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionSelector(
                    options: ['detailed', 'concise', 'bullet_points'],
                    labels: ['Detailed', 'Concise', 'Bullet Points'],
                    selected: _format,
                    onSelect: (v) => setState(() => _format = v),
                  ),

                  const SizedBox(height: 24),

                  // Tone
                  Text(
                    'Language Tone',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionSelector(
                    options: ['formal', 'simple', 'technical'],
                    labels: ['Formal', 'Simple', 'Technical'],
                    selected: _tone,
                    onSelect: (v) => setState(() => _tone = v),
                  ),

                  const SizedBox(height: 24),

                  // Custom instructions
                  _buildTextField(
                    controller: _instructionsController,
                    label: 'Custom Instructions (optional)',
                    hint: 'Any specific instructions for the AI...',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppTheme.mediumGray.withOpacity(0.3)),
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
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primarySkyBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Create Template',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem(ReportSection section, int index, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(
            Icons.drag_handle_rounded,
            color: AppTheme.mediumGray.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 8),
          // Order number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primarySkyBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primarySkyBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Section name
          Expanded(
            child: Text(
              section.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.darkSlate,
              ),
            ),
          ),
          // Remove button
          GestureDetector(
            onTap: () => _removeSection(section.id),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.accentCoral.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppTheme.accentCoral,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.darkSlate,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.darkSlate),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mediumGray.withOpacity(0.6),
            ),
            filled: true,
            fillColor: AppTheme.lightGray.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primarySkyBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionSelector({
    required List<String> options,
    required List<String> labels,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (index) {
        final isSelected = selected == options[index];
        return GestureDetector(
          onTap: () => onSelect(options[index]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primarySkyBlue.withOpacity(0.1)
                  : AppTheme.lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primarySkyBlue : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              labels[index],
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.primarySkyBlue : AppTheme.darkSlate,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// Add Section Sheet
class _AddSectionSheet extends StatelessWidget {
  final List<ReportSection> availableSections;
  final Function(ReportSection) onSelectSection;
  final VoidCallback onAddCustom;

  const _AddSectionSheet({
    required this.availableSections,
    required this.onSelectSection,
    required this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Add Section',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAddCustom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySkyBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: AppTheme.primarySkyBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Custom',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primarySkyBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sections list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: availableSections.length,
              itemBuilder: (context, index) {
                final section = availableSections[index];
                return GestureDetector(
                  onTap: () => onSelectSection(section),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySkyBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppTheme.primarySkyBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                              if (section.description != null)
                                Text(
                                  section.description!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
