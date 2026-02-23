import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';

/// A named [Node] for building tree models.
abstract class Node<CHILD_TYPE extends Node<CHILD_TYPE>> {
  String get name;
  String get comment;
  List<CHILD_TYPE> get children;

  List<CHILD_TYPE> get descendants {
    List<CHILD_TYPE> all = [];
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

  T findFirstNodePath<T extends NodePath>(NodePathFinder<T> finder) =>
      finder(this);

  List<T> findAllNodePaths<T extends NodePath>(NodePathsFinder<T> finder) =>
      finder(this);
}

class NodePath extends DelegatingList<Node> {
  NodePath(super.base);

  const NodePath.empty() : super(const []);

  Iterable<String> toNamePath() => map((node) => node.name).toList();

  Iterable<String> toNamePathWithArrayRanges() => map(
    (node) => (node is ArrayType)
        ? '${node.name}${(node as ArrayType).arrayRanges}'
        : node.name,
  );

  List<String> toCommentPath() => map((node) => node.comment).toList();

  @override
  String toString() => toNamePath().join('.');
}

class NodePathWithIndexes extends NodePath {
  /// arrayIndexes[x] is the array index value (e.g. null, [2] or [2,5,3]) for each NodePath[x]
  final List<String?> arrayIndexes;

  NodePathWithIndexes(super.base, this.arrayIndexes) {
    if (length != arrayIndexes.length) {
      throw ArgumentError(
        'The number of nodes and the number of '
        'arrayIndexes must be the same length',
      );
    }
  }

  const NodePathWithIndexes.empty() : arrayIndexes = const [], super.empty();

  List<String> toNamePathWithArrayIndexes() => [
    for (var index = 0; index < length; index++)
      '${this[index].name}${arrayIndexes[index] ?? ''}',
  ];

  @override
  String toString() => toNamePathWithArrayIndexes().join('.');
}

// extension NodePathExtension on List<Node> {
//   String get namePathWithArrayRanges => [
//     for (var node in this)
//       (node is DataTypeBase) ? node.nameWithArrayRanges : node.name,
//   ].join('.');
// }

typedef NodePathFinder<T extends NodePath> = T Function(Node node);

typedef NodePathsFinder<T extends NodePath> = List<T> Function(Node node);

/// NodePathFinder for an expression like InterfaceGlobal.CrusherMod[1]
/// It returns a [NodePathWithIndexes]
NodePathFinder<NodePathWithIndexes> namePathWithIndexesFinder(
  /// e.g. ['InterfaceGlobal', 'CrusherMod[1]'].
  /// Note that:
  /// * the name may be indexed
  /// * the index is not validated
  Iterable<String> namePath, {
  bool caseSensitive = true,
  NodePathWithIndexes precedingPath = const NodePathWithIndexes.empty(),
}) => (Node node) {
  if (namePath.isEmpty) {
    return const NodePathWithIndexes.empty();
  }
  // Match: [...] followed optionally by a trailing dot, then end-of-string
  final arrayValueRegExp = RegExp(r"\[(\s*-?\d+(?:\s*,\s*-?\d+)*)\]\s*\.?\s*$");
  var match = arrayValueRegExp.firstMatch(namePath.first);
  var arrayValue = match?.group(0)!;
  var nameWithoutArrayIndex = namePath.first.replaceAll(arrayValueRegExp, '');

  if (!equalNames(nameWithoutArrayIndex, node.name, caseSensitive)) {
    return NodePathWithIndexes.empty();
  }
  var currentPath = NodePathWithIndexes(
    [...precedingPath, node],
    [...precedingPath.arrayIndexes, arrayValue],
  );
  if (namePath.length == 1) {
    return currentPath;
  }

  /// find recursively in children
  var finder = namePathWithIndexesFinder(
    namePath.skip(1),
    precedingPath: currentPath,
  );
  for (var child in node.children) {
    var found = finder(child as Node);
    if (found.isNotEmpty) {
      return found;
    }
  }
  return const NodePathWithIndexes.empty();
};

/// returns the first [NodePath] for the first matching name path
NodePathFinder<NodePath> namePathFinder(
  Iterable<String> namePath, {
  bool caseSensitive = true,
  NodePath precedingPath = const NodePath.empty(),
}) => (Node node) {
  var currentPath = NodePath([...precedingPath, node]);
  if (namePath.isEmpty) {
    return const NodePath.empty();
  }
  if (!equalNames(namePath.first, node.name, caseSensitive)) {
    return const NodePath.empty();
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
  return const NodePath.empty();
};

/// returns the first [NodePath] for the first matching name path
NodePathsFinder<NodePath> leafPathsFinder({
  NodePath precedingPath = const NodePath.empty(),
}) => (Node node) {
  var currentPath = NodePath([...precedingPath, node]);
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
