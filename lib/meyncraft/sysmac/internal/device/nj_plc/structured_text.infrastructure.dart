import 'package:archive/archive.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

String createStructuredText(ArchiveFile archiveFile) {
  var xml = convertContentToUtf8(archiveFile);
  var xmlDocument = XmlDocument.parse(xml);
  var textElements = xmlDocument.findAllElements('Text');
  if (textElements.isEmpty) {
    /// Likely to be an EncryptedFile reference
    return '// Encrypted structured text';
  }
  var structuredText = textElements.first.innerText;
  return structuredText;
}
