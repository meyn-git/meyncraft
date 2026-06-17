import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/meyncraft/about/meyncraft_about_tab.domain.dart';
import 'package:meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyn_sysmac/isa88/isa88.domain.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/generate/generator_report.domain.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:xml/xml.dart';

class SysmacPackMlUnitInterfaceTemplate implements TemplateProject {
  @override
  final String name = 'SysmacPackMlUnitInterface';

  @override
  final String? documentation = null;

  @override
  final String? gitRepository = null;

  @override
  final String description =
      'Creates Pack-ML unit interface from a Sysmac project file.';

  @override
  final List<TemplateProjectParameter> parameters = [
    sysmacProjectFileParameter,
  ];

  @override
  final List<Generator> generators = [SysmacPackMlUnitInterfaceGenerator()];

  @override
  final List<String> tags = ['sysmac', 'packml', 'code'];
}

class SysmacPackMlUnitInterfaceGenerator implements Generator {
  @override
  String get source => '$runtimeType Dart class';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-Sysmac-{{unit}}-PackMlUnitInterface.xml';

  @override
  final String? outputInstructions =
      'You can import the generated file in Sysmac:\n'
      '* In the Sysmac Menu select: Tools \\ IEC 61131-10 XML \\ Import\n'
      '* Select the generated file by clicking the folder button\n'
      '* Click on the "Execute" button\n'
      '* Merge changes if prompted\n'
      '* Replace the existing UnitInterface program section '
      "(with fbUnitInterface's) with the sections in the $_programName program"
      '"of the corresponding unit\n'
      '* Delete the last program $_programName\n'
      '* Now delete function block fbUnitInterface and its implementations '
      'since the generated code is a more detailed and efficient replacement.\n';

  static const _programName = 'GeneratedByMeynCraft';

  @override
  Future<GeneratorReport> generate(
    TemplateProject template,
    Map<String, dynamic> parameterValues,
    GeneratorReport report,
  ) async {
    var sysmacProject = await MeynSysmacProjectService().getProject(
      parameterValues,
    );
    var generatedFiles = <File>[];
    try {
      var units = sysmacProject.isa88Nodes.whereType<Unit>();
      var version = await applicationVersion();
      var pouInfo = SmcExtPouInfo(
        author: 'MeynCraft code generator',
        version: version,
      );

      for (var unit in units) {
        var sections = _createSections(unit);
        var mainBody = MainBody.ladderProgram(sections);
        List<GlobalVariable> globalVariables = [
          GlobalVariable(
            Variable2(
              variableName: 'InterfaceGlobal',
              variableType: 'sInterface',
              comment: 'Interfaces',
            ),
          ),
        ];

        var program = Program(
          pouInfo: pouInfo,
          globalVariables: globalVariables,
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

        var outputFilePath = await createOutputPath(outputPath, {
          ...parameterValues,
          'unit': unit.name,
        });
        var outputFile = File(outputFilePath);
        await outputFile.create();
        await outputFile.writeAsString(xmlString);
        report.addGeneratedFileToMarkdown(outputFile);
        generatedFiles.add(outputFile);
      }
    } on Exception catch (exception, stackTrace) {
      report.addFailureToMarkdown(template, this, exception, stackTrace);
    }
    report.addGenerationSummary(template, this, generatedFiles);
    return report;
  }

  // List<LadderSection> _createSections(Iterable<Unit> units) =>
  //     units.map((unit) => _createUnitSection(unit)).toList();

  List<LadderSection> _createSections(Unit unit) => [
    _createPackMlCmdUnSection(unit),
    _createPackMlCmdUnAndEqSection(unit),
    _createPackMlModeAndStateSection(unit),
  ];

  LadderSection _createPackMlCmdUnSection(Unit unit) {
    final document = XmlDocument.parse(_createPackMlCmdUnXml(unit));
    var section = document.rootElement;
    var rungElements = section.childElements;
    return LadderSection.fromRungElements(
      name: 'PackMlCmdUn',
      evaluationOrder: 1,
      rungElements: rungElements.toList(),
    );
  }

  LadderSection _createPackMlCmdUnAndEqSection(Unit unit) => LadderSection(
    name: 'PackMlCmdUnAndEq',
    evaluationOrder: 2,
    rungs: _createPackMlEquipmentInterfaceRungs(unit),
  );

  LadderSection _createPackMlModeAndStateSection(Unit unit) {
    final document = XmlDocument.parse(_createPackMlModeAndStateXml(unit));
    var section = document.rootElement;
    var rungElements = section.childElements;
    return LadderSection.fromRungElements(
      name: 'PackMlModeAndState',
      evaluationOrder: 3,
      rungElements: rungElements.toList(),
    );
  }

  List<Rung> _createPackMlEquipmentInterfaceRungs(Unit unit) {
    var index = 1;
    return [
      createGeneratedByMeynCraftCommentHeaderRung(index++, unit),
      createMergeCommentHeaderRung(index++, unit),
      ...PackMlTransitionCommand.values.map(
        (tc) => createTransferCommandRung(
          index++,
          unit,
          tc,
          tc.sysmacName.endsWith('SC') ? 'AND' : 'OR',
        ),
      ),
      ...unit.equipmentModules.expand(
        (equipment) => [
          createEquipmentModuleCommentHeaderRung(index++, equipment),
          createTransferStateAndModeRung(index++, unit, equipment),
          createEquipmentCmdInitRung(index++, unit, equipment),
        ],
      ),
    ];
  }

  Rung createGeneratedByMeynCraftCommentHeaderRung(
    int index,
    Unit unit,
  ) => Rung.comment(
    index,

    '# This code was generated with MeynCraft on ${createNowInSysmacXmlFormat()}.\n'
    'For more information see: https://github.com/meyn-git/meyncraft (scroll down for documentation).\n',
  );

  Rung createMergeCommentHeaderRung(int index, Unit unit) => Rung.comment(
    index,
    '# Merge the unit Pack-ML commands and the equipment module Pack-ML commands into InterfaceGlobal.${unit.name}.PackML.StateTransSum',
  );

  Rung createTransferCommandRung(
    int index,
    Unit unit,
    PackMlTransitionCommand tc,
    String andOr,
  ) => Rung.structuredText(
    evaluationOrder: index,
    comment: '${tc.sysmacName}: ${tc.description}',
    structuredText: [
      'InterfaceGlobal.${unit.name}.PackML.StateTransSum.${tc.sysmacName}:=',
      '// From unit itself',
      'InterfaceGlobal.${unit.name}.PackML.StateTrans.${tc.sysmacName}${unit.equipmentModules.isEmpty ? '' : ' $andOr'}',
      '// From its equipment',
      '${unit.equipmentModules.map((em) => '${em.variableFromParent}.PackML.StateTrans.${tc.sysmacName}').join(' $andOr\n')};',
    ].join('\n'),
  );

  Rung createEquipmentModuleCommentHeaderRung(
    int index,
    EquipmentModule equipment,
  ) => Rung.comment(index, '# ${equipment.name}');

  Rung createTransferStateAndModeRung(
    int index,
    Unit unit,
    EquipmentModule equipment,
  ) => Rung.structuredText(
    evaluationOrder: index,
    comment:
        'Transfer Pack-ML mode and state from ${unit.name} unit to ${equipment.name} equipment module',
    structuredText: [
      'InterfaceGlobal.${equipment.name}.Unit.Cmd.WarningDone:=InterfaceGlobal.${unit.name}.Sts.StartWarningDone;',
      'InterfaceGlobal.${equipment.name}.Unit.Cmd.WarningDoneExecute:=InterfaceGlobal.${unit.name}.Sts.StartWarningDoneExecute;',
      'InterfaceGlobal.${equipment.name}.PackML.Mode:=InterfaceGlobal.${unit.name}.PackML.Mode;',
      'InterfaceGlobal.${equipment.name}.PackML.ModeBit:=InterfaceGlobal.${unit.name}.PackML.ModeBit;',
      'InterfaceGlobal.${equipment.name}.PackML.State:=InterfaceGlobal.${unit.name}.PackML.State;',
      'InterfaceGlobal.${equipment.name}.PackML.StateBit:=InterfaceGlobal.${unit.name}.PackML.StateBit;',
    ].join('\n'),
  );

  Rung createEquipmentCmdInitRung(
    int index,
    Unit unit,
    EquipmentModule equipment,
  ) => Rung.structuredText(
    evaluationOrder: index,
    comment:
        'Init ${equipment.name} equipment module StateTrans structure on '
        'first plc cycle in case the task with the the '
        'equipment module function block is disabled',
    structuredText: [
      'IF P_First_Run THEN',
      ...PackMlTransitionCommand.values.map(
        (tc) =>
            '  InterfaceGlobal.${equipment.name}.'
            'PackML.StateTrans.${tc.sysmacName}'
            '${tc.sysmacName.endsWith('SC') ? ':=TRUE;' : ':=FALSE;'}',
      ),
      'END_IF;',
    ].join('\n'),
  );

  String _createPackMlCmdUnXml(Unit unit) =>
      '''
       <BodyContent xsi:type="smcext:LdSection" name="PackMlCmdUn" evaluationOrder="2">
            <Rung evaluationOrder="1">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Abort: A command from any state to go to Aborting state</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
                <ConnectionPointOut connectionPointOutId="2" />
                <ConnectionPointOut connectionPointOutId="3" />
                <ConnectionPointOut connectionPointOutId="4" />
              </LdObject>
              <LdObject xsi:type="Contact" negated="true" operand="SafetyOkAndReset">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="5" />
              </LdObject>
              <LdObject xsi:type="Contact" negated="true" operand="HardwareOk">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="6" />
              </LdObject>
              <LdObject xsi:type="Contact" edge="rising" operand="iModeCleanSw">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="7" />
              </LdObject>
              <LdObject xsi:type="Contact" edge="falling" operand="iModeCleanSw">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="4" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="8" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_Abort">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="5" />
                  <Connection refConnectionPointOutId="6" />
                  <Connection refConnectionPointOutId="7" />
                  <Connection refConnectionPointOutId="8" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="9" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="9" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="2">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Aborting_SC: A command to move from the Aborting to Aborted state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Aborting_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="3">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Clear: A command to clear faults and move from Aborted to Stopped state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Contact" negated="true" operand="StateTransfUn.Cmd_Abort">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_Clear">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="4">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Clearing_SC: A command to move from the Clearing to Stopped state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Clearing_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="5">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Start: A command to start the unit from Stopped to Starting.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
                <ConnectionPointOut connectionPointOutId="2" />
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Production">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="4" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Cleaning">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="5" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="StartStopButtons_StartReq">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="4" />
                  <Connection refConnectionPointOutId="5" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="6" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Manual">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="7" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="HmiGlobal.${unit.name}.PackML.Cmd.Start">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="7" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="8" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_Start">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="6" />
                  <Connection refConnectionPointOutId="8" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="9" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="9" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="6">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Starting_SC: Indicates the unit is transitioning to the Starting state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Starting_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="7">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Stop: A command to stop the unit from any active state to Stopping.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
                <ConnectionPointOut connectionPointOutId="2" />
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Production">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="4" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Cleaning">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="5" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="StartStopButtons_StopReq">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="4" />
                  <Connection refConnectionPointOutId="5" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="6" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Manual">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="7" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="HmiGlobal.${unit.name}.PackML.Cmd.Stop">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="7" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="8" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_Stop">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="6" />
                  <Connection refConnectionPointOutId="8" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="9" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="9" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="8">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Stopping_SC: Indicates the unit is transitioning to the Stopping state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Stopping_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="9">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Hold: A command to pause production from Execute to Holding.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="P_Off">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_Hold">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="10">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Holding_SC: Indicates the unit is transitioning to the Holding state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Holding_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="11">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Unhold: A command to resume production from Held to Unholding.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_UnHold">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="12">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Unholding_SC: Indicates the unit is transitioning to the Unholding state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_UnHolding_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="13">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Suspend: A command to suspend production due to external conditions.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="P_Off">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_Suspend">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="14">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Suspending_SC: Indicates the unit is transitioning to the Suspending state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Suspending_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="15">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Unsuspend: A command to resume from Suspended to Unsuspending.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_UnSuspend">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="16">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Unsuspending_SC: Indicates the unit is transitioning to the Unsuspending state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_UnSuspending_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="17">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cmd_Reset: A command to reset the unit after stop or completion.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
                <ConnectionPointOut connectionPointOutId="2" />
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Production">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="4" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Cleaning">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="5" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="StartStopButtons_StartReq">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="4" />
                  <Connection refConnectionPointOutId="5" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="6" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="HmiGlobal.${unit.name}.PackML.Cmd.Start">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="4" />
                  <Connection refConnectionPointOutId="5" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="7" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Manual">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="8" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="HmiGlobal.${unit.name}.PackML.Cmd.Start">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="8" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="9" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Cmd_Reset">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="6" />
                  <Connection refConnectionPointOutId="7" />
                  <Connection refConnectionPointOutId="9" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="10" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="10" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="18">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Resetting_SC: Indicates the unit is transitioning to the Resetting state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Resetting_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="19">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Execute_SC: Command to go from Execute to Completing state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="P_Off">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Execute_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="20">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Sts_Completing_SC: Command to go from Completing to Resetting state.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="StateTransfUn.Sts_Completing_SC">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
          </BodyContent>
         
''';

  String _createPackMlModeAndStateXml(Unit unit) =>
      '''
   <BodyContent xsi:type="smcext:LdSection" name="PackMlModeAndState" evaluationOrder="4">
            <Rung evaluationOrder="1">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">PackML mode requests</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="2">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Production mode request</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Contact" negated="true" operand="iModeCleanSw">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="Contact" negated="true" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Production">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="Contact" negated="true" operand="InterfaceGlobal.${unit.name}.PackML.ModeBit.Manual">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="4" />
              </LdObject>
              <LdObject xsi:type="Contact" negated="true" operand="iModeSelHydrBleedOut">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="4" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="5" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="ProductionModeReq">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="5" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="6" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="6" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="3">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Manual mode request</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="ConfigGlobal.${unit.name}.HybridExtensionPanel">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="iExtEvisManualMode">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="ManualModeReq">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="4" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="4" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="4">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Cleaning mode request</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="Contact" operand="iModeCleanSw">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="2" />
              </LdObject>
              <LdObject xsi:type="Coil" operand="CleaningModeReq">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="2" />
                </ConnectionPointIn>
                <ConnectionPointOut connectionPointOutId="3" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="3" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="5">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">#PackML mode and state machine</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="1" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="6">
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <FbdObject xsi:type="DataSource" identifier="InterfaceGlobal.${unit.name}.PackML">
                <ConnectionPointOut connectionPointOutId="2" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="HmiGlobal.${unit.name}.PackML">
                <ConnectionPointOut connectionPointOutId="3" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="ProductionModeReq">
                <ConnectionPointOut connectionPointOutId="4" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="ManualModeReq">
                <ConnectionPointOut connectionPointOutId="5" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="CleaningModeReq">
                <ConnectionPointOut connectionPointOutId="6" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="">
                <ConnectionPointOut connectionPointOutId="7" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="">
                <ConnectionPointOut connectionPointOutId="8" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="InterfaceGlobal.Common.BlinkIndicator">
                <ConnectionPointOut connectionPointOutId="9" />
              </FbdObject>
              <FbdObject xsi:type="Block" typeName="fbPackML" instanceName="f${unit.name}PackML">
                <InOutVariables>
                  <InOutVariable parameterName="ioUnitPackML">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="2" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="2" />
                    </ConnectionPointIn>
                    <ConnectionPointOut connectionPointOutId="11">
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointOutOrder order="2" />
                        </Data>
                      </AddData>
                    </ConnectionPointOut>
                  </InOutVariable>
                  <InOutVariable parameterName="ioHmi">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="3" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="3" />
                    </ConnectionPointIn>
                    <ConnectionPointOut connectionPointOutId="12">
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointOutOrder order="3" />
                        </Data>
                      </AddData>
                    </ConnectionPointOut>
                  </InOutVariable>
                </InOutVariables>
                <InputVariables>
                  <InputVariable parameterName="ENI">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="1" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="1" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iProductionModeReq">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="4" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="4" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iManualModeReq">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="5" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="5" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iCleaningModeReq">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="6" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="6" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iServiceModeReq">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="7" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="7" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iMonitorModeReq">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="8" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="8" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iPulseBlinkIndicator">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="9" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="9" />
                    </ConnectionPointIn>
                  </InputVariable>
                </InputVariables>
                <OutputVariables>
                  <OutputVariable parameterName="ENO">
                    <ConnectionPointOut connectionPointOutId="10">
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointOutOrder order="1" />
                        </Data>
                      </AddData>
                    </ConnectionPointOut>
                  </OutputVariable>
                </OutputVariables>
              </FbdObject>
              <FbdObject xsi:type="DataSink" identifier="InterfaceGlobal.${unit.name}.PackML">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="11" />
                </ConnectionPointIn>
              </FbdObject>
              <FbdObject xsi:type="DataSink" identifier="HmiGlobal.${unit.name}.PackML">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="12" />
                </ConnectionPointIn>
              </FbdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="10" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
            <Rung evaluationOrder="7">
              <CommonObject xsi:type="Comment">
                <Content xsi:type="SimpleText">Start acoustic warning signal (3 seconds). Equipment movement can be disabled while warning is active.</Content>
              </CommonObject>
              <LdObject xsi:type="LeftPowerRail">
                <ConnectionPointOut connectionPointOutId="1" />
              </LdObject>
              <FbdObject xsi:type="DataSource" identifier="InterfaceGlobal.${unit.name}.PackML">
                <ConnectionPointOut connectionPointOutId="2" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="SettingGlobal.${unit.name}.TimeStartUp">
                <ConnectionPointOut connectionPointOutId="3" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="TRUE">
                <ConnectionPointOut connectionPointOutId="4" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="FALSE">
                <ConnectionPointOut connectionPointOutId="5" />
              </FbdObject>
              <FbdObject xsi:type="DataSource" identifier="FALSE">
                <ConnectionPointOut connectionPointOutId="6" />
              </FbdObject>
              <FbdObject xsi:type="Block" typeName="fbStartWarning" instanceName="fStartWarning">
                <InOutVariables>
                  <InOutVariable parameterName="ioPackML">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="2" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="2" />
                    </ConnectionPointIn>
                    <ConnectionPointOut connectionPointOutId="8">
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointOutOrder order="2" />
                        </Data>
                      </AddData>
                    </ConnectionPointOut>
                  </InOutVariable>
                </InOutVariables>
                <InputVariables>
                  <InputVariable parameterName="ENI">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="1" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="1" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iTimeStartWarning">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="3" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="3" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iWarnResetting">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="4" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="4" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iWarnStopping">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="5" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="5" />
                    </ConnectionPointIn>
                  </InputVariable>
                  <InputVariable parameterName="iWarnModeChange">
                    <ConnectionPointIn>
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointInOrder order="6" />
                        </Data>
                      </AddData>
                      <Connection refConnectionPointOutId="6" />
                    </ConnectionPointIn>
                  </InputVariable>
                </InputVariables>
                <OutputVariables>
                  <OutputVariable parameterName="ENO">
                    <ConnectionPointOut connectionPointOutId="7">
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointOutOrder order="1" />
                        </Data>
                      </AddData>
                    </ConnectionPointOut>
                  </OutputVariable>
                  <OutputVariable parameterName="oWarningActive">
                    <ConnectionPointOut connectionPointOutId="9">
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointOutOrder order="3" />
                        </Data>
                      </AddData>
                    </ConnectionPointOut>
                  </OutputVariable>
                  <OutputVariable parameterName="oWarningDone">
                    <ConnectionPointOut connectionPointOutId="10">
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointOutOrder order="4" />
                        </Data>
                      </AddData>
                    </ConnectionPointOut>
                  </OutputVariable>
                  <OutputVariable parameterName="oWarningDoneExecute">
                    <ConnectionPointOut connectionPointOutId="11">
                      <AddData>
                        <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0.xsd" handleUnknown="discard">
                          <smcext:ConnectionPointOutOrder order="5" />
                        </Data>
                      </AddData>
                    </ConnectionPointOut>
                  </OutputVariable>
                </OutputVariables>
              </FbdObject>
              <FbdObject xsi:type="DataSink" identifier="InterfaceGlobal.${unit.name}.PackML">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="8" />
                </ConnectionPointIn>
              </FbdObject>
              <FbdObject xsi:type="DataSink" identifier="InterfaceGlobal.${unit.name}.Sts.StartWarningActive">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="9" />
                </ConnectionPointIn>
              </FbdObject>
              <FbdObject xsi:type="DataSink" identifier="StartWarningDone">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="10" />
                </ConnectionPointIn>
              </FbdObject>
              <FbdObject xsi:type="DataSink" identifier="StartWarningExecuteDone">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="11" />
                </ConnectionPointIn>
              </FbdObject>
              <LdObject xsi:type="RightPowerRail">
                <ConnectionPointIn>
                  <Connection refConnectionPointOutId="7" />
                </ConnectionPointIn>
              </LdObject>
            </Rung>
          </BodyContent>
       
''';
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

  final String sysmacName;
  final String description;

  const PackMlTransitionCommand(this.sysmacName, this.description);
}
