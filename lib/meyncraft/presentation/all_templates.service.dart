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
      parameters: [sysmacProjectFileParameter],
      templates: [TemplateMapping(source: 'JMobileTags.xml', target: '{{sysmacProjectFilePath}}-JMobileTags.xml')],
      tags: ['jmobile', 'exor', 'sysmac', 'tags'],
    ),

    TemplateManifest(
      name: 'JMobileEvents',
      description: 'Creates JMobile events from a Sysmac project file.',
      parameters: [sysmacProjectFileParameter],
      tags: ['jmobile', 'exor', 'sysmac', 'events'],
    ),

    TemplateManifest(
      name: 'SysmacEventGlobalArray',
      description:
          'Creates EventGlobalArray mapping code from a Sysmac project file.',
      parameters: [sysmacProjectFileParameter],
      tags: ['sysmac', 'events', 'code', 'EventGlobalArray'],
    ),
    TemplateManifest(
      name: 'EventReport',
      description: 'Generates a report of events from a Sysmac project.',
      parameters: [sysmacProjectFileParameter],
      tags: ['sysmac', 'events', 'report'],
    ),
    TemplateManifest(
      name: 'Isa88Report',
      description: 'Generates an ISA 88 report from a Sysmac project.',
      parameters: [sysmacProjectFileParameter],
      tags: ['sysmac', 'isa88', 'report'],
    ),
  ];
}
