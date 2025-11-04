import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/nj_plc.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/structured_text.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

List<Function$> createFunctions(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement codeOwnerElement,
) {
  var functionElements = getFilteredDescendingElements(
    codeOwnerElement,
    include: isFunctionElement,
    exclude: (e) =>
        isNestedLibraryElement(rootElement: codeOwnerElement, element: e),
  );

  var functions = functionElements
      .map((e) => createFunction(sysmacProjectArchive, e))
      .whereType<Function$>() //remove nulls
      .toList();

  return functions;
}

bool isFunctionElement(XmlElement e) =>
    e.name.local == entity && e.getAttribute(typeAttribute) == 'Function';

Function$? createFunction(
  SysmacProjectArchive sysmacProject,
  XmlElement functionElement,
) {
  var name = functionElement.getAttribute(nameAttribute)!;
  var entities = functionElement.descendantElements.where(
    (e) => e.name.local == 'Entity',
  );
  var variablesElement = entities.firstWhere(
    (e) => e.getAttribute(typeAttribute) == 'Variables',
  );
  var pouBodyElements = entities.where(
    (e) => e.getAttribute(typeAttribute) == 'PouBody',
  );
  var id = pouBodyElements.first.getAttribute(idAttribute)!;

  var subType = pouBodyElements.first.getAttribute(subTypeAttribute)!;
  switch (subType) {
    case 'Ladder':
      return createLadderFunction(sysmacProject, name: name, id: id);
    case 'StructuredText':
      return createStructuredTextFunction(sysmacProject, name: name, id: id);
    case 'FBDExtended':

      /// ignore safety
      return null;
    default:
      print('Unsupported Function sub type: $subType');
      return null;
  }
}

StructuredTextFunction createStructuredTextFunction(
  SysmacProjectArchive sysmacProject, {
  required String name,
  required String id,
}) {
  var archiveFile = sysmacProject.projectIndexXml.findArchiveFile(id)!;
  var structuredText = createStructuredText(archiveFile);
  return StructuredTextFunction(name: name, structuredText: structuredText);
}

LadderFunction createLadderFunction(
  SysmacProjectArchive sysmacProject, {
  required String name,
  required String id,
}) {
  var rungs = createRungs(sysmacProject, id);
  return LadderFunction(name: name, rungs: rungs);
}
