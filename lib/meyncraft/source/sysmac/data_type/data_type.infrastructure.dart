import 'package:archive/archive.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:xml/xml.dart';

import '../base_type/base_type.infrastructure.dart';
import '../sysmac_project.infrastructure.dart';

const String nameAttribute = 'Name';
const String baseTypeAttribute = 'BaseType';
const String commentAttribute = 'Comment';
const String enumValueAttribute = 'EnumValue';

const String nameSpacePathSeparator = '\\';

class DataTypeTreeFactory {
  DataTypeTree create(SysmacProjectArchive sysmacProjectArchive) {
    DataTypeTree dataTypeTree = DataTypeTree();
    _addAndCreateChildren(sysmacProjectArchive, dataTypeTree);
    DataTypeReferenceFactory().replaceWherePossible(dataTypeTree);
    return dataTypeTree;
  }

  void _addAndCreateChildren(
    SysmacProjectArchive sysmacProjectArchive,
    DataTypeTree dataTypeTree,
  ) {
    var dataTypeArchiveXmlFiles = sysmacProjectArchive.projectIndexXml
        .dataTypeArchiveXmlFiles();

    for (var dataTypeArchiveXmlFile in dataTypeArchiveXmlFiles) {
      String nameSpacePath = dataTypeArchiveXmlFile.nameSpacePath;
      DataTypeBase nameSpace = _findOrCreateNameSpacePath(
        dataTypeTree,
        nameSpacePath,
      );

      var dataTypes = dataTypeArchiveXmlFile.toDataTypes();
      nameSpace.children.addAll(dataTypes);
    }
  }

  DataTypeBase _findOrCreateNameSpacePath(
    DataTypeBase nameSpace,
    String nameSpacePathToFind,
  ) {
    if (nameSpacePathToFind.isEmpty) {
      // found
      return nameSpace;
    }

    var namesToFind = nameSpacePathToFind.split(nameSpacePathSeparator);
    String nameToFind = namesToFind.first;

    for (DataTypeBase child in nameSpace.children) {
      if (child.name == nameToFind) {
        namesToFind.removeAt(0);
        String remainingPathToFind = namesToFind.join(nameSpacePathSeparator);
        return _findOrCreateNameSpacePath(child, remainingPathToFind);
      }
    }
    //not found: create nameSpace tree
    for (String nameToCreate in namesToFind) {
      var newNameSpaceChild = NameSpace(nameToCreate);
      nameSpace.children.add(newNameSpaceChild);
      nameSpace = newNameSpaceChild;
    }
    return nameSpace;
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

  List<DataType> toDataTypes() {
    var dataElement = xmlDocument.firstElementChild!;
    var dataTypeRootElement = dataElement.firstElementChild!;
    return dataTypeRootElement.children
        .where((node) => isDataTypeElement(node))
        .map((node) => _createDataType(node))
        .toList();
  }

  final _baseTypeFactory = BaseTypeFactory();

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

  bool isDataTypeElement(XmlNode node) =>
      node is XmlElement && node.name.local == 'DataType';
}
