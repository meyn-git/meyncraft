import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/detail/detail.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/event.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:petitparser/petitparser.dart';
import 'package:xml/xml.dart';

import 'data_type/data_type.infrastructure.dart';
import 'project_index.infrastructure.dart';

/// A [SysmacProjectFile] is an exported
/// [Omron Sysmac project](https://automation.omron.com/en/us/products/family/sysstdio).
/// This is a file with the *.scm file extension.
///
/// Note that you need to export the
/// [Omron Sysmac project](https://automation.omron.com/en/us/products/family/sysstdio)
/// before using it with [SysmacGenerator].
///
/// A [SysmacProjectFile] name should have the following format:\
/// &lt;site number&gt;DE&lt;panel number&gt;-&lt;panel name&gt;-&lt;standard version&gt;-&lt;customer version&gt;&lt;not installed reason&gt;.smc2\
/// e.g.: 4321DE06-Evisceration-001-005-to_be_installed.smc2
/// * &lt;site number&gt;= Meyn layout number
/// * &lt;panel number&gt;= Unique number within site (see electrical schematic)
/// * &lt;panel name&gt;= See official product name on web site (without line number!)
/// * &lt;standard version&gt;= 0-...
/// * &lt;customer version&gt;= 0-..., increases with 1 with every new version.
/// * &lt;not installed reason&gt;= optional text explaining why this version is not the latest version at the customer.
class SysmacProjectFile {}

class SysmacProjectFactory {
  //TODO make async
  SysmacProject create(File file) {
    var sysmacProjectArchive = SysmacProjectArchive(file);
    var dataTypeTree = DataTypeTreeFactory().create(sysmacProjectArchive);
    var globalVariableService = GlobalVariableService(
      sysmacProjectArchive,
      dataTypeTree,
    );
    var details = createDetails(file);
    var eventService = EventService(globalVariableService);
    return SysmacProject(
      details: details,
      dataTypeTree: dataTypeTree,
      globalVariableService: globalVariableService,
      eventService: eventService,
    );
  }
}

/// Represents a physical Sysmac project file,
/// which is actually a zip [Archive] containing [ArchiveFile]s
class SysmacProjectArchive {
  static String extension = 'smc2';
  late final File file;
  late ProjectIndexXml projectIndexXml;

  SysmacProjectArchive(File file) {
    _validateExtension(file);
    _validateExists(file);
    Archive archive = readArchive(file);
    projectIndexXml = ProjectIndexXml(archive);
  }

  void _validateExtension(File file) {
    if (!file.path.toLowerCase().endsWith(".$extension")) {
      throw ArgumentError(
        "does not end with .$extension extension",
        'sysmacProjectFilePath',
      );
    }
  }

  void _validateExists(File file) {
    if (!file.existsSync()) {
      throw ArgumentError(
        'does not point to a existing Sysmac project file',
        'sysmacProjectFilePath',
      );
    }
  }

  Archive readArchive(File file) {
    final bytes = file.readAsBytesSync();
    return ZipDecoder().decodeBytes(bytes);
  }
}

/// Parses the XML of an [ArchiveFile] inside a [SysmacProjectFile]
/// to an [XmlDocument] and can convert it to more meaningful domain objects
abstract class ArchiveXml {
  final XmlDocument xmlDocument;

  ArchiveXml.fromArchiveFile(ArchiveFile archiveFile)
    : this.fromXml(_convertContentToUtf8(archiveFile));

  ArchiveXml.fromXml(String xml) : xmlDocument = XmlDocument.parse(xml);

  static String _convertContentToUtf8(ArchiveFile archiveFile) {
    var content = archiveFile.content;
    return utf8.decode(content);
  }
}
