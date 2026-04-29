import 'package:meyncraft/meyncraft/template_manifest/template_manifest.domain.dart';

List<TemplateManifest> getAllTemplateManifests() {
  var sysmacProjectFileParameter = Parameter(
    name: 'sysmacProjectFilePath',
    description: 'Path to the Sysmac project file to generate from',
    type: ParameterType.relativePath,
    required: true,
  );
  return [
    TemplateManifest(
      name: 'JMobileTags',
      description: 'Creates JMobile tags from a Sysmac project file.',
      generatedFileInstructions:
          'You can import the generated tag file in JMobile:\n'
          '* Open an existing JMobile project\n'
          '* Open the tags window from the left menu Configuration \\ Tags\n'
          '* Select the "Ethernet/IP CIP prot1 Model Omron" form the existing tag list\n'
          '* Click on the "import dictionary button" in the toolbar\n'
          '* Select the "Tag editor exported xml" row from the import dialog and click ok\n'
          '* Select the generated file\n'
          '* Remove old dictionaries (but not dictionaries that contain internal tags)\n',
      parameters: [sysmacProjectFileParameter],
      templates: [
        TemplateMapping(
          source: 'jmobile_tags.dart',
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
      templates: [
        TemplateMapping(
          source: 'jmobile_events.dart',
          target: '{{sysmacProjectFilePath}}-JMobile-Events.xml',
        ),
      ],
      tags: ['jmobile', 'exor', 'sysmac', 'events'],
    ),

    TemplateManifest(
      name: 'SysmacPackMlMonitor',
      description:
          'Creates Sysmac monitor code to debug PackMLfrom a Sysmac project file.',
      generatedFileInstructions:
          'You can import the generated file in Sysmac:\n'
          '* In the Sysmac Menu select tools \\ Tools \\ IEC 61131-10 XML \\ Import\n'
          '* Select the generated file\n'
          '* Then move the sections in the last programs to the begin of the"UnitControl" section of the corresponding unit',
      parameters: [sysmacProjectFileParameter],
      templates: [
        TemplateMapping(
          source: 'sysmac_packml_monitor.dart',
          target:
              '{{sysmacProjectFilePath}}-Sysmac-{{unit.name}}-PackMlMonitor.xml',
        ),
      ],
      tags: ['sysmac', 'packml', 'code'],
    ),

    TemplateManifest(
      name: 'SysmacEventGlobalArray',
      description:
          'Creates EventGlobalArray mapping code from a Sysmac project file.',
      generatedFileInstructions:
          'You can import the generated file in Sysmac:\n'
          '* In the Sysmac Menu select tools \\ Tools \\ IEC 61131-10 XML \\ Import\n'
          '* Select the generated file\n'
          '* Then move the sections in the last program "GeneratedByMeynCraft" to the end of section "Global\\EventHandling"',
      parameters: [sysmacProjectFileParameter],
      templates: [
        TemplateMapping(
          source: 'sysmac_event_global_array.dart',
          target: '{{sysmacProjectFilePath}}-Sysmac-EventGlobalArray.txt',
        ),
      ],
      tags: ['sysmac', 'events', 'code', 'EventGlobalArray'],
    ),
    TemplateManifest(
      name: 'EventReport',
      description: 'Generates a report of events from a Sysmac project.',
      generatedFileInstructions:
          'You can open the generated file e.g. for quick reference '
          'using Excel or any other spreadsheet software.',
      parameters: [sysmacProjectFileParameter],
      templates: [
        TemplateMapping(
          source: 'event_report.dart',
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
      templates: [
        TemplateMapping(
          source: 'isa88_report.dart',
          target: '{{sysmacProjectFilePath}}-Isa88Report.csv',
        ),
      ],
      tags: ['sysmac', 'isa88', 'report'],
    ),
  ];
}
