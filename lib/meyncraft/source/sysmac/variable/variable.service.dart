import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.domain.dart';
import 'package:xml/xml.dart';

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

  @Deprecated('Use variables instead')
  List<VariableOld> get variablesOld {
    var projectIndexXml = sysmacProjectArchive.projectIndexXml;

    var archiveXmlFiles = projectIndexXml.globalVariableArchiveXmlFiles(
      dataTypeTree,
    );

    List<VariableOld> variables = [];
    for (var variableArchiveXmlFile in archiveXmlFiles) {
      variables.addAll(variableArchiveXmlFile.toVariables());
    }
    return variables;
  }

  List<VariableOld> findVariablesByName(String nameToFind) =>
      variablesOld.where((variable) => variable.name == nameToFind).toList();

  List<VariableOld> findVariablesWithEventGlobalName() =>
      findVariablesByName(eventGlobalVariableName);

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

/// Represents an [ArchiveXml] with information of some [VariableOld]s within a given [nameSpacePath]
class GlobalVariableArchiveXmlFile extends ArchiveXml {
  final DataTypeTree dataTypeTree;
  final String nameSpacePath;
  final BaseTypeFactory _baseTypeFactory = BaseTypeFactory();
  final DataTypeReferenceFactory dataTypeReferenceFactory =
      DataTypeReferenceFactory();

  GlobalVariableArchiveXmlFile.fromArchiveFile({
    required this.dataTypeTree,
    required this.nameSpacePath,
    required ArchiveFile archiveFile,
  }) : super.fromArchiveFile(archiveFile);

  GlobalVariableArchiveXmlFile.fromXml({
    required this.dataTypeTree,
    required this.nameSpacePath,
    required String xml,
  }) : super.fromXml(xml);

  List<VariableOld> toVariables() {
    var dataElement = xmlDocument.firstElementChild!;
    var variableRootElement = dataElement.firstElementChild;
    if (variableRootElement == null) {
      return [];
    }
    return variableRootElement.children
        .where((node) => isVariableElement(node))
        .map((node) => _createVariable(node))
        .toList();
  }

  VariableOld _createVariable(XmlNode variableElement) {
    String name = variableElement.getAttribute(nameAttribute)!;
    String baseTypeExpression = variableElement.getAttribute(
      dataTypeNameAttribute,
    )!;
    BaseType baseType = _baseTypeFactory
        .createFromExpressionIncludingCustomTypes(
          baseTypeExpression,
          dataTypeTree,
        );
    String comment = variableElement.getAttribute(commentAttribute)!;
    var variable = VariableOld(
      name: name,
      baseType: baseType,
      comment: comment,
    );

    // recursively creating children
    var children = variableElement.children
        .where((node) => isVariableElement(node))
        .map((node) => _createVariable(node))
        .toList();
    variable.children.addAll(children);

    return variable;
  }

  bool isVariableElement(XmlNode node) =>
      node is XmlElement && node.name.local == 'Variable';
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
