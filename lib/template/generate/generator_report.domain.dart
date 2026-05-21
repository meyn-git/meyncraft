import 'dart:io';

import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/template/generate/generator_error_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator_warnings_tab.presentation.dart';
import 'package:meyncraft/template/generate/warning.domain.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_instruction_tab.presentation.dart';

class GeneratorReport extends DynamicMarkdownTabContent {
  GeneratorReport() : super('Generation Report');

  void addFailureToMarkdown(
    TemplateProject template,
    Generator generator,
    Exception exception,
    StackTrace stackTrace,
  ) {
    var linkUri = addTabLink(
      GeneratorErrorTab(template, generator, exception, stackTrace),
    );
    addToMarkdown('* **FAILED** [Click here for more information]($linkUri)');
  }

  void addWarningsToMarkdown(
    TemplateProject template,
    Generator generator,
    List<Warning> warnings,
  ) {
    var linkUri = addTabLink(
      GeneratorWarningsTab(template, generator, warnings),
    );
    addToMarkdown(
      '* **${warnings.length == 1 ? 'WARNING' : 'WARNINGS'}**'
      ' [Click here for more information]($linkUri)',
    );
  }

  void addGenerationSummary(
    TemplateProject template,
    Generator generator,
    List<File> generatedFiles,
  ) {
    if (generatedFiles.isEmpty) {
      addToMarkdown('* No files generated');
    }
    var linkUri = addTabLink(
      TemplateInstructionTab(template, generator, generatedFiles),
    );
    var fileOrFiles = generatedFiles.length == 1 ? 'file' : 'files';
    addToMarkdown(
      '* Generated ${generatedFiles.length} $fileOrFiles. '
      '[Click here for instructions on how to use the generated $fileOrFiles.]($linkUri)',
    );
  }

  void addGeneratedFileToMarkdown(File generatedFile) {
    addToMarkdown(
      '* Generated file: [${generatedFile.path}](${generatedFile.uri})',
    );
  }
}
