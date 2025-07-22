import 'dart:io';

import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';

//TODO make async
void writeSysmacEventArrayCodeFile(SysmacProject sysmacProject) {
  var events = sysmacProject.eventService.events;

  var code = StringBuffer();
  code.writeln(
    '// The EventGlobal is copied to EventGlobalArray for more efficient communication.',
  );
  code.writeln(
    '// This code was generated on 2025-07-17 with sysmac_generator.',
  );
  code.writeln(
    '// For more information see: https://github.com/nils-ten-hoeve/sysmac_generator',
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
