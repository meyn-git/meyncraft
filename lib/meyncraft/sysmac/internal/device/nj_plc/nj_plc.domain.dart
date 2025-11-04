import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';

class NjPlc implements Device, CodeOwner {
  @override
  final String name;
  @override
  final String type;
  //TODO IP address?
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
