import 'dart:io';

import 'package:meyncraft/meyncraft/generate/reports/event_report.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';

Future<void> writeIsa88ReportFile(MeynSysmacProject sysmacProject) async {
  var outputFile = createOutputFile(sysmacProject, '-Isa88Report.csv');
  logger.info('Creating: ${outputFile.path}');

  var units = sysmacProject.units;

  var report = StringBuffer();
  report.writeln(
    [
      wrapCommas('Unit'),
      wrapCommas('Equipment Module'),
      wrapCommas('Control Module'),

      wrapCommas('Function Block Instance Name'),
      wrapCommas('Function Block Type'),
      wrapCommas('Interface From Higher Level'),
    ].join(','),
  );

  for (var unit in units) {
    report.writeln(
      [
        wrapCommas(unit.name),
        wrapCommas(''),
        wrapCommas(''),
        wrapCommas(''),
        wrapCommas(''),
        wrapCommas(
          '${unit.interfaceGlobalMember.namePath.join('.')}'
          '${unit.interfaceGlobalMember.arrayRanges}',
        ),
      ].join(','),
    );
    //TODO add controlModules
    for (var equipmentModule in unit.equipmentModules) {
      report.writeln(
        [
          wrapCommas(''),
          wrapCommas(equipmentModule.name),
          wrapCommas(''),
          wrapCommas(''),
          wrapCommas(''),
          wrapCommas(
            '${equipmentModule.interfaceGlobalMember.namePath.join('.')}'
            '${equipmentModule.interfaceGlobalMember.arrayRanges}',
          ),
        ].join(','),
      );
    }
  }

  await outputFile.create();
  await outputFile.writeAsString(report.toString());

  logger.info('Created: ${outputFile.path}');
  logger.info(
    '     A file that can be opened with MS-Excel to quickly check the ISA88 structure of a Sysmac project',
  );
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
