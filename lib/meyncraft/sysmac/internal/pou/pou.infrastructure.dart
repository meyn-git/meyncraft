import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/pou/pou.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

List<ProgramOrganizationUnit> createPous(
  SysmacProjectArchive sysmacProjectArchive,
) {
  // File file = File('test\\1176DE02-Evisceration-008.smc2');
  // SysmacProjectArchive sysmacProjectArchive = await SysmacProjectArchive.create(
  //   file,
  // );
  ProjectIndexXml projectIndexXml = sysmacProjectArchive.projectIndexXml;

  /// International Electrotechnical Commission (IEC) - Program organization unit (POU).
  var pouElements = findIecPousGroups(projectIndexXml);
  var pous = <ProgramOrganizationUnit>[];
  for (var pouElement in pouElements) {
    print('POU: ${pouElement.getAttribute(subTypeAttribute)}');
    // printFile(sysmacProjectArchive, pou.getAttribute(idAttribute));

    var pouGroups = pouElement.descendantElements.where(
      (e) => e.name.local == entity && e.getAttribute(typeAttribute) == 'Group',
    );

    for (var pouGroup in pouGroups) {
      print('  Pou Group: ${pouGroup.getAttribute('subtype')}');
      // printFile(
      //   sysmacProjectArchive.archive,
      //   pouGroup.getAttribute(idAttribute),
      // );
      var programElements = pouGroup.descendantElements.where(
        (e) =>
            e.name.local == entity &&
            e.getAttribute(typeAttribute) == 'Program',
      );

      for (var programElement in programElements) {
        print('    Program: ${programElement.getAttribute(nameAttribute)}');

        if (programElement.getAttribute(subTypeAttribute) ==
            'MultipartLadder') {
          var program = createProgram(sysmacProjectArchive, programElement);
          pous.add(program);
        } else {
          print('${programElement.getAttribute(subTypeAttribute)}');
        }
        // printFile(
        //   sysmacProjectArchive.archive,
        //   program.getAttribute(idAttribute),
        // );

        var pouBodies = pouGroup.descendantElements.where(
          (e) =>
              e.name.local == entity &&
              e.getAttribute(typeAttribute) == 'PouBody',
        );

        for (var pouBody in pouBodies) {
          print('    Pou Body: ${pouBody.getAttribute(nameAttribute)}');

          printFile(sysmacProjectArchive, pouBody.getAttribute(idAttribute));

          if (pouBody.getAttribute(subTypeAttribute) == 'Ladder') {
            var ladderBody = createLadderBody(
              sysmacProjectArchive: sysmacProjectArchive,
              id: pouBody.getAttribute(idAttribute)!,
              name: pouBody.getAttribute(nameAttribute)!,
            );
            //TODO pous.add(ladderBody);
          }

          if (pouBody.getAttribute(subTypeAttribute) == 'StructuredText') {
            var structuredTextBody = createStructuredTextProgram(
              sysmacProject: sysmacProjectArchive,
              id: pouBody.getAttribute(idAttribute)!,
              name: pouBody.getAttribute(nameAttribute)!,
            );
            // TODO pous.add(structuredTextBody);
          }

          //   var sourceHolders = pouBody.descendantElements.where(
          //     (e) =>
          //         e.name.local == entity &&
          //         e.getAttribute(typeAttribute) == 'SourceHolder',
          //   );

          //   printFile(
          //     sysmacProjectArchive.archive,
          //     sourceHolders.first.getAttribute(idAttribute),
          //   );

          //   var pouBodySourceHolders = pouBody.descendantElements.where(
          //     (e) =>
          //         e.name.local == entity &&
          //         e.getAttribute(typeAttribute) == 'PouBodySourceHolder',
          //   );
          //   printFile(
          //     sysmacProjectArchive.archive,
          //     pouBodySourceHolders.first.getAttribute(idAttribute),
          //   );
        }
      }

      var functionElements = pouGroup.descendantElements.where(
        (e) =>
            e.name.local == entity &&
            e.getAttribute(typeAttribute) == 'Function',
      );
      for (var functionElement in functionElements) {
        // print('    Program: ${functionElement.getAttribute(nameAttribute)}');
        var fun = createFunctionBody(
          sysmacProject: sysmacProjectArchive,
          id: functionElement.getAttribute(idAttribute)!,
          name: functionElement.getAttribute(nameAttribute)!,
        );
        if (fun != null) {
          //TODO pous.add(fun);
        }
      }

      var functionBlocksElements = pouGroup.descendantElements.where(
        (e) =>
            e.name.local == entity &&
            e.getAttribute(typeAttribute) == 'FunctionBlock',
      );
      for (var functionBlockElement in functionBlocksElements) {
        // print('    Program: ${functionBlockElement.getAttribute(nameAttribute)}');
        var functionBlock = createFunctionBlock(
          sysmacProject: sysmacProjectArchive,
          id: functionBlockElement.getAttribute(idAttribute)!,
          name: functionBlockElement.getAttribute(nameAttribute)!,
        );
        if (functionBlock != null) {
          //TODO pous.add(functionBlock);
        }
      }
    }
  }

  return pous;
}

Program createProgram(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement programElement,
) {
  var name = programElement.getAttribute(nameAttribute)!;
  var entities = programElement.descendantElements.where(
    (e) => e.name.local == 'Entity',
  );
  var variablesElement = entities.firstWhere(
    (e) =>
        e.getAttribute(typeAttribute) ==
        'Variables', //&& e.getAttribute(subTypeAttribute) == 'Ladder',
  );
  var pouBodyElements = entities.where(
    (e) =>
        e.getAttribute(typeAttribute) ==
        'PouBody', // && e.getAttribute(subTypeAttribute) == 'Ladder',
  );

  var programBodies = pouBodyElements
      .map((e) => createProgramBody(sysmacProjectArchive, e))
      .toList();

  var program = Program(name, programBodies);
  return program;
}

StructuredTextBody createStructuredTextProgram({
  required SysmacProjectArchive sysmacProject,
  required String id,
  required String name,
}) {
  var archiveFile = sysmacProject.projectIndexXml.findArchiveFile(id);
  if (archiveFile == null) {
    throw ArgumentError(
      'StructuredTextProgram archive file: $id.xml not found',
    );
  }
  var content = _convertContentToUtf8(archiveFile);
  var structuredText = content; //TODO
  return StructuredTextBody(name: name, structuredText: structuredText);
}

FunctionBlockBody? createFunctionBlock({
  required SysmacProjectArchive sysmacProject,
  required String id,
  required String name,
}) {
  var archiveFile = sysmacProject.projectIndexXml.findArchiveFile(id);
  if (archiveFile == null) {
    //FIXME throw ArgumentError('Function block archive file: $id.xml not found');
    return null;
  }
  var content = _convertContentToUtf8(archiveFile);
  var structuredText = content; //TODO
  return FunctionBlockBody(name: name, structuredText: structuredText);
}

FunctionBody? createFunctionBody({
  required SysmacProjectArchive sysmacProject,
  required String id,
  required String name,
}) {
  var archiveFile = sysmacProject.projectIndexXml.findArchiveFile(id);
  if (archiveFile == null) {
    //FIXME throw ArgumentError('Function archive file: $id.xml not found');
    return null;
  }
  var content = _convertContentToUtf8(archiveFile);
  var structuredText = content; //TODO
  return FunctionBody(name: name, structuredText: structuredText);
}

LadderBody createLadderBody({
  required SysmacProjectArchive sysmacProjectArchive,
  required String name,
  required String id,
}) {
  var archiveFile = sysmacProjectArchive.projectIndexXml.findArchiveFile(id);
  if (archiveFile == null) {
    throw ArgumentError('Ladder program archive file: $id.xml not found');
  }
  var content = _convertContentToUtf8(archiveFile);
  var jsons = content.split('\n');
  var rungs = <Rung>[];
  for (var json in jsons) {
    if (json.trim().isEmpty) {
      continue;
    }
    var map = parseJsonToMap(json);
    var rung = createRungFromJsonMap(map);
    rungs.add(rung);
  }
  return LadderBody(name, rungs);
}

Rung createRungFromJsonMap(Map<String, dynamic> map) {
  var comment = map['CMT'] as String?;
  var objects = map['CLs'] as List<dynamic>;
  var ladderObjects = <LadderObject>[];
  for (var object in objects) {
    var objectMap = object as Map<String, dynamic>;
    var type = objectMap['__type'] as String;
    switch (type) {
      case 'LD':
        ladderObjects.add(Contact(objectMap));
        break;
      case 'ST':
        ladderObjects.add(Coil(objectMap));
        break;
      default:
        // Unknown type, skip or handle accordingly
        break;
    }
  }
  return Rung(ladderObjects, comment);
}

Map<String, dynamic> parseJsonToMap(String jsonString) =>
    jsonDecode(jsonString) as Map<String, dynamic>;

String _convertContentToUtf8(ArchiveFile archiveFile) {
  var content = archiveFile.content;
  return utf8.decode(content);
}

/// FIXME: remove
void printFile(SysmacProjectArchive sysmacProject, String? id) {
  if (id == null) {
    return;
  }
  var archiveFile = sysmacProject.projectIndexXml.findArchiveFile(id);
  if (archiveFile == null) {
    return;
  }
  print(_convertContentToUtf8(archiveFile));
}

List<XmlElement> findIecPousGroups(ProjectIndexXml projectIndex) => projectIndex
    .xmlDocument
    .descendants
    .where(
      (node) =>
          node is XmlElement &&
          node.name.local == entity &&
          node.getAttribute(typeAttribute) == 'Group' &&
          node.getAttribute('subtype') == 'IecPous',
    )
    .cast<XmlElement>()
    .toList();

ProgramBody createProgramBody(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement entityElement,
) {
  String name = entityElement.getAttribute(nameAttribute)!;
  String id = entityElement.getAttribute(idAttribute)!;
  String subType = entityElement.getAttribute(subTypeAttribute)!;
  switch (subType) {
    case 'Ladder':
      return createLadderBody(
        sysmacProjectArchive: sysmacProjectArchive,
        name: name,
        id: id,
      );

    default:
      throw Exception('Unsupported Entity sub-type: $subType');
  }
}
