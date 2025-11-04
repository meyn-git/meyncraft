import 'dart:io';

import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/unit_equipment/unit_equipment.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/unit_equipment/unit_equipment.service.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:xml/xml.dart';

Future<void> writeSysmacUnitInterfaceXmlImportFile(
  SysmacProject sysmacProject,
) async {
  var outputFile = createOutputFile(sysmacProject, '-SysmacUnitInterface.xml');
  logger.info('Creating: ${outputFile.path}');

  var programs = createPrograms(sysmacProject);
  var project = Project(programs, []);
  var xmlString = project.toXmlString(
    pretty: true,
    indent: '  ',
    preserveWhitespace: (node) =>
        node is XmlElement && ['ST', 'Content'].contains(node.name.local),
  );

  await outputFile.create();
  await outputFile.writeAsString(xmlString);

  logger.info(
    '    Import this file in Sysmac with Menu \\ Tools \\ IEC 61131-10 XML \\ Import',
  );
  logger.info(
    '    Then move the UnitInterface sections in program "GeneratedByMeynCraft_<Unit Name>"'
    'to the corresponding existing programs',
  );
}

List<Program> createPrograms(SysmacProject sysmacProject) {
  var units = findMeynUnitsAndEquipments(sysmacProject);
  return units.map((u) => _createProgram(u)).toList();
}

Program _createProgram(Unit unit) {
  List<LadderSection> sections = _createSections(unit);
  var mainBody = MainBody.ladderSection(sections);
  var programName = 'GeneratedByMeynCraft_${unit.name}';
  return Program(
    programName: programName,
    pouInfo: _createPouInfo(),
    globalVariables: _createGlobalVariables(unit),
    internalVariables: _createInternalVariables(unit),
    mainBody: mainBody,
  );
}

SmcExtPouInfo _createPouInfo() {
  return SmcExtPouInfo(
    author: 'MeynCraft code generator',
    //TODO would be nice if we would use the MeynCraft version by reading the pubspec.yaml file
    version: '1.0.0',
  );
}

List<Variable2> _createInternalVariables(Unit unit) {
  return [
    Variable2(variableName: 'StartWarningDone', variableType: 'BOOL'),
    Variable2(variableName: 'StartWarningExecuteDone', variableType: 'BOOL'),
    ..._createInternalUnitVariables(unit),
  ];
}

List<GlobalVariable> _createGlobalVariables(Unit unit) => <GlobalVariable>[
  GlobalVariable(
    Variable2(variableName: 'InterfaceGlobal', variableType: 'sInterface'),
  ),
  GlobalVariable(
    Variable2(variableName: 'ConfigGlobal', variableType: 'sConfig'),
  ),
  GlobalVariable(
    Variable2(
      variableName: unitStartAllowedVariableName(unit),
      variableType: 'BOOL',
    ),
  ),
];

List<Variable2> _createInternalUnitVariables(Unit unit) {
  var variables = <Variable2>[];

  variables.add(
    Variable2(
      variableName: 'NOP',
      variableType: 'BOOL',
      comment: 'No operation (does nothing)',
    ),
  );

  var dataTypeBases = unit.equipments
      .map((e) => e.interfaceGlobalMember.dataTypeBase)
      .toSet();
  var functionBlockVars = dataTypeBases
      .map(
        (DataTypeBase d) => Variable2(
          variableName: 'fb${d.name}EqInterface',
          variableType: '${arrayRanges(d).toTypeExpression()}fbUnitInterface',
        ),
      )
      .toList();
  variables.addAll(functionBlockVars);
  variables.add(
    Variable2(
      variableName: eqStartedVarName,
      variableType: 'Unit\\${unit.name}\\sEquipment',
    ),
  );
  variables.add(
    Variable2(
      variableName: eqAlarmVarName,
      variableType: 'Unit\\${unit.name}\\sEquipment',
    ),
  );

  return variables;
}

const eqStartedVarName = 'EqStarted';

const eqAlarmVarName = 'EqAlarm';

const String fbUnitInterfaceType = 'fbUnitInterface';

List<LadderSection> _createSections(Unit unit) {
  var ladderSections = <LadderSection>[];
  var rungs = <Rung>[];
  var rungNr = 0;
  rungs.add(Rung.comment(rungNr++, _generatedComment()));
  rungs.add(Rung.comment(rungNr++, _unitInterfaceComment));
  rungs.add(createUnitStartAllowedRung(rungNr++, unit));
  rungs.add(createEqStartedMonitorRung(rungNr++, unit));
  rungs.add(createEqAlarmMonitorRung(rungNr++, unit));
  rungs.add(createResetAllCmdSetAllScRung(rungNr++, unit));
  rungs.add(createSummarizeRung(rungNr++, unit));
  rungs.add(Rung.comment(rungNr++, _equipmentInterfaceComment));
  for (var equipment in unit.equipments) {
    for (var arrayValue in equipment.arrayValues) {
      var rung = createEquipmentInterfaceRung(
        rungNr++,
        unit,
        equipment,
        arrayValue,
      );
      rungs.add(rung);
    }
  }
  ladderSections.add(
    LadderSection(name: 'UnitInterface', evaluationOrder: 1, rungs: rungs),
  );

  return ladderSections;
}

String _unitInterfaceComment =
    '#Unit Interface\n'
    'Interfaces from a ISA88 Unit to one or more ISA88 Equipment Modules.';

String _equipmentInterfaceComment =
    '#Equipment Interface\n'
    'Interfaces between a ISA88 Unit and one or more ISA88 Equipment Modules.';

String _generatedComment() =>
    '#THIS CODE WAS GENERATED WITH MEYNCRAFT!\n'
    'Date: ${createNowInSysmacXmlFormat()}.\n'
    'More information: https://github.com/meyn-git/meyncraft (scroll down for documentation)';

Rung createUnitStartAllowedRung(int rungNr, Unit unit) {
  var variables = <String>[];
  for (var equipment in unit.equipments) {
    for (var arrayValue in equipment.arrayValues) {
      variables.add('EqStarted.${equipment.name}$arrayValue');
    }
  }
  var structuredText =
      '${unitStartAllowedVariableName(unit)}:=\n    ${variables.join(' AND\n    ')};';
  return Rung.structuredText(
    evaluationOrder: rungNr,
    structuredText: structuredText,
    comment: 'Start condition for unit',
  );
}

String unitStartAllowedVariableName(Unit unit) => '${unit.name}StartAllowed';

Rung createEqStartedMonitorRung(int rungNr, Unit unit) {
  int connectionPointId = 1;
  var variableNames = _createVariableNames(eqStartedVarName, unit.equipments);
  return Rung(
    rungNr,
    'Monitor if equipment started (for debugging).\n'
    'A unit may potentially keep until all equipment report as started before progressing to the PackML execute state',
    [
      LadderObject.leftPowerRail([ConnectionPointOut(connectionPointId)]),
      for (int i = 0; i < variableNames.length; i++)
        LadderObject.contact(
          variableNames[i],
          null,
          ConnectionPointIn([(i % 5 == 0) ? 1 : connectionPointId]),
          ConnectionPointOut(++connectionPointId),
        ),
      LadderObject.coil(
        'NOP',
        null,
        ConnectionPointIn(_coilConnectionPoints(connectionPointId)),
        ConnectionPointOut(++connectionPointId),
      ),

      LadderObject.rightPowerRail([
        ConnectionPointIn([connectionPointId]),
      ]),
    ],
  );
}

List<String> _createVariableNames(String preFix, List<Equipment> equipments) {
  var variableNames = <String>[];
  for (var equipment in equipments) {
    for (var arrayValue in equipment.arrayValues) {
      variableNames.add('$preFix.${equipment.name}$arrayValue');
    }
  }
  return variableNames;
}

Rung createEqAlarmMonitorRung(int rungNr, Unit unit) {
  int connectionPointId = 1;
  var variableNames = _createVariableNames(eqAlarmVarName, unit.equipments);
  return Rung(
    rungNr,
    'Monitor if equipment is in alarm (for debugging)\n'
    'An equipment module can request a unit to stop or abort when '
    'it has an critical alarm.',
    [
      LadderObject.leftPowerRail([ConnectionPointOut(connectionPointId)]),
      for (int i = 0; i < variableNames.length; i++)
        LadderObject.contact(
          variableNames[i],
          null,
          ConnectionPointIn([(i % 5 == 0) ? 1 : connectionPointId]),
          ConnectionPointOut(++connectionPointId),
        ),
      LadderObject.coil(
        'NOP',
        null,
        ConnectionPointIn(_coilConnectionPoints(connectionPointId)),
        ConnectionPointOut(++connectionPointId),
      ),

      LadderObject.rightPowerRail([
        ConnectionPointIn([connectionPointId]),
      ]),
    ],
  );
}

List<int> _coilConnectionPoints(int connectionPointId) {
  if (connectionPointId < 6) {
    return [connectionPointId];
  }

  List<int> result = [];
  for (int i = 6; i <= connectionPointId; i += 5) {
    result.add(i);
  }

  // Ensure the final number is included if it's not already
  if (result.last != connectionPointId) {
    result.add(connectionPointId);
  }

  return result;
}

Rung createResetAllCmdSetAllScRung(int rungNr, Unit unit) {
  var functionBlockWithSourcesAndSinks = FunctionBlockWithSourcesAndSinks(
    r'\\OmronLib\PackML30\PMLTransitionCmd_ResetAllCmdSetAllSC',
    [
      FunctionLink(
        variableName:
            '${unit.interfaceGlobalMember.expression}.PackML.StateTransSum',
        functionVariableName: 'PMLTransitionCommand',
      ),
    ],
    [],
    [FunctionLink(variableName: '', functionVariableName: '')],
    currentConnectionPointId: 1,
  );
  return Rung(
    rungNr++,
    'State transition command reset\n'
    'Hereafter the signals from/to the equipment modules are merged\n'
    '* OR evaluation on state transition commands (Cmd_<state name>)\n'
    '* AND evaluation on state completion conditions (Sts_<state name>_SC)',
    [
      LadderObject.leftPowerRail([ConnectionPointOut(1)]),
      ...functionBlockWithSourcesAndSinks,
      LadderObject.rightPowerRail([
        ConnectionPointIn([functionBlockWithSourcesAndSinks.enoOutId]),
      ]),
    ],
  );
}

Rung createSummarizeRung(int rungNr, Unit unit) {
  var functionBlockWithSourcesAndSinks = FunctionBlockWithSourcesAndSinks(
    r'\\OmronLib\PackML30\PMLTransitionCmd_Summarize',
    [
      FunctionLink(
        variableName:
            '${unit.interfaceGlobalMember.expression}.PackML.StateTransSum',
        functionVariableName: 'TransitionCmd1',
      ),
    ],
    [
      FunctionLink(
        variableName: 'InterfaceGlobal.Evisceration.PackML.StateTrans',
        functionVariableName: 'TransitionCmd2',
      ),
    ],
    [FunctionLink(variableName: '', functionVariableName: '')],
    currentConnectionPointId: 1,
  );
  return Rung(
    rungNr++,
    'Summarize unit state command and transition conditions',
    [
      LadderObject.leftPowerRail([ConnectionPointOut(1)]),
      ...functionBlockWithSourcesAndSinks,
      LadderObject.rightPowerRail([
        ConnectionPointIn([functionBlockWithSourcesAndSinks.enoOutId]),
      ]),
    ],
  );
}

Rung createEquipmentInterfaceRung(
  int rungNr,
  Unit unit,
  Equipment equipment,
  String? array,
) {
  var functionBlockWithSourcesAndSinks = FunctionBlockWithSourcesAndSinks(
    'fbUnitInterface',
    [
      FunctionLink(
        variableName:
            '${equipment.interfaceGlobalMember.expression}$array.Unit',
        functionVariableName: 'ioEquipment',
      ),
      FunctionLink(
        variableName:
            '${equipment.interfaceGlobalMember.expression}$array.PackML',
        functionVariableName: 'ioEquipmentPackML',
      ),
      FunctionLink(
        variableName: '${unit.interfaceGlobalMember.expression}.PackML',
        functionVariableName: 'ioUnitPackML',
      ),
    ],
    [
      FunctionLink(
        variableName: '${equipment.configGlobalPresentMember.expression}$array',
        functionVariableName: 'iConfigPresent',
      ),
      FunctionLink(
        variableName: 'StartWarningDone',
        functionVariableName: 'iStartWarningDone',
      ),
      FunctionLink(
        variableName: 'StartWarningExecuteDone',
        functionVariableName: 'iStartWarningExecuteDone',
      ),
      FunctionLink(variableName: 'False', functionVariableName: 'iReset'),
      FunctionLink(
        variableName: 'False',
        functionVariableName: 'iEventsSuppress',
      ),
    ],
    [
      FunctionLink(
        variableName: '$eqAlarmVarName.${equipment.name}$array',
        functionVariableName: 'oAlarm',
      ),
      FunctionLink(variableName: '', functionVariableName: 'oWarning'),
      FunctionLink(
        variableName: '$eqStartedVarName.${equipment.name}$array',
        functionVariableName: 'oStarted',
      ),
      FunctionLink(
        variableName: '',
        functionVariableName: 'oEquipmentPackMLMode',
      ),
      FunctionLink(
        variableName: '',
        functionVariableName: 'oEquipmentPackMLState',
      ),
    ],
    instanceName: 'fb${equipment.name}EqInterface$array',
    currentConnectionPointId: 1,
  );
  return Rung(rungNr++, '${equipment.name}$array', [
    LadderObject.leftPowerRail([ConnectionPointOut(1)]),
    ...functionBlockWithSourcesAndSinks,
    LadderObject.rightPowerRail([
      ConnectionPointIn([functionBlockWithSourcesAndSinks.enoOutId]),
    ]),
  ]);
}

File createOutputFile(SysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.identity.projectFile;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}
