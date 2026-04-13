import 'dart:io';

import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/isa88/isa88.domain.dart';

Future<void> writeSysmacPackMlMonitorFile(
  MeynSysmacProject sysmacProject,
) async {
  var units = sysmacProject.isa88Nodes.whereType<Unit>();
  for (var unit in units) {
    await createPackMlMonitorFile(sysmacProject, unit);
  }
}

Future<void> createPackMlMonitorFile(
  MeynSysmacProject sysmacProject,
  Unit unit,
) async {
  var structuredText = StringBuffer();

  for (var equipment in unit.equipmentModules) {
    var call = equipment.fbUnitInterfaceCallPath?.call;
    if (call == null) continue;

    var interfaceExpression = call.parametersIn
        .firstWhere((parameter) => parameter.argument == 'ioEquipmentPackML')
        .variable!;

    structuredText.writeln("dummy:=$interfaceExpression.StateTrans.Cmd_Abort;");
  }

  // structuredText.writeln('');
  // structuredText.writeln('\tEND_CASE;');
  // structuredText.writeln('');
  // structuredText.writeln('\t// Clear array');
  // structuredText.writeln('\tFOR Index := Index TO IndexMax DO');
  // structuredText.writeln("\t\tModuleNo_SC[Index] := 'Ready';");
  // structuredText.writeln('\tEND_FOR;');
  // structuredText.writeln('');
  // structuredText.writeln('\t// Module without SC to output');
  // structuredText.writeln('\toModuleNo_SC := ModuleNo_SC[iIndex];');
  // structuredText.writeln('');
  // structuredText.writeln('\t// PackML state to output');
  // structuredText.writeln('\tCASE iUnitPackML.State OF');
  // for (var packMlState in scPackMlStates) {
  //   structuredText.writeln(
  //     "\t\t${packMlState.name.toUpperCase()}:\t\t\t\t\toPackMLState := '${packMlState.name.titleCase}';",
  //   );
  // }
  // structuredText.writeln('\tELSE');
  // structuredText.writeln('\t\toPackMLState := \'Undefined\';');
  // structuredText.writeln('\tEND_CASE;');
  // structuredText.writeln('');
  // structuredText.writeln('END_IF;');
  // structuredText.writeln('ENO := ENI;');

  var outputFile = createOutputFile(
    sysmacProject,
    'Sysmac-${unit.name}-PackMlMonitor.txt',
  );
  await outputFile.create();
  await outputFile.writeAsString(structuredText.toString());

  logger.info('Created: ${outputFile.path}');
  logger.info(
    '     A file that can be opened with a text editor and copied past into Sysmac',
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
