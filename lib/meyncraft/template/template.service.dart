import 'package:meyncraft/meyncraft/generate/generator.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';

List<TemplateManifest> allTemplates() {
  return [
    TemplateManifest(
      name: 'JMobileTags',
      description: 'Creates JMobile tags from a Sysmac project file.',
      generatedFileInstructions:
          'You can import the generated tag file in JMobile:\n'
          '* Open an existing JMobile project\n'
          '* In the "Project view" double click on Configuration \\ Tags\n'
          '* Select the "Ethernet/IP CIP prot1 Model Omron" form the existing tag list\n'
          '* Click on the "import dictionary button" in the toolbar\n'
          '* Select the "Tag editor exported xml" row from the import dialog and click ok\n'
          '* Select the generated file as the "watched dictionary file"\n'
          '* Click on "Ok"\n'
          '* In the "Project view" remove old dictionaries (but not dictionaries that contain internal tags)\n'
          '* Note that new tags in dictionaries will need to by added to the tags by finding them in the "Tags" view'
          ', selecting them and "Adding to tags" with a right click\n'
          '* Note that pages that use tags that no longer exist need to be fixed. '
          'These can be found with the project validator: Menu \\ Run \\ Run Project Validator. '
          'When these tags are no longer used you can remove them from the tags.\n',
      parameters: [sysmacProjectFileParameter],
      generators: [
        CodeTemplateGenerator(
          target: '{{sysmacProjectFilePath}}-JMobile-Tags.xml',
        ),
      ],
      tags: ['jmobile', 'exor', 'sysmac', 'tags'],
    ),

    TemplateManifest(
      name: 'JMobileEvents',
      description: 'Creates JMobile events from a Sysmac project file.',
      generatedFileInstructions:
          'You can import the generated event file in J-Mobile:\n'
          '* Open an existing JMobile project\n'
          '* Open the events window from the left menu Configuration \\ Alarms\n'
          '* Click on the "import alarms button" in the toolbar\n'
          '* Select the generated file\n'
          '* Note that you must clear the existing runtime dynamic alarm files during downloading:\n'
          '  * In download dialog, click on "Advanced"\n'
          '  * Check "Delete runtime dynamic files"\n'
          '  * Check "Alarms"\n',
      parameters: [sysmacProjectFileParameter],
      generators: [
        CodeTemplateGenerator(
          target: '{{sysmacProjectFilePath}}-JMobile-Events.xml',
        ),
      ],
      tags: ['jmobile', 'exor', 'sysmac', 'events'],
    ),

    TemplateManifest(
      name: 'SysmacEventGlobalArray',
      description:
          'Creates EventGlobalArray mapping code from a Sysmac project file.',
      generatedFileInstructions:
          'You can import the generated file in Sysmac:\n'
          '* In the Sysmac Menu select: Tools \\ IEC 61131-10 XML \\ Import\n'
          '* Select the generated file by clicking the folder button\n'
          '* Click on the "Execute" button\n'
          '* Merge changes if prompted\n'
          '* Then move the sections in the last program "GeneratedByMeynCraft" '
          'to the end of section "Global\\EventHandling"',
      parameters: [sysmacProjectFileParameter],
      generators: [
        CodeTemplateGenerator(
          target: '{{sysmacProjectFilePath}}-Sysmac-EventGlobalArray.txt',
        ),
      ],
      tags: ['sysmac', 'events', 'code', 'EventGlobalArray'],
    ),

    TemplateManifest(
      name: 'SysmacPackMlMonitor',
      description:
          'Creates Sysmac monitor code to debug PackMLfrom a Sysmac project file.',
      generatedFileInstructions:
          'You can import the generated file in Sysmac:\n'
          '* In the Sysmac Menu select: Tools \\ IEC 61131-10 XML \\ Import\n'
          '* Select the generated file by clicking the folder button\n'
          '* Click on the "Execute" button\n'
          '* Merge changes if prompted\n'
          '* Then move the sections in the last programs to the begin of the '
          '"UnitControl" section of the corresponding unit',
      parameters: [sysmacProjectFileParameter],
      generators: [
        CodeTemplateGenerator(
          target:
              '{{sysmacProjectFilePath}}-Sysmac-{{unit.name}}-PackMlMonitor.xml',
        ),
      ],
      tags: ['sysmac', 'packml', 'code'],
    ),

    TemplateManifest(
      name: 'EventReport',
      description: 'Generates a report of events from a Sysmac project.',
      generatedFileInstructions:
          'You can open the generated file e.g. for quick reference '
          'using Excel or any other spreadsheet software.',
      parameters: [sysmacProjectFileParameter],
      generators: [
        CodeTemplateGenerator(
          target: '{{sysmacProjectFilePath}}-EventReport.csv',
        ),
      ],
      tags: ['sysmac', 'events', 'report'],
    ),
    TemplateManifest(
      name: 'Isa88Report',
      description: 'Generates an ISA 88 report from a Sysmac project.',
      generatedFileInstructions:
          'You can open the generated file e.g. for quick reference '
          'using Excel or any other spreadsheet software.',
      parameters: [sysmacProjectFileParameter],
      generators: [
        CodeTemplateGenerator(
          target: '{{sysmacProjectFilePath}}-Isa88Report.csv',
        ),
      ],
      tags: ['sysmac', 'isa88', 'report'],
    ),
  ];
}

final sysmacProjectFileParameter = Parameter(
  name: 'sysmacProjectFilePath',
  description: 'Path to the Sysmac project file to generate from',
  type: ParameterType.relativePath,
  required: true,
);
