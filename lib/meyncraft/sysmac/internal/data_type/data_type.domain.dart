import '../base_type/base_type.domain.dart';
import '../../node.domain.dart';

// ///Root [Node] of the DataType tree containing [DataTypeBase]s
// class dataTypes extends DataTypeBase {
//   dataTypes() : super('$dataTypes');

//   @override
//   List<DataTypeBase> children = [];
// }

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
    return const [];
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

  List<DataTypeBasePaths> findPaths(
    DataTypeBaseFilter includeFilter, {
    bool forEachArrayValue = true,
    List<String>? parentNamePath,
    List<String>? parentCommentPath,
  }) {
    var results = <DataTypeBasePaths>[];
    var commentPath = <String>[...parentCommentPath ?? [], comment];
    var namePaths = _createNamePaths(forEachArrayValue, parentNamePath ?? []);
    if (includeFilter(this)) {
      for (var namePath in namePaths) {
        results.add(
          DataTypeBasePaths(
            dataTypeBase: this,
            namePath: namePath,
            commentPath: commentPath,
          ),
        );
      }
    }
    for (var child in children) {
      for (var namePath in namePaths) {
        results.addAll(
          child.findPaths(
            includeFilter,
            forEachArrayValue: forEachArrayValue,
            parentNamePath: namePath,
            parentCommentPath: commentPath,
          ),
        );
      }
    }
    return results;
  }

  List<List<String>> _createNamePaths(
    bool forEachArrayValue,
    List<String> parentNamePath,
  ) {
    var namePath = [...parentNamePath, name];
    if (!forEachArrayValue) {
      return [namePath];
    }
    var arrayValues = _arrayValues();
    if (arrayValues.isEmpty) {
      return [namePath];
    }
    return arrayValues
        .map(
          (a) => [
            for (var i = 0; i < namePath.length; i++)
              i < (namePath.length - 1) ? namePath[i] : namePath[i] + a,
          ],
        )
        .toList();
  }

  List<String> _arrayValues() {
    if (this is DataType) {
      return (this as DataType).baseType.arrayRanges.toStringList();
    }
    return [];
  }
}

class NameSpace extends DataTypeBase {
  NameSpace(super.name, [super.comment]);

  @override
  List<DataTypeBase> children = <DataTypeBase>[];
}

/// A [DataType] is a custom data type that is made of [BaseType]s
class DataType extends DataTypeBase {
  // DataType? parent;
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

typedef DataTypeBaseFilter = bool Function(DataTypeBase dataTypeBase);

class DataTypeBasePaths {
  final List<String> namePath;
  final List<String> commentPath;
  final DataTypeBase dataTypeBase;

  DataTypeBasePaths({
    required this.dataTypeBase,
    required this.namePath,
    required this.commentPath,
  });
}
