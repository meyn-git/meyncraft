import 'package:collection/collection.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/nj_plc.domain.dart';
import 'package:meyncraft/sysmac/internal/variable/variable.domain.dart';

abstract class Program extends ProgramOrganizationUnit {}

class LadderProgram extends DelegatingList<LadderSection> implements Program {
  @override
  final String name;
  @override
  final codeType = CodeType.ladder;
  @override
  final List<Variable> externalVariables;
  @override
  final List<Variable> internalVariables;

  LadderProgram({
    required this.name,
    required this.internalVariables,
    required this.externalVariables,
    required List<LadderSection> ladderSections,
  }) : super(ladderSections);

  @override
  String toString() => name;
}

class StructuredTextProgram implements Program {
  @override
  final String name;
  @override
  final codeType = CodeType.structuredText;
  @override
  final List<Variable> externalVariables;
  @override
  final List<Variable> internalVariables;

  final String structuredText;
  StructuredTextProgram({
    required this.name,
    required this.internalVariables,
    required this.externalVariables,
    required this.structuredText,
  });

  @override
  String toString() => name;
}

class LadderSection {
  final String name;
  final List<Rung> rungs;

  LadderSection(this.name, this.rungs);

  @override
  String toString() => name;
}

class Rung {
  final String? comment;
  final List<LadderObject> ladderObjects;
  Rung(this.ladderObjects, [this.comment]);
}

abstract class LadderObject {}

class HorizontalLine implements LadderObject {
  final int x;
  final int y;

  HorizontalLine({required this.x, required this.y});
}

class VerticalLine implements LadderObject {
  final int index;
  final int x;
  final int y;

  VerticalLine({required this.index, required this.x, required this.y});
}

class Contact implements LadderObject {
  final String variable;
  final int index;
  final int x;
  final int y;
  final EdgeDetection edgeDetection;
  final bool negated;

  Contact(
    this.variable, {
    required this.index,
    required this.x,
    required this.y,
    required this.edgeDetection,
    required this.negated,
  });
}

class Coil implements LadderObject {
  final String variable;
  final int index;
  final int x;
  final int y;
  final EdgeDetection edgeDetection;
  final ActuationMode actuationMode;
  final bool negated;

  Coil(
    this.variable, {
    required this.index,
    required this.x,
    required this.y,
    required this.edgeDetection,
    required this.actuationMode,
    required this.negated,
  });
}

enum EdgeDetection { none, up, down }

enum ActuationMode { none, set, reset }

class Jump implements LadderObject {
  final int x;
  final int y;
  final int index;
  final String label;

  Jump({
    required this.x,
    required this.y,
    required this.index,
    required this.label,
  });
}

class Parameter {
  final ParameterType type;
  final String argument;
  final String? argumentType;
  final String? variable;
  final bool? inAndOut;
  final int index;
  Parameter({
    required this.type,
    required this.argument,
    this.argumentType,
    this.variable,
    this.inAndOut,
    required this.index,
  });
}

enum ParameterType { parameter, inOutConnection }

/// A Call to a [Function] or a [FunctionBlock]
abstract class Call implements LadderObject {
  String get name;
  int get index;
  int get x;
  int get y;
  List<Parameter> get parametersIn;
  List<Parameter> get parametersOut;
}

class FunctionCall implements Call {
  @override
  final String name;
  @override
  final int index;
  @override
  final int x;
  @override
  final int y;
  @override
  final List<Parameter> parametersIn;
  @override
  final List<Parameter> parametersOut;
  final bool ud;
  final bool pl;

  FunctionCall(
    this.name, {
    required this.index,
    required this.x,
    required this.y,
    required this.parametersIn,
    required this.parametersOut,
    required this.ud,
    required this.pl,
  });
}

class FunctionBlockCall implements Call {
  @override
  final String name;
  @override
  final int index;
  @override
  final int x;
  @override
  final int y;
  @override
  final List<Parameter> parametersIn;
  @override
  final List<Parameter> parametersOut;
  final String variable;
  final bool ud;

  FunctionBlockCall(
    this.name, {
    required this.variable,
    required this.index,
    required this.x,
    required this.y,
    required this.parametersIn,
    required this.parametersOut,
    required this.ud,
  });
}

class InlineStructuredText implements LadderObject {
  final String structuredText;
  final int index;
  final int x;
  final int y;

  InlineStructuredText(
    this.structuredText, {
    required this.index,
    required this.x,
    required this.y,
  });
}
