import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_instruction_tab.presentation.dart';

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
  Future<DynamicMarkdownTabContent> generate(
    TemplateProject template,
    Map<String, dynamic> parameterValues,
    DynamicMarkdownTabContent outputReport,
  ) async {
    File? generatedFile;
    try {
      generatedFile = await writeEventReportFile(parameterValues);
      outputReport.addToMarkdown(
        '* Generated file: [${generatedFile.path}](${generatedFile.uri})',
      );
    } on Exception catch (exception, stackTrace) {
      var linkUri = outputReport.addTabLink(
        GeneratorErrorTab(template, this, exception, stackTrace),
      );
      outputReport.addToMarkdown(
        '* **Failed** [Click here for more information]($linkUri)',
      );
    }
    if (generatedFile == null) {
      outputReport.addToMarkdown('* No files generated');
    }
    var linkUri = outputReport.addTabLink(
      TemplateInstructionTab(template, this, [generatedFile!]),
    );
    outputReport.addToMarkdown(
      '* Generated 1 file. '
      '[Click here for instructions on how to use the generated file.]($linkUri)',
    );
    return outputReport;
  }

  Future<File> writeEventReportFile(
    Map<String, dynamic> parameterValues,
  ) async {
    var sysmacProject = await MeynSysmacProjectService().getProject(
      parameterValues,
    );
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

    var outputFilePath = await createOutputPath(outputPath, parameterValues);
    var outputFile = File(outputFilePath);
    await outputFile.create();
    await outputFile.writeAsString(report.toString());
    return outputFile;
  }

  String wrapWithDoubleQuotes(String text) => '"$text"';
}
