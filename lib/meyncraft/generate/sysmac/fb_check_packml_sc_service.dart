import 'dart:io';

import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/pack_ml/pack_ml.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/unit_equipment/unit_equipment.domain.dart';
import 'package:recase/recase.dart';

Future<void> writeSysmacFbCheckPackMlScFile(
  MeynSysmacProject sysmacProject,
) async {
  var units = sysmacProject.units;
  for (var unit in units) {
    await createFbCheckPackMlScFile(sysmacProject, unit);
  }
}

Future<void> createFbCheckPackMlScFile(
  MeynSysmacProject sysmacProject,
  Unit unit,
) async {
  var structuredText = StringBuffer();
  structuredText.writeln(
    '// This function block can be used to analyze why a PackML state keeps waiting on a start/stop completed (sc) event',
  );
  structuredText.writeln(
    '// e.g. InterfaceGlobal.PanConvBrush.PackML.StateTrans.Sts_Stopping_SC',
  );
  structuredText.writeln(
    '// This code was generated with MeynCraft on ${DateTime.now().toIso8601String().split('.').first}.',
  );
  structuredText.writeln(
    '// For more information see: https://github.com/meyn-git/meyncraft (scroll down for documentation)',
  );
  structuredText.writeln('');
  structuredText.writeln('IF ENI THEN');
  structuredText.writeln('\tIndexMax := ${unit.equipmentModules.length};');
  structuredText.writeln('\tIndex := 0;');
  structuredText.writeln('\tCASE iUnitPackML.State OF');
  var scPackMlStates = [
    PackMlState.aborting,
    PackMlState.resetting,
    PackMlState.starting,
    PackMlState.stopping,
  ];
  for (var scPackMlState in scPackMlStates) {
    structuredText.writeln('');
    structuredText.writeln('\t${scPackMlState.name.toUpperCase()}:');
    structuredText.writeln('\t\tIF TRUE THEN');
    for (var equipment in unit.equipmentModules) {
      for (var arrayValue
          in equipment.interfaceGlobalMember.arrayRanges.toStringList()) {
        structuredText.writeln(
          '\t\t\tIF ConfigGlobal.${unit.name}.${equipment.name}Present$arrayValue'
          ' AND NOT InterfaceGlobal.${equipment.name}$arrayValue.PackML.'
          'StateTrans.Sts_${scPackMlState.name.pascalCase}_SC THEN',
        );
        structuredText.writeln(
          "\t\t\t\tModuleNo_SC[Index] := '${equipment.name}$arrayValue';",
        );
        structuredText.writeln(
          "\t\t\t\tIF Index < IndexMax THEN Index := Index + 1; END_IF;",
        );
        structuredText.writeln("\t\t\tEND_IF;");
      }
    }
    structuredText.writeln('\t\tEND_IF;');
  }

  structuredText.writeln('');
  structuredText.writeln('\tEND_CASE;');
  structuredText.writeln('');
  structuredText.writeln('\t// Clear array');
  structuredText.writeln('\tFOR Index := Index TO IndexMax DO');
  structuredText.writeln("\t\tModuleNo_SC[Index] := 'Ready';");
  structuredText.writeln('\tEND_FOR;');
  structuredText.writeln('');
  structuredText.writeln('\t// Module without SC to output');
  structuredText.writeln('\toModuleNo_SC := ModuleNo_SC[iIndex];');
  structuredText.writeln('');
  structuredText.writeln('\t// PackML state to output');
  structuredText.writeln('\tCASE iUnitPackML.State OF');
  for (var packMlState in scPackMlStates) {
    structuredText.writeln(
      "\t\t${packMlState.name.toUpperCase()}:\t\t\t\t\toPackMLState := '${packMlState.name.titleCase}';",
    );
  }
  structuredText.writeln('\tELSE');
  structuredText.writeln('\t\toPackMLState := \'Undefined\';');
  structuredText.writeln('\tEND_CASE;');
  structuredText.writeln('');
  structuredText.writeln('END_IF;');
  structuredText.writeln('ENO := ENI;');

  var outputFile = createOutputFile(
    sysmacProject,
    '-${unit.name}-fbCheckPackML_SC.txt',
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
