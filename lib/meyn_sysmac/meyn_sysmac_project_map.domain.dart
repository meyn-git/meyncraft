import 'dart:collection';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/sysmac/internal/variable/variable.domain.dart';

//import 'package:meyncraft/sysmac/internal/variable/variable.domain_map_converter.dart';

/// a [lazy evaluation](https://en.wikipedia.org/wiki/Lazy_evaluation) Map
/// that represents a [MeynSysmacProject]
/// to be used as parameter when we implement a template engine
///
/// It is lazy because most key values take some time to parse.
/// This way it is only parsed when needed.
///
/// It mimics a [Map] and returns the following properties on [project] when its relative key is asked
/// * dataTypes
/// * globalVariables
/// * devices
/// * identity
/// * events
/// * isa88Nodes
///
/// e.g.:
/// projectMap=MeynSysmacProjectMap(project);
/// var devices=projectMap['devices'];

class MeynSysmacProjectMap extends MapBase<String, dynamic> {
  final MeynSysmacProject project;
  late final _dataTypes = project.dataTypes
      .map((dataTypeBase) => dataTypeBaseToMap(dataTypeBase))
      .whereType<Map<String, dynamic>>() //removes nulls
      .toList();
  // late final _globalVariables = project.globalVariables
  //     .where(_variableIsIncluded)
  //     .map((variable) => variableToMap(variable))
  //     .toList();

  late final _globalVariables = [];

  static const String dataTypesKey = 'dataTypes';
  static const String globalVariablesKey = 'globalVariables';
  static const String devicesKey = 'devices';
  static const String identityKey = 'identity';
  static const String eventsKey = 'events';
  static const String isa88NodesKey = 'isa88Nodes';

  static const List<String> _keys = [
    dataTypesKey,
    globalVariablesKey,
    devicesKey,
    identityKey,
    eventsKey,
    isa88NodesKey,
  ];

  MeynSysmacProjectMap(this.project);

  @override
  dynamic operator [](Object? key) => switch (key) {
    dataTypesKey => _dataTypes,
    globalVariablesKey => _globalVariables,
    devicesKey => project.devices,
    identityKey => project.identity,
    eventsKey => project.events,
    isa88NodesKey => project.isa88Nodes,
    _ => null,
  };

  @override
  void operator []=(String key, dynamic value) {
    throw UnsupportedError('MeynSysmacProjectMap is read-only');
  }

  @override
  Iterable<String> get keys => _keys;

  @override
  dynamic remove(Object? key) {
    throw UnsupportedError('MeynSysmacProjectMap is read-only');
  }

  @override
  void clear() {
    throw UnsupportedError('MeynSysmacProjectMap is read-only');
  }

  bool _variableIsIncluded(Variable variable) =>
      variable.baseType is! VbType && variable.baseType is! UnknownBaseType;
}

Map<String, dynamic>? dataTypeBaseToMap(DataTypeBase dataTypeBase) {
  if (dataTypeBase is NameSpace) {
    var nameSpace = dataTypeBase;
    return <String, dynamic>{
      'type': '$NameSpace',
      'name': nameSpace.name,
      'comment': nameSpace.comment,
      'children': nameSpace.children
          .map(dataTypeBaseToMap)
          .whereType<Map<String, dynamic>>()
          .toList(),
    };
  }
  if (dataTypeBase is EnumerationMember) {
    var enumMember = dataTypeBase;
    return <String, dynamic>{
      'type': '$EnumerationMember',
      'name': enumMember.name,
      'comment': enumMember.comment,
      'index': enumMember.index,
      'baseType': baseTypeToMap(enumMember.baseType),
    };
  }
  if (dataTypeBase is Enumeration) {
    var enumeration = dataTypeBase;
    return <String, dynamic>{
      'type': '$Enumeration',
      'name': enumeration.name,
      'comment': enumeration.comment,
      'children': enumeration.children
          .map(dataTypeBaseToMap)
          .whereType<Map<String, dynamic>>()
          .toList(),
    };
  }
  if (dataTypeBase is Union) {
    var union = dataTypeBase;
    return <String, dynamic>{
      'type': '$Union',
      'name': union.name,
      'comment': union.comment,
      'children': union.children
          .map(dataTypeBaseToMap)
          .whereType<Map<String, dynamic>>()
          .toList(),
    };
  }
  if (dataTypeBase is DataTypeMember) {
    var dataTypeMember = dataTypeBase;
    return <String, dynamic>{
      'type': '$DataTypeMember',
      'name': dataTypeMember.name,
      'comment': dataTypeMember.comment,
      //  'baseType':
      //  /// FIXME: thise causes endless roundtrips baseTypeToMap(dataTypeMember.baseType),
      //  /// Therefore doing this instead
      //  <String, dynamic>{
      //       'type': '${dataTypeMember.baseType.runtimeType}',
      //       if (dataTypeMember.baseType is DataTypeBase)
      //       'name': (dataTypeMember.baseType as DataTypeBase).name,
      //       if (dataTypeMember.baseType is IecType)
      //       'name': (dataTypeMember.baseType as IecType).name,
      //       if (dataTypeMember.baseType is DataTypeBase)
      //       'comment': (dataTypeMember.baseType as DataTypeBase).comment,
      //     },

      'children': dataTypeMember.children
          .map(dataTypeBaseToMap)
          .whereType<Map<String, dynamic>>()
          .toList(),
    };
  }
  if (dataTypeBase is Structure) {
    var structure = dataTypeBase;
    return <String, dynamic>{
      'type': '$Structure',
      'name': structure.name,
      'comment': structure.comment,
      'children': structure.children
          .map(dataTypeBaseToMap)
          .whereType<Map<String, dynamic>>()
          .toList(),
    };
  }
  print('UnSupported type: ${dataTypeBase.runtimeType}');
  return null;
}

Map<String, dynamic>? baseTypeToMap(BaseType baseType) {
  if (baseType is IecType) {
    return <String, dynamic>{'type': '$IecType', 'name': baseType.name};
  }
  if (baseType is DataTypeBase) {
    return dataTypeBaseToMap(baseType);
  }
  if (baseType is DataTypeReference) {
    var dataTypePath = baseType.dataTypePath;
    var path = dataTypePath
        /// FIXME the following mapping is a hack to fix round trips when using:
        .map((dataTypeBase) => dataTypeBaseToMap(dataTypeBase as DataTypeBase))
        .whereType<DataTypeBase>()
        // .map(
        //   (node) => <String, dynamic>{
        //     'type': '${node.runtimeType}',
        //     'name': node.name,
        //     'comment': node.comment,
        //   },
        // )
        .toList();
    return <String, dynamic>{
      'type': '$DataTypeReference',
      'namePath': dataTypePath.toNamePath(),
      'namePathWithArrayRanges': dataTypePath.toNamePathWithArrayRanges(),
      'commentPath': dataTypePath.toCommentPath(),
      'path': path,
    };
  }
  if (baseType is ArrayType) {
    var arrayType = baseType;
    return <String, dynamic>{
      'type': '$ArrayType',
      'baseType': baseTypeToMap(arrayType.baseType),
      'arrayRanges': arrayType.arrayRanges
          .map((arrayRange) => arrayRangeToMap(arrayRange))
          .toList(),
    };
  }
  print('UnSupported type: ${baseType.runtimeType}');
  return null;
}

Map<String, dynamic> arrayRangeToMap(ArrayRange arrayRange) =>
    <String, dynamic>{
      'type': '$ArrayRange',
      'min': arrayRange.min,
      'max': arrayRange.max,
    };
