import 'dart:io';

import 'package:meyncraft/meyncraft/generate/reports/event_report.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/isa88/isa88.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';

Future<void> writeIsa88ReportFile(MeynSysmacProject sysmacProject) async {
  var outputFile = createOutputFile(sysmacProject, '-Isa88Report.csv');
  logger.info('Creating: ${outputFile.path}');

  var isa88Nodes = sysmacProject.isa88Nodes;

  var report = StringBuffer();

  for (var rootNode in isa88Nodes) {
    write(report, node: rootNode, level: 0);
  }

  await outputFile.create();
  await outputFile.writeAsString(report.toString());

  logger.info('Created: ${outputFile.path}');
  logger.info(
    '     A file that can be opened with MS-Excel to quickly check the ISA88 structure of a Sysmac project',
  );
}

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
        '${wrapWithDoubleQuotes(nodeParameter.key)}= '
        '${wrapWithDoubleQuotes(nodeParameter.value)}',
    ].join(','),
  );

  if (node is Unit) {
    for (var equipmentModule in node.equipmentModules) {
      write(report, level: level + 1, node: equipmentModule);
    }
  } else if (node is EquipmentModule) {
    for (var child in node.argumentsAndModules.entries) {
      write(report, level: level + 1, parameter: child.key, node: child.value);
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

File createOutputFile(MeynSysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.identity.projectFile;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}
