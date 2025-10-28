import 'package:collection/collection.dart';

/// For [ProgramBody]s, [FunctionBody]s, and [FunctionBlockBody]s
abstract class ProgramOrganizationUnit {
  String get name;
}

class Programs extends DelegatingList<Program>
    implements ProgramOrganizationUnit {
  @override
  final String name = 'Programs';

  Programs(super.programs);

  @override
  String toString() => toIndentedString(name, this);
}

class Program extends DelegatingList<ProgramBody>
    implements ProgramOrganizationUnit {
  @override
  final String name;

  Program(this.name, List<ProgramBody> programBodies) : super(programBodies);

  @override
  String toString() => toIndentedString(name, this);
}

abstract class PouBody {
  String get name;
}

abstract class ProgramBody implements PouBody {}

class StructuredTextBody extends ProgramBody {
  @override
  final String name;
  final String structuredText;
  StructuredTextBody({required this.name, required this.structuredText});
}

class LadderBody extends ProgramBody {
  @override
  final String name;
  final List<Rung> rungs;

  LadderBody(this.name, this.rungs);

  @override
  String toString() => name;
}

class Rung {
  final String? comment;
  final List<LadderObject> ladderObjects;
  Rung(this.ladderObjects, [this.comment]);
}

abstract class LadderObject {}

class Contact extends LadderObject {
  final String variable;
  Contact._(this.variable);

  factory Contact(Map<String, dynamic> map) {
    var variable = map['Var'] as String;
    return Contact._(variable);
  }
}

class Coil extends LadderObject {
  final String variable;
  Coil._(this.variable);

  factory Coil(Map<String, dynamic> map) {
    var variable = map['Var'] as String;

    return Coil._(variable);
  }
}

class Functions extends DelegatingList<FunctionBody>
    implements ProgramOrganizationUnit {
  Functions(super.functions);

  @override
  final String name = 'Functions';
}

class FunctionBody implements PouBody {
  @override
  final String name;
  final String structuredText;

  FunctionBody({required this.name, required this.structuredText});
}

class FunctionBlocks extends DelegatingList<FunctionBlockBody>
    implements ProgramOrganizationUnit {
  FunctionBlocks(super.functions);

  @override
  final String name = 'FunctionBlocks';
}

class FunctionBlockBody implements PouBody {
  @override
  final String name;
  final String structuredText;

  FunctionBlockBody({required this.name, required this.structuredText});
}

String toIndentedString(String title, List<Object> objects) {
  var result = StringBuffer();
  result.writeln(title);
  for (var obj in objects) {
    var asString = obj.toString();
    if (asString.isNotEmpty) {
      var lines = asString.split('\n');
      var first = true;
      for (var line in lines) {
        result.write(first ? '* ' : '  ');
        first = false;
        result.writeln(line);
      }
    }
  }
  return result.toString();
}
