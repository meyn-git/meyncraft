import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';

class NjPlc implements Device, CodeOwner {
  @override
  final String name;
  @override
  final String type;
  //TODO IP address?

  /// TODO are libraties owned by the project or by the PLC?
  @override
  final List<Library> libraries;
  @override
  final List<Program> programs;
  @override
  final List<Function$> functions;
  @override
  final List<FunctionBlock> functionBlocks;

  NjPlc({
    required this.name,
    required this.type,
    required this.libraries,
    required this.programs,
    required this.functions,
    required this.functionBlocks,
  });

  @override
  late final Map<CodeOwner, List<Program>> allPrograms = {
    this: programs,
    for (var library in libraries) ...library.allPrograms,
  };

  @override
  late final Map<CodeOwner, List<Function$>> allFunctions = {
    this: functions,
    for (var library in libraries) ...library.allFunctions,
  };

  @override
  late final Map<CodeOwner, List<FunctionBlock>> allFunctionBlocks = {
    this: functionBlocks,
    for (var library in libraries) ...library.allFunctionBlocks,
  };

  @override
  String toString() => name;
}

/// There are three main types of Program Organization Units (POUs):
///
/// - **Program**: The top-level block that typically contains the main logic
///   of the application. It can call functions and function blocks.
///
/// - **Function Block (FB)**: A reusable block of code that can maintain
///   internal state (like memory). It's ideal for modeling components such as
///   motors, valves, or PID controllers.
///
/// - **Function (FUN)**: A block of code that performs a specific task and

abstract class ProgramOrganizationUnit {
  String get name;
  CodeType get codeType;
  List<Variable> get internalVariables;
  List<Variable> get externalVariables;
}
