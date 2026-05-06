// ignore_for_file: type_literal_in_constant_pattern

import 'dart:io';

import 'package:meyncraft/meyncraft/generate/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/meyncraft/generate/generator.domain.dart';
import 'package:meyncraft/meyncraft/generate/generator.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';
import 'package:meyncraft/meyncraft/template/template.service.dart';
import 'package:xml/xml.dart';

class JMobileEventsTemplate implements Template {
  @override
  final String name = 'JMobileEvents';

  @override
  final String description =
      'Creates JMobile events from a Sysmac project file.';

  @override
  final String? documentation = null;

  @override
  final String? gitRepository = null;

  @override
  final String? generatedFileInstructions =
      'You can import the generated event file in J-Mobile:\n'
      '* Open an existing JMobile project\n'
      '* Open the events window from the left menu Configuration \\ Alarms\n'
      '* Click on the "import alarms button" in the toolbar\n'
      '* Select the generated file\n'
      '* Note that you must clear the existing runtime dynamic alarm files during downloading:\n'
      '  * In download dialog, click on "Advanced"\n'
      '  * Check "Delete runtime dynamic files"\n'
      '  * Check "Alarms"\n';

  @override
  final List<Parameter> parameters = [sysmacProjectFileParameter];

  @override
  final List<Generator> generators = [JMobileEventsGenerator()];

  @override
  final List<String> tags = ['jmobile', 'exor', 'sysmac', 'events'];
}

class JMobileEventsGenerator implements Generator {
  @override
  String get source => 'Dart code: $runtimeType';

  @override
  final String target =
      '{{removeFileExtension(sysmacProjectFilePath)}}-JMobile-Events.xml';

  JMobileEventsGenerator();

  @override
  Future<MarkdownReport> generate(
    Template template,
    Map<String, dynamic> parameterValues,
    MarkdownReport outputReport,
  ) async {
    var sysmacProjectFilePath =
        parameterValues[sysmacProjectFileParameter.name];
    if (sysmacProjectFilePath == null) {
      throw Exception('Missing parameter: ${sysmacProjectFileParameter.name}');
    }
    var sysmacProject = await MeynSysmacProject.loadFromFile(
      File(sysmacProjectFilePath),
    );
    List<File> generatedFiles = [];
    try {
      generatedFiles = await writeJMobileEventsFile(
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

  Future<List<File>> writeJMobileEventsFile(
    MeynSysmacProject sysmacProject,
    MarkdownReport outputReport,
  ) async {
    var events = sysmacProject.events;
    outputReport.append('* Found ${events.length} Sysmac events\n');
    //TODO add link in case there are warnings
    String formattedXml = createFormattedEventsXml(events);
    var outputFile = createOutputFile(sysmacProject, '-JMobileEvents.xml');
    await outputFile.create();
    await outputFile.writeAsString(formattedXml);
    outputReport.append(
      '* Created file: [${outputFile.path}](${outputFile.uri})\n',
    );
    return [outputFile];
  }
}

@Deprecated('Use the JMobileEventsTemplate instead')
Future<void> writeJMobileEventsFile(MeynSysmacProject sysmacProject) async {
  var events = sysmacProject.events;
  String formattedXml = createFormattedEventsXml(events);
  var outputFile = createOutputFile(sysmacProject, '-JMobileEvents.xml');
  await outputFile.create();
  await outputFile.writeAsString(formattedXml);
  logger.info('Created: ${outputFile.path}');
  logger.info('     You can import the events in J-Mobile:');
  logger.info('     * Open an existing JMobile project');
  logger.info(
    '     * Open the events window from the left menu Configuration \\ Alarms',
  );
  logger.info('     * Click on the "import alarms button" in the toolbar');
  logger.info('     * Select the generated ${outputFile.path} file');
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

String createFormattedEventsXml(List<Event> events) {
  var alarms = events.map((e) => createJMobileAlarmElement(e)).toList();

  var document = XmlDocument([
    XmlComment('This code was generated with MeynCraft on ${DateTime.now()}.'),
    XmlComment(
      'For more information see: https://github.com/meyn-git/meyncraft (scroll down for documentation)',
    ),
    XmlElement(XmlName('alarms'), [], alarms),
  ]);
  String xml = document.toXmlString(pretty: true, indent: '  ');
  return xml;
}

enum ExorSeverity {
  notImportant(0, [EventPriority.info]),
  low(1, [EventPriority.low]),
  belowNormal(2, [EventPriority.mediumLow]),
  normal(3, [EventPriority.medium]),
  aboveNormal(4, [EventPriority.mediumHigh]),
  hight(5, [EventPriority.high]),
  critical(6, [EventPriority.critical, EventPriority.fatal]);

  final int level;
  final List<EventPriority> comparableToSysmacPriorities;

  const ExorSeverity(this.level, this.comparableToSysmacPriorities);

  static ExorSeverity valueOf(EventPriority priority) {
    for (var value in values) {
      if (value.comparableToSysmacPriorities.contains(priority)) {
        return value;
      }
    }
    return normal;
  }
}

XmlElement createJMobileAlarmElement(Event event) {
  return XmlElement(
    XmlName('alarm'),
    [
      XmlAttribute(XmlName('eventBuffer'), 'AlarmBuffer1'),
      XmlAttribute(XmlName('logToEventArchive'), 'true'),
      XmlAttribute(XmlName('eventType'), '14'),
      XmlAttribute(XmlName('subType'), '1'),
      XmlAttribute(XmlName('storeAlarmInfo'), 'true'),
    ],
    [
      XmlElement(XmlName('name'), [], [
        XmlText('Event_${event.number.toString().padLeft(4, '0')}'),
      ]),
      XmlElement(XmlName('groups'), [], [XmlText(event.group)]),
      XmlElement(
        XmlName('source'),
        [
          XmlAttribute(XmlName('index'), event.number.toString()),
          XmlAttribute(XmlName('arrayType'), 'true'),
        ],
        [XmlText('EventGlobalArray')],
      ),
      XmlElement(XmlName('alarmType'), [], [XmlText('bitMaskAlarm')]),
      XmlElement(XmlName('bitMask'), [], [XmlText('1')]),
      XmlElement(XmlName('enableTag'), [], []),
      XmlElement(XmlName('remoteAck'), [], []),
      XmlElement(XmlName('ackNotify'), [], []),
      XmlElement(XmlName('touchAckNotify'), [], []),
      XmlElement(XmlName('enabled'), [], [XmlText('true')]),
      XmlElement(XmlName('requireAck'), [], [
        XmlText(event.acknowledgeRequired.toString()),
      ]),
      XmlElement(XmlName('blinkTxt'), [], [XmlText('false')]),
      XmlElement(XmlName('requireReset'), [], [XmlText('true')]),
      XmlElement(XmlName('severity'), [], [
        XmlText(ExorSeverity.valueOf(event.priority).level.toString()),
      ]),
      XmlElement(XmlName('priority'), [], [XmlText('3')]),
      XmlElement(XmlName('logMask'), [], [XmlText('76')]),
      XmlElement(XmlName('notifyMask'), [], [XmlText('76')]),
      XmlElement(XmlName('actionMask'), [], [XmlText('1')]),
      XmlElement(XmlName('printMask'), [], [XmlText('1')]),
      _createCustomFields(event),
      _createColors(),
      XmlElement(XmlName('actions'), [], []),
      XmlElement(XmlName('useractions'), [], []),
      _createDescription(event),
      XmlElement(
        XmlName('enableAudit'),
        [
          XmlAttribute(XmlName('auditBuff'), ''),
          XmlAttribute(XmlName('subT'), '1'),
          XmlAttribute(XmlName('eventT'), '18'),
        ],
        [XmlText('false')],
      ),
    ],
  );
}

XmlElement _createCustomFields(Event event) {
  return XmlElement(XmlName('customFields'), [], [
    XmlElement(
      XmlName('customField_1'),
      [],
      List.generate(10, (i) {
        return XmlElement(
          XmlName('L${i + 1}'),
          [XmlAttribute(XmlName('langName'), _langName(i + 1))],
          [XmlText(event.number.toString())],
        );
      }),
    ),
    XmlElement(
      XmlName('customField_2'),
      [],
      List.generate(10, (i) {
        return XmlElement(
          XmlName('L${i + 1}'),
          [XmlAttribute(XmlName('langName'), _langName(i + 1))],
          [XmlText(event.namePath)],
        );
      }),
    ),
  ]);
}

XmlElement _createColors() {
  final colorMap = {
    'ackTxtColor': '#ff0000',
    'ackBgColor': '#ffff00',
    'disabledTxtColor': '#000000',
    'disabledBgColor': '#ffffff',
    'triggeredTxtColor': '#000000',
    'triggeredBgColor': '#ff0000',
    'notTriggeredTxtColor': '#000000',
    'notTriggeredBgColor': '#ffffff',
    'triggeredAckedTxtColor': '#000000',
    'triggeredAckedBgColor': '#ffa500',
    'triggeredNotAckedTxtColor': '#000000',
    'triggeredNotAckedBgColor': '#ff0000',
    'notTriggeredAckedTxtColor': '#000000',
    'notTriggeredAckedBgColor': '#008000',
    'notTriggeredNotAckedTxtColor': '#000000',
    'notTriggeredNotAckedBgColor': '#ffff00',
  };

  return XmlElement(
    XmlName('colors'),
    [],
    colorMap.entries.map((entry) {
      return XmlElement(XmlName(entry.key), [], [XmlText(entry.value)]);
    }).toList(),
  );
}

XmlElement _createDescription(Event event) {
  return XmlElement(
    XmlName('description'),
    [],
    List.generate(10, (i) {
      return XmlElement(
        XmlName('L${i + 1}'),
        [XmlAttribute(XmlName('langName'), _langName(i + 1))],
        [XmlText(event.componentCodesAndMessage)],
      );
    }),
  );
}

String _langName(int index) {
  const langNames = [
    'English',
    'Dutch',
    'German',
    'French',
    'Spanish',
    'Polish',
    'BrazilPortuguese',
    'Russian',
    'Turkish',
    'Chinese',
  ];
  return langNames[index - 1];
}
