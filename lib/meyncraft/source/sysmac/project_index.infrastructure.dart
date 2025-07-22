import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:xml/xml.dart';

import 'data_type/data_type.infrastructure.dart';
import 'sysmac_project.infrastructure.dart';

const String typeAttribute = 'type';
const String subTypeAttribute = 'subtype';
const String nameAttribute = 'name';
const String idAttribute = 'id';
const String nameSpaceAttribute = 'namespace';
const String entity = 'Entity';
const String dataType = 'DataType';
const String variable = 'Variable';

/// Represents the only [ArchiveFile] with an
/// .[oem](https://en.wikipedia.org/wiki/Original_equipment_manufacturer)
/// file extension inside a [SysmacProjectFile].
///
/// It contains a [XmlDocument] containing them main project index that contains
/// references to other xml or swld files.
///
/// It can convert this [XmlDocument] to domain objects that represent
/// more meaningful information (e.g. references to other xml files)
class ProjectIndexXml extends ArchiveXml {
  final Archive archive;

  ProjectIndexXml(this.archive) : super.fromArchiveFile(_findOemFile(archive));

  static ArchiveFile _findOemFile(Archive archive) => archive.firstWhere(
    (ArchiveFile archiveFile) =>
        archiveFile.isFile && archiveFile.name.endsWith('.oem'),
  );

  List<DataTypeArchiveXmlFile> dataTypeArchiveXmlFiles() {
    List<XmlNode> dataTypeEntities = _findDataTypeEntities();

    List<DataTypeArchiveXmlFile> dataTypeArchiveXmlFiles = [];
    for (var dataTypeEntity in dataTypeEntities) {
      try {
        String id = dataTypeEntity.getAttribute(idAttribute)!;
        String nameSpacePath =
            dataTypeEntity.getAttribute(nameSpaceAttribute) ?? '';
        var archiveFile = _findArchiveFile(id);
        if (archiveFile != null) {
          var dataTypeXmlArchiveFile = DataTypeArchiveXmlFile.fromArchiveFile(
            nameSpacePath: nameSpacePath,
            archiveFile: archiveFile,
          );
          dataTypeArchiveXmlFiles.add(dataTypeXmlArchiveFile);
        }
      } on Error {
        // Not found: no problem, try next
      }
    }
    return dataTypeArchiveXmlFiles;
  }

  List<XmlNode> _findGlobalVariableEntities() => xmlDocument.descendants
      .where((node) => _isGlobalVariableEntity(node))
      .toList();

  @Deprecated(
    'This is needed for OldVariable which is deprecated. Use Variable instead',
  )
  List<XmlNode> _findGlobalMemoryVariableEntities() => xmlDocument.descendants
      .where((node) => _isGlobalMemoryVariableEntity(node))
      .toList();

  List<XmlNode> _findDataTypeEntities() {
    var dataTypeEntities = xmlDocument.descendants
        .where((node) => _isDataTypeEntity(node))
        .toList();
    return dataTypeEntities;
  }

  bool _isDataTypeEntity(XmlNode node) =>
      node is XmlElement &&
      node.name.local == entity &&
      node.getAttribute(typeAttribute) == dataType;

  @Deprecated(
    'This is needed for OldVariable which is deprecated. Use Variable instead',
  )
  bool _isGlobalMemoryVariableEntity(XmlNode node) =>
      node is XmlElement &&
      node.name.local == entity &&
      node.getAttribute(typeAttribute) == 'Variables' &&
      node.getAttribute(subTypeAttribute) == 'MemoryVariables' &&
      node.getAttribute(nameAttribute) == 'Global Variables';

  bool _isGlobalVariableEntity(XmlNode node) =>
      node is XmlElement &&
      node.name.local == entity &&
      node.getAttribute(typeAttribute) == 'Variables' &&
      node.getAttribute(subTypeAttribute) == 'Global' &&
      node.getAttribute(nameAttribute) == 'Global Variables';

  ArchiveFile globalVariableArchiveFile() {
    List<XmlNode> entities = _findGlobalVariableEntities();
    if (entities.length != 1) {
      throw Exception('Expected only one reference to the variables');
    }
    var variableDataFileId = entities.first.getAttribute(idAttribute)!;
    var variableDataFile = _findArchiveFile(variableDataFileId);
    if (variableDataFile == null) {
      throw Exception('Could not find file: $variableDataFileId');
    }
    return variableDataFile;
  }

  @Deprecated(
    'This is needed for OldVariable which is deprecated. Use Variable instead',
  )
  List<GlobalVariableArchiveXmlFile> globalVariableArchiveXmlFiles(
    DataTypeTree dataTypeTree,
  ) {
    List<XmlNode> entities = _findGlobalMemoryVariableEntities();

    List<GlobalVariableArchiveXmlFile> variableArchiveXmlFiles = [];
    for (var dataTypeEntity in entities) {
      try {
        String id = dataTypeEntity.getAttribute(idAttribute)!;
        String nameSpacePath =
            dataTypeEntity.getAttribute(nameSpaceAttribute) ?? '';
        var archiveFile = _findArchiveFile(id);
        if (archiveFile != null) {
          var variableXmlArchiveFile =
              GlobalVariableArchiveXmlFile.fromArchiveFile(
                dataTypeTree: dataTypeTree,
                nameSpacePath: nameSpacePath,
                archiveFile: archiveFile,
              );
          variableArchiveXmlFiles.add(variableXmlArchiveFile);
        }
      } catch (e) {
        // Not found: no problem, try next
      }
    }
    return variableArchiveXmlFiles;
  }

  ArchiveFile? _findArchiveFile(String id) {
    String xmlFileName = '$id.xml';
    return archive.firstWhereOrNull(
      (ArchiveFile archiveFile) => archiveFile.name.endsWith(xmlFileName),
    );
  }
}
