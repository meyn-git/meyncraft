import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/isa88/isa88.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';

/// See [Isa88Node]
List<Isa88Node> createMeynIsa88Nodes(SysmacProject sysmacProject) {
  var callPaths = findCallPaths(sysmacProject);
  var isa88Nodes = <Isa88Node>[];

  var fbUnitControlCallPaths = callPaths.where(isFbUnitControl);

  for (var fbUnitControlCallPath in fbUnitControlCallPaths) {
    var unit = createUnit(sysmacProject, callPaths, fbUnitControlCallPath);
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
  List<CallPath> callPaths,
) {
  var fbUnitInterfaceCallPaths = callPaths.where(
    (callPath) =>
        isFbUnitInterface(callPath) &&
        isLinkedToUnit(
          variableFromUnit.namePathWithArrayIndexes.join('.'),
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
      callPaths,
      variableToEquipment,
    );

    if (equipmentCallPath != null &&
        equipmentCallPath.call.name != 'fbEventHandling') {
      var controlModules = createParameterNamesAndControlModules();

      var name =
          '${variableToEquipment.last.name}'
          '${variableToEquipment.arrayIndexes.last ?? ""}';

      var equipmentModule = EquipmentModule(
        name: name,
        variableFromParent: variableToEquipment,
        fbUnitInterfaceCallPath: fbUnitInterfaceCallPath,
        callPath: equipmentCallPath,
        children: controlModules,
      );
      equipmentModules.add(equipmentModule);
    }
  }
  return equipmentModules;
}

Map<String, ControlModule> createParameterNamesAndControlModules() => {};

CallPath? findEquipmentCallPath(
  List<CallPath> callPaths,
  NodePath unitEquipmentInterface,
) {
  var interface = (unitEquipmentInterface is NodePathWithIndexes)
      ? unitEquipmentInterface.namePathWithArrayIndexes.join('.')
      : unitEquipmentInterface.namePath.join('.');
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
  List<CallPath> callPaths,
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
    callPaths,
  );

  return Unit(
    name: name,
    callPath: unitCallPath,
    variableToEquipment: unitToEquipmentModuleInterface,
    equipmentModules: equipmentModules,
  );
}

List<CallPath> findCallPaths(SysmacProject sysmacProject) {
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
