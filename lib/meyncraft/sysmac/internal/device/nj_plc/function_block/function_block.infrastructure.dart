import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/nj_plc.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/structured_text.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

List<FunctionBlock> createFunctionBlocks(
  SysmacProject sysmacProject,
  XmlElement codeOwnerElement,
) {
  var functionBlockElements = getFilteredDescendingElements(
    codeOwnerElement,
    include: isFunctionBlockElement,
    exclude: (e) =>
        isNestedLibraryElement(rootElement: codeOwnerElement, element: e),
  );

  var functionBlocks = functionBlockElements
      .map((e) => createFunctionBlock(sysmacProject, e))
      .whereType<FunctionBlock>() //removes nulls
      .toList();

  return functionBlocks;
}

bool isFunctionBlockElement(XmlElement e) =>
    e.name.local == entity && e.getAttribute(typeAttribute) == 'FunctionBlock';

FunctionBlock? createFunctionBlock(
  SysmacProject sysmacProject,
  XmlElement functionBlockElement,
) {
  var name = functionBlockElement.getAttribute(nameAttribute)!;
  var entities = functionBlockElement.descendantElements.where(
    (e) => e.name.local == 'Entity',
  );
  var variablesElement = entities.firstWhere(
    (e) => e.getAttribute(typeAttribute) == 'Variables',
  );
  var pouBodyElement = entities.firstWhere(
    (e) => e.getAttribute(typeAttribute) == 'PouBody',
  );

  var subType = pouBodyElement.getAttribute(subTypeAttribute)!;
  switch (subType) {
    case 'Ladder':
      return createLadderFunctionBlock(
        sysmacProject,
        name: name,
        variablesElement: variablesElement,
        pouBodyElement: pouBodyElement,
      );
    case 'StructuredText':
      return createStructuredTextFunctionBlock(
        sysmacProject,
        name: name,
        variablesElement: variablesElement,
        pouBodyElement: pouBodyElement,
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
  SysmacProject sysmacProject, {
  required String name,
  required XmlElement variablesElement,
  required XmlElement pouBodyElement,
}) {
  var variableGroups = createVariableGroups(
    sysmacProject.archive,
    sysmacProject.dataTypeTree,
    variablesElement.getAttribute(idAttribute)!,
  );
  var internalVariables = variableGroups[VariableGroup.internal] ?? [];
  var externalVariables = variableGroups[VariableGroup.external] ?? [];
  var inOutVariables = variableGroups[VariableGroup.functionInOut] ?? [];

  var id = pouBodyElement.getAttribute(idAttribute)!;
  var archiveFile = sysmacProject.archive.projectIndexXml.findArchiveFile(id)!;
  var structuredText = createStructuredText(archiveFile);
  return StructuredTextFunctionBlock(
    name: name,
    internalVariables: internalVariables,
    externalVariables: externalVariables,
    inOutVariables: inOutVariables,
    structuredText: structuredText,
  );
}

LadderFunctionBlock createLadderFunctionBlock(
  SysmacProject sysmacProject, {
  required String name,
  required XmlElement variablesElement,
  required XmlElement pouBodyElement,
}) {
  var variableGroups = createVariableGroups(
    sysmacProject.archive,
    sysmacProject.dataTypeTree,
    variablesElement.getAttribute(idAttribute)!,
  );
  var internalVariables = variableGroups[VariableGroup.internal] ?? [];
  var externalVariables = variableGroups[VariableGroup.external] ?? [];
  var inOutVariables = variableGroups[VariableGroup.functionInOut] ?? [];

  var id = pouBodyElement.getAttribute(idAttribute)!;
  var rungs = createRungs(sysmacProject.archive, id);
  return LadderFunctionBlock(
    name: name,
    internalVariables: internalVariables,
    externalVariables: externalVariables,
    inOutVariables: inOutVariables,
    rungs: rungs,
  );
}
