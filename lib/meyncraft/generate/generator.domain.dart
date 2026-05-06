import 'dart:async';

import 'package:meyncraft/meyncraft/generate/generator.service.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';

abstract class Generator {
  /// A human readable description of what the generator uses as a source
  /// e.g.:
  /// * a relative path to a template file, e.g. "templates/controller.dart.mustache"
  /// * a class that generates the content programmatically.
  String get source;

  /// Path where the generated file should be placed.
  /// Can include placeholders for parameters, e.g. "src/{{name}}.dart"
  String get target;

  /// Optional instructions (in markdown format) on how to use the generated file
  //TODO String? get targetInstructions;

  /// Optional condition that must be met
  /// for this mapping to be applied, e.g. "{{includeTests == true}}"
  // TODO String? get when;

  Future<MarkdownReport> generate(
    Template template,
    Map<String, dynamic> parameterValues,
    MarkdownReport outputReport,
  );
}

@Deprecated('This class was only created to make the code work')
class CodeTemplateGenerator implements Generator {
  @override
  String get source => 'Dart code: $runtimeType';

  @override
  final String target;

  CodeTemplateGenerator({required this.target});

  @override
  Future<MarkdownReport> generate(
    Template template,
    Map<String, dynamic> parameterValues,
    MarkdownReport outputReport,
  ) async {
    // String? sysmacProjectFilePath =
    //     parameterValues[sysmacProjectFileParameter.name];
    // if (sysmacProjectFilePath == null) {
    //   results.add(
    //     Failure(
    //       'Missing required parameter: ${sysmacProjectFileParameter.name}',
    //     ),
    //   );
    //   // results.close();
    //   return;
    // }

    // try {
    //   var meynSysmacProjectService = GetIt.I.get<MeynSysmacProjectService>();
    //   var meynSysmacProject = await meynSysmacProjectService.getProject(
    //     sysmacProjectFilePath,
    //   );
    // } on Exception catch (e) {
    //   results.add(
    //     Failure('Error reading Sysmac project file: ${e.toString()}'),
    //   );
    //   // results.close();
    //   return;
    // }

    // return Future.value(
    //   Error('CodeTemplateGenerator is deprecated and should not be used'),
    // );
    return MarkdownReport()
      ..append('CodeTemplateGenerator is deprecated and should not be used\n');
  }

  // @override
  // TODO final String?  targetInstructions = null;
}
