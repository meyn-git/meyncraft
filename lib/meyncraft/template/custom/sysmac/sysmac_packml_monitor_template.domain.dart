import 'dart:io';

import 'package:meyncraft/meyncraft/presentation/markdown_tab.presentation.dart';
import 'package:meyncraft/meyncraft/template/custom/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/isa88/isa88.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';

class SysmacPackMlMonitorTemplate implements Template {
  @override
  final String name = 'SysmacPackMlMonitor';

  @override
  final String? documentation = null;

  @override
  final String? gitRepository = null;

  @override
  final String description =
      'Creates Sysmac monitor code to debug PackMLfrom a Sysmac project file.';

  @override
  final List<Parameter> parameters = [sysmacProjectFileParameter];

  @override
  final List<Generator> generators = [SysmacPackMlMonitorGenerator()];

  @override
  final List<String> tags = ['sysmac', 'packml', 'code'];
}

class SysmacPackMlMonitorGenerator implements Generator {
  @override
  String get source => 'Dart code: $runtimeType';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-Sysmac-{{unit.name}}-PackMlMonitor.txt';

  @override
  final String? outputInstructions =
      'You can import the generated file in Sysmac:\n'
      '* In the Sysmac Menu select: Tools \\ IEC 61131-10 XML \\ Import\n'
      '* Select the generated file by clicking the folder button\n'
      '* Click on the "Execute" button\n'
      '* Merge changes if prompted\n'
      '* Then move the sections in the last programs to the begin of the '
      '"UnitControl" section of the corresponding unit';

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
      var units = sysmacProject.isa88Nodes.whereType<Unit>();
      var generatedFiles = <File>[];
      for (var unit in units) {
        var file = await createPackMlMonitorFile(sysmacProject, unit);
        generatedFiles.add(file);
      }
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
}

Future<List<File>> writeSysmacPackMlMonitorFiles(
  MeynSysmacProject sysmacProject,
) async {
  var units = sysmacProject.isa88Nodes.whereType<Unit>();
  var generatedFiles = <File>[];
  for (var unit in units) {
    var file = await createPackMlMonitorFile(sysmacProject, unit);
    generatedFiles.add(file);
  }
  //TODO create an XML import file instead of a text file that needs to be copied pasted.
  //TODO also include state complete commands see scPackMlStates
  return generatedFiles;
}

Future<File> createPackMlMonitorFile(
  MeynSysmacProject sysmacProject,
  Unit unit,
) async {
  var structuredText = StringBuffer();

  var unitInterfaceExpression = unit.callPath.call.parametersIn
      .firstWhere((parameter) => parameter.argument == 'ioUnitPackML')
      .variable!;
  structuredText.writeln(
    "dummy:=$unitInterfaceExpression.StateTransSum.Cmd_Abort;",
  );

  for (var equipment in unit.equipmentModules) {
    var call = equipment.fbUnitInterfaceCallPath?.call;
    if (call == null) continue;

    var interfaceExpression = call.parametersIn
        .firstWhere((parameter) => parameter.argument == 'ioEquipmentPackML')
        .variable!;

    structuredText.writeln("dummy:=$interfaceExpression.StateTrans.Cmd_Abort;");
  }

  var outputFile = createOutputFile(
    sysmacProject,
    'Sysmac-${unit.name}-PackMlMonitor.txt',
  );
  await outputFile.create();
  await outputFile.writeAsString(structuredText.toString());
  return outputFile;
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
