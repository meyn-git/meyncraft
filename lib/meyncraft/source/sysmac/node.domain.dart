import 'package:collection/collection.dart';

/// A named [Node] for building tree models.
abstract class Node<T extends Node<T>> {
  final String name;

  Node(this.name);

  final List<T> children = [];

  List<T> get descendants {
    List<T> all = [];
    for (var child in children) {
      all.add(child);
      all.addAll(child.descendants);
    }
    return all;
  }

  /// Tries to find a child using a list of [namesToFind]
  /// Returns this when [namesToFind] is empty.
  /// Returns null when a name can't be found.
  Node? findNamePath(List<String> namesToFind) {
    if (namesToFind.isEmpty) {
      return this;
    }
    var childNameToFind = namesToFind.first;
    Node? foundChild = children.firstWhereOrNull(
      (child) => child.name == childNameToFind,
    );
    if (namesToFind.length == 1) {
      return foundChild;
    }
    //try to find rest of the names
    namesToFind.removeAt(0);
    return foundChild?.findNamePath(namesToFind);
  }

  Node? findNamePathString(String pathToFind) =>
      findNamePath(pathToFind.split('\\'));

  Node? findFirst(bool Function(Node node) predicate) {
    if (predicate(this)) {
      return this;
    }
    for (var child in children) {
      //recursive call
      var found = child.findFirst(predicate);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  List<Node> findPath(Node nodeToFind, [List<Node> currentPath = const []]) {
    currentPath = [...currentPath, this];
    if (nodeToFind.toString() == toString()) {
      return currentPath;
    }
    for (var child in children) {
      //recursive call
      var result = child.findPath(nodeToFind, currentPath);
      if (result.isNotEmpty) {
        return result;
      }
    }
    return [];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Node &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          const ListEquality().equals(children, other.children);

  @override
  int get hashCode => name.hashCode ^ children.hashCode;

  @override
  String toString() {
    String string = '$runtimeType {name: $name}';
    for (var child in children) {
      var lines = child.toString().split('\n');
      for (var line in lines) {
        string += "\n  $line";
      }
    }
    return string;
  }
}

class LeafNode<T extends Node<T>> extends Node<T> {
  LeafNode(super.name);

  /// A [LeafNode] has no children
  @override
  List<T> get children => [];
}

//
// class NameSpaceWithTypeAndComment<T extends Node<T>> {
//   BaseType baseType;
//   final String comment;
//
//   NameSpaceWithTypeAndComment({
//     required String name,
//     required this.baseType,
//     required this.comment,
//   }) : super(name);
//
//   @override
//   List<Node<T>> get children {
//     if (baseType is DataTypeReference) {
//       return (baseType as DataTypeReference).dataType.children;
//     } else {
//       return super.children;
//     }
//   }
// }
