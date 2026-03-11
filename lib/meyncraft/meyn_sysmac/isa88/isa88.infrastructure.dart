import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/isa88/isa88.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';

/// See [Isa88Node]
List<Isa88Node> createMeynIsa88Nodes(SysmacProject sysmacProject) {
  var allCallPaths = findAllCallPaths(sysmacProject);
  var isa88Nodes = <Isa88Node>[];

  var fbUnitControlCallPaths = allCallPaths.where(isFbUnitControl);

  for (var fbUnitControlCallPath in fbUnitControlCallPaths) {
    var unit = createUnit(sysmacProject, allCallPaths, fbUnitControlCallPath);
    if (unit != null) {
      isa88Nodes.add(unit);
    }
  }

  return isa88Nodes;
}

NodePathWithIndexes? _variableToEquipment(
  List<Variable> globalVariables,
  CallPath fbUnitInterfaceCallPath,
) {
  final RegExp unitSuffix = RegExp(r'\.Unit$', caseSensitive: false);
  var variableToEquipmentExpression = fbUnitInterfaceCallPath.call.parametersIn
      .firstWhere((parameter) => parameter.argument == 'ioEquipment')
      .variable
      ?.replaceAll(unitSuffix, '');

  if (variableToEquipmentExpression == null) return null;

  var variableToEquipment =
      (globalVariables.findFirstNodePath(
            namePathWithIndexesFinder(variableToEquipmentExpression.split('.')),
          )
          as NodePathWithIndexes);
  if (variableToEquipment.isEmpty) {
    logger.warning(
      'Could not find global variable: $variableToEquipmentExpression',
    );
  }

  return variableToEquipment;
}

List<EquipmentModule> _createEquipmentModules(
  List<Variable> globalVariables,
  NodePathWithIndexes variableFromUnit,
  List<CallPath> allCallPaths,
) {
  var fbUnitInterfaceCallPaths = allCallPaths.where(
    (callPath) =>
        isFbUnitInterface(callPath) &&
        isLinkedToUnit(
          variableFromUnit.toNamePathWithArrayIndexes().join('.'),
          callPath,
        ),
  );

  var equipmentModules = <EquipmentModule>[];
  for (var fbUnitInterfaceCallPath in fbUnitInterfaceCallPaths) {
    var variableToEquipment = _variableToEquipment(
      globalVariables,
      fbUnitInterfaceCallPath,
    );
    if (variableToEquipment == null) continue;

    var equipmentCallPath = findEquipmentCallPath(
      allCallPaths,
      variableToEquipment,
    );

    if (equipmentCallPath != null &&
        equipmentCallPath.call.name != 'fbEventHandling') {
      var argumentsAndControlModules = createArgumentsAndControlModules(
        globalVariables,
        allCallPaths,
        equipmentCallPath,
      );

      var name =
          '${variableToEquipment.last.name}'
          '${variableToEquipment.arrayIndexes.last ?? ""}';

      var equipmentModule = EquipmentModule(
        name: name,
        variableFromParent: variableToEquipment,
        fbUnitInterfaceCallPath: fbUnitInterfaceCallPath,
        callPath: equipmentCallPath,
        argumentsAndModules: argumentsAndControlModules,
      );
      equipmentModules.add(equipmentModule);
    }
  }
  return equipmentModules;
}

/// Key: function (block) parameter argument tied to the [ControlModule]
/// Value: [ControlModule]
Map<String, ControlModule> createArgumentsAndControlModules(
  List<Variable> globalVariables,
  List<CallPath> allCallPaths,
  CallPath equipmentCallPath,
) {
  var argumentsAndVariableExpressions = <String, String>{
    for (var parameterIn in equipmentCallPath.call.parametersIn)
      parameterIn.argument: parameterIn.variable ?? '',
    for (var parameterOut in equipmentCallPath.call.parametersOut)
      parameterOut.argument: parameterOut.variable ?? '',
  };

  /// TODO: we need a relation with the scope of callPaths
  var variables = [
    // callPath = allCallPaths where((callPath) => callPath.program==equipmentCallPath.program)
    ...equipmentCallPath.program.internalVariables,
    // callPath = allCallPaths
    ...globalVariables,
  ];

  var argumentsAndVariables = Map.fromEntries(
    argumentsAndVariableExpressions
        .map(
          (argument, variableExpression) => MapEntry(
            argument,
            variables.findFirstNodePath(
              namePathWithIndexesFinder(variableExpression.split('.')),
            ),
          ),
        )
        .entries
        .where(
          (entry) =>
              entry.value.isNotEmpty && entry.value is NodePathWithIndexes,
        ),
  ).map((key, value) => MapEntry(key, value as NodePathWithIndexes));

  var argumentsAndControlVariables = Map.fromEntries(
    argumentsAndVariables.entries.where(
      (entry) => isControlModuleVariable(entry.value),
    ),
  );

  var argumentsAndControlModules = Map.fromEntries(
    argumentsAndControlVariables
        .map(
          (argument, controlVariable) => MapEntry(
            argument,
            createControlModule(allCallPaths, controlVariable),
          ),
        )
        .entries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, entry.value as ControlModule)),
  );

  return argumentsAndControlModules;
}

ControlModule? createControlModule(
  List<CallPath> allCallPaths,
  NodePathWithIndexes controlVariable,
) {
  var variableExpression = controlVariable.toNamePathWithArrayIndexes().join(
    '.',
  );

  /// TODO: limit the callPaths to a specific program if variableExpression is a internal variable
  var callPath = allCallPaths.firstWhereOrNull(
    (callPath) => callPath.call.parametersIn.any(
      (parameter) => parameter.variable == variableExpression,
    ),
  );

  if (callPath == null) return null;

  var name =
      '${controlVariable.last.name}'
      '${controlVariable.arrayIndexes.last ?? ""}';

  return ControlModule(
    name: name,
    variableFromParent: controlVariable,
    callPath: callPath,
    argumentsAndControlModules: {},
  );
}

CallPath? findEquipmentCallPath(
  List<CallPath> callPaths,
  NodePath unitEquipmentInterface,
) {
  var interface = (unitEquipmentInterface is NodePathWithIndexes)
      ? unitEquipmentInterface.toNamePathWithArrayIndexes().join('.')
      : unitEquipmentInterface.toNamePath().join('.');
  for (var callPath in callPaths) {
    if (callPath.call.name != 'fbUnitInterface' &&
        callPath.call.parametersIn.any(
          (parameter) => parameter.variable == interface,
        )) {
      return callPath;
    }
  }
  return null;
}

var packMlSuffix = RegExp(r'\.PackML$', caseSensitive: false);

Unit? createUnit(
  SysmacProject sysmacProject,
  List<CallPath> allCallPaths,
  CallPath unitCallPath,
) {
  var interfaceExpression = unitCallPath.call.parametersIn
      .where((parameter) => parameter.argument == 'ioUnitPackML')
      .first
      .variable
      ?.replaceAll(packMlSuffix, '');

  if (interfaceExpression == null) return null;

  var unitToEquipmentModuleInterface =
      sysmacProject.globalVariables.findFirstNodePath(
            namePathWithIndexesFinder(interfaceExpression.split('.')),
          )
          as NodePathWithIndexes;
  if (unitToEquipmentModuleInterface.isEmpty) return null;

  var name =
      '${unitToEquipmentModuleInterface.last.name}'
      '${unitToEquipmentModuleInterface.arrayIndexes.last ?? ""}';

  var equipmentModules = _createEquipmentModules(
    sysmacProject.globalVariables,
    unitToEquipmentModuleInterface,
    allCallPaths,
  );

  return Unit(
    name: name,
    callPath: unitCallPath,
    variableToEquipment: unitToEquipmentModuleInterface,
    equipmentModules: equipmentModules,
  );
}

List<CallPath> findAllCallPaths(SysmacProject sysmacProject) {
  var codeOwners = sysmacProject.devices.whereType<CodeOwner>();
  var callPaths = <CallPath>[];
  for (var codeOwner in codeOwners) {
    for (var program in codeOwner.programs.whereType<LadderProgram>()) {
      for (var section in program) {
        for (var rung in section.rungs) {
          for (var call in rung.ladderObjects.whereType<Call>()) {
            var callPath = CallPath(
              codeOwner: codeOwner,
              program: program,
              ladderSection: section,
              call: call,
            );
            callPaths.add(callPath);
          }
        }
      }
    }
  }
  return callPaths;
}

/// returns true when it is a [FunctionBlockCall] of type fbUnitControl
bool isFbUnitControl(CallPath callPath) =>
    callPath.call is FunctionBlockCall && callPath.call.name == 'fbUnitControl';

/// returns true when it is a [FunctionBlockCall] of type fbUnitInterface
bool isFbUnitInterface(CallPath callPath) =>
    callPath.call is FunctionBlockCall &&
    callPath.call.name == 'fbUnitInterface';

/// true if a fbUnitInterface is linked to [unitEquipmentInterface]
bool isLinkedToUnit(String unitEquipmentInterface, CallPath callPath) =>
    callPath.call.parametersIn.any(
      (parameter) => (parameter.variable == null
          ? false
          : parameter.variable!.replaceAll(packMlSuffix, '') ==
                unitEquipmentInterface),
    );

bool isControlModuleVariable(NodePath variablePath) {
  BaseType baseType;
  if (variablePath.last is Variable) {
    baseType = (variablePath.last as Variable).baseType;
  } else if (variablePath.last is DataTypeMember) {
    baseType = (variablePath.last as DataTypeMember).baseType;
  } else {
    return false;
  }
  if (baseType is! DataTypeReference) return false;
  return _startsWithControlModuleNameSpace(baseType);
}

bool _startsWithControlModuleNameSpace(DataTypeReference dataTypeReference) {
  if (dataTypeReference.dataTypePath.isEmpty) return false;
  var dataTypePath = dataTypeReference.dataTypePath;
  return dataTypePath.first.name.toLowerCase() == 'cm';
}
