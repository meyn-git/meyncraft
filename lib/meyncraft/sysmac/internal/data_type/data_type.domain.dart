import '../base_type/base_type.domain.dart';
import '../../node.domain.dart';

extension DataTypeBaseListExtension on List<DataTypeBase> {
  List<DataTypeBase> get descendants {
    List<DataTypeBase> all = [];
    for (var child in this) {
      all.add(child);
      all.addAll(child.descendants);
    }
    return all;
  }

  NodePath findFirstNodePath(NodePathFinder finder) {
    for (var child in this) {
      var result = finder(child);
      if (result.isNotEmpty) {
        return result;
      }
    }
    return const NodePath.empty();
  }

  List<NodePath> findAllNodePaths(NodePathsFinder finder) {
    var nodePaths = <NodePath>[];
    for (var child in this) {
      var foundNodePaths = finder(child);
      if (foundNodePaths.isNotEmpty) {
        nodePaths.addAll(foundNodePaths);
      }
    }
    return nodePaths;
  }
}

/// Abstract base type of [DataType]s and [NameSpace]s
abstract class DataTypeBase extends Node<DataTypeBase> {
  @override
  final String name;
  @override
  final String comment;

  DataTypeBase(this.name, [this.comment = '']);
}

/// [NameSpace] is a [DataType] with a name and comment only
class NameSpace extends DataTypeBase {
  NameSpace(super.name, [super.comment]);

  @override
  List<DataTypeBase> children = <DataTypeBase>[];
}

/// A [DataType] is a custom data type that is made of [BaseType]s
class DataType extends DataTypeBase {
  BaseType baseType;

  final List<DataTypeBase> _children = [];

  DataType({required String name, required this.baseType, String comment = ''})
    : super(name, comment);

  @override
  List<DataTypeBase> get children {
    if (baseType is DataTypeReference) {
      return (baseType as DataTypeReference).dataType.children;
    } else {
      return _children;
    }
  }

  @override
  String toString() {
    String string =
        '$DataType{name: $name, comment: $comment, baseType: $baseType}';
    for (var child in children) {
      var lines = child.toString().split('\n');
      for (var line in lines) {
        string += "\n  $line";
      }
    }
    return string;
  }
}
