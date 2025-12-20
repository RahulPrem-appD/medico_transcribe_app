/// Model class representing a quick note
class Note {
  final String id;
  final String title;
  final String content;
  final String? patientName;
  final String? color; // Hex color string for note card
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.patientName,
    this.color,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Note from database row
  factory Note.fromRow(Map<String, dynamic> row) {
    return Note(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      content: row['content'] as String? ?? '',
      patientName: row['patient_name'] as String?,
      color: row['color'] as String?,
      isPinned: (row['is_pinned'] as int?) == 1,
      createdAt: row['created_at'] is DateTime 
          ? row['created_at'] as DateTime 
          : DateTime.parse(row['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: row['updated_at'] is DateTime 
          ? row['updated_at'] as DateTime 
          : DateTime.parse(row['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'patient_name': patientName,
      'color': color,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? patientName,
    String? color,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      patientName: patientName ?? this.patientName,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get preview text (first 100 chars of content)
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}

