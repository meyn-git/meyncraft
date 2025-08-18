import 'dart:convert';

import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.infrastructure.dart';

const String nameSpacePathSeparator = '\\';
const String nameAttribute = 'Name';
const String dataTypeNameAttribute = 'DataTypeName';
const String commentAttribute = 'Comment';
const String eventGlobalVariableName = 'EventGlobal';
const String networkPublicationAttribute = 'NetworkPublication';

class GlobalVariableService {
  final SysmacProjectArchive sysmacProjectArchive;
  final DataTypeTree dataTypeTree;

  GlobalVariableService(this.sysmacProjectArchive, this.dataTypeTree);

  late final List<Variable> variables = _createVariables();

  List<Variable> _createVariables() {
    var projectIndexXml = sysmacProjectArchive.projectIndexXml;
    var variableArchiveFile = projectIndexXml.globalVariableArchiveFile();
    var variableData = utf8.decode(variableArchiveFile.content);
    var entities = parseSlwdData(variableData);
    var variables = <Variable>[];
    for (var entity in entities) {
      var variable = createVariable(entity, dataTypeTree);
      variables.add(variable);
    }
    return variables;
  }

  List<Variable> findVariablesByName(String nameToFind) =>
      variables.where((variable) => variable.name == nameToFind).toList();

  Variable createVariable(
    Map<String, String> attributes,
    DataTypeTree dataTypeTree,
  ) {
    var name = attributes['N']!;
    var comment = attributes['Com'] ?? '';
    var typeExpression = attributes['D']!;
    var baseType = _baseTypeFactory.createFromExpressionIncludingCustomTypes(
      typeExpression,
      dataTypeTree,
    );
    var at = attributes['AT'];
    var networkPublish = NetworkPublish.ofValue(attributes['NTP']);

    return Variable(
      name: name,
      comment: comment,
      networkPublish: networkPublish,
      baseType: baseType,
      at: at,
    );
  }

  final _baseTypeFactory = BaseTypeFactory();
}

List<Map<String, String>> parseSlwdData(String input) {
  final entities = <Map<String, String>>[];
  final lines = input.split('\n');

  for (var line in lines) {
    if (line.startsWith('++')) {
      final attributes = <String, String>{};

      // Remove the leading '++' and trim whitespace
      final content = line.substring(2).trim();

      // Split by tabs or multiple spaces
      final parts = content.split(RegExp(r'\s+'));

      for (var part in parts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          attributes[keyValue[0]] = keyValue[1];
        }
      }

      entities.add(attributes);
    }
  }

  return entities;
}

class Variable {
  final String name;
  final String comment;
  final NetworkPublish networkPublish;
  final BaseType baseType;
  // optional IO address where variable is linked
  final String? at;

  Variable({
    required this.name,
    required this.comment,
    required this.networkPublish,
    required this.baseType,
    this.at,
  });
}

enum NetworkPublish {
  publicationOnly,
  doNotPublish,
  input,
  output;

  static NetworkPublish ofValue(String? value) => value == null
      ? doNotPublish
      : values.firstWhere(
          (v) => v.name.toLowerCase() == value.toLowerCase(),
          orElse: () => doNotPublish,
        );
}
