import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';

/// See: https://en.wikipedia.org/wiki/ISA-88
/// An ISA 88 node is one of the following (from stand to leafs):
/// * ProcessCell
/// * [Unit]
/// * [EquipmentModule]
/// * [ControlModule]
abstract class Isa88Node {
  String get name;
  CallPath get callPath;
}

class Unit implements Isa88Node {
  @override
  final String name;

  @override
  final CallPath callPath;

  final List<EquipmentModule> equipmentModules;
  final NodePathWithIndexes variableToEquipment;

  Unit({
    required this.name,
    required this.callPath,
    required this.equipmentModules,
    required this.variableToEquipment,
  });

  @override
  String toString() =>
      'Unit(name: $name, '
      'variableToEquipment: ${variableToEquipment.namePathWithArrayIndexes.join('.')}, '
      'callPath: $callPath )';
}

abstract class ModuleNode extends Isa88Node {
  NodePath get variableFromParent;
}

class EquipmentModule implements ModuleNode {
  @override
  final NodePathWithIndexes variableFromParent;

  @override
  final CallPath callPath;

  final CallPath? fbUnitInterfaceCallPath;

  final Map<
    /// Function block parameterName
    String,

    /// Either a [EquipmentModule] or [ControlModule]
    ModuleNode
  >
  children;

  @override
  final String name;

  EquipmentModule({
    required this.name,
    required this.variableFromParent,
    this.fbUnitInterfaceCallPath,
    required this.callPath,
    required this.children,
  });

  @override
  String toString() =>
      'EquipmentModule(name: $name, '
      'variableFromParent: ${variableFromParent.namePathWithArrayIndexes.join('.')}, '
      'callPath: $callPath )';
}

class ControlModule implements ModuleNode {
  @override
  final NodePathWithIndexes variableFromParent;

  @override
  final CallPath callPath;

  final Map<
    /// Function block parameterName
    String,
    ControlModule
  >
  controlModules;

  @override
  final String name;

  ControlModule({
    required this.name,
    required this.variableFromParent,
    required this.callPath,
    required this.controlModules,
  });

  @override
  String toString() =>
      'ControlModule(name: $name'
      'variableFromParent: ${variableFromParent.namePathWithArrayIndexes.join('.')}, '
      'callPath: $callPath )';
}

/// A path to a Function (Block) call, e.g. CodeOwner.Program.Section.Rung.FunctionBlockCall
class CallPath {
  final CodeOwner codeOwner;
  final Program program;
  final LadderSection ladderSection;
  final Call call;

  CallPath({
    required this.codeOwner,
    required this.program,
    required this.ladderSection,
    required this.call,
  });

  @override
  String toString() =>
      '${codeOwner.name}.'
      '${program.name}.'
      '${ladderSection.name}.'
      '${call is FunctionBlockCall ? "${(call as FunctionBlockCall).variable} of ${call.name}" : call.name}';
}
