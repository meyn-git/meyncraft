import 'dart:io';

import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';

Future<void> writeEventReportFile(MeynSysmacProject sysmacProject) async {
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
        wrapCommas(componentCodesNewStyle),
        wrapCommas(componentCodesOldStyle),
        wrapCommas(event.messageParts.join('-')),
        event.priority.name,
        event.acknowledgeRequired,
        wrapCommas(variableNameWithAddresses),
      ].join(','),
    );
  }

  var outputFile = createOutputFile(sysmacProject, '-EventReport.csv');
  await outputFile.create();
  await outputFile.writeAsString(report.toString());

  logger.info('Created: ${outputFile.path}');
  logger.info(
    '     A file that can be opened with MS-Excel to quickly check the generated events',
  );
}

String wrapCommas(String contentWithCommas) => '"$contentWithCommas"';

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
