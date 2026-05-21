// ignore_for_file: type_literal_in_constant_pattern

import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/generate/generator_report.domain.dart';
import 'package:meyncraft/template/template.domain.dart';
import 'package:xml/xml.dart';

class JMobileEventsTemplate implements TemplateProject {
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
  final List<TemplateProjectParameter> parameters = [
    sysmacProjectFileParameter,
  ];

  @override
  final List<Generator> generators = [JMobileEventsGenerator()];

  @override
  final List<String> tags = ['jmobile', 'exor', 'sysmac', 'events'];
}

class JMobileEventsGenerator implements Generator {
  @override
  String get source => '$runtimeType Dart class';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-JMobile-Events.xml';

  @override
  final String? outputInstructions =
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
  Future<GeneratorReport> generate(
    TemplateProject template,
    Map<String, dynamic> parameterValues,
    GeneratorReport report,
  ) async {
    List<File> generatedFiles = [];
    try {
      var generatedFile = await writeJMobileEventsFile(
        template,
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

  Future<File> writeJMobileEventsFile(
    TemplateProject template,
    Map<String, dynamic> parameterValues,
    GeneratorReport report,
  ) async {
    var sysmacProject = await MeynSysmacProjectService().getProject(
      parameterValues,
    );
    var events = sysmacProject.events;
    report.addToMarkdown('* Found ${events.length} Sysmac events\n');
    if (events.warnings.isNotEmpty) {
      report.addWarningsToMarkdown(template, this, events.warnings);
    }

    String formattedXml = createFormattedEventsXml(events);

    var outputFilePath = await createOutputPath(outputPath, parameterValues);
    var outputFile = File(outputFilePath);
    await outputFile.create();
    await outputFile.writeAsString(formattedXml);
    return outputFile;
  }
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
