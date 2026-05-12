import 'dart:async';

import 'package:meyncraft/meyncraft/presentation/markdown_tab.presentation.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';

abstract class Generator {
  /// A human readable description of what the generator uses as a source
  /// e.g.:
  /// * a relative path to a template file, e.g. "templates/controller.dart.mustache"
  /// * a class that generates the content programmatically.
  String get source;

  /// Path where the generated file should be placed.
  /// Can include placeholders for parameters, e.g. "src/{{name}}.dart"
  String get outputPath;

  /// Optional instructions (in markdown format) on how to use the generated file
  String? get outputInstructions;

  /// Optional condition that must be met
  /// for this mapping to be applied, e.g. "{{includeTests == true}}"
  // TODO String? get when;

  Future<DynamicMarkdownTabContent> generate(
    Template template,
    Map<String, dynamic> parameterValues,
    DynamicMarkdownTabContent outputReport,
  );
}
