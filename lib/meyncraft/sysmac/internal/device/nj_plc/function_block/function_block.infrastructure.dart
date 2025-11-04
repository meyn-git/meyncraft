import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/nj_plc.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/structured_text.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

List<FunctionBlock> createFunctionBlocks(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement codeOwnerElement,
) {
  var functionBlockElements = getFilteredDescendingElements(
    codeOwnerElement,
    include: isFunctionBlockElement,
    exclude: (e) =>
        isNestedLibraryElement(rootElement: codeOwnerElement, element: e),
  );

  var functionBlocks = functionBlockElements
      .map((e) => createFunctionBlock(sysmacProjectArchive, e))
      .whereType<FunctionBlock>() //removes nulls
      .toList();

  return functionBlocks;
}

bool isFunctionBlockElement(XmlElement e) =>
    e.name.local == entity && e.getAttribute(typeAttribute) == 'FunctionBlock';

FunctionBlock? createFunctionBlock(
  SysmacProjectArchive sysmacProject,
  XmlElement functionBlockElement,
) {
  var name = functionBlockElement.getAttribute(nameAttribute)!;
  var entities = functionBlockElement.descendantElements.where(
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
      return createLadderFunctionBlock(sysmacProject, name: name, id: id);
    case 'StructuredText':
      return createStructuredTextFunctionBlock(
        sysmacProject,
        name: name,
        id: id,
      );
    case 'FBDExtended':

      /// ignore safety
      return null;
    default:
      print('Unsupported Function Block sub type: $subType');
      return null;
  }
}

StructuredTextFunctionBlock createStructuredTextFunctionBlock(
  SysmacProjectArchive sysmacProject, {
  required String name,
  required String id,
}) {
  var archiveFile = sysmacProject.projectIndexXml.findArchiveFile(id)!;
  var structuredText = createStructuredText(archiveFile);
  return StructuredTextFunctionBlock(
    name: name,
    structuredText: structuredText,
  );
}

LadderFunctionBlock createLadderFunctionBlock(
  SysmacProjectArchive sysmacProject, {
  required String name,
  required String id,
}) {
  var rungs = createRungs(sysmacProject, id);
  return LadderFunctionBlock(name: name, rungs: rungs);
}
