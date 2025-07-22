import 'dart:io';

import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';

//TODO make async
void writeSysmacEventArrayCodeFile(SysmacProject sysmacProject) {
  var events = sysmacProject.eventService.events;

  var code = StringBuffer();
  code.writeln(
    '// The EventGlobal variable is copied to the EventGlobalArray variable.',
  );
  code.writeln(
    '// This is needed for more efficient event communication with HMIs and MeynConnect.',
  );
  code.writeln(
    '// This code was generated with MeynCraft on ${DateTime.now()}.',
  );
  code.writeln(
    '// For more information see: https://github.com/meyn-git/meyncraft (scroll down for documentation)',
  );
  for (var event in events) {
    code.writeln('EventGlobalArray[${event.number}]:=${event.namePath};');
  }

  var outputFile = createOutputFile(sysmacProject, '-SysmacEventArray.txt');
  outputFile.createSync();
  outputFile.writeAsStringSync(code.toString());

  logger.info('Created: ${outputFile.path}');
}

File createOutputFile(SysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.archive.file;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}
