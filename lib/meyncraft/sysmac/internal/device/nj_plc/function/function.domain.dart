import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';

abstract class Function$ {
  String get name;
  CodeType get codeType;
}

class LadderFunction implements Function$ {
  @override
  final String name;
  @override
  final codeType = CodeType.ladder;
  final List<Rung> rungs;

  LadderFunction({required this.name, required this.rungs});

  @override
  String toString() => name;
}

class StructuredTextFunction implements Function$ {
  @override
  final String name;
  @override
  final codeType = CodeType.structuredText;
  final String structuredText;

  StructuredTextFunction({required this.name, required this.structuredText});

  @override
  String toString() => name;
}
