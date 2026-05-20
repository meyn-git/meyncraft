import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/meyncraft/about/meyncraft_about_tab.domain.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyn_sysmac/isa88/isa88.domain.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:meyncraft/template/template_instruction_tab.presentation.dart';
import 'package:xml/xml.dart';

class SysmacPackMlMonitorTemplate implements TemplateProject {
  @override
  final String name = 'SysmacPackMlMonitor';

  @override
  final String? documentation = null;

  @override
  final String? gitRepository = null;

  @override
  final String description =
      'Creates Pack-ML monitor code (e.g. to debug Pack-ML issues) from a Sysmac project file.';

  @override
  final List<TemplateProjectParameter> parameters = [
    sysmacProjectFileParameter,
  ];

  @override
  final List<Generator> generators = [SysmacPackMlMonitorGenerator()];

  @override
  final List<String> tags = ['sysmac', 'packml', 'code'];
}

class SysmacPackMlMonitorGenerator implements Generator {
  @override
  String get source => '$runtimeType Dart class';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-Sysmac-PackMlMonitor.xml';

  @override
  final String? outputInstructions =
      'You can import the generated file in Sysmac:\n'
      '* In the Sysmac Menu select: Tools \\ IEC 61131-10 XML \\ Import\n'
      '* Select the generated file by clicking the folder button\n'
      '* Click on the "Execute" button\n'
      '* Merge changes if prompted\n'
      '* Move the sections in the $_programName program to the begin of the '
      '"UnitControl" section of the corresponding unit\n'
      '* Delete the last program $_programName\n'
      '* Now delete function block fbCheckPackML_SC and its implementations '
      'since the generated code is a more detailed and efficient replacement.\n';

  static const _programName = 'GeneratedByMeynCraft';

  @override
  Future<DynamicMarkdownTabContent> generate(
    TemplateProject template,
    Map<String, dynamic> parameterValues,
    DynamicMarkdownTabContent outputReport,
  ) async {
    var sysmacProject = await MeynSysmacProjectService().getProject(
      parameterValues,
    );
    try {
      var units = sysmacProject.isa88Nodes.whereType<Unit>();
      var version = await applicationVersion();
      var pouInfo = SmcExtPouInfo(
        author: 'MeynCraft code generator',
        version: version,
      );
      var sections = _createSections(units);
      var mainBody = MainBody.ladderSection(sections);
      List<GlobalVariable> globalVariables = [
        GlobalVariable(
          Variable2(
            variableName: 'InterfaceGlobal',
            variableType: 'sInterface',
            comment: 'Interfaces',
          ),
        ),
      ];
      List<Variable2> internalVariables = [
        Variable2(
          variableName: 'Mode',
          variableType: 'ePackMLMode',
          comment: 'To monitor the current Pack-ML mode',
        ),
        Variable2(
          variableName: 'State',
          variableType: 'ePackMLState',
          comment: 'To monitor the current Pack-ML state',
        ),
        Variable2(
          variableName: 'Cmd1',
          variableType: r'OmronLib\PackML30\sPACKML_TRANSITION_COMMAND',
          comment: 'To monitor the current Pack-ML state transfer command',
        ),
        Variable2(
          variableName: 'Cmd2',
          variableType: r'OmronLib\PackML30\sPACKML_TRANSITION_COMMAND',
          comment: 'To monitor the current Pack-ML state transfer command',
        ),
      ];
      var program = Program(
        pouInfo: pouInfo,
        globalVariables: globalVariables,
        internalVariables: internalVariables,
        programName: _programName,
        mainBody: mainBody,
      );
      var project = Project([program], []);
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

      outputReport.addToMarkdown(
        '* Generated file: [${outputFile.path}](${outputFile.uri})\n',
      );

      var linkUri = outputReport.addTabLink(
        TemplateInstructionTab(template, this, [outputFile]),
      );
      outputReport.addToMarkdown(
        '* Generated 1 file. '
        '[Click here for instructions on how to use the generated file.]($linkUri)',
      );
    } on Exception catch (exception, stackTrace) {
      var linkUri = outputReport.addTabLink(
        GeneratorErrorTab(template, this, exception, stackTrace),
      );
      outputReport.addToMarkdown(
        '* **Failed** [Click here for more information]($linkUri)',
      );
      outputReport.addToMarkdown('* No files generated');
    }

    return outputReport;
  }

  List<LadderSection> _createSections(Iterable<Unit> units) =>
      units.map((unit) => _createUnitSection(unit)).toList();

  LadderSection _createUnitSection(Unit unit) => LadderSection(
    name: '${unit.name}PackMlMonitor',
    evaluationOrder: 1,
    rungs: _createUnitRungs(unit),
  );

  List<Rung> _createUnitRungs(Unit unit) => [
    createCommentRung(),
    createOverviewRung(unit),
    ...PackMlTransitionCommand.values.map(
      (tc) => createTransferCommandRung(
        unit,
        tc,
        tc.plcName.endsWith('SC') ? 'AND' : 'OR',
      ),
    ),
  ];

  Rung createCommentRung() => Rung.comment(
    0,
    'This rung can help you to debug Pack-ML state transfers.\n'
    'This code was generated with MeynCraft on ${createNowInSysmacXmlFormat()}.\n'
    'For more information see: https://github.com/meyn-git/meyncraft (scroll down for documentation).\n',
  );

  Rung createOverviewRung(Unit unit) => Rung.structuredText(
    evaluationOrder: 1,
    comment: 'Pack-ML transfer command overview',
    structuredText: [
      'Mode:=InterfaceGlobal.${unit.name}.PackML.Mode;',
      'State:=InterfaceGlobal.${unit.name}.PackML.State;',
      ...PackMlTransitionCommand.values.map(
        (tc) =>
            'Cmd1.${tc.plcName}:=InterfaceGlobal.${unit.name}.PackML.StateTrans.${tc.plcName};',
      ),
    ].join('\n'),
  );

  Rung createTransferCommandRung(
    Unit unit,
    PackMlTransitionCommand tc,
    String andOr,
  ) => Rung.structuredText(
    evaluationOrder: 1,
    comment: '${tc.plcName}: ${tc.description}',
    structuredText: [
      'Cmd2.${tc.plcName}:=',
      '// From unit itself',
      'InterfaceGlobal.${unit.name}.PackML.StateTrans.${tc.plcName}${unit.equipmentModules.isEmpty ? '' : ' $andOr'}',
      '// From its equipment',
      '${unit.equipmentModules.map((em) => '${em.variableFromParent}.PackML.StateTrans.${tc.plcName}').join(' $andOr\n')};',
    ].join('\n'),
  );
}

// TODO
// // Cmd_Abort to go from any state to the Abort state
// Monitor.Cmd_Abort:=
// // From unit itself
// InterfaceGlobal.MaestroPlus.PackML OR
// // From its equipment:
// InterfaceGlobal.GibLnSync.PackML.StateTrans.Cmd_Abort OR

// Future<List<File>> writeSysmacPackMlMonitorFiles(
//   MeynSysmacProject sysmacProject,
// ) async {
//   var units = sysmacProject.isa88Nodes.whereType<Unit>();
//   var generatedFiles = <File>[];
//   for (var unit in units) {
//     var file = await createPackMlMonitorFile(sysmacProject, unit);
//     generatedFiles.add(file);
//   }
//   //TODO create an XML import file instead of a text file that needs to be copied pasted.
//   //TODO also include state complete commands see scPackMlStates
//   return generatedFiles;
// }

// Future<File> createPackMlMonitorFile(
//   MeynSysmacProject sysmacProject,
//   Unit unit,
// ) async {
//   var structuredText = StringBuffer();

//   var unitInterfaceExpression = unit.callPath.call.parametersIn
//       .firstWhere((parameter) => parameter.argument == 'ioUnitPackML')
//       .variable!;
//   structuredText.writeln(
//     "dummy:=$unitInterfaceExpression.StateTransSum.Cmd_Abort;",
//   );

//   for (var equipment in unit.equipmentModules) {
//     var call = equipment.fbUnitInterfaceCallPath?.call;
//     if (call == null) continue;

//     var interfaceExpression = call.parametersIn
//         .firstWhere((parameter) => parameter.argument == 'ioEquipmentPackML')
//         .variable!;

//     structuredText.writeln("dummy:=$interfaceExpression.StateTrans.Cmd_Abort;");
//   }

//   var outputFile = createOutputFile(
//     sysmacProject,
//     'Sysmac-${unit.name}-PackMlMonitor.txt',
//   );
//   await outputFile.create();
//   await outputFile.writeAsString(structuredText.toString());
//   return outputFile;
// }

/// PackML state transitions with PLC name and description
enum PackMlTransitionCommand {
  cmdAbort('Cmd_Abort', 'A command from any state to go to Aborting state'),
  stsAbortingSC(
    'Sts_Aborting_SC',
    'A command to move from the Aborting to Aborted state.',
  ),

  cmdClear(
    'Cmd_Clear',
    'A command to clear faults and move from Aborted to Stopped state.',
  ),
  stsClearingSC(
    'Sts_Clearing_SC',
    'A command to move from the Clearing to Stopped state.',
  ),

  //TODO rest

  cmdStart(
    'Cmd_Start',
    'A command to start the unit from Stopped to Starting.',
  ),
  stsStartingSC(
    'Sts_Starting_SC',
    'Indicates the unit is transitioning to the Starting state.',
  ),

  cmdStop(
    'Cmd_Stop',
    'A command to stop the unit from any active state to Stopping.',
  ),
  stsStoppingSC(
    'Sts_Stopping_SC',
    'Indicates the unit is transitioning to the Stopping state.',
  ),

  cmdHold('Cmd_Hold', 'A command to pause production from Execute to Holding.'),
  stsHoldingSC(
    'Sts_Holding_SC',
    'Indicates the unit is transitioning to the Holding state.',
  ),

  cmdUnhold(
    'Cmd_Unhold',
    'A command to resume production from Held to Unholding.',
  ),
  stsUnholdingSC(
    'Sts_Unholding_SC',
    'Indicates the unit is transitioning to the Unholding state.',
  ),

  cmdSuspend(
    'Cmd_Suspend',
    'A command to suspend production due to external conditions.',
  ),
  stsSuspendingSC(
    'Sts_Suspending_SC',
    'Indicates the unit is transitioning to the Suspending state.',
  ),

  cmdUnsuspend(
    'Cmd_Unsuspend',
    'A command to resume from Suspended to Unsuspending.',
  ),
  stsUnsuspendingSC(
    'Sts_Unsuspending_SC',
    'Indicates the unit is transitioning to the Unsuspending state.',
  ),

  cmdReset(
    'Cmd_Reset',
    'A command to reset the unit after stop or completion.',
  ),
  stsResettingSC(
    'Sts_Resetting_SC',
    'Indicates the unit is transitioning to the Resetting state.',
  ),

  stsExecuteCS(
    'Sts_Execute_SC',
    'Command to go from Execute to Completing state.',
  ),

  stsCompletingSC(
    'Sts_Completing_SC',
    'Command to go from Completing to Resetting state.',
  );

  final String plcName;
  final String description;

  const PackMlTransitionCommand(this.plcName, this.description);
}
