import 'package:meyncraft/meyncraft/template/generate/generator.domain.dart';

abstract class Template {
  /// Template name
  String get name;

  /// Human-readable description of what the template does
  String get description;

  /// Optional URL of a git repository where the template is stored
  String? get gitRepository;

  /// Optional URL to documentation for the template, e.g. a README file in the repository
  String? get documentation;

  /// Input parameters
  List<Parameter> get parameters;

  /// Template source-to-target mappings
  List<Generator> get generators;

  List<String> get tags;
}

/// A template from a template manifest file
class TemplateManifest implements Template {
  /// Template name
  @override
  final String name;

  /// Human-readable description of what the template does
  @override
  final String description;

  /// Optional URL of a git repository where the template is stored
  @override
  final String? gitRepository;

  /// Optional URL to documentation for the template, e.g. a README file in the repository
  @override
  final String? documentation;

  /// Input parameters
  @override
  final List<Parameter> parameters;

  /// Template source-to-target mappings
  @override
  final List<Generator> generators;

  @override
  final List<String> tags;

  TemplateManifest({
    required this.name,
    required this.description,
    this.gitRepository,
    this.documentation,
    this.parameters = const [],
    this.generators = const [],
    this.tags = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateManifest &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class Parameter {
  final String name;
  final String description;
  final ParameterType type;
  final bool required;

  Parameter({
    required this.name,
    required this.description,
    required this.type,
    required this.required,
  });
}

enum ParameterType { string, enumeration, boolean, number, relativePath, uri }

final sysmacProjectFileParameter = Parameter(
  name: 'sysmacProjectFilePath',
  description: 'Path to the Sysmac project file to generate from',
  type: ParameterType.relativePath,
  required: true,
);
