import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:xml/xml.dart';

const String nameSpacePathSeparator = '\\';
const String dataTypeNameAttribute = 'DataTypeName';
const String commentAttribute = 'Comment';
const String networkPublicationAttribute = 'NetworkPublication';

List<Variable> createGlobalVariables(
  SysmacProjectArchive sysmacProjectArchive,
  DataTypeTree dataTypeTree,
) {
  var globalVariableElement = sysmacProjectArchive
      .projectIndexXml
      .xmlDocument
      .descendantElements
      .firstWhere((e) => isGlobalVariableElement(e));
  var id = globalVariableElement.getAttribute(idAttribute)!;

  var globalVariables =
      createVariableGroups(
        sysmacProjectArchive,
        dataTypeTree,
        id,
      )[VariableGroup.global] ??
      [];

  return globalVariables;
}

bool isGlobalVariableElement(XmlElement element) =>
    element.name.local == entity &&
    element.getAttribute(typeAttribute) == 'Variables' &&
    element.getAttribute(subTypeAttribute) == 'Global';

Map<VariableGroup, List<Variable>> createVariableGroups(
  SysmacProjectArchive sysmacProjectArchive,
  DataTypeTree dataTypeTree,
  String id,
) {
  var projectIndexXml = sysmacProjectArchive.projectIndexXml;
  var variableArchiveFile = projectIndexXml.findArchiveFile(id);
  if (variableArchiveFile == null) {
    logger.warning('Could not find variable archive file: $id');
    return {};
  }
  var variableData = convertContentToUtf8(variableArchiveFile);
  var groups = parseSLWD(variableData);
  var variableGroups = {
    for (var group in groups)
      toVariableGroup(group): toVariables(group, dataTypeTree),
  };
  return variableGroups;
}

VariableGroup toVariableGroup(Group group) => switch (group.name) {
  'VAR_GLOBAL' => VariableGroup.global,
  'VAR' => VariableGroup.internal,
  'VAR_EXTERNAL' => VariableGroup.external,
  'VAR_INPUT' => VariableGroup.functionInOut,
  'RETURN' => VariableGroup.functionReturn,
  _ => VariableGroup.unknown,
};

VariableDirection? toDirection(String? name) => switch (name) {
  'VAR_INPUT' => VariableDirection.in$,
  'VAR_OUTPUT' => VariableDirection.out,
  'VAR_IN_OUT' => VariableDirection.inOut,
  _ => null,
};
List<Variable> toVariables(Group group, DataTypeTree dataTypeTree) => group
    .entities
    .map((attributes) => createVariable(attributes, dataTypeTree))
    .toList();

Variable createVariable(
  Map<String, String> attributes,
  DataTypeTree dataTypeTree,
) {
  var name = attributes['N']!;
  var comment = attributes['Com'] ?? '';
  var direction = toDirection(attributes['G']);
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
    direction: direction,
  );
}

final _baseTypeFactory = BaseTypeFactory();

class Group {
  final String name;
  final List<Map<String, String>> entities;

  Group(this.name, List<Map<String, String>>? entities)
    : entities = entities ?? [];
}

List<Group> parseSLWD(String input) {
  final lines = input
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty);
  final groups = <Group>[];
  Group? currentGroup;

  for (final line in lines) {
    if (line.startsWith('+GN=')) {
      final parts = RegExp(
        r'\+GN=(\S+)(?:\s+GA=(\S+))?(?:\s+GVT=(\S+))?',
      ).firstMatch(line);
      if (parts != null) {
        currentGroup = Group(parts.group(1)!, []);
        groups.add(currentGroup);
      }
    } else if (line.startsWith('++D=') && currentGroup != null) {
      final detailParts = RegExp(r'(\w+)=(\S+)').allMatches(line);
      final attributes = {
        for (final match in detailParts) match.group(1)!: match.group(2)!,
      };
      currentGroup.entities.add(attributes);
    }
  }

  return groups;
}

VariableMember? findGlobalVariable(
  SysmacProject sysmacProject,
  String nameToFind,
) {
  var variables = sysmacProject.globalVariables.where(
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
