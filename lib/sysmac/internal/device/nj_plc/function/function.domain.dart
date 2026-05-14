import 'package:meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/nj_plc.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/sysmac/internal/variable/variable.domain.dart';

abstract class Function$ extends ProgramOrganizationUnit {
  List<Variable> get inOutVariables;
}

class LadderFunction implements Function$ {
  @override
  final String name;
  @override
  final codeType = CodeType.ladder;
  @override
  final List<Variable> externalVariables;
  @override
  final List<Variable> internalVariables;
  @override
  final List<Variable> inOutVariables;

  final List<Rung> rungs;

  LadderFunction({
    required this.name,
    required this.internalVariables,
    required this.externalVariables,
    required this.inOutVariables,
    required this.rungs,
  });

  @override
  String toString() => name;
}

class StructuredTextFunction implements Function$ {
  @override
  final String name;
  @override
  final codeType = CodeType.structuredText;
  @override
  final List<Variable> externalVariables;
  @override
  final List<Variable> internalVariables;
  @override
  final List<Variable> inOutVariables;

  final String structuredText;

  StructuredTextFunction({
    required this.name,
    required this.internalVariables,
    required this.externalVariables,
    required this.inOutVariables,
    required this.structuredText,
  });

  @override
  String toString() => name;
}
