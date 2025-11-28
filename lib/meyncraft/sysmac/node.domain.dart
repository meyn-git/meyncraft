import 'package:collection/collection.dart';

/// A named [Node] for building tree models.
abstract class Node<T extends Node<T>> {
  String get name;
  String get comment;
  List<T> get children;

  List<T> get descendants {
    List<T> all = [];
    for (var child in children) {
      all.add(child);
      all.addAll(child.descendants);
    }
    return all;
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

  NodePath findFirstNodePath(NodePathFinder finder) => finder(this);

  List<NodePath> findAllNodePaths(NodePathsFinder finder) => finder(this);
}

typedef NodePath = List<Node>;

typedef NodePathFinder = NodePath Function(Node node);

typedef NodePathsFinder = List<NodePath> Function(Node node);

/// returns the first [NodePath] for the first matching name path
NodePathFinder namePathFinder(
  Iterable<String> namePath, {
  bool caseSensitive = true,
  NodePath precedingPath = const [],
}) => (Node node) {
  var currentPath = [...precedingPath, node];
  if (namePath.isEmpty) {
    return [];
  }
  if (!equalNames(namePath.first, node.name, caseSensitive)) {
    return [];
  }
  if (namePath.length == 1) {
    return currentPath;
  }
  var finder = namePathFinder(namePath.skip(1), precedingPath: currentPath);
  for (var child in node.children) {
    var found = finder(child as Node);
    if (found.isNotEmpty) {
      return found;
    }
  }
  return [];
};

/// returns the first [NodePath] for the first matching name path
NodePathsFinder leafPathsFinder({NodePath precedingPath = const []}) =>
    (Node node) {
      var currentPath = [...precedingPath, node];
      if (node.children.isEmpty) {
        return [currentPath];
      }

      var nodePaths = <NodePath>[];
      var finder = leafPathsFinder(precedingPath: currentPath);
      for (var child in node.children) {
        var foundNodePaths = finder(child as Node);
        if (foundNodePaths.isNotEmpty) {
          nodePaths.addAll(foundNodePaths);
        }
      }
      return nodePaths;
    };

bool equalNames(String name1, String name2, bool caseSensitive) =>
    caseSensitive ? name1 == name2 : name1.toLowerCase() == name2.toLowerCase();
