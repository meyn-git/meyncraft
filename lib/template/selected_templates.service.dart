import 'package:flutter/material.dart';
import 'package:meyncraft/template/template.domain.dart';

/// Service to manage the state of selected templates in the application.
class SelectedTemplateService extends ChangeNotifier {
  final List<TemplateProject> _selectedTemplates = [];

  List<TemplateProject> get selectedTemplates =>
      List.unmodifiable(_selectedTemplates);

  void add(TemplateProject template) {
    if (_selectedTemplates.contains(template)) return;
    _selectedTemplates.add(template);
    _selectedTemplates.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void remove(TemplateProject template) {
    _selectedTemplates.remove(template);
    notifyListeners();
  }

  bool contains(TemplateProject template) =>
      _selectedTemplates.contains(template);
}
