import 'dart:io';

import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';

Future<void> writeSysmacEventFile(SysmacProject sysmacProject) async {
  var events = sysmacProject.eventService.events;

  var code = StringBuffer();
  for (var event in events) {
    code.writeln(
      '${event.number},${event.namePath},${event.group},${event.componentCodes.join(' ')},${event.message},${event.priority.name},${event.acknowledgeRequired}',
    );
  }

  var outputFile = createOutputFile(sysmacProject, '-SysmacEvents.csv');
  await outputFile.create();
  await outputFile.writeAsString(code.toString());

  logger.info('Created: ${outputFile.path}');
  logger.info(
    '     A file that can be opened with MS-Excel to quickly check the generated events',
  );
}

File createOutputFile(SysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.details.projectFile;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}
