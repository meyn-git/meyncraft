import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'project_index.infrastructure.dart';

/// Represents a physical Sysmac project file,
/// which is actually a zip [Archive] containing [ArchiveFile]s
class SysmacProjectArchive {
  static String extension = 'smc2';
  final Archive archive;
  final File file;
  final ProjectIndexXml projectIndexXml;

  SysmacProjectArchive._(this.file, this.archive)
    : projectIndexXml = ProjectIndexXml(file, archive);

  static Future<SysmacProjectArchive> loadFromFile(File file) async {
    _validateExtension(file);
    _validateExists(file);
    var archive = await readArchive(file);
    return SysmacProjectArchive._(file, archive);
  }

  static void _validateExtension(File file) {
    if (!file.path.toLowerCase().endsWith(".$extension")) {
      throw ArgumentError(
        "does not end with .$extension extension",
        'sysmacProjectFilePath',
      );
    }
  }

  static void _validateExists(File file) {
    if (!file.existsSync()) {
      throw ArgumentError(
        'does not point to a existing Sysmac project file',
        'sysmacProjectFilePath',
      );
    }
  }

  static Future<Archive> readArchive(File file) async {
    final bytes = await file.readAsBytes();
    return ZipDecoder().decodeBytes(bytes);
  }
}

/// Parses the XML of an [ArchiveFile] inside a [SysmacProjectFile]
/// to an [XmlDocument] and can convert it to more meaningful domain objects
abstract class ArchiveXml {
  final XmlDocument xmlDocument;

  ArchiveXml.fromArchiveFile(ArchiveFile archiveFile)
    : this.fromXml(convertContentToUtf8(archiveFile));

  ArchiveXml.fromXml(String xml) : xmlDocument = XmlDocument.parse(xml);
}

String convertContentToUtf8(ArchiveFile archiveFile) {
  var content = archiveFile.content;
  return utf8.decode(content);
}
