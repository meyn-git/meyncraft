import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyn_sysmac/isa88/isa88.domain.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_instruction_tab.presentation.dart';

class Isa88ReportTemplate implements TemplateProject {
  @override
  final String name = 'Isa88Report';

  @override
  final String description =
      'Generates an ISA 88 report from a Sysmac project.';

  @override
  final String? documentation = null;

  @override
  final String? gitRepository = null;

  @override
  final List<TemplateProjectParameter> parameters = [
    sysmacProjectFileParameter,
  ];

  @override
  final List<Generator> generators = [Isa88ReportGenerator()];

  @override
  final List<String> tags = ['sysmac', 'isa88', 'report'];
}

class Isa88ReportGenerator implements Generator {
  @override
  String get source => '$runtimeType Dart class';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-Report-Isa88.csv';

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
      generatedFile = await writeIsa88ReportFile(parameterValues);
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

  Future<File> writeIsa88ReportFile(
    Map<String, dynamic> parameterValues,
  ) async {
    var sysmacProject = await MeynSysmacProjectService().getProject(
      parameterValues,
    );
    var outputFilePath = await createOutputPath(outputPath, parameterValues);
    var outputFile = File(outputFilePath);

    var isa88Nodes = sysmacProject.isa88Nodes;

    var report = StringBuffer();

    for (var rootNode in isa88Nodes) {
      write(report, node: rootNode, level: 0);
    }

    await outputFile.create();
    await outputFile.writeAsString(report.toString());

    return outputFile;
  }

  String wrapWithDoubleQuotes(String text) => '"$text"';

  void write(
    StringBuffer report, {
    required int level,
    String? parameter,
    required Isa88Node node,
  }) {
    var nodeTitle =
        '${parameter == null ? '' : '$parameter= '}${node.name} (${node.runtimeType})';
    var nodeParameters = _createNodeParameters(node);
    report.writeln(
      [
        for (int i = 0; i < level; i++) wrapWithDoubleQuotes(''),
        wrapWithDoubleQuotes(nodeTitle),
        for (int i = level; i < 10; i++) wrapWithDoubleQuotes(''),
        for (var nodeParameter in nodeParameters.entries)
          wrapWithDoubleQuotes(
            '${nodeParameter.key}= '
            '${nodeParameter.value}',
          ),
      ].join(','),
    );

    if (node is Unit) {
      for (var equipmentModule in node.equipmentModules) {
        write(report, level: level + 1, node: equipmentModule);
      }
    } else if (node is EquipmentModule) {
      for (var child in node.argumentsAndModules.entries) {
        write(
          report,
          level: level + 1,
          parameter: child.key,
          node: child.value,
        );
      }
    } else if (node is ControlModule) {
      for (var controlModule in node.argumentsAndControlModules.entries) {
        write(
          report,
          level: level + 1,
          parameter: controlModule.key,
          node: controlModule.value,
        );
      }
    }
  }

  Map<String, String> _createNodeParameters(Isa88Node node) {
    if (node is Unit) {
      return {
        'variableToEquipment': node.variableToEquipment
            .toNamePathWithArrayIndexes()
            .join('.'),
        'function(block)': node.callPath.toString(),
      };
    }
    if (node is EquipmentModule) {
      return {
        'variableFromParent': node.variableFromParent
            .toNamePathWithArrayIndexes()
            .join('.'),
        'function(block)': node.callPath.toString(),
      };
    }
    if (node is ControlModule) {
      return {
        'variableFromParent': node.variableFromParent
            .toNamePathWithArrayIndexes()
            .join('.'),
        'function(block)': node.callPath.toString(),
      };
    }

    return {};
  }
}
