import 'package:archive/archive.dart';
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
  DataTypes dataTypes = DataTypes();
  _addAndCreateChildren(sysmacProjectArchive, dataTypes);
  replaceDataTypeReferencesWherePossible(dataTypes);
  return dataTypes;
}

void _addAndCreateChildren(
  SysmacProjectArchive sysmacProjectArchive,
  DataTypes dataTypes,
) {
  var dataTypeArchiveXmlFiles = sysmacProjectArchive.projectIndexXml
      .dataTypeArchiveXmlFiles();

  for (var dataTypeArchiveXmlFile in dataTypeArchiveXmlFiles) {
    var newDataTypes = dataTypeArchiveXmlFile.toDataTypes();

    if (dataTypeArchiveXmlFile.nameSpacePath.isEmpty) {
      _addAllNoneExisting(dataTypes, newDataTypes);
    } else {
      var nameSpacePath = dataTypeArchiveXmlFile.nameSpacePath.split(r'\');
      DataTypeBase nameSpace = _findOrCreateNameSpacePath(
        dataTypes,
        nameSpacePath,
      );
      _addAllNoneExisting(nameSpace.children, newDataTypes);
    }
  }
}

void _addAllNoneExisting(List<DataTypeBase> children, DataTypes newDataTypes) {
  for (var newDataType in newDataTypes) {
    var exists = children.any(
      (dt) => dt.name.toLowerCase() == newDataType.name.toLowerCase(),
    );
    if (!exists) {
      children.add(newDataType);
    } 
  }
}

DataTypeBase _findOrCreateNameSpacePath(
  DataTypes dataTypes,
  List<String> namePath,
) {
  for (var dataType in dataTypes) {
    var foundPath = dataType.findFirstNodePath(
      findPartialOrFullNamePath(namePath),
    );

    if (foundPath.isNotEmpty) {
      if (foundPath.length == namePath.length) {
        // found full path: return it
        return dataType;
      }

      /// complete path
      var remainingNamePath = namePath.skip(foundPath.length);
      var existingNamePath = foundPath.last as DataTypeBase;
      var lastNameSpace = appendToNameSpaceAndReturnLast(
        existingNamePath,
        remainingNamePath,
      );
      return lastNameSpace;
    }
  }

  /// add new name space path to the root
  var newNameSpace = NameSpace(namePath.first);
  dataTypes.add(newNameSpace);
  var lastNameSpace = appendToNameSpaceAndReturnLast(
    newNameSpace,
    namePath.skip(1),
  );
  return lastNameSpace;
}

/// returns the first [NodePath] for the first matching (partial) name path
NodePathFinder findPartialOrFullNamePath(
  Iterable<String> namePath, {
  bool caseSensitive = true,
  NodePath precedingPath = const [],
}) => (Node node) {
  var currentPath = [...precedingPath, node];
  if (namePath.isEmpty) {
    return [];
  }
  if (!equalNames(namePath.first, node.name, caseSensitive)) {
    return precedingPath;
  }
  if (namePath.length == 1) {
    return currentPath;
  }
  var finder = namePathFinder(namePath.skip(1), precedingPath: currentPath);
  for (var child in node.children) {
    var found = finder(child as Node);
    if (found.isNotEmpty) {
      return found;
    }
  }
  return [];
};

/// returns the last node of a created name space path
DataTypeBase appendToNameSpaceAndReturnLast(
  DataTypeBase last,
  Iterable<String> namePath,
) {
  for (var name in namePath) {
    var nameSpace = NameSpace(name);
    last.children.add(nameSpace);
    last = nameSpace;
  }
  return last;
}

// DataTypeBase _findOrCreateNam11eSpacePath(
//   DataTypes nameSpace,
//   String nameSpacePathToFind,
// ) {
//   if (nameSpacePathToFind.isEmpty) {
//     // found
//     return nameSpace;
//   }

//   var namesToFind = nameSpacePathToFind.split(nameSpacePathSeparator);
//   String nameToFind = namesToFind.first;

//   for (DataTypeBase child in nameSpace) {
//     if (child.name == nameToFind) {
//       namesToFind.removeAt(0);
//       String remainingPathToFind = namesToFind.join(nameSpacePathSeparator);
//       return _findOrCreateNameSpacePath(child, remainingPathToFind);
//     }
//   }
//   //not found: create nameSpace tree
//   for (String nameToCreate in namesToFind) {
//     var newNameSpaceChild = NameSpace(nameToCreate);
//     nameSpace.add(newNameSpaceChild);
//     nameSpace = newNameSpaceChild;
//   }
//   return nameSpace;
// }

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
        ? BaseTypeFactory().createFromExpression(baseTypeExpression)
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
