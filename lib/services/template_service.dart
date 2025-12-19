import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_template.dart';

/// Service for managing report templates
class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  static const String _customTemplatesKey = 'custom_report_templates';
  static const String _lastUsedTemplateKey = 'last_used_template_id';

  SharedPreferences? _prefs;
  bool _isInitializing = false;

  Future<void> initialize() async {
    if (_prefs != null || _isInitializing) return;
    _isInitializing = true;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      // Retry after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e2) {
        print('Error initializing SharedPreferences (retry): $e2');
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Get all templates (built-in + custom)
  Future<List<ReportTemplate>> getAllTemplates() async {
    final customTemplates = await getCustomTemplates();
    return [...BuiltInTemplates.templates, ...customTemplates];
  }

  /// Get only custom templates
  Future<List<ReportTemplate>> getCustomTemplates() async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      if (_prefs == null) {
        return [];
      }
      
      final jsonString = _prefs!.getString(_customTemplatesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ReportTemplate.fromJson(json))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error loading custom templates: $e');
      return [];
    }
  }

  /// Save a custom template
  Future<bool> saveCustomTemplate(ReportTemplate template) async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      if (_prefs == null) {
        return false;
      }
      
      final templates = await getCustomTemplates();
      
      // Check if template with same ID exists (update) or add new
      final existingIndex = templates.indexWhere((t) => t.id == template.id);
      if (existingIndex >= 0) {
        templates[existingIndex] = template;
      } else {
        templates.add(template);
      }

      final jsonString = jsonEncode(templates.map((t) => t.toJson()).toList());
      return await _prefs!.setString(_customTemplatesKey, jsonString);
    } catch (e) {
      print('Error saving custom template: $e');
      return false;
    }
  }

  /// Delete a custom template
  Future<bool> deleteCustomTemplate(String templateId) async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      if (_prefs == null) {
        return false;
      }
      
      final templates = await getCustomTemplates();
      templates.removeWhere((t) => t.id == templateId);

      final jsonString = jsonEncode(templates.map((t) => t.toJson()).toList());
      return await _prefs!.setString(_customTemplatesKey, jsonString);
    } catch (e) {
      print('Error deleting custom template: $e');
      return false;
    }
  }

  /// Get the last used template ID
  Future<String?> getLastUsedTemplateId() async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      if (_prefs == null) {
        return null;
      }
      return _prefs!.getString(_lastUsedTemplateKey);
    } catch (e) {
      print('Error getting last used template ID: $e');
      return null;
    }
  }

  /// Set the last used template ID
  Future<bool> setLastUsedTemplateId(String templateId) async {
    try {
      if (_prefs == null) {
        await initialize();
      }
      if (_prefs == null) {
        return false;
      }
      return await _prefs!.setString(_lastUsedTemplateKey, templateId);
    } catch (e) {
      print('Error setting last used template ID: $e');
      return false;
    }
  }

  /// Get a template by ID
  Future<ReportTemplate?> getTemplateById(String id) async {
    final allTemplates = await getAllTemplates();
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Generate a unique ID for new templates
  String generateTemplateId() {
    return 'custom_${DateTime.now().millisecondsSinceEpoch}';
  }
}

