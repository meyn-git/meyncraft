import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/comment_attribute.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/component_code.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:petitparser/petitparser.dart';

class Event {
  final int number;
  final String namePath;
  final String group;
  final String message;
  final List<ComponentCode> componentCodes;
  final EventPriority priority;
  final bool acknowledgeRequired;

  Event({
    required this.number,
    required this.namePath,
    required this.group,
    required this.message,
    this.componentCodes = const <ComponentCode>[],
    required this.priority,
    required this.acknowledgeRequired,
  });

  String get componentCodesAndMessage =>
      [...componentCodes.map((c) => c.createCode()), message].join(' ');

  @override
  String
  toString() => // 'Event(number: $number, namePath: $namePath, group: $group, message: $message)';
      '${namePath.padRight(60)}  $componentCodesAndMessage ${priority.abbreviation} $acknowledgeRequired';
}

class Counter {
  int value = 0;
  int next() {
    value = value + 1;
    return value;
  }
}

/// Used to creates Events from [Variable] and [DataType]
class EventNode {
  final String name;
  final String comment;
  final BaseType baseType;
  final List<EventNode> children;

  EventNode.fromVariable(Variable variable)
    : name = variable.name,
      // The comment of the GlobalEvent variable is not needed
      comment = '',
      baseType = variable.baseType,
      children = createChildren(variable.baseType);

  EventNode.fromDataType(DataType dataType)
    : name = dataType.name,
      comment = dataType.comment,
      baseType = dataType.baseType,
      children = createChildren(dataType.baseType);

  static List<EventNode> createChildren(BaseType baseType) =>
      baseType is DataTypeReference
      ? baseType.dataType.children
            .map((c) => c as DataType)
            .map((child) => EventNode.fromDataType(child))
            .toList()
      : [];

  static bool skip(BaseType baseType) =>
      baseType is EnumChild ||
      baseType is UnknownBaseType ||
      baseType is DataTypeReference;

  /// creates a name path of this node.
  /// returns a list with:
  /// * one path if there is no array.
  /// * or a path for each array value
  List<String> createNamePaths(String parentNamePath) {
    var path = createNamePath(parentNamePath);
    var arrayValues = baseType.arrayRanges.toStringList();
    if (arrayValues.isEmpty) {
      return <String>[path];
    } else {
      return arrayValues.map((a) => path + a).toList();
    }
  }

  /// creates a name path for this node without array values
  String createNamePath(String parentNamePath) => parentNamePath.isEmpty
      ? name.trim()
      : [parentNamePath, name.trim()].join('.');

  String createCommentPath(String parentCommentPath) =>
      parentCommentPath.isEmpty
      ? comment.trim()
      : [parentCommentPath, _uppercaseFirstLetter(comment.trim())].join('-');

  List<Event> createEvents(
    Counter counter, {
    String parentNamePath = '',
    String parentCommentPath = '',
  }) {
    var events = <Event>[];
    if (children.isEmpty) {
      if (baseType is! NxBool) {
        return events;
      }
      var namePaths = createNamePaths(parentNamePath);
      var commentPath = createCommentPath(parentCommentPath);
      for (var namePath in namePaths) {
        var eventValues = createEventValues(namePath, commentPath);
        var acknowledgeNeeded = AcknowledgeAttribute.acknowledge(eventValues);
        var priority = PriorityAttribute.priority(eventValues);
        var componentCodes = findComponentCodes(namePath, eventValues);
        var message = createMessage(eventValues);
        var event = Event(
          number: counter.next(),
          namePath: namePath,
          group: createGroupName(namePath),
          componentCodes: componentCodes,
          message: message,
          priority: priority,
          acknowledgeRequired: acknowledgeNeeded,
        );
        events.add(event);
      }
    } else {
      var namePaths = createNamePaths(parentNamePath);
      var commentPath = createCommentPath(parentCommentPath);
      for (var namePath in namePaths) {
        for (var child in children) {
          /// recursive call
          events.addAll(
            child.createEvents(
              counter,
              parentNamePath: namePath,
              parentCommentPath: commentPath,
            ),
          );
        }
      }
    }
    return events;
  }

  /// e.g. returns GizzardPump1 if namePath == EventGlobal.GizzardPump[1].MtrProt
  String createGroupName(String namePath) {
    // Remove leading 'EventGlobal.'
    if (namePath.startsWith('EventGlobal.')) {
      namePath = namePath.substring('EventGlobal.'.length);
    }

    // Remove everything after the first dot
    int dotIndex = namePath.indexOf('.');
    if (dotIndex != -1) {
      namePath = namePath.substring(0, dotIndex);
    }

    // Remove '[' and ']' characters
    namePath = namePath.replaceAll(RegExp(r'[\[\]]'), '');

    return namePath;
  }

  /// normalizes the commentPath to a message.
  String createMessage(List eventValues) {
    var rawMessage = eventValues
        .where((v) => v is String || v is num)
        .map((v) => v.toString())
        .join();
    return rawMessage
        // remove all leading dashes
        .replaceAll(RegExp(r'^(-\s*)+'), '')
        // remove all unneeded characters
        .replaceAll(' : ', ':')
        .replaceAll(' :', ':')
        .replaceAll(': ', ':')
        .replaceAll('  ', ' ')
        .replaceAll('--', '-')
        .replaceAll(', message instead of alarm event', '')
        .trim();
  }

  List<ComponentCode> findComponentCodes(String namePath, List eventValues) {
    var componentCodes = eventValues.whereType<ComponentCode>();
    var columnAttribute = ComponentCodeAddColumnsAttribute.valueOf(
      namePath,
      eventValues,
    );
    var lettersAttribute = ComponentCodeOverrideLettersAttribute.valueOf(
      eventValues,
    );
    var result = <ComponentCode>[];
    for (var componentCode in componentCodes) {
      if (columnAttribute != null) {
        componentCode = columnAttribute.componentCode(componentCode, namePath);
      }
      if (lettersAttribute != null) {
        componentCode = lettersAttribute.componentCode(componentCode);
      }
      result.add(componentCode);
    }
    return result;
  }

  /// override the letters of the component code based on the comment path.
  /// TODO do this with a CommentAttribute e.g. [ccl=S] or [ccl=Q]
  String getComponentCodeLetters(
    String commentPath,
    ComponentCode componentCode,
  ) {
    if (commentPath.endsWith('Switched off')) {
      // Motor Switch
      return 'S';
    }
    if (commentPath.endsWith('Motor protection') ||
        commentPath.endsWith('VFD circuit breaker')) {
      // Motor Switch
      return 'Q';
    }
    return componentCode.letters;
  }

  String _uppercaseFirstLetter(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }

  List<CommentAttribute> defaultAttributes = [
    PriorityAttribute(EventPriority.medium),
    AcknowledgeAttribute(true),
    ComponentCodeAddColumnsAttribute(1),
  ];

  /// FIXME: This is temporarily until MeynCraft is common good
  /// and the standard libraries contain ComponentCodeLettersAttributes',
  /// then this List can be removed
  List<CommentAttribute> conditionalAttributes = [
    // TODO add [ccl=S] in Cm\MtrCtrl\sEventDol and Cm\MtrCtrl\sEventVfd library structure comments and remove following line
    ConditionalAttribute('*.MtrSw', [
      ComponentCodeOverrideLettersAttribute('S'),
    ]),
    // TODO add [ccl=Q] in Cm\MtrCtrl\sEventDol and Cm\MtrCtrl\sEventVfd library structure comments and remove following line
    ConditionalAttribute('*.MtrProt', [
      ComponentCodeOverrideLettersAttribute('Q'),
    ]),
    // TODO add [ccl=M] in Cm\MtrCtrl\sEventDol library structure comments and remove following lines
    ConditionalAttribute('*.NotRunning', [
      ComponentCodeOverrideLettersAttribute('M'),
    ]),
    ConditionalAttribute('*.NotStopped', [
      ComponentCodeOverrideLettersAttribute('M'),
    ]),
    // following lines are commented because *.Interlocked is used be several structures
    // ConditionalAttribute('*.Interlocked', [
    //   ComponentCodeOverrideLettersAttribute('M'),
    // ]),
    // TODO add [ccl=U] in Cm\MtrCtrl\sEventVfd library structure comments and remove following lines
    // following lines are commented because fuses als have .Tripped but must stay F
    // ConditionalAttribute('*.Tripped', [
    //   ComponentCodeOverrideLettersAttribute('U'),
    // ]),
    ConditionalAttribute('*.DriveOff', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.DriveWarning', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.Low10V', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.MtrEtrOverTmp', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.TorqueLimit', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.OverCurr', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.GroundFault', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.ShortCircuit', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.SafeStop', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.FeedbackMonitor', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),
    ConditionalAttribute('*.TrackingErr', [
      ComponentCodeOverrideLettersAttribute('U'),
    ]),

    // TODO add [noAck] in Equipment\*Module\sEvent library structure comment and remove following line
    ConditionalAttribute('*.StopTimeOut', [AcknowledgeAttribute(false)]),
    // TODO add [noAck][prio=info] in Safety\sEventInDualChannel\Reset library structure comment and remove following line
    ConditionalAttribute('*.RstReq', [
      AcknowledgeAttribute(false),
      PriorityAttribute(EventPriority.info),
    ]),
    // TODO add [noAck][prio=info] in Safety\sEventInDualChannel\Activated library structure comment and remove following line
    ConditionalAttribute('*.Active', [
      AcknowledgeAttribute(false),
      PriorityAttribute(EventPriority.info),
    ]),
    ConditionalAttribute('*.ActiveWarning', [
      AcknowledgeAttribute(false),
      PriorityAttribute(EventPriority.info),
    ]),
    // TODO add [noAck][prio=info] in Cm\StartStopCtrl\sEvent library structure comment and remove following line
    ConditionalAttribute('*.StopBox*', [
      AcknowledgeAttribute(false),
      PriorityAttribute(EventPriority.info),
    ]),
  ];

  List createEventValues(String namePath, String commentPath) {
    var result = commentPathParser.parse(commentPath);
    var values = result is Failure
        ? [...conditionalAttributes]
        : [...conditionalAttributes, ...result.value];
    var eventValues = replaceEventValues(namePath, values);
    var unknownAttributes = eventValues.whereType<UnknownAttribute>();
    if (unknownAttributes.isNotEmpty) {
      logger.warning(
        'Unknown attributes found in event "$namePath" with commentPath "$commentPath": $unknownAttributes',
      );
    }
    return eventValues;
  }

  /// Replaces all [Replaceable] values in the parsedValues with their replacement value.
  List replaceEventValues(String namePath, Iterable eventValues) {
    var values = [];
    for (var eventValue in eventValues) {
      if (eventValue is Replaceable) {
        var newValue = eventValue.replacementValue(namePath);
        var newValues = newValue is Iterable ? newValue : [newValue];
        values.addAll(replaceEventValues(namePath, newValues));
      } else {
        values.add(eventValue);
      }
    }
    return values;
  }
}

/// Priority definition:
/// | Name        | Abbreviation | Level | Description                                                                 | Example                                                                                      |
/// |-------------|--------------|-------|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
/// | Fatal       | F            | 1     | A fatal problem that prevents the system from working (fatal for system).   | An EtherCAT error, an important fuse of the control system, missing IO cards, critical IO card errors, etc. |
/// | Critical    | C            | 2     | A critical problem that stops the system.                                   | An emergency stop, a critical motor tripped, low hydraulic level, etc.                      |
/// | High        | H            | 3     | A problem with major consequences, but system keeps running.                | Direct action is needed, e.g.: an important motor tripped, etc.                             |
/// | Medium High | MH           | 4     | A problem with moderate consequences.                                       | Urgent action is required.                                                                  |
/// | Medium      | M            | 5     | A problem with some consequences.                                           | Action within 5 minutes is required, e.g. when a low temperature is detected.               |
/// | Medium Low  | ML           | 6     | A problem with minor consequences.                                          | Action within 15 minutes is required.                                                       |
/// | Low         | L            | 7     | A problem with almost no consequences.                                      | Eventually action is required, e.g. a tripped plucker motor.                                |
/// | Info        | I            | 9     | All events that are not an error, such as information for the operator.     | When a stop button is pressed, or external stop is activated.                               |
enum EventPriority {
  fatal(
    name: 'Fatal',
    abbreviation: 'F',
    level: 1,
    description:
        'A fatal problem that prevents the system from working (fatal for system).',
    example:
        'An EtherCAT error, an important fuse of the control system, missing IO cards, critical IO card errors, etc.',
  ),
  critical(
    name: 'Critical',
    abbreviation: 'C',
    level: 2,
    description: 'A critical problem that stops the system.',
    example:
        'An emergency stop, a critical motor tripped, low hydraulic level, etc.',
  ),
  high(
    name: 'High',
    abbreviation: 'H',
    level: 3,
    description: 'A problem with major consequences, but system keeps running.',
    example: 'Direct action is needed, e.g.: an important motor tripped, etc.',
  ),
  mediumHigh(
    name: 'Medium High',
    abbreviation: 'MH',
    level: 4,
    description: 'A problem with moderate consequences.',
    example: 'Urgent action is required.',
  ),
  medium(
    name: 'Medium',
    abbreviation: 'M',
    level: 5,
    description: 'A problem with some consequences.',
    example:
        'Action within 5 minutes is required, e.g. when a low temperature is detected.',
  ),
  mediumLow(
    name: 'Medium Low',
    abbreviation: 'ML',
    level: 6,
    description: 'A problem with minor consequences.',
    example: 'Action within 15 minutes is required.',
  ),
  low(
    name: 'Low',
    abbreviation: 'L',
    level: 7,
    description: 'A problem with almost no consequences.',
    example: 'Eventually action is required, e.g. a tripped plucker motor.',
  ),
  info(
    name: 'Info',
    abbreviation: 'I',
    level: 9,
    description:
        'All events that are not an error, such as information for the operator',
    example: 'When a stop button is pressed, or external stop is activated.',
  );

  final String name;
  final String abbreviation;
  final int level;
  final String description;
  final String example;

  const EventPriority({
    required this.name,
    required this.abbreviation,
    required this.level,
    required this.description,
    required this.example,
  });
}
