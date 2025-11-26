import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:xml/xml.dart';

import '../base_type/base_type.infrastructure.dart';
import '../../sysmac_project.infrastructure.dart';

const String nameAttribute = 'Name';
const String baseTypeAttribute = 'BaseType';
const String commentAttribute = 'Comment';
const String enumValueAttribute = 'EnumValue';

const String nameSpacePathSeparator = '\\';

DataTypes createDataTypes(SysmacProjectArchive sysmacProjectArchive) {
  var dataTypes = _createChildren(sysmacProjectArchive);
  replaceDataTypeReferencesWherePossible(dataTypes);
  return dataTypes;
}

DataTypes _createChildren(SysmacProjectArchive sysmacProjectArchive) {
  DataTypes dataTypes = DataTypes();
  var dataTypeArchiveXmlFiles = sysmacProjectArchive.projectIndexXml
      .dataTypeArchiveXmlFiles();

  for (var dataTypeArchiveXmlFile in dataTypeArchiveXmlFiles) {
    var newDataTypes = dataTypeArchiveXmlFile.toDataTypes();
    var nameSpacePath = dataTypeArchiveXmlFile.nameSpacePath.split(r'\');
    var newDataTypesWithNameSpace = addNameSpace(nameSpacePath, newDataTypes);
    merge(dataTypes, newDataTypesWithNameSpace);
  }
  return dataTypes;
}

List<DataTypeBase> addNameSpace(
  List<String> nameSpacePath,
  DataTypes newDataTypes,
) {
  if (nameSpacePath.join('.').isEmpty) {
    // add to the root
    return newDataTypes;
  }
  NameSpace? root;
  NameSpace? last;
  for (var nameSpace in nameSpacePath) {
    if (root == null) {
      root = NameSpace(nameSpace);
      last = root;
    } else {
      var newNameSpace = NameSpace(nameSpace);
      last!.children.add(newNameSpace);
      last = newNameSpace;
    }
  }
  last!.children.addAll(newDataTypes);
  return [root!];
}

void merge(
  List<DataTypeBase> existingDataTypes,
  List<DataTypeBase> newDataTypes,
) {
  for (var newDataType in newDataTypes) {
    var existingNode = existingDataTypes.firstWhereOrNull(
      (existingDataType) =>
          existingDataType.name.toLowerCase() == newDataType.name.toLowerCase(),
    );
    if (existingNode == null) {
      existingDataTypes.add(newDataType);
    } else {
      /// recursively merge children
      merge(existingNode.children, newDataType.children);
    }
  }
}


/// Represents an [ArchiveXml] with information of some [DataType]s within a given [nameSpacePath]
class DataTypeArchiveXmlFile extends ArchiveXml {
  final String nameSpacePath;

  DataTypeArchiveXmlFile.fromArchiveFile({
    required this.nameSpacePath,
    required ArchiveFile archiveFile,
  }) : super.fromArchiveFile(archiveFile);

  DataTypeArchiveXmlFile.fromXml({
    required this.nameSpacePath,
    required String xml,
  }) : super.fromXml(xml);

  DataTypes toDataTypes() {
    var dataElement = xmlDocument.firstElementChild!;
    var dataTypeRootElement = dataElement.firstElementChild!;
    var dataTypes = DataTypes();
    dataTypes.addAll(
      dataTypeRootElement.children
          .where((node) => isDataTypeElement(node))
          .map((node) => _createDataType(node)),
    );
    return dataTypes;
  }

  DataType _createDataType(XmlNode dataTypeElement) {
    String name = dataTypeElement.getAttribute(nameAttribute)!;
    String baseTypeExpression = dataTypeElement.getAttribute(
      baseTypeAttribute,
    )!;

    String? enumValue = dataTypeElement.getAttribute(enumValueAttribute);

    BaseType baseType = enumValue == null || enumValue.isEmpty
        ? _baseTypeFactory.createFromExpression(baseTypeExpression)
        : EnumChild(int.parse(enumValue));
    String comment = dataTypeElement.getAttribute(commentAttribute)!;
    var dataType = DataType(name: name, baseType: baseType, comment: comment);

    // recursively creating children
    var children = dataTypeElement.children
        .where((node) => isDataTypeElement(node))
        .map((node) => _createDataType(node))
        .toList();
    dataType.children.addAll(children);
    return dataType;
  }

  final _baseTypeFactory = BaseTypeFactory();

  bool isDataTypeElement(XmlNode node) =>
      node is XmlElement && node.name.local == 'DataType';
}
