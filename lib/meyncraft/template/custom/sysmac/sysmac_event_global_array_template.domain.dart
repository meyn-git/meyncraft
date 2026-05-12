import 'dart:io';

import 'package:meyncraft/meyncraft/presentation/markdown_tab.presentation.dart';
import 'package:meyncraft/meyncraft/template/custom/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';
import 'package:xml/xml.dart';

class SysmacEventGlobalArrayTemplate implements Template {
  @override
  final String name = 'SysmacEventGlobalArray';
  @override
  final String description =
      'Creates EventGlobalArray mapping code from a Sysmac project file.';

  @override
  final String? documentation = null;

  @override
  final String? gitRepository = null;

  @override
  final List<Parameter> parameters = [sysmacProjectFileParameter];
  @override
  final List<Generator> generators = [SysmacEventGlobalArrayGenerator()];
  @override
  final List<String> tags = ['sysmac', 'events', 'code', 'EventGlobalArray'];
}

class SysmacEventGlobalArrayGenerator implements Generator {
  @override
  String get source => 'Dart code: $runtimeType';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-Sysmac-EventGlobalArray.xml';

  @override
  final String? outputInstructions =
      'You can import the generated file in Sysmac:\n'
      '* In the Sysmac Menu select: Tools \\ IEC 61131-10 XML \\ Import\n'
      '* Select the generated file by clicking the folder button\n'
      '* Click on the "Execute" button\n'
      '* Merge changes if prompted\n'
      '* Then move the sections in the last program "GeneratedByMeynCraft" '
      '  to the end of section "Global\\EventHandling"';

  @override
  Future<DynamicMarkdownTabContent> generate(
    Template template,
    Map<String, dynamic> parameterValues,
    DynamicMarkdownTabContent outputReport,
  ) async {
    var sysmacProjectFilePath =
        parameterValues[sysmacProjectFileParameter.name];
    if (sysmacProjectFilePath == null) {
      throw Exception('Missing parameter: ${sysmacProjectFileParameter.name}');
    }
    var sysmacProject = await MeynSysmacProject.loadFromFile(
      File(sysmacProjectFilePath),
    );
    var generatedFiles = <File>[];
    try {
      generatedFiles = await writeSysmacEventArrayXmlImportFile(
        sysmacProject,
        outputReport,
      );
    } on Exception catch (e, stackTrace) {
      var errorLink = GenerationErrorLink(
        template: template,
        generator: this,
        message: 'Error generating JMobile tags file',
        stackTrace: stackTrace,
      );
      outputReport.append('* ${errorLink.toMarkdown()}');
    }
    if (generatedFiles.isEmpty) {
      outputReport.append('* No files generated');
    }
    outputReport.append(
      '* Generated ${generatedFiles.length} files. [Click here for instructions on how to use the generated files.](meyncraft://test)',
    );
    return outputReport;
  }

  Future<List<File>> writeSysmacEventArrayXmlImportFile(
    MeynSysmacProject sysmacProject,
    DynamicMarkdownTabContent outputReport,
  ) async {
    var pouInfo = SmcExtPouInfo(
      author: 'MeynCraft code generator',
      //TODO would be nice if we would use the MeynCraft version by reading the pubspec.yaml file
      version: '1.0.0',
    );

    var events = sysmacProject.events;
    outputReport.append('* Found ${events.length} Sysmac events\n');
    List<LadderSection> sections = _createSections(events);
    var eventGlobalVariable = _createEventGlobalVariable();
    var eventGlobalArrayVariable = _createEventGlobalArrayVariable(
      sysmacProject,
    );
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
    outputReport.append(
      '* Created file: [${outputFile.path}](${outputFile.uri})\n',
    );
    return [outputFile];
  }
}

Future<void> writeSysmacEventArrayXmlImportFile(
  MeynSysmacProject sysmacProject,
) async {
  var pouInfo = SmcExtPouInfo(
    author: 'MeynCraft code generator',
    //TODO would be nice if we would use the MeynCraft version by reading the pubspec.yaml file
    version: '1.0.0',
  );
  var events = sysmacProject.events;
  List<LadderSection> sections = _createSections(events);
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
  MeynSysmacProject sysmacProject,
) => GlobalVariable(
  Variable2(
    variableName: eventGlobalArrayName,
    variableType: 'ARRAY[0..${sysmacProject.events.length}] OF BOOL',
    comment:
        'This array is a copy from EventGlobal and is needed for efficient communication with Exor-HMIs or MeynConnect',
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

List<LadderSection> _createSections(List<Event> events) {
  var rungs = <Rung>[];
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

File createOutputFile(MeynSysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.identity.projectFile;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}
