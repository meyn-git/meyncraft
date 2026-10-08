import 'package:map_converter/map_converter.dart';
import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project_map.domain.dart';
import 'package:meyncraft/sysmac/iec61131_10/iec61131_10.dart' as iec;
import 'package:meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/sysmac/node.domain.dart';
import 'package:dart_mappable/dart_mappable.dart';

@MappableClass()
class Variable extends Node<DataTypeBase> implements BaseTypeOwner {
  @override
  final String name;
  @override
  final String comment;
  final iec.NetworkPublish networkPublish;
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

// class PolymorphismConverter implements PrimitiveConverter {
//   final Map<Type, PrimitiveConverter> typesAndConverters;
//   const PolymorphismConverter(this.typesAndConverters);

//   @override
//   fromPrimitive(value) {
//     for (var entry in typesAndConverters.entries) {
//       if (value.runtimeType == entry.key) {
//         return entry.value.fromPrimitive(value);
//       }
//     }
//     throw UnsupportedError(
//       'Expected type: ${typesAndConverters.keys.join(', or ')}',
//     );
//   }

//   @override
//   toPrimitive(value) {
//     for (var entry in typesAndConverters.entries) {
//       if (value.runtimeType == entry.key) {
//         return entry.value.toPrimitive(value);
//       }
//     }
//     throw UnsupportedError(
//       'Expected type: ${typesAndConverters.keys.join(', or ')}',
//     );
//   }
// }

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

/// Fixme can we convert this to a PolymorphicConverter
// class BaseTypeConverter
//     implements PrimitiveConverter<BaseType, Map<String, dynamic>> {
//   const BaseTypeConverter();

//   // NOT NEEDED
//   @override
//   BaseType fromPrimitive(Map<String, dynamic> value) {
//     throw UnimplementedError();
//   }

//   @override
//   Map<String, dynamic> toPrimitive(BaseType baseType) =>
//       baseTypeToMap(baseType) ?? {};

//   // Not needed
// }
