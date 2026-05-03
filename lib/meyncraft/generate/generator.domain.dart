import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/generate/generate_result.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/meyncraft/template/template.service.dart';

abstract class Generator {
  /// A human readable description of what the generator uses as a source
  /// e.g.:
  /// * a relative path to a template file, e.g. "templates/controller.dart.mustache"
  /// * a class that generates the content programmatically.
  String get source;

  /// Path where the generated file should be placed. Can include placeholders for parameters, e.g. "src/{{name}}.dart"
  String get target;

  /// Optional condition that must be met for this mapping to be applied, e.g. "{{includeTests == true}}"
  // TODO String? get when;

  Future<void> generate(
    Map<String, dynamic> parameterValues,
    StreamController<GeneratorResult> results,
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
  Future<void> generate(
    Map<String, dynamic> parameterValues,
    StreamController<GeneratorResult> results,
  ) async {
    String? sysmacProjectFilePath =
        parameterValues[sysmacProjectFileParameter.name];
    if (sysmacProjectFilePath == null) {
      results.add(
        Failure(
          'Missing required parameter: ${sysmacProjectFileParameter.name}',
        ),
      );
      results.close();
      return;
    }

    try {
      var meynSysmacProjectService = GetIt.I.get<MeynSysmacProjectService>();
      var meynSysmacProject = await meynSysmacProjectService.getProject(
        sysmacProjectFilePath,
      );
    } on Exception catch (e) {
      results.add(
        Failure('Error reading Sysmac project file: ${e.toString()}'),
      );
      results.close();
      return;
    }

    return Future.value(
      Error('CodeTemplateGenerator is deprecated and should not be used'),
    );
  }
}
