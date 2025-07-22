import '../base_type/base_type.domain.dart';
import '../node.domain.dart';

///Root [Node] of the DataType tree containing [DataTypeBase]s
class DataTypeTree extends DataTypeBase {
  DataTypeTree() : super('$DataTypeTree');
}

/// Abstract base type of [DataType]s and [NameSpace]s
abstract class DataTypeBase extends Node<DataTypeBase> {
  final String comment;

  DataTypeBase(super.name, [this.comment = '']);
}

class NameSpace extends DataTypeBase {
  NameSpace(super.name, [super.comment]);
}

/// A [DataType] is a custom data type that is made of [BaseType]s
class DataType extends DataTypeBase {
  // DataType? parent;
  BaseType baseType;

  DataType({required String name, required this.baseType, String comment = ''})
    : super(name, comment);

  @override
  List<DataTypeBase> get children {
    if (baseType is DataTypeReference) {
      return (baseType as DataTypeReference).dataType.children;
    } else {
      return super.children;
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
