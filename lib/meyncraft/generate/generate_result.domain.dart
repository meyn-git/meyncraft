import 'dart:async';

import 'package:meyncraft/meyncraft/template/template.domain.dart';

abstract class GeneratorResult {
  String toMarkdown();
}

class Info extends GeneratorResult {
  final String message;

  Info(this.message);

  @override
  String toMarkdown() => message;
}

class Warning extends GeneratorResult {
  final String message;

  Warning(this.message);

  @override
  String toMarkdown() => message;
}

class Error extends GeneratorResult {
  final String message;

  Error(this.message);

  @override
  String toMarkdown() => message;
}

// A major error that prevents generation from completing.
class Failure extends GeneratorResult {
  final String message;

  Failure(this.message);
  @override
  String toMarkdown() => message;
}

class TemplateGenerationResult extends GeneratorResult {
  final Template template;
  final childResults = StreamController<GeneratorResult>();

  TemplateGenerationResult(
    this.template,
    StreamController<GeneratorResult> parentResults,
  ) {
    childResults.stream.listen(
      (result) {
        parentResults.add(IndentedGeneratorResult(result));
      },
      onDone: () {
        parentResults.close();
      },
    );
  }

  @override
  String toMarkdown() => '# [${template.name}](detail:${template.name})\n';
}

class IndentedGeneratorResult extends GeneratorResult {
  final GeneratorResult result;

  IndentedGeneratorResult(this.result);

  @override
  String toMarkdown() {
    return '> ${result.toMarkdown().replaceAll('\n', '\n> ')}';
  }
}
