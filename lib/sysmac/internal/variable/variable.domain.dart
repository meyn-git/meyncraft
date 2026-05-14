import 'package:meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/sysmac/node.domain.dart';

class Variable extends Node<DataTypeBase> implements BaseTypeOwner {
  @override
  final String name;
  @override
  final String comment;
  final NetworkPublish networkPublish;
  @override
  BaseType baseType;
  final String? hardwareAddress;
  final VariableDirection? direction;
  final bool isRetained;
  final bool isConstant;
  final String? initialValue;

  @override
  List<DataTypeBase> get children {
    var leaf = baseTypeLeaf(baseType);
    if (leaf is DataType) {
      return leaf.children;
    } else {
      return [];
    }
  }

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

extension VariableListExtension on List<Variable> {
  NodePath findFirstNodePath<T extends NodePath>(NodePathFinder<T> finder) {
    for (var child in this) {
      var result = finder(child);
      if (result.isNotEmpty) {
        return result;
      }
    }
    return const NodePath.empty();
  }

  List<T> findAllNodePaths<T extends NodePath>(NodePathsFinder<T> finder) {
    var nodePaths = <T>[];
    for (var child in this) {
      var foundNodePaths = finder(child);
      if (foundNodePaths.isNotEmpty) {
        nodePaths.addAll(foundNodePaths);
      }
    }
    return nodePaths;
  }
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
