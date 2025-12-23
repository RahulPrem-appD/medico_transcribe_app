import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  // Color options for notes
  final List<String> _noteColors = [
    '#FFFFFF', // White
    '#FFE5E5', // Light red
    '#FFF4E5', // Light orange
    '#FFFBE5', // Light yellow
    '#E5F8E5', // Light green
    '#E5F3FF', // Light blue
    '#F0E5FF', // Light purple
    '#FFE5F8', // Light pink
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOut,
    );
    
    _fabController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    try {
      final notes = await _db.getNotes(pinnedFirst: true);
      setState(() {
        _notes = notes;
        _filteredNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notes: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.accentCoral,
          ),
        );
      }
    }
  }

  void _filterNotes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase()) ||
                 note.content.toLowerCase().contains(query.toLowerCase()) ||
                 (note.patientName?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _showNoteEditor({Note? existingNote}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _NoteEditorScreen(
          note: existingNote,
          colors: _noteColors,
        ),
      ),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _togglePin(Note note) async {
    try {
      await _db.toggleNotePin(note.id);
      _loadNotes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pin note', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.accentCoral,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${note.title}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.mediumGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteNote(note.id);
        _loadNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note deleted', style: GoogleFonts.poppins()),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete note', style: GoogleFonts.poppins()),
              backgroundColor: AppTheme.accentCoral,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.softSkyBg,
              AppTheme.paleBlue,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredNotes.isEmpty
                        ? _buildEmptyState()
                        : _buildNotesList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showNoteEditor(),
          backgroundColor: AppTheme.primarySkyBlue,
          elevation: 8,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'New Note',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
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
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppTheme.darkSlate),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Notes',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkSlate,
                  ),
                ),
                Text(
                  '${_notes.length} note${_notes.length == 1 ? '' : 's'}',
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
        child: TextField(
          controller: _searchController,
          onChanged: _filterNotes,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search notes...',
            hintStyle: GoogleFonts.poppins(
              color: AppTheme.mediumGray,
              fontSize: 14,
            ),
            icon: const Icon(Icons.search_rounded, color: AppTheme.primarySkyBlue),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _filterNotes('');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primarySkyBlue),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primarySkyBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isEmpty 
                  ? Icons.sticky_note_2_outlined 
                  : Icons.search_off_rounded,
              size: 64,
              color: AppTheme.primarySkyBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty 
                ? 'No notes yet' 
                : 'No notes found',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Tap the button below to create your first note'
                : 'Try a different search term',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNoteCard(note, index);
      },
    );
  }

  Widget _buildNoteCard(Note note, int index) {
    final color = note.color != null
        ? Color(int.parse(note.color!.replaceFirst('#', '0xFF')))
        : Colors.white;

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.accentCoral,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteNote(note),
      child: GestureDetector(
        onTap: () => _showNoteEditor(existingNote: note),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primarySkyBlue.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned) ...[
                    Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: AppTheme.primarySkyBlue,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      note.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppTheme.mediumGray,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'pin') {
                        _togglePin(note);
                      } else if (value == 'delete') {
                        _deleteNote(note);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              note.isPinned 
                                  ? Icons.push_pin_outlined 
                                  : Icons.push_pin_rounded,
                              size: 18,
                              color: AppTheme.primarySkyBlue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              note.isPinned ? 'Unpin' : 'Pin',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_rounded,
                              size: 18,
                              color: AppTheme.accentCoral,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (note.patientName != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySkyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: AppTheme.primarySkyBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        note.patientName!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.primarySkyBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  note.preview,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.mediumGray,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: AppTheme.mediumGray.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    note.formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.mediumGray.withOpacity(0.7),
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
}

/// Note Editor Screen
class _NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final List<String> colors;

  const _NoteEditorScreen({
    this.note,
    required this.colors,
  });

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  final DatabaseService _db = DatabaseService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _patientController;
  String? _selectedColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _patientController = TextEditingController(text: widget.note?.patientName ?? '');
    _selectedColor = widget.note?.color ?? widget.colors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _patientController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.accentCoral,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.note == null) {
        // Create new note
        await _db.createNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          patientName: _patientController.text.trim().isEmpty 
              ? null 
              : _patientController.text.trim(),
          color: _selectedColor,
        );
      } else {
        // Update existing note
        await _db.updateNote(
          id: widget.note!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          patientName: _patientController.text.trim().isEmpty 
              ? null 
              : _patientController.text.trim(),
          color: _selectedColor,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.accentCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _selectedColor != null
        ? Color(int.parse(_selectedColor!.replaceFirst('#', '0xFF')))
        : Colors.white;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleField(),
                      const SizedBox(height: 16),
                      _buildPatientField(),
                      const SizedBox(height: 16),
                      _buildContentField(),
                      const SizedBox(height: 24),
                      _buildColorPicker(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: AppTheme.darkSlate),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.note == null ? 'New Note' : 'Edit Note',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveNote,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(
              'Save',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primarySkyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _titleController,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.darkSlate,
        ),
        decoration: InputDecoration(
          hintText: 'Note title',
          hintStyle: GoogleFonts.poppins(
            color: AppTheme.mediumGray,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          icon: const Icon(Icons.title_rounded, color: AppTheme.primarySkyBlue),
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildPatientField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _patientController,
        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.darkSlate),
        decoration: InputDecoration(
          hintText: 'Patient name (optional)',
          hintStyle: GoogleFonts.poppins(color: AppTheme.mediumGray),
          border: InputBorder.none,
          icon: const Icon(Icons.person_outline_rounded, color: AppTheme.primarySkyBlue),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildContentField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _contentController,
        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.darkSlate, height: 1.6),
        decoration: InputDecoration(
          hintText: 'Start typing your note...',
          hintStyle: GoogleFonts.poppins(color: AppTheme.mediumGray),
          border: InputBorder.none,
        ),
        maxLines: null,
        minLines: 8,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note Color',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.colors.map((colorHex) {
            final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
            final isSelected = _selectedColor == colorHex;

            return GestureDetector(
              onTap: () => setState(() => _selectedColor = colorHex),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primarySkyBlue 
                        : AppTheme.mediumGray.withOpacity(0.2),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppTheme.primarySkyBlue,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

