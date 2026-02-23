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

/// Types that the programmer defines, or that Sysmac creates automatically.
abstract interface class CustomType implements BaseType {}

/// Abstract base type of [DataType]s and [NameSpace]s
abstract interface class DataTypeBase extends Node<DataTypeBase>
    implements CustomType {}

/// [NameSpace] is a [DataType] with a name and comment only
class NameSpace extends DataTypeBase {
  @override
  final String name;

  @override
  final String comment;

  @override
  final List<DataTypeBase> children;

  NameSpace({
    required this.name,
    this.comment = '',
    List<DataTypeBase>? children,
  }) : children = children ?? <DataTypeBase>[];
}

/// A [DataType] is a custom data type that is made of [BaseType]s
abstract interface class DataType extends DataTypeBase {}

/// A [DataTypeMember] is a child of a [Structure] or a child of a [Union]
///
/// Its [baseType] is either an
/// * a [BasicType]
/// * a [DataTypeReference]
class DataTypeMember extends DataType implements BaseTypeOwner {
  @override
  final String name;

  @override
  final String comment;

  @override
  BaseType baseType;

  @override
  List<DataTypeBase> get children {
    var leaf = baseTypeLeaf(baseType);
    if (leaf is DataType) {
      return leaf.children;
    } else {
      return [];
    }
  }

  DataTypeMember({
    required this.name,
    required this.comment,
    required this.baseType,
  });
}

/// Refers to a DataType or one of its children
/// This BaseType is normally owned by a [Variable], [ArrayType] or [DataTypeMember]
class DataTypeReference implements BaseType, BaseTypeOwner {
  final NodePath dataTypePath;
  @override
  late BaseType baseType;

  DataTypeReference({required this.dataTypePath}) {
    if (dataTypePath.isEmpty) {
      throw ArgumentError('DataTypeReference.dataTypePath may not be empty');
    }
    baseType = dataTypePath.last as BaseType;
  }
}

// class UnknownDataTypeBase extends DataType {
//   @override
//   final String name;

//   @override
//   final String comment;

//   @override
//   final List<DataTypeBase> children = const [];

//   final String typeExpression;

//   UnknownDataTypeBase({
//     required this.name,
//     required this.comment,
//     required this.typeExpression,
//   });

//   @override
//   String toString() => 'UnknownDataTypeBase($typeExpression)';
// }

class Structure extends DataType {
  @override
  final String name;

  @override
  final String comment;

  @override
  final List<DataTypeMember> children;

  Structure({
    required this.name,
    required this.comment,
    required this.children,
  });
}

class Union extends DataType {
  @override
  final String name;

  @override
  final String comment;

  @override
  final List<DataTypeMember> children;

  Union({required this.name, required this.comment, required this.children});
}

class Enumeration extends DataType {
  @override
  final String name;

  @override
  final String comment;

  @override
  final List<EnumerationMember> children;

  Enumeration({
    required this.name,
    required this.comment,
    required this.children,
  });
}

class EnumerationMember extends DataType implements BaseTypeOwner {
  @override
  final String name;

  @override
  final String comment;

  @override
  BaseType baseType;

  final int index;

  @override
  final List<DataType> children = const [];

  EnumerationMember({
    required this.name,
    required this.comment,
    required this.baseType,
    required this.index,
  });
}
