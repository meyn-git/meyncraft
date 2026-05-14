import 'package:meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/library/library.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';

abstract class Device {
  String get name;
  String get type;
}

abstract class CodeOwner {
  String get name;
  String get type;
  List<Library> get libraries;
  List<Program> get programs;
  Map<CodeOwner, List<Program>> get allPrograms;
  List<Function$> get functions;
  Map<CodeOwner, List<Function$>> get allFunctions;
  List<FunctionBlock> get functionBlocks;
  Map<CodeOwner, List<FunctionBlock>> get allFunctionBlocks;
}

class NesSafetyPlc implements Device {
  @override
  final String name;
  @override
  final String type;

  NesSafetyPlc({required this.name, required this.type});

  @override
  String toString() => name;
}

class NaHmi implements Device {
  @override
  final String name;
  @override
  final String type;

  NaHmi({required this.name, required this.type});

  @override
  String toString() => name;
}
