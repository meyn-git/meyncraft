import 'dart:async';

import 'package:meyncraft/meyncraft/command.domain.dart';
import 'package:meyncraft/meyncraft/command.presentation.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/template_about_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:template_engine/template_engine.dart';

Future<DynamicMarkdownTabContent> generate(
  List<TemplateProject> selectedTemplates,
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
  outputReport.addToButtons(ElevatedCommandButton(ReGenerate()));
  outputReport.addToButtons(ElevatedCommandButton(CloseCurrentTab()));
  return outputReport;
}

class GeneratorErrorTab extends MarkdownTab {
  GeneratorErrorTab(
    TemplateProject template,
    Generator generator,
    Exception exception,
    StackTrace stackTrace, {
    super.key,
  }) : super(createMarkdownContent(template, generator, exception, stackTrace));

  static MarkdownTabContent createMarkdownContent(
    TemplateProject template,
    Generator generator,
    Exception exception,
    StackTrace stackTrace,
  ) {
    var templateTab = TemplateAboutTab(template);
    var templateTabUri = meynCraftUriToTab(templateTab);
    return StaticMarkdownContent(
      tabTitle: 'Error',
      buttons: [ElevatedCommandButton(CloseCurrentTab())],
      markdown: createMarkdown(
        template,
        templateTabUri,
        generator,
        exception,
        stackTrace,
      ),
      linkedTabs: [templateTab],
    );
  }

  static String createMarkdown(
    TemplateProject template,
    Uri templateTabUri,
    Generator generator,
    Exception exception,
    StackTrace stackTrace,
  ) {
    return '## Source\n'
        '* Template: [${template.name}]($templateTabUri)\n'
        '* Generator source: ${generator.source}\n'
        '## Exception\n'
        '${exception.toString()}\n'
        '## Stack trace\n'
        '${stackTrace.toString().replaceAll('\n', '\\\n')}\n';
  }
}

// Uses a template engine to create the output path eg:
// * outputPath: '{{removeFileExtension(sysmacProjectFilePath)}}-Sysmac-PackMlMonitor.xml'
// * parameters: { sysmacProjectFilePath: 'C:/myProject/sysmacProject.smc2' }
// * result: 'C:/myProject/sysmacProject-Sysmac-PackMlMonitor.xml'

Future<String> createOutputPath(
  String outputPath,
  VariableMap? parameters,
) async {
  var functionGroups = [
    ...DefaultFunctionGroups(),
    FunctionGroup('MeynCraftFunctions', [
      ExpressionFunction(
        name: 'removeFileExtension',
        description: 'removes a ile extension from a file path',
        exampleExpression: "removeFileExtension('myPath/myFile.exe')",
        exampleResult: "'myPath/myFile'",
        parameters: <Parameter>[
          Parameter(
            name: 'filePath',
            description: 'A file path, either absolute, relative or a URI',
            presence: Presence.mandatory(),
          ),
        ],
        function: (position, renderContext, parameters) {
          var filePath = parameters['filePath'];
          if (filePath is! String) {
            throw ParameterException('String expected');
          }

          final index = filePath.lastIndexOf('.');
          if (index == -1) return Future.value(filePath);
          return Future.value(filePath.substring(0, index));
        },
      ),
    ]),
  ];
  var engine = TemplateEngine(functionGroups: functionGroups);
  var parseResult = await engine.parseText(outputPath);
  var renderResult = await engine.render(parseResult, parameters);
  return renderResult.text;
}
