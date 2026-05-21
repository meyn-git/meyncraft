import 'dart:async';

import 'package:meyncraft/meyncraft/command.domain.dart';
import 'package:meyncraft/meyncraft/command.presentation.dart';
import 'package:meyncraft/template/generate/generator_report.domain.dart';
import 'package:meyncraft/template/template_about_tab.presentation.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:template_engine/template_engine.dart';

Future<GeneratorReport> generate(
  List<TemplateProject> selectedTemplates,
  Map<String, dynamic> parameterValues,
  GeneratorReport report,
) async {
  for (var template in selectedTemplates) {
    //var templateResult = TemplateGenerationResult(template, results);
    var linkUrl = report.addTabLink(TemplateAboutTab(template));
    report.addToMarkdown('# [${template.name}]($linkUrl)\n');
    for (var generator in template.generators) {
      try {
        report = await generator.generate(template, parameterValues, report);
      } on Exception catch (exception, stackTrace) {
        report.addFailureToMarkdown(template, generator, exception, stackTrace);
      }
    }
  }

  report.addToMarkdown('# Generation completed.');
  report.addToButtons(ElevatedCommandButton(ReGenerate()));
  report.addToButtons(ElevatedCommandButton(CloseCurrentTab()));
  return report;
}

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
