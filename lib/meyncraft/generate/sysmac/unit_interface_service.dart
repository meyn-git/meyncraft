import 'dart:io';

import 'package:meyncraft/meyncraft/generate/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:xml/xml.dart';

Future<void> writeUnitInterfaceXmlImportFile(
  SysmacProject sysmacProject,
) async {
  var outputFile = createOutputFile(sysmacProject, '-SysmacUnitInterface.xml');
  logger.info('Creating: ${outputFile.path}');

  var pouInfo = SmcExtPouInfo(
    author: 'MeynCraft code generator',
    //TODO would be nice if we would use the MeynCraft version by reading the pubspec.yaml file
    version: '1.0.0',
  );

  VariableMember? interfaceGlobalVar = _findGlobalVariable(
    sysmacProject,
    interfaceGlobalVariableName,
  );
  if (interfaceGlobalVar == null) return;
  VariableMember? configGlobalVar = _findGlobalVariable(
    sysmacProject,
    configGlobalVariableName,
  );
  if (configGlobalVar == null) return;

  var units = _createUnits(interfaceGlobalVar, configGlobalVar);

  List<LadderSection> sections = _createSections(units);
  var mainBody = MainBody.ladderSection(sections);
  var program = Program(
    name: _programName,
    pouInfo: pouInfo,
    globalVariables: _createGlobalVariables(),
    internalVariables: _createInternalVariables(units),
    mainBody: mainBody,
  );
  var project = Project([program], []);
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
    '    Then move the sections in program "$_programName" to the end of section "Global\\EventHandling"',
  );
}

List<Variable2> _createInternalVariables(List<Unit> units) {
  return [
    Variable2(variableName: 'StartWarningDone', variableType: 'BOOL'),
    Variable2(variableName: 'StartWarningExecuteDone', variableType: 'BOOL'),
    ..._createEquipmentFunctionBlockVariables(units),
  ];
}

List<GlobalVariable> _createGlobalVariables() => <GlobalVariable>[
  GlobalVariable(
    Variable2(variableName: 'InterfaceGlobal', variableType: 'sInterface'),
  ),
  GlobalVariable(
    Variable2(variableName: 'ConfigGlobal', variableType: 'sConfig'),
  ),
];

List<Unit> _createUnits(
  VariableMember interfaceGlobalVar,
  VariableMember configGlobalVar,
) {
  List<VariableMember> unitInterfaces = interfaceGlobalVar.find(
    _unitInterfacesToEquipmentsFilter,
  );
  if (unitInterfaces.isEmpty) {
    logger.warning(
      '    Could not find any unit interfaces in the ${interfaceGlobalVar.expression} variable',
    );
  }
  logger.info('    Found: ${unitInterfaces.length} unit interfaces');
  List<VariableMember> equipmentInterfaces = interfaceGlobalVar.find(
    _equipmentInterfacesToUnitFilter,
  );
  var equipmentInterfacesWithoutUnit = [...equipmentInterfaces];
  if (unitInterfaces.isEmpty) {
    logger.warning(
      '    Could not find any equipment interfaces in the ${interfaceGlobalVar.expression} variable',
    );
  }
  logger.info('    Found: ${equipmentInterfaces.length} equipment interfaces');

  var units = <Unit>[];
  for (var unitInterface in unitInterfaces) {
    var unitName = unitInterface.namePath.last;
    var unitConfigs = configGlobalVar.find(
      (d) => _configMemberForUnitFilter(d, unitName),
    );
    if (unitConfigs.length != 1) {
      logger.warning(
        '    Expected variable ${configGlobalVar.expression} to have a member for unit $unitName',
      );
      break;
    }
    var unitConfig = unitConfigs.first;
    var equipments = <Equipment>[];
    for (var equipmentInterface in equipmentInterfaces) {
      var nameToFind = '${equipmentInterface.namePath.last}Present';
      var equipmentPresentConfigs = unitConfig.find(
        (d) => d.name == nameToFind && d is DataType && d.baseType is NxBool,
      );
      if (equipmentPresentConfigs.isNotEmpty) {
        equipments.add(
          Equipment(
            interfaceGlobalMember: equipmentInterface,
            configGlobalPresentMember: equipmentPresentConfigs.first,
          ),
        );
        equipmentInterfacesWithoutUnit.remove(equipmentInterface);
      }
    }
    if (equipments.isEmpty) {
      logger.warning(
        '    Expected variable ${unitConfig.expression} to have EquipmentPresent booleans',
      );
    }
    var unit = Unit(
      interfaceGlobalMember: unitInterface,
      configGlobalMember: unitConfigs.first,
      equipments: equipments,
    );
    units.add(unit);
  }

  for (var equipmentInterfaceWithoutUnit in equipmentInterfacesWithoutUnit) {
    logger.warning(
      '    Could not find a ${configGlobalVar.expression}.<UnitName>.'
      '${equipmentInterfaceWithoutUnit.namePath.last}Present as '
      '${_arrayRanges(equipmentInterfaceWithoutUnit.dataTypeBase).toTypeExpression()}BOOL'
      ', and therefor could not generate code to link it to a Unit!',
    );
  }

  return units;
}

List<Variable2> _createEquipmentFunctionBlockVariables(List<Unit> units) {
  List<Equipment> allEquipment = units
      .expand<Equipment>((unit) => unit.equipments)
      .toList();
  var dataTypeBases = allEquipment
      .map((e) => e.interfaceGlobalMember.dataTypeBase)
      .toSet();
  return dataTypeBases
      .map(
        (DataTypeBase d) => Variable2(
          variableName: 'fb${d.name}EqInterface',
          variableType: '${_arrayRanges(d).toTypeExpression()}fbUnitInterface',
        ),
      )
      .toList();
}

ArrayRanges _arrayRanges(DataTypeBase dataTypeBase) {
  if (dataTypeBase is DataType) {
    return (dataTypeBase).baseType.arrayRanges;
  }
  return ArrayRanges();
}

const String fbUnitInterfaceType = 'fbUnitInterface';

String _programName = 'GeneratedByMeynCraft';

List<LadderSection> _createSections(List<Unit> units) {
  var ladderSections = <LadderSection>[];
  for (var unit in units) {
    var rungs = <Rung>[];
    var rungNr = 0;
    rungs.add(Rung.comment(rungNr++, _generatedComment()));
    rungs.add(Rung.comment(rungNr++, _unitInterfaceComment));
    rungs.add(Rung.comment(rungNr++, 'Monitor Start ready')); //TODO
    rungs.add(Rung.comment(rungNr++, 'Monitor Error')); //TODO
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
      LadderSection(
        name: '${unit.name}UnitInterfaces',
        evaluationOrder: 1,
        rungs: rungs,
      ),
    );
  }
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
        functionVariableName: 'iEventSuppress',
      ),
    ],
    [
      FunctionLink(variableName: '', functionVariableName: 'oAlarm'),
      FunctionLink(variableName: '', functionVariableName: 'oWarning'),
      FunctionLink(variableName: '', functionVariableName: 'oStarted'),
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

const String interfaceGlobalVariableName = 'InterfaceGlobal';
const String configGlobalVariableName = 'ConfigGlobal';

VariableMember? _findGlobalVariable(
  SysmacProject sysmacProject,
  String nameToFind,
) {
  var variables = sysmacProject.globalVariableService.variables.where(
    (v) => v.name == nameToFind,
  );
  if (variables.length != 1) {
    logger.warning(
      '  Expected the sysmac project to have 1 global variable of name "$nameToFind"',
    );
    return null;
  }
  var variable = variables.first;
  var variableType = variable.baseType;
  if (variableType is! DataTypeReference) {
    logger.warning('Expected "$nameToFind" to be a DataType');
    return null;
  }
  return VariableMember(variable, variableType.dataType, []);
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

bool _unitInterfacesToEquipmentsFilter(DataTypeBase base) =>
    base is DataType &&
    (base.baseType) is DataTypeReference &&
    (base.baseType as DataTypeReference).dataType.children.any(
      (c) => _matches(c, name: 'PackML', type: r'Generic\Unit\sPackML'),
    );

bool _equipmentInterfacesToUnitFilter(DataTypeBase base) =>
    base is DataType &&
    (base.baseType) is DataTypeReference &&
    (base.baseType as DataTypeReference).dataType.children.any(
      (c) => _matches(c, name: 'Unit', type: r'Generic\Equipment\sInterface'),
    ) &&
    (base.baseType as DataTypeReference).dataType.children.any(
      (c) => _matches(c, name: 'PackML', type: r'Generic\Equipment\sPackML'),
    );

bool _configMemberForUnitFilter(DataTypeBase base, String unitName) =>
    base is DataType && base.name == unitName;

bool _matches(
  DataTypeBase base, {
  required String name,
  required String type,
}) =>
    base.name == name &&
    base is DataType &&
    base.baseType is DataTypeReference &&
    (base.baseType as DataTypeReference).namePathWithBackSlashes
            .toLowerCase() ==
        type.toLowerCase();

class Unit {
  /// the member inside the InterfaceGlobal variable
  /// that represents the unit interface to one or more equipments
  final VariableMember interfaceGlobalMember;

  /// the member inside the ConfigGlobal variable
  /// that represents the unit configuration
  final VariableMember configGlobalMember;
  final List<Equipment> equipments;

  Unit({
    required this.interfaceGlobalMember,
    required this.configGlobalMember,
    required this.equipments,
  });

  late final String name = interfaceGlobalMember.namePath.last;
}

class Equipment {
  /// the member inside the InterfaceGlobal variable
  /// that represents the equipment interface with a unit
  final VariableMember interfaceGlobalMember;

  /// the member inside the ConfigGlobal variable
  /// that represents a boolean whether this equipment is present
  final VariableMember configGlobalPresentMember;

  late final String name = interfaceGlobalMember.namePath.last;

  Equipment({
    required this.interfaceGlobalMember,
    required this.configGlobalPresentMember,
  });

  late final List<String> arrayValues = _arrayValues();

  ArrayRanges _arrayRanges() {
    var dataTypeBase = interfaceGlobalMember.dataTypeBase;
    if (dataTypeBase is DataType) {
      return dataTypeBase.baseType.arrayRanges;
    }
    return ArrayRanges();
  }

  List<String> _arrayValues() {
    var arrayRanges = _arrayRanges();
    if (arrayRanges.isEmpty) {
      return [''];
    }
    return arrayRanges.toStringList();
  }
}

/// contains information of a member somewhere in a [variable]
class VariableMember {
  final Variable variable;
  final DataTypeBase dataTypeBase;
  final List<String> namePath;

  VariableMember(this.variable, this.dataTypeBase, List<String> namePath)
    : namePath = [variable.name, ...namePath];

  late final String expression = namePath.join('.');

  List<VariableMember> find(bool Function(DataTypeBase base) filter) {
    var paths = dataTypeBase.findPaths(filter, forEachArrayValue: false);
    return paths
        .map(
          (p) => VariableMember(variable, p.dataTypeBase, [
            ...namePath.skip(1),
            ...p.namePath.skip(1),
          ]),
        )
        .toList();
  }
}
