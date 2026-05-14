import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:meyncraft/logger/logger.service.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:xml/xml.dart';

import '../base_type/base_type.infrastructure.dart';
import '../../sysmac_project.infrastructure.dart';

const String nameAttribute = 'Name';
const String baseTypeAttribute = 'BaseType';
const String commentAttribute = 'Comment';
const String enumValueAttribute = 'EnumValue';

const String nameSpacePathSeparator = '\\';

List<DataTypeBase> createDataTypes(SysmacProjectArchive sysmacProjectArchive) {
  var dataTypes = _createChildren(sysmacProjectArchive);
  BaseTypeFactory.forIecTypes().tryToResolveDataTypeBaseTypes(dataTypes);
  return dataTypes;
}

List<DataTypeBase> _createChildren(SysmacProjectArchive sysmacProjectArchive) {
  var dataTypes = <DataTypeBase>[];
  var dataTypeArchiveXmlFiles = sysmacProjectArchive.projectIndexXml
      .dataTypeArchiveXmlFiles();

  for (var dataTypeArchiveXmlFile in dataTypeArchiveXmlFiles) {
    var newDataTypes = dataTypeArchiveXmlFile.toDataTypeBases();
    var nameSpacePath = dataTypeArchiveXmlFile.nameSpacePath.split(r'\');
    var newDataTypesWithNameSpace = addNameSpace(nameSpacePath, newDataTypes);
    merge(dataTypes, newDataTypesWithNameSpace);
  }
  return dataTypes;
}

List<DataTypeBase> addNameSpace(
  List<String> nameSpacePath,
  List<DataTypeBase> newDataTypes,
) {
  if (nameSpacePath.join('.').isEmpty) {
    // add to the root
    return newDataTypes;
  }
  NameSpace? root;
  NameSpace? last;
  for (var nameSpace in nameSpacePath) {
    if (root == null) {
      root = NameSpace(name: nameSpace);
      last = root;
    } else {
      var newNameSpace = NameSpace(name: nameSpace);
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

  List<DataTypeBase> toDataTypeBases() {
    var dataElement = xmlDocument.firstElementChild!;
    var dataTypeRootElement = dataElement.firstElementChild!;
    var dataTypes = <DataTypeBase>[];
    dataTypes.addAll(
      dataTypeRootElement.childElements
          .where((element) => element.name.local == 'DataType')
          .map((element) => _createDataType(element))
          // remove nulls
          .whereType<DataTypeBase>(),
    );
    return dataTypes;
  }

  DataTypeBase? _createDataType(XmlElement dataTypeElement) {
    String baseTypeExpression = dataTypeElement.getAttribute(
      baseTypeAttribute,
    )!;

    if (baseTypeExpression == 'ENUM') {
      return _createEnum(dataTypeElement);
    }
    if (baseTypeExpression == 'STRUCT') {
      return _createStructure(dataTypeElement);
    }
    if (baseTypeExpression == 'UNION') {
      return _createUnion(dataTypeElement);
    }
    logger.warning(
      'Unknown base type expression "$baseTypeExpression" for xml element: $dataTypeElement',
    );
    return null;
  }

  final _baseTypeFactory = BaseTypeFactory.forIecTypes();

  Enumeration _createEnum(XmlElement dataTypeElement) {
    String name = dataTypeElement.getAttribute(nameAttribute)!;
    String comment = dataTypeElement.getAttribute(commentAttribute)!;
    var children = dataTypeElement.childElements
        .where((element) => element.name.local == 'DataType')
        .map((element) => _createEnumMember(element))
        .toList();
    return Enumeration(name: name, comment: comment, children: children);
  }

  EnumerationMember _createEnumMember(XmlElement dataTypeElement) {
    String name = dataTypeElement.getAttribute(nameAttribute)!;
    String comment = dataTypeElement.getAttribute(commentAttribute)!;
    String baseTypeExpression = dataTypeElement.getAttribute(
      baseTypeAttribute,
    )!;
    int index = int.parse(dataTypeElement.getAttribute(enumValueAttribute)!);
    var baseType = _baseTypeFactory.createFromExpression(baseTypeExpression);
    return EnumerationMember(
      name: name,
      comment: comment,
      baseType: baseType,
      index: index,
    );
  }

  Structure _createStructure(XmlElement dataTypeElement) {
    String name = dataTypeElement.getAttribute(nameAttribute)!;
    String comment = dataTypeElement.getAttribute(commentAttribute)!;
    var members = dataTypeElement.childElements
        .where((element) => element.name.local == 'DataType')
        .map((element) => _createDataTypeReference(element))
        .toList();
    return Structure(name: name, comment: comment, children: members);
  }

  DataTypeMember _createDataTypeReference(XmlElement dataTypeElement) {
    var name = dataTypeElement.getAttribute(nameAttribute)!;
    var comment = dataTypeElement.getAttribute(commentAttribute)!;
    var typeExpression = dataTypeElement.getAttribute(baseTypeAttribute)!;
    var baseType = _baseTypeFactory.createFromExpression(typeExpression);
    // note that if the typeExpression is a reference to a dataType
    // than baseType will be an UnknownBaseType which will be replaced
    // with the correct BaseType later, see resolveDataTypeReferences(dataTypes)
    return DataTypeMember(name: name, comment: comment, baseType: baseType);
  }

  DataType _createUnion(XmlElement dataTypeElement) {
    String name = dataTypeElement.getAttribute(nameAttribute)!;
    String comment = dataTypeElement.getAttribute(commentAttribute)!;
    var members = dataTypeElement.childElements
        .where((element) => element.name.local == 'DataType')
        .map((element) => _createDataTypeReference(element))
        .toList();
    return Union(name: name, comment: comment, children: members);
  }
}
