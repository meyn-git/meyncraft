import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/template_manifest/template_manifest.domain.dart';

/// Service to manage the state of selected templates in the application.
class SelectedTemplateService extends ChangeNotifier {
  final List<TemplateManifest> _selectedTemplates = [];

  List<TemplateManifest> get selectedTemplates =>
      List.unmodifiable(_selectedTemplates);

  void add(TemplateManifest templateManifest) {
    _selectedTemplates.add(templateManifest);
    _selectedTemplates.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void remove(TemplateManifest templateManifest) {
    _selectedTemplates.remove(templateManifest);
    notifyListeners();
  }

  bool contains(TemplateManifest templateManifest) =>
      _selectedTemplates.contains(templateManifest);
}
