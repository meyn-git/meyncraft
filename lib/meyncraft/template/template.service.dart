import 'package:meyncraft/meyncraft/generate/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/meyncraft/generate/generator.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';

List<Template> allTemplates() {
  return [
    JMobileTagsTemplate(),

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
