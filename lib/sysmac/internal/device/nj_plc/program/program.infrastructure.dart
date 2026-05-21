import 'dart:convert';

import 'package:meyncraft/logger/logger.service.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/nj_plc.infrastructure.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/structured_text.infrastructure.dart';
import 'package:meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'package:meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

List<Program> createPrograms(
  SysmacProject sysmacProject,
  XmlElement codeOwnerElement,
) {
  var programElements = getFilteredDescendingElements(
    codeOwnerElement,
    include: isProgramElement,
    exclude: (e) =>
        isNestedLibraryElement(rootElement: codeOwnerElement, element: e),
  );

  var programs = programElements
      .map((e) => createProgram(sysmacProject, e))
      .whereType<Program>() // remove nulls
      .toList();

  return programs;
}

bool isProgramElement(XmlElement e) =>
    e.name.local == entity && e.getAttribute(typeAttribute) == 'Program';

Program? createProgram(SysmacProject sysmacProject, XmlElement programElement) {
  var subType = programElement.getAttribute(subTypeAttribute);
  switch (subType) {
    case 'MultipartLadder':
      return createLadderProgram(sysmacProject, programElement);
    case 'StructuredText':
      return createStructuredTextProgram(sysmacProject, programElement);

    case 'FBDExtended':
      // for now ignoring  'FBDExtended'
      // which seems to be related to safety programs and functions
      return null;
    default:
      logger.w('unknown program sub type: $subType');
      return null;
  }
}

int getElementDepth(XmlElement element) {
  int depth = 0;
  XmlNode? current = element.parent;

  while (current != null && current is XmlElement) {
    depth++;
    current = current.parent;
  }

  return depth;
}

LadderProgram createLadderProgram(
  SysmacProject sysmacProject,
  XmlElement programElement,
) {
  var name = programElement.getAttribute(nameAttribute)!;
  var entities = programElement.descendantElements.where(
    (e) => e.name.local == 'Entity',
  );
  var variablesElement = entities.firstWhere(
    (e) => e.getAttribute(typeAttribute) == 'Variables',
  );
  var variableGroups = createVariableGroups(
    sysmacProject.archive,
    sysmacProject.dataTypes,
    variablesElement.getAttribute(idAttribute)!,
  );
  var internalVariables = variableGroups[VariableGroup.internal] ?? [];
  var externalVariables = variableGroups[VariableGroup.external] ?? [];

  var pouBodyElements = entities.where(
    (e) => e.getAttribute(typeAttribute) == 'PouBody',
  );

  var ladderSections = pouBodyElements
      .map((e) => createLadderSection(sysmacProject.archive, e))
      .whereType<LadderSection>() // remove nulls
      .toList();

  return LadderProgram(
    name: name,
    ladderSections: ladderSections,
    internalVariables: internalVariables,
    externalVariables: externalVariables,
  );
}

StructuredTextProgram? createStructuredTextProgram(
  SysmacProject sysmacProject,
  XmlElement programElement,
) {
  var name = programElement.getAttribute(nameAttribute)!;
  var entities = programElement.descendantElements.where(
    (e) => e.name.local == 'Entity',
  );
  var variablesElement = entities.firstWhere(
    (e) => e.getAttribute(typeAttribute) == 'Variables',
  );
  var variableGroups = createVariableGroups(
    sysmacProject.archive,
    sysmacProject.dataTypes,
    variablesElement.getAttribute(idAttribute)!,
  );
  var internalVariables = variableGroups[VariableGroup.internal] ?? [];
  var externalVariables = variableGroups[VariableGroup.external] ?? [];

  var pouBodyElement = entities.firstWhere(
    (e) => e.getAttribute(typeAttribute) == 'PouBody',
  );
  var id = pouBodyElement.getAttribute(idAttribute)!;
  var archiveFile = sysmacProject.archive.projectIndexXml.findArchiveFile(id);
  if (archiveFile == null) {
    logger.w('StructuredTextProgram archive file: $id.xml not found');
    return null;
  }
  var structuredText = createStructuredText(archiveFile);

  return StructuredTextProgram(
    name: name,
    structuredText: structuredText,
    internalVariables: internalVariables,
    externalVariables: externalVariables,
  );
}

LadderSection? createLadderSection(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement entityElement,
) {
  String name = entityElement.getAttribute(nameAttribute)!;
  String id = entityElement.getAttribute(idAttribute)!;
  String subType = entityElement.getAttribute(subTypeAttribute)!;
  if (subType != 'Ladder') {
    logger.w('Unsupported Entity sub-type: $subType');
    return null;
  }
  return createLadderBody(
    sysmacProjectArchive: sysmacProjectArchive,
    name: name,
    id: id,
  );
}

LadderSection createLadderBody({
  required SysmacProjectArchive sysmacProjectArchive,
  required String name,
  required String id,
}) {
  List<Rung> rungs = createRungs(sysmacProjectArchive, id);
  return LadderSection(name, rungs);
}

List<Rung> createRungs(SysmacProjectArchive sysmacProjectArchive, String id) {
  var archiveFile = sysmacProjectArchive.projectIndexXml.findArchiveFile(id);
  if (archiveFile == null) {
    logger.w('Ladder program archive file: $id.xml not found');
    return [];
  }
  var content = convertContentToUtf8(archiveFile);
  var jsonLines = content.split('\n');
  var rungs = <Rung>[];
  for (var json in jsonLines) {
    if (json.trim().isEmpty) {
      continue;
    }
    var map = parseJsonToMap(json);
    var rung = createRungFromJsonMap(map);
    rungs.add(rung);
  }
  return rungs;
}

Rung createRungFromJsonMap(Map<String, dynamic> map) {
  var comment = map['CMT'] as String?;
  var objects = map['CLs'] as List<dynamic>;
  var ladderObjects = <LadderObject>[];
  for (var object in objects) {
    var objectMap = object as Map<String, dynamic>;
    var ladderObject = createLadderObject(objectMap);
    if (ladderObject == null) {
      logger.w('Unknown ladder object type: ${objectMap['__type']}');
    } else {
      ladderObjects.add(ladderObject);
    }
  }
  var verticalLines = map['VLs'] as List<dynamic>;
  ladderObjects.addAll(createVerticalLines(verticalLines));

  return Rung(ladderObjects, comment);
}

LadderObject? createLadderObject(Map<String, dynamic> objectMap) {
  var type = objectMap['__type'] as String;
  return switch (type) {
    'LD' => createContact(objectMap),
    'ST' => createCoil(objectMap),
    'JMP' => createJump(objectMap),
    'F' => createFunctionCall(objectMap),
    'FB' => createFunctionBlockCall(objectMap),
    'IST' => createInLineStructuredText(objectMap),
    'HL' => createHorizontalLine(objectMap),
    _ => null,
  };
}

List<VerticalLine> createVerticalLines(List verticalLines) => verticalLines
    .map((e) => createVerticalLine(e as Map<String, dynamic>))
    .toList();

HorizontalLine createHorizontalLine(Map<String, dynamic> map) {
  var x = (map['X'] ?? 0) as int;
  var y = (map['Y'] ?? 0) as int;
  return HorizontalLine(x: x, y: y);
}

VerticalLine createVerticalLine(Map<String, dynamic> map) {
  var x = (map['X'] ?? 0) as int;
  var y = (map['Y'] ?? 0) as int;
  var index = (map['Ix'] ?? 0) as int;
  return VerticalLine(index: index, x: x, y: y);
}

LadderObject createInLineStructuredText(Map<String, dynamic> map) {
  var structuredText = map['TXT']!;
  var index = (map['Ix'] ?? 0) as int;
  var x = (map['X'] ?? 0) as int;
  var y = (map['Y'] ?? 0) as int;
  // ignoring:
  // W = width
  // H = height
  // EID = id

  return InlineStructuredText(structuredText, index: index, x: x, y: y);
}

LadderObject createFunctionBlockCall(Map<String, dynamic> map) {
  var name = map['Name']!;
  var variable = map['Var']!;
  var index = (map['Ix'] ?? 0) as int;
  var x = (map['X'] ?? 0) as int;
  var y = (map['Y'] ?? 0) as int;
  var ud = map['UD'] == true;
  var parametersIn = createParameters(map['In']);
  var parametersOut = createParameters(map['Out']);

  return FunctionBlockCall(
    name,
    variable: variable,
    index: index,
    x: x,
    y: y,
    parametersIn: parametersIn,
    parametersOut: parametersOut,
    ud: ud,
  );
}

Jump createJump(Map<String, dynamic> map) {
  var x = (map['X'] ?? 0) as int;
  var y = (map['Y'] ?? 0) as int;
  var index = (map['Ix'] ?? 0) as int;
  var label = map["Label"]!;
  return Jump(x: x, y: y, index: index, label: label);
}

LadderObject createFunctionCall(Map<String, dynamic> map) {
  var name = map['Name']!;
  var index = (map['Ix'] ?? 0) as int;
  var x = (map['X'] ?? 0) as int;
  var y = (map['Y'] ?? 0) as int;
  var ud = map['UD'] == true;
  var pl = map['PL'] == true;
  var parametersIn = createParameters(map['In']);
  var parametersOut = createParameters(map['Out']);

  return FunctionCall(
    name,
    index: index,
    x: x,
    y: y,
    parametersIn: parametersIn,
    parametersOut: parametersOut,
    ud: ud,
    pl: pl,
  );
}

List<Parameter> createParameters(Object? parameters) {
  if (parameters is! List) {
    return <Parameter>[];
  }
  return parameters
      .map(createParameter)
      .whereType<Parameter>() // remove nulls
      .toList();
}

Parameter? createParameter(dynamic parameter) {
  if (parameter is! Map<String, dynamic>) {
    return null;
  }
  ParameterType? type = switch (parameter['__type']) {
    'PF' => ParameterType.inOutConnection,
    'PRM' => ParameterType.parameter,
    _ => null,
  };
  if (type == null) {
    // warning(
    //   'Unsupported Function(Block) parameter type: ${parameter['__type']}',
    // );
    return null;
  }
  var argument = parameter['Arg']!;
  var argumentType = parameter['Type'];
  var variable = parameter['Var'];
  var io = parameter['IO'] as bool?;
  var index = (parameter['Ix'] ?? 0) as int;
  return Parameter(
    type: type,
    argument: argument,
    argumentType: argumentType,
    variable: variable,
    inAndOut: io,
    index: index,
  );
}

Contact createContact(Map<String, dynamic> map) {
  var variable = map['Var'] as String;
  var index = (map['Ix'] ?? 0) as int;
  var x = (map['X'] ?? 0) as int;
  var y = (map['Y'] ?? 0) as int;
  var edgeDetection = map['Up'] == true
      ? EdgeDetection.up
      : map['Dwn'] == true
      ? EdgeDetection.down
      : EdgeDetection.none;
  var negated = map['Not'] == true;

  return Contact(
    variable,
    index: index,
    x: x,
    y: y,
    edgeDetection: edgeDetection,
    negated: negated,
  );
}

Coil createCoil(Map<String, dynamic> map) {
  var variable = map['Var'] as String;
  var index = (map['Ix'] ?? 0) as int;
  var x = (map['X'] ?? 0) as int;
  var y = (map['Y'] ?? 0) as int;
  var edgeDetection = map['Up'] == true
      ? EdgeDetection.up
      : map['Dwn'] == true
      ? EdgeDetection.down
      : EdgeDetection.none;
  var actuationMode = map['S'] == true
      ? ActuationMode.set
      : map['RS'] == true
      ? ActuationMode.reset
      : ActuationMode.none;
  var negated = map['Not'] == true;

  return Coil(
    variable,
    index: index,
    x: x,
    y: y,
    actuationMode: actuationMode,
    edgeDetection: edgeDetection,
    negated: negated,
  );
}

Map<String, dynamic> parseJsonToMap(String jsonString) =>
    jsonDecode(jsonString) as Map<String, dynamic>;
