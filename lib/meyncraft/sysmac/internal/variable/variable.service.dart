import 'dart:convert';

import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';

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
    var variables = entities
        .map((e) => createVariable(e, dataTypeTree))
        .toList();
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

VariableMember? findGlobalVariable(
  SysmacProject sysmacProject,
  String nameToFind,
) {
  var variables = sysmacProject.globalVariableService.variables.where(
    (v) => v.name == nameToFind,
  );
  if (variables.length != 1) {
    logger.warning(
      '  Expected the sysmac project to have 1 global variable of name "$nameToFind"',
    );
    return null;
  }
  var variable = variables.first;
  var variableType = variable.baseType;
  if (variableType is! DataTypeReference) {
    logger.warning('Expected "$nameToFind" to be a DataType');
    return null;
  }
  return VariableMember(variable, variableType.dataType, []);
}
