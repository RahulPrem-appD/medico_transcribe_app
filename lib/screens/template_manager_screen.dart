import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/report_template.dart';
import '../services/template_service.dart';

class TemplateManagerScreen extends StatefulWidget {
  const TemplateManagerScreen({super.key});

  @override
  State<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends State<TemplateManagerScreen> {
  final TemplateService _templateService = TemplateService();
  List<ReportTemplate> _builtInTemplates = [];
  List<ReportTemplate> _customTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    await _templateService.initialize();
    final customTemplates = await _templateService.getCustomTemplates();
    setState(() {
      _builtInTemplates = BuiltInTemplates.templates;
      _customTemplates = customTemplates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softSkyBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTemplateDialog,
        backgroundColor: AppTheme.primarySkyBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Template',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.darkSlate,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Report Templates',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom templates section
          if (_customTemplates.isNotEmpty) ...[
            _buildSectionHeader('My Templates', _customTemplates.length),
            const SizedBox(height: 12),
            ..._customTemplates.map((t) => _buildTemplateCard(t, isCustom: true)),
            const SizedBox(height: 24),
          ],
          
          // Built-in templates section
          _buildSectionHeader('Built-in Templates', _builtInTemplates.length),
          const SizedBox(height: 12),
          ..._builtInTemplates.map((t) => _buildTemplateCard(t, isCustom: false)),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primarySkyBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primarySkyBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(ReportTemplate template, {required bool isCustom}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTemplateDetails(template, isCustom),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCustom
                        ? AppTheme.warningAmber.withOpacity(0.1)
                        : AppTheme.primarySkyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForTemplate(template.icon),
                    color: isCustom ? AppTheme.warningAmber : AppTheme.primarySkyBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.mediumGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildTag('${template.config.sections.length} sections'),
                          const SizedBox(width: 6),
                          _buildTag(template.config.format),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCustom)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppTheme.mediumGray),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditTemplateDialog(template);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(template);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 10),
                            Text('Edit', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 20, color: AppTheme.accentCoral),
                            const SizedBox(width: 10),
                            Text('Delete', style: GoogleFonts.poppins(color: AppTheme.accentCoral)),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right, color: AppTheme.mediumGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppTheme.mediumGray,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getIconForTemplate(String iconName) {
    switch (iconName) {
      case 'bolt':
        return Icons.bolt_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'update':
        return Icons.update_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'send':
        return Icons.send_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  void _showTemplateDetails(ReportTemplate template, bool isCustom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySkyBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForTemplate(template.icon),
                      color: AppTheme.primarySkyBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkSlate,
                          ),
                        ),
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
                ],
              ),
            ),
            const Divider(height: 1),
            // Sections list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                    ...template.config.sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                      );
                    }),
                    const SizedBox(height: 16),
                    // Settings
                    Row(
                      children: [
                        _buildDetailChip('Format', template.config.format),
                        const SizedBox(width: 10),
                        _buildDetailChip('Tone', template.config.tone),
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
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          template.config.customInstructions!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Actions for custom templates
            if (isCustom)
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(template);
                        },
                        icon: const Icon(Icons.delete_outline, color: AppTheme.accentCoral),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.poppins(color: AppTheme.accentCoral),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.accentCoral),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditTemplateDialog(template);
                        },
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                        label: Text(
                          'Edit Template',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primarySkyBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primarySkyBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
              color: AppTheme.primarySkyBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTemplateDialog() {
    _showTemplateEditor(null);
  }

  void _showEditTemplateDialog(ReportTemplate template) {
    _showTemplateEditor(template);
  }

  void _showTemplateEditor(ReportTemplate? existingTemplate) {
    final nameController = TextEditingController(text: existingTemplate?.name ?? '');
    final descController = TextEditingController(text: existingTemplate?.description ?? '');
    final instructionsController = TextEditingController(
      text: existingTemplate?.config.customInstructions ?? '',
    );
    
    List<ReportSection> selectedSections = existingTemplate?.config.sections.toList() ?? [];
    String selectedFormat = existingTemplate?.config.format ?? 'detailed';
    String selectedTone = existingTemplate?.config.tone ?? 'formal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      existingTemplate == null ? 'Create Template' : 'Edit Template',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: AppTheme.mediumGray),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      Text(
                        'Template Name',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g., My Custom Template',
                          filled: true,
                          fillColor: AppTheme.lightGray.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Description field
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          hintText: 'Brief description of this template',
                          filled: true,
                          fillColor: AppTheme.lightGray.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Sections
                      Row(
                        children: [
                          Text(
                            'Sections',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkSlate,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              _showSectionPicker(selectedSections, (sections) {
                                setModalState(() {
                                  selectedSections = sections;
                                });
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('Add', style: GoogleFonts.poppins()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (selectedSections.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'No sections added yet.\nTap "Add" to select sections.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedSections.length,
                          onReorder: (oldIndex, newIndex) {
                            setModalState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = selectedSections.removeAt(oldIndex);
                              selectedSections.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final section = selectedSections[index];
                            return Container(
                              key: ValueKey(section.id),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.lightGray),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.drag_handle, color: AppTheme.mediumGray, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      section.name,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedSections.removeAt(index);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppTheme.accentCoral,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      
                      // Format & Tone
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Format',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedFormat,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppTheme.lightGray.withOpacity(0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: ['detailed', 'concise', 'bullet_points']
                                      .map((f) => DropdownMenuItem(
                                            value: f,
                                            child: Text(f.replaceAll('_', ' ')),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setModalState(() => selectedFormat = v!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tone',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedTone,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppTheme.lightGray.withOpacity(0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: ['formal', 'simple', 'technical']
                                      .map((t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setModalState(() => selectedTone = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Custom instructions
                      Text(
                        'Custom Instructions (Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: instructionsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Additional instructions for the AI...',
                          filled: true,
                          fillColor: AppTheme.lightGray.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Save button
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a template name', style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.accentCoral,
                          ),
                        );
                        return;
                      }
                      if (selectedSections.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please add at least one section', style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.accentCoral,
                          ),
                        );
                        return;
                      }

                      final template = ReportTemplate(
                        id: existingTemplate?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        description: descController.text.trim().isNotEmpty
                            ? descController.text.trim()
                            : 'Custom template',
                        isBuiltIn: false,
                        config: ReportTemplateConfig(
                          sections: selectedSections,
                          format: selectedFormat,
                          tone: selectedTone,
                          customInstructions: instructionsController.text.trim().isNotEmpty
                              ? instructionsController.text.trim()
                              : null,
                        ),
                      );

                      await _templateService.saveCustomTemplate(template);
                      await _loadTemplates();
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              existingTemplate == null ? 'Template created!' : 'Template updated!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySkyBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      existingTemplate == null ? 'Create Template' : 'Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSectionPicker(List<ReportSection> currentSections, Function(List<ReportSection>) onUpdate) {
    final availableSections = PredefinedSections.all
        .where((s) => !currentSections.any((cs) => cs.id == s.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Add Section',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: availableSections.length,
                itemBuilder: (context, index) {
                  final section = availableSections[index];
                  return ListTile(
                    title: Text(section.name, style: GoogleFonts.poppins()),
                    subtitle: section.description != null
                        ? Text(
                            section.description!,
                            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.mediumGray),
                          )
                        : null,
                    trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primarySkyBlue),
                    onTap: () {
                      final newSections = [...currentSections, section];
                      onUpdate(newSections);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ReportTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Template', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${template.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.mediumGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _templateService.deleteCustomTemplate(template.id);
              await _loadTemplates();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Template deleted', style: GoogleFonts.poppins()),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCoral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

