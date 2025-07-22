// ignore_for_file: type_literal_in_constant_pattern

import 'dart:io';

import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/event.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';
import 'package:xml/xml.dart';
// TODO remove?
// void writeSysmacEventArrayCodeFile(
//     SysmacProject sysmacProject, List<Event> events) {
//   var code = StringBuffer();

//   code.writeln(
//       '// The EventGlobal is copied to EventGlobalArray for more efficient communication.');
//   code.writeln(
//       '// This code was generated on 2025-07-17 with sysmac_generator.');
//   code.writeln(
//       '// For more information see: https://github.com/nils-ten-hoeve/sysmac_generator');
//   for (var event in events) {
//     code.writeln('EventGlobalArray[${event.number}]:=${event.namePath};');
//   }
//   var outputFile = createOutputFile(sysmacProject, '-SysmacEventArray.txt');
//   outputFile.createSync();
//   outputFile.writeAsStringSync(code.toString());
//   print('Created: ${outputFile.path} (${events.length} events)');
// }

//TODO make async
void writeJMobileEventsFile(SysmacProject sysmacProject) {
  var events = sysmacProject.eventService.events;
  String formattedXml = createFormattedEventsXml(events);
  var outputFile = createOutputFile(sysmacProject, '-JMobileEvents.xml');
  outputFile.createSync();
  outputFile.writeAsStringSync(formattedXml);
  logger.info('Created: ${outputFile.path}');
}

File createOutputFile(SysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.archive.file;
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

enum XorSeverity {
  notImportant(0, [EventPriority.info]),
  low(1, [EventPriority.low]),
  belowNormal(2, [EventPriority.mediumLow]),
  normal(3, [EventPriority.medium]),
  aboveNormal(4, [EventPriority.mediumHigh]),
  hight(5, [EventPriority.high]),
  critical(6, [EventPriority.critical, EventPriority.fatal]);

  final int level;
  final List<EventPriority> comparableToSysmacPriorities;

  const XorSeverity(this.level, this.comparableToSysmacPriorities);

  static XorSeverity valueOf(EventPriority priority) {
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
        XmlText(XorSeverity.valueOf(event.priority).level.toString()),
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
