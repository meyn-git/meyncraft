import 'package:flutter/material.dart';
import 'package:meyncraft/template/template.domain.dart';

/// Service to manage the state of selected templates in the application.
class SelectedTemplateService extends ChangeNotifier {
  final List<Template> _selectedTemplates = [];

  List<Template> get selectedTemplates => List.unmodifiable(_selectedTemplates);

  void add(Template template) {
    if (_selectedTemplates.contains(template)) return;
    _selectedTemplates.add(template);
    _selectedTemplates.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void remove(Template template) {
    _selectedTemplates.remove(template);
    notifyListeners();
  }

  bool contains(Template template) => _selectedTemplates.contains(template);
}
