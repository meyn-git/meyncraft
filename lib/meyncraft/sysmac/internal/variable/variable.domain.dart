import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';

@Deprecated('Use Variable')
class VariableOld extends DataType {
  VariableOld({
    required super.name,
    required super.baseType,
    required super.comment,
  });

  @override
  String toString() {
    String string =
        '$VariableOld{name: $name, comment: $comment, dataType: $baseType}';
    for (var child in children) {
      var lines = child.toString().split('\n');
      for (var line in lines) {
        string += "\n  $line";
      }
    }
    return string;
  }
}

class Variable 
//TODO extends Node<DataTypeBase> 
{
  @override
  final String name;
  final String comment;
  final NetworkPublish networkPublish;
  final BaseType baseType;
  final String? hardwareAddress;
  final VariableDirection? direction;
  final bool isRetained;
  final bool isConstant;
  final String? initialValue;
  // TODO
  // @override
  // late final List<DataTypeBase> children = baseType is DataTypeReference
  //     ? (baseType as DataTypeReference).dataType.children
  //     : [];

  Variable({
    required this.name,
    required this.comment,
    required this.networkPublish,
    required this.baseType,
    this.hardwareAddress,
    this.direction,
    this.isRetained = false,
    this.isConstant = false,
    this.initialValue,
  });
}

enum VariableGroup {
  global,
  internal,
  external,
  unknown,
  functionInOut,
  functionReturn,
}

enum VariableDirection { in$, out, inOut }

/// contains information of a member somewhere in a [variable]
class VariableMember {
  final Variable variable;
  final DataTypeBase dataTypeBase;
  final List<String> namePath;

  VariableMember(this.variable, this.dataTypeBase, List<String> namePath)
    : namePath = [variable.name, ...namePath];

  late final String expression = namePath.join('.');

  List<VariableMember> find(bool Function(DataTypeBase base) filter) {
    var paths = dataTypeBase.findPaths(filter, forEachArrayValue: false);
    return paths
        .map(
          (p) => VariableMember(variable, p.dataTypeBase, [
            ...namePath.skip(1),
            ...p.namePath.skip(1),
          ]),
        )
        .toList();
  }
}
