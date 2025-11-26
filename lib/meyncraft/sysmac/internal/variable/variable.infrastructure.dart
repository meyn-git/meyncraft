import 'dart:core';

import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:petitparser/petitparser.dart';
import 'package:xml/xml.dart';

const String nameSpacePathSeparator = '\\';
const String dataTypeNameAttribute = 'DataTypeName';
const String commentAttribute = 'Comment';
const String networkPublicationAttribute = 'NetworkPublication';

Variables createGlobalVariables(
  SysmacProjectArchive sysmacProjectArchive,
  DataTypes dataTypes,
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
        dataTypes,
        id,
      )[VariableGroup.global] ??
      [];
  return Variables(globalVariables);
}

bool isGlobalVariableElement(XmlElement element) =>
    element.name.local == entity &&
    element.getAttribute(typeAttribute) == 'Variables' &&
    element.getAttribute(subTypeAttribute) == 'Global';

Map<VariableGroup, List<Variable>> createVariableGroups(
  SysmacProjectArchive sysmacProjectArchive,
  DataTypes dataTypes,
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
      toVariableGroup(group): toVariables(group, dataTypes),
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
List<Variable> toVariables(Group group, DataTypes dataTypes) => group.entities
    .map((attributes) => createVariable(attributes, dataTypes))
    .toList();

final _baseTypeFactory = BaseTypeFactory();

Variable createVariable(Map<String, String> attributes, DataTypes dataTypes) {
  var name = attributes['N']!;
  var comment = attributes['Com'] ?? '';
  var direction = toDirection(attributes['G']);
  var isRetained = attributes['R'] == '1';
  var isConstant = attributes['Const'] == '1';
  var initialValue = attributes['IV'];
  var hardwareAddress = attributes['AT'];
  var networkPublish = NetworkPublish.ofValue(attributes['NTP']);
  var typeExpression = attributes['D']!;
  var baseType = _baseTypeFactory.createFromExpressionIncludingCustomTypes(
    typeExpression,
    dataTypes,
  );

  // var unknownAttributes = {...attributes};
  // unknownAttributes.remove('N');
  // unknownAttributes.remove('Com');
  // unknownAttributes.remove('G');
  // unknownAttributes.remove('D');
  // unknownAttributes.remove('AT');
  // unknownAttributes.remove('NTP');
  // unknownAttributes.remove('R');
  // unknownAttributes.remove('IV');
  // if (unknownAttributes.isNotEmpty) {
  //   print(unknownAttributes);
  // }

  return Variable(
    name: name,
    comment: comment,
    networkPublish: networkPublish,
    baseType: baseType,
    hardwareAddress: hardwareAddress,
    direction: direction,
    isRetained: isRetained,
    isConstant: isConstant,
    initialValue: initialValue,
  );
}

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
      var result = slwdLineParser.parse(line);
      if (result is Success) {
        var attributes = result.value;
        var groupName = attributes['GN']!;
        currentGroup = Group(groupName, []);
        groups.add(currentGroup);
      }
    } else if (line.startsWith('++D=') && currentGroup != null) {
      var result = slwdLineParser.parse(line);
      if (result is Success) {
        var attributes = result.value;
        currentGroup.entities.add(attributes);
      }
    }
  }
  return groups;
}

/// Build a parser for key=value pairs separated by whitespace.
/// Keys: letters and digits only.
/// Values: any characters except tabs/newlines.
/// Leading  +, or ++ are ignored by trimming before parsing.
Parser<Map<String, String>> slwdLineParser =
    (slwdPrefixParser & slwdAttributesParser).map((values) => values[1]);

Parser<String> slwdPrefixParser = (string('+').repeat(1, 2)).flatten();

Parser<Map<String, String>> slwdAttributesParser = (slwdAttributeParser.plus())
    .map((entries) => Map.fromEntries(entries));

Parser<MapEntry<String, String>> slwdAttributeParser =
    (slwdKeyParser & char('=') & slwdValueParser).map(
      (values) => MapEntry(values[0], (values[2] as String).trim()),
    );

Parser<String> slwdValueParser = SlwdValueParser();

Parser<String> slwdKeyParser = (letter() | digit()).plus().flatten();

class SlwdValueParser extends Parser<String> {
  @override
  Parser<String> copy() => SlwdValueParser();

  @override
  Result<String> parseOn(Context context) {
    var endIndex = findEndIndex(context);
    var result = context.buffer.substring(context.position, endIndex);
    return context.success(result, endIndex);
  }

  final nextAttributeParser = slwdKeyParser & char('=');

  int findEndIndex(Context context) {
    var input = context.buffer;
    for (int i = context.position; i < input.length; i++) {
      var context = Context(input, i);
      var result = nextAttributeParser.parseOn(context);
      if (result is Success) return i;
    }
    // no match: consume until the end
    return input.length;
  }
}
