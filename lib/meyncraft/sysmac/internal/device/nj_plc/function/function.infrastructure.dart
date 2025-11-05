import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/nj_plc.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/structured_text.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:xml/xml.dart';

List<Function$> createFunctions(
  SysmacProject sysmacProject,
  XmlElement codeOwnerElement,
) {
  var functionElements = getFilteredDescendingElements(
    codeOwnerElement,
    include: isFunctionElement,
    exclude: (e) =>
        isNestedLibraryElement(rootElement: codeOwnerElement, element: e),
  );

  var functions = functionElements
      .map((e) => createFunction(sysmacProject, e))
      .whereType<Function$>() //remove nulls
      .toList();

  return functions;
}

bool isFunctionElement(XmlElement e) =>
    e.name.local == entity && e.getAttribute(typeAttribute) == 'Function';

Function$? createFunction(
  SysmacProject sysmacProject,
  XmlElement functionElement,
) {
  var name = functionElement.getAttribute(nameAttribute)!;
  var entities = functionElement.descendantElements.where(
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
      return createLadderFunction(
        sysmacProject,
        name: name,
        variablesElement: variablesElement,
        pouBodyElement: pouBodyElement,
      );
    case 'StructuredText':
      return createStructuredTextFunction(
        sysmacProject,
        name: name,
        variablesElement: variablesElement,
        pouBodyElement: pouBodyElement,
      );
    case 'FBDExtended':

      /// ignore safety
      return null;
    default:
      print('Unsupported Function sub type: $subType');
      return null;
  }
}

StructuredTextFunction createStructuredTextFunction(
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
  return StructuredTextFunction(
    name: name,
    internalVariables: internalVariables,
    externalVariables: externalVariables,
    structuredText: structuredText,
    inOutVariables: inOutVariables,
  );
}

LadderFunction createLadderFunction(
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
  return LadderFunction(
    name: name,
    internalVariables: internalVariables,
    externalVariables: externalVariables,
    inOutVariables: inOutVariables,
    rungs: rungs,
  );
}
