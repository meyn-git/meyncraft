import 'dart:io';

import 'package:meyncraft/meyncraft/presentation/markdown_tab.presentation.dart';
import 'package:meyncraft/meyncraft/template/custom/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';
import 'package:template_engine/template_engine.dart' as te;

class EventReportTemplate implements Template {
  @override
  final String name = 'EventReport';

  @override
  final String description =
      'Generates a report of events from a Sysmac project.';

  @override
  final String? documentation = null;

  @override
  final String? gitRepository = null;

  @override
  final List<Parameter> parameters = [sysmacProjectFileParameter];

  @override
  final List<Generator> generators = [EventReportGenerator()];

  @override
  final List<String> tags = ['sysmac', 'events', 'report'];
}

class EventReportGenerator implements Generator {
  @override
  String get source => 'Dart code: $runtimeType';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-EventReport.csv';

  @override
  final String? outputInstructions =
      'You can open the generated file e.g. for quick reference '
      'using Excel or any other spreadsheet software.';

  @override
  Future<DynamicMarkdownTabContent> generate(
    Template template,
    Map<String, dynamic> parameterValues,
    DynamicMarkdownTabContent outputReport,
  ) async {
    var sysmacProjectFilePath =
        parameterValues[sysmacProjectFileParameter.name];
    if (sysmacProjectFilePath == null) {
      throw Exception('Missing parameter: ${sysmacProjectFileParameter.name}');
    }
    var sysmacProject = await MeynSysmacProject.loadFromFile(
      File(sysmacProjectFilePath),
    );
    File? generatedFile;
    try {
      generatedFile = await writeEventReportFile(
        sysmacProject,
        parameterValues,
      );
      outputReport.append(
        '* Created: [${generatedFile.path}](${generatedFile.uri})',
      );
    } on Exception catch (e, stackTrace) {
      var errorLink = GenerationErrorLink(
        template: template,
        generator: this,
        message: 'Error generating JMobile tags file',
        stackTrace: stackTrace,
      );
      outputReport.append('* ${errorLink.toMarkdown()}');
    }
    if (generatedFile == null) {
      outputReport.append('* No files generated');
    }
    outputReport.append(
      '* Generated 1 file. [Click here for instructions on how to use the generated files.](meyncraft://test)',
    );
    return outputReport;
  }

  Future<File> writeEventReportFile(
    MeynSysmacProject sysmacProject,
    Map<String, dynamic> parameterValues,
  ) async {
    var events = sysmacProject.events;

    var report = StringBuffer();
    for (var event in events) {
      var componentCodesOldStyle = event.componentCodes.join(', ');
      var componentCodesNewStyle = event.variableNameWithComponentCodes.values
          .expand((e) => e)
          .join(', ');
      var variableNameWithAddresses = [
        for (var entry in event.variableNameWithHardwareAddress.entries)
          '${entry.key}:${entry.value}',
      ].join(', ');
      report.writeln(
        [
          event.number,
          event.namePath,
          event.group,
          wrapWithDoubleQuotes(componentCodesNewStyle),
          wrapWithDoubleQuotes(componentCodesOldStyle),
          wrapWithDoubleQuotes(event.messageParts.join('-')),
          event.priority.name,
          event.acknowledgeRequired,
          wrapWithDoubleQuotes(variableNameWithAddresses),
        ].join(','),
      );
    }

    var outputPath = await createOutputPath(parameterValues);
    var outputFile = File(outputPath);
    await outputFile.create();
    await outputFile.writeAsString(report.toString());
    return outputFile;
  }

  Future<String> createOutputPath(te.VariableMap? parameters) async {
    var functionGroups = [
      ...te.DefaultFunctionGroups(),
      te.FunctionGroup('MeynCraftFunctions', [
        te.ExpressionFunction(
          name: 'removeFileExtension',
          description: 'removes a ile extension from a file path',
          exampleExpression: "removeFileExtension('myPath/myFile.exe')",
          exampleResult: "'myPath/myFile'",
          parameters: <te.Parameter>[
            te.Parameter(
              name: 'filePath',
              description: 'A file path, either absolute, relative or a URI',
              presence: te.Presence.mandatory(),
            ),
          ],
          function: (position, renderContext, parameters) {
            var filePath = parameters['filePath'];
            if (filePath is! String) {
              throw te.ParameterException('String expected');
            }

            final index = filePath.lastIndexOf('.');
            if (index == -1) return Future.value(filePath);
            return Future.value(filePath.substring(0, index));
          },
        ),
      ]),
    ];
    var engine = te.TemplateEngine(functionGroups: functionGroups);
    var parseResult = await engine.parseText(outputPath);
    var renderResult = await engine.render(parseResult, parameters);
    return renderResult.text;
  }
}

String wrapWithDoubleQuotes(String text) => '"$text"';

//FIXME remove
// File createOutputFile(MeynSysmacProject sysmacProject, String suffix) {
//   var sysmacFile = sysmacProject.identity.projectFile;
//   var directory = sysmacFile.parent.path;
//   var filename = sysmacFile.uri.pathSegments.last;
//   var nameWithoutExtension = filename.split('.').first;
//   var outputPath =
//       '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
//   var outputFile = File(outputPath);
//   return outputFile;
// }
