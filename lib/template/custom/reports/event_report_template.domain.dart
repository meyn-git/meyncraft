import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/generate/generator_report.domain.dart';
import 'package:meyncraft/template/template.domain.dart';

class EventReportTemplate implements TemplateProject {
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
  final List<TemplateProjectParameter> parameters = [
    sysmacProjectFileParameter,
  ];

  @override
  final List<Generator> generators = [EventReportGenerator()];

  @override
  final List<String> tags = ['sysmac', 'events', 'report'];
}

class EventReportGenerator implements Generator {
  @override
  String get source => '$runtimeType Dart class';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-Report-Events.csv';

  @override
  final String? outputInstructions =
      'You can open the generated file (e.g. for quick reference) '
      'using Excel or any other spreadsheet software.';

  @override
  Future<GeneratorReport> generate(
    TemplateProject template,
    Map<String, dynamic> parameterValues,
    GeneratorReport report,
  ) async {
    var generatedFiles = <File>[];
    try {
      var generatedFile = await writeEventReportFile(
        template,
        parameterValues,
        report,
      );
      report.addGeneratedFileToMarkdown(generatedFile);
      generatedFiles.add(generatedFile);
    } on Exception catch (exception, stackTrace) {
      report.addFailureToMarkdown(template, this, exception, stackTrace);
    }
    report.addGenerationSummary(template, this, generatedFiles);
    return report;
  }

  Future<File> writeEventReportFile(
    TemplateProject template,
    Map<String, dynamic> parameterValues,
    GeneratorReport report,
  ) async {
    var sysmacProject = await MeynSysmacProjectService().getProject(
      parameterValues,
    );
    var events = sysmacProject.events;
    report.addToMarkdown('* Found ${events.length} Sysmac events\n');
    if (events.warnings.isNotEmpty) {
      report.addWarningsToMarkdown(template, this, events.warnings);
    }

    var csv = StringBuffer();
    for (var event in events) {
      var componentCodesOldStyle = event.componentCodes.join(', ');
      var componentCodesNewStyle = event.variableNameWithComponentCodes.values
          .expand((e) => e)
          .join(', ');
      var variableNameWithAddresses = [
        for (var entry in event.variableNameWithHardwareAddress.entries)
          '${entry.key}:${entry.value}',
      ].join(', ');
      csv.writeln(
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

    var outputFilePath = await createOutputPath(outputPath, parameterValues);
    var outputFile = File(outputFilePath);
    await outputFile.create();
    await outputFile.writeAsString(csv.toString());
    return outputFile;
  }

  String wrapWithDoubleQuotes(String text) => '"$text"';
}
