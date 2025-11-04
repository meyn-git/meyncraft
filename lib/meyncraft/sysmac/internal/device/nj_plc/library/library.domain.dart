import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';

class Library implements CodeOwner {
  @override
  final String name;
  @override
  final String type = 'Library';
  @override
  final List<Library> libraries;
  @override
  final List<FunctionBlock> functionBlocks;
  @override
  final List<Function$> functions;
  @override
  final List<Program> programs;

  Library(
    this.name,
    this.libraries,
    this.programs,
    this.functions,
    this.functionBlocks,
  );

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
}
