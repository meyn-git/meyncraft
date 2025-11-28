import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import 'internal/data_type/data_type.infrastructure.dart';
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
  final Archive _archive;

  ProjectIndexXml(this._archive)
    : super.fromArchiveFile(_findOemFile(_archive));

  static ArchiveFile _findOemFile(Archive archive) => archive.firstWhere(
    (ArchiveFile archiveFile) =>
        archiveFile.isFile && archiveFile.name.endsWith('.oem'),
  );

  List<DataTypeArchiveXmlFile> dataTypeArchiveXmlFiles() {
    var plcDeviceEntities = _findPlcDeviceEntities();

    List<XmlNode> dataTypeEntities = _findDataTypeEntities(plcDeviceEntities);

    List<DataTypeArchiveXmlFile> dataTypeArchiveXmlFiles = [];
    for (var dataTypeEntity in dataTypeEntities) {
      try {
        String id = dataTypeEntity.getAttribute(idAttribute)!;
        String nameSpacePath =
            dataTypeEntity.getAttribute(nameSpaceAttribute) ?? '';
        var archiveFile = findArchiveFile(id);
        if (archiveFile != null) {
          var dataTypeArchiveXmlFile = DataTypeArchiveXmlFile.fromArchiveFile(
            nameSpacePath: nameSpacePath,
            archiveFile: archiveFile,
          );
          dataTypeArchiveXmlFiles.add(dataTypeArchiveXmlFile);
        }
      } on Error {
        // Not found: no problem, try next
      }
    }
    return dataTypeArchiveXmlFiles;
  }

  List<XmlNode> _findDataTypeEntities(Iterable<XmlElement> plcDeviceEntities) =>
      [
        for (var plcDeviceEntity in plcDeviceEntities)
          ...plcDeviceEntity.descendantElements.where(_isDataTypeEntity),
      ];

  bool _isDataTypeEntity(XmlElement element) =>
      element.name.local == entity &&
      element.getAttribute(typeAttribute) == dataType;

  ArchiveFile? findArchiveFile(String id) {
    String xmlFileName = '$id.xml';
    return _archive.firstWhereOrNull(
      (ArchiveFile archiveFile) => archiveFile.name.endsWith(xmlFileName),
    );
  }

  /// gets a nam path of the given [dataTypeEntity] by getting the name attribute  of the xml elements up to the root
  String namePathOfElement(XmlElement dataTypeEntity) {
    List<String> namePath = [];
    XmlElement? currentElement = dataTypeEntity;
    while (currentElement != null) {
      var name = currentElement.getAttribute(nameAttribute);
      if (name != null) {
        namePath.insert(0, name);
      }
      currentElement = currentElement.parentElement;
    }
    return namePath.join('.');
  }

  Iterable<XmlElement> _findPlcDeviceEntities() =>
      xmlDocument.descendantElements.where(
        (e) =>
            e.name.local == entity &&
            e.getAttribute(typeAttribute) == 'Device' &&
            (e.getAttribute(subTypeAttribute) ?? '').startsWith('NJ'),
      );
}
