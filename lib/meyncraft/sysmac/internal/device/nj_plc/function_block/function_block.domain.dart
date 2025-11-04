import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';

abstract class FunctionBlock {
  String get name;
  CodeType get codeType;
}

class StructuredTextFunctionBlock implements FunctionBlock {
  @override
  final String name;
  @override
  final codeType = CodeType.structuredText;
  final String structuredText;

  StructuredTextFunctionBlock({
    required this.name,
    required this.structuredText,
  });

  @override
  String toString() => name;
}

class LadderFunctionBlock implements FunctionBlock {
  @override
  final String name;
  @override
  final codeType = CodeType.ladder;
  final List<Rung> rungs;

  LadderFunctionBlock({required this.name, required this.rungs});

  @override
  String toString() => name;
}
