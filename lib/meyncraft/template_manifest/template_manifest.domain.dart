class TemplateManifest {
  /// Template name
  final String name;

  /// Human-readable description of what the template does
  final String description;

  /// Optional instructions (optionally in markdown format) on how to use the generated file
  final String? generatedFileInstructions;

  /// Optional URL of a git repository where the template is stored
  final String? gitRepository;

  /// Optional URL to documentation for the template, e.g. a README file in the repository
  final String? documentation;

  /// Input parameters
  final List<Parameter> parameters;

  /// Template source-to-target mappings
  final List<TemplateMapping> templates;

  final List<String> tags;

  TemplateManifest({
    required this.name,
    required this.description,
    this.generatedFileInstructions,
    this.gitRepository,
    this.documentation,
    this.parameters = const [],
    this.templates = const [],
    this.tags = const [],
  });
}

class TemplateMapping {
  /// Relative path to the template file
  final String source;

  /// Path where the generated file should be placed. Can include placeholders for parameters, e.g. "src/{{name}}.dart"
  final String target;

  /// Optional condition that must be met for this mapping to be applied, e.g. "{{includeTests == true}}"
  final String? when;

  TemplateMapping({required this.source, required this.target, this.when});
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
