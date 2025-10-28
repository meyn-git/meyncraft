import 'dart:io';

import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:xml/xml.dart';

Future<void> writeSysmacEventArrayXmlImportFile(
  SysmacProject sysmacProject,
) async {
  var pouInfo = SmcExtPouInfo(
    author: 'MeynCraft code generator',
    //TODO would be nice if we would use the MeynCraft version by reading the pubspec.yaml file
    version: '1.0.0',
  );
  List<LadderSection> sections = _createSections(sysmacProject);
  var eventGlobalVariable = _createEventGlobalVariable();
  var eventGlobalArrayVariable = _createEventGlobalArrayVariable(sysmacProject);
  var mainBody = MainBody.ladderSection(sections);
  var program = Program(
    programName: _programName,
    pouInfo: pouInfo,
    globalVariables: [eventGlobalVariable, eventGlobalArrayVariable],
    mainBody: mainBody,
  );
  var project = Project([program], [eventGlobalArrayVariable]);
  var xmlString = project.toXmlString(
    pretty: true,
    indent: '  ',
    preserveWhitespace: (node) =>
        node is XmlElement && ['ST', 'Content'].contains(node.name.local),
  );

  var outputFile = createOutputFile(sysmacProject, '-SysmacEventArray.xml');
  await outputFile.create();
  await outputFile.writeAsString(xmlString);

  logger.info('Created: ${outputFile.path}');
  logger.info(
    '     Import this file in Sysmac with Menu \\ Tools \\ IEC 61131-10 XML \\ Import',
  );
  logger.info(
    '     Then move the sections in program "$_programName" to the end of section "Global\\EventHandling"',
  );
}

GlobalVariable _createEventGlobalArrayVariable(
  SysmacProject sysmacProject,
) => GlobalVariable(
  Variable2(
    variableName: eventGlobalArrayName,
    variableType:
        'ARRAY[0..${sysmacProject.eventService.events.length}] OF BOOL',
    comment:
        'This array is a copy from EventGlobal and is needed for efficient communication with XOR-HMIs or MeynConnect',
    networkPublish: NetworkPublish.publicationOnly,
  ),
);

///only needed as reference
GlobalVariable _createEventGlobalVariable() => GlobalVariable(
  Variable2(variableName: eventGlobalName, variableType: 'sEvent'),
);

const eventGlobalName = 'EventGlobal';
const eventGlobalArrayName = 'EventGlobalArray';

String _programName = 'GeneratedByMeynCraft';

List<LadderSection> _createSections(SysmacProject sysmacProject) {
  var rungs = <Rung>[];
  var events = sysmacProject.eventService.events;
  var code = StringBuffer();
  var rungNr = 0;
  for (var event in events) {
    code.writeln('$eventGlobalArrayName[${event.number}]:=${event.namePath};');
    if (event.number % 1000 == 0 || event == events.last) {
      rungNr++;
      rungs.add(
        Rung.structuredText(
          comment: _createComment(rungNr),
          evaluationOrder: rungNr,
          structuredText: code.toString().replaceFirst(RegExp(r'\n$'), ''),
        ),
      );
      code = StringBuffer();
    }
  }

  return [
    LadderSection(name: 'EventGlobalToArray', evaluationOrder: 1, rungs: rungs),
  ];
}

String _createComment(int rungNr) {
  if (rungNr == 1) {
    var comment = StringBuffer();
    comment.writeln(
      'The EventGlobal variable is copied to the EventGlobalArray variable.',
    );
    comment.writeln(
      'This is needed for more efficient event communication with HMIs and MeynConnect.\n',
    );
    comment.writeln(
      'This code was generated with MeynCraft on ${createNowInSysmacXmlFormat()}.',
    );
    comment.write(
      'For more information see: https://github.com/meyn-git/meyncraft (scroll down for documentation)',
    );
    return comment.toString();
  }
  return 'EventGlobalArray[${(rungNr - 1) * 1000 + 1}-${(rungNr - 1) * 1000 + 999}]';
}

File createOutputFile(SysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.details.projectFile;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}
