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

/// TODO We might need to generalize to a ReferenceType that can also reference to functions or functionBlocks
/// Reference to either:
/// * a [BasicType]
/// * a [DataType] or one of its children
///
/// A [DataTypeReference] is often a child of a [Structure] or a child of a [Union]
class DataTypeReference extends DataType {
  @override
  final String name;

  @override
  final String comment;

  final BasicType? basicType;

  /// Either:
  /// * An empty NodePath when [basicType] is not null (e.g. a [ArrayType] or an [IecType])
  /// * The path to the referenced [DataTypeBase] or one of its children
  final NodePath dataTypePath;

  late final BaseType baseType = _baseType();

  BaseType _baseType() {
    if (basicType != null) {
      return basicType!;
    }
    if (dataTypePath.last is DataTypeReference) {
      return (dataTypePath.last as DataTypeReference).baseType;
    }
    if (dataTypePath.last is BaseType) {
      return dataTypePath.last as BaseType;
    }
    return UnknownBaseType(dataTypePath.toNamePath().join('.'));
  }

  @override
  late final List<DataTypeBase> children = (baseType is DataType)
      ? (baseType as DataType).children
      : <DataTypeBase>[];

  DataTypeReference.forDataTypePath({
    required this.name,
    required this.comment,
    required this.dataTypePath,
  }) : basicType = null;

  DataTypeReference.forBasicType({
    required this.name,
    required this.comment,
    required this.basicType,
  }) : dataTypePath = const NodePath.empty();
}

class UnknownDataTypeBase extends DataType {
  @override
  final String name;

  @override
  final String comment;

  @override
  final List<DataTypeBase> children = const [];

  final String typeExpression;

  UnknownDataTypeBase({
    required this.name,
    required this.comment,
    required this.typeExpression,
  });

  @override
  String toString() => 'UnknownDataTypeBase($typeExpression)';
}

class Structure extends DataType {
  @override
  final String name;

  @override
  final String comment;

  @override
  final List<DataType> children;

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
  final List<DataType> children;

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

class EnumerationMember extends DataType {
  @override
  final String name;

  @override
  final String comment;

  final BaseType baseType;

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
