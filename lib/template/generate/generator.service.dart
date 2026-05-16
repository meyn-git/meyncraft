import 'dart:async';

import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/template_about_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/template/template.domain.dart';

Future<DynamicMarkdownTabContent> generate(
  List<Template> selectedTemplates,
  Map<String, dynamic> parameterValues,
  DynamicMarkdownTabContent outputReport,
) async {
  for (var template in selectedTemplates) {
    //var templateResult = TemplateGenerationResult(template, results);
    var linkUrl = outputReport.addTabLink(TemplateAboutTab(template));
    outputReport.addToMarkdown('# [${template.name}]($linkUrl)\n');
    for (var generator in template.generators) {
      try {
        outputReport = await generator.generate(
          template,
          parameterValues,
          outputReport,
        );
      } on Exception catch (exception, stackTrace) {
        var linkUri = outputReport.addTabLink(
          GeneratorErrorTab(template, generator, exception, stackTrace),
        );
        outputReport.addToMarkdown(
          '* **Failed** [Click here for more information]($linkUri)',
        );
      }
    }
  }

  outputReport.addToMarkdown('# Generation completed.');
  return outputReport;
}

class GeneratorErrorTab extends MarkdownTab {
  GeneratorErrorTab(
    Template template,
    Generator generator,
    Exception exception,
    StackTrace stackTrace, {
    super.key,
  }) : super(createMarkdownContent(template, generator, exception, stackTrace));

  static DynamicMarkdownTabContent createMarkdownContent(
    Template template,
    Generator generator,
    Exception exception,
    StackTrace stackTrace,
  ) {
    var output = DynamicMarkdownTabContent('Error');
    var urlLink = output.addTabLink(TemplateAboutTab(template));
    output.addToMarkdown(
      '## Source\n'
      '* Template: [${template.name}]($urlLink)\n'
      '* Generator source: ${generator.source}\n'
      '## Exception\n'
      '${exception.toString()}\n'
      '## Stack trace\n'
      '${stackTrace.toString().replaceAll('\n', '\\\n')}\n',
    );
    return output;
  }
}
