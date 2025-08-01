import 'dart:io';

import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';

Future<void> writeSysmacEventFile(SysmacProject sysmacProject) async {
  var events = sysmacProject.eventService.events;

  var code = StringBuffer();
  for (var event in events) {
    code.writeln(
      '${event.number},${event.namePath},${event.componentCodes.join(' ')},${event.message},${event.priority.name},${event.acknowledgeRequired}',
    );
  }

  var outputFile = createOutputFile(sysmacProject, '-SysmacEvents.csv');
  await outputFile.create();
  await outputFile.writeAsString(code.toString());

  logger.info('Created: ${outputFile.path}');
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
