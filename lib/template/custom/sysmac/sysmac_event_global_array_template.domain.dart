import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/meyncraft/about/meyncraft_about_tab.domain.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/generate/generator_report.domain.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:xml/xml.dart';

class SysmacEventGlobalArrayTemplate implements TemplateProject {
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
  final List<TemplateProjectParameter> parameters = [
    sysmacProjectFileParameter,
  ];
  @override
  final List<Generator> generators = [SysmacEventGlobalArrayGenerator()];
  @override
  final List<String> tags = ['sysmac', 'events', 'code', 'EventGlobalArray'];
}

class SysmacEventGlobalArrayGenerator implements Generator {
  @override
  String get source => '$runtimeType Dart class';

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
      '* Move the sections in the last program $_programName '
      'to the end of section "Global\\EventHandling"\n'
      '* Delete the last program $_programName\n';

  @override
  Future<GeneratorReport> generate(
    TemplateProject template,
    Map<String, dynamic> parameterValues,
    GeneratorReport report,
  ) async {
    var generatedFiles = <File>[];
    try {
      var generatedFile = await writeSysmacEventArrayXmlImportFile(
        parameterValues,
        report,
      );
      report.addGeneratedFileToMarkdown(generatedFile);
      generatedFiles.add(generatedFile);
    } on Exception catch (exception, stackTrace) {
      report.addFailureToMarkdown(template, this, exception, stackTrace);
    }
    report.addGenerationSummary(template, this, generatedFiles);
    return report;
  }

  Future<File> writeSysmacEventArrayXmlImportFile(
    Map<String, dynamic> parameterValues,
    DynamicMarkdownTabContent outputReport,
  ) async {
    var sysmacProject = await MeynSysmacProjectService().getProject(
      parameterValues,
    );

    var version = await applicationVersion();
    var pouInfo = SmcExtPouInfo(
      author: 'MeynCraft code generator',
      version: version,
    );

    var events = sysmacProject.events;
    outputReport.addToMarkdown('* Found ${events.length} Sysmac events\n');
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
    var outputFilePath = await createOutputPath(outputPath, parameterValues);
    var outputFile = File(outputFilePath);

    await outputFile.create();
    await outputFile.writeAsString(xmlString);

    return outputFile;
  }
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
