import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/event_component_code.domain.dart';
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
  final List<List<int>> arrayValues;

  Event({
    required this.number,
    required this.namePath,
    required this.group,
    required this.message,
    this.componentCodes = const <ComponentCode>[],
    required this.priority,
    required this.acknowledgeRequired,
    required this.arrayValues,
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
      : [parentCommentPath, comment.trim()].join('-');

  final ComponentCodeParser componentCodeParser = ComponentCodeParser();

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
      var componentCodes = getComponentCodes(commentPath);
      var acknowledgeNeeded = !noAcknowledgeNeeded(commentPath);
      var priority = EventPriority.valueOf(commentPath);
      for (var namePath in namePaths) {
        var arrayValues = createArrayValues(namePath);
        var message = createMessage(commentPath, componentCodes, arrayValues);
        var event = Event(
          number: counter.next(),
          namePath: namePath,
          group: createGroupName(namePath),
          componentCodes: updateComponentCodes(
            commentPath,
            componentCodes,
            arrayValues,
          ),
          message: message,
          priority: priority,
          acknowledgeRequired: acknowledgeNeeded,
          arrayValues: arrayValues,
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
  String createMessage(
    String commentPath,
    List<ComponentCode> componentCodes,
    List<List<int>> arrayValues,
  ) {
    return commentPath
        // remove all component codes
        .replaceAll(
          RegExp(componentCodes.map((cc) => cc.createCode()).join('|')),
          '',
        )
        .replaceAll(
          RegExp(r'\[arrayNr\]', caseSensitive: false),
          arrayValues.lastOrNull?.lastOrNull?.toString() ?? '',
        )
        .replaceAll(commentAttributes, '')
        // remove all leading dashes
        .replaceAll(RegExp(r'^(-\s*)+'), '')
        .replaceAll(' : ', ':')
        .replaceAll(' :', ':')
        .replaceAll(': ', ':')
        .replaceAll('  ', '')
        .trim();
  }

  bool noAcknowledgeNeeded(String commentPath) {
    String comment = commentPath.trim().toLowerCase();
    return comment.contains('[noack]') ||
        // TODO add [noAck][prio=m] in Equipment\MtrModule\sEvent library structure comment and remove following line
        comment.endsWith('stop time out') ||
        // TODO add [noAck][prio=i] in Safety\sEventInDualChannel\Reset library structure comment and remove following line
        comment.contains('-reset request') ||
        // TODO add [noAck][prio=i] in Safety\sEventInDualChannel\Activated library structure comment and remove following line
        comment.contains('-activated') ||
        // TODO add [noAck][prio=i] in Cm\StartStopCtrl\sEvent library structure comment and remove following line
        comment.contains('start request start/stop') ||
        // TODO add [noAck][prio=i] in Cm\StartStopCtrl\sEvent library structure comment and remove following line
        comment.contains('start request satellite panel');
  }

  /// creates a list of array values for this node.
  /// e.g. for EventGlobal.Plucker[1],Motor[3,4].MtrProt returns [[1], [3, 4]]
  List<List<int>> createArrayValues(String namePath) {
    final regex = RegExp(r'\[(.*?)\]');
    final matches = regex.allMatches(namePath);
    return matches.map((match) {
      final content = match.group(1);
      if (content == null || content.isEmpty) return <int>[];
      return content.split(',').map((e) => int.parse(e.trim())).toList();
    }).toList();
  }

  List<ComponentCode> updateComponentCodes(
    String commentPath,
    List<ComponentCode> componentCodes,
    List<List<int>> arrayValues,
  ) {
    if (componentCodes.isEmpty ||
        arrayValues.isEmpty ||
        componentCodes.length > 1) {
      return componentCodes;
    }

    /// calculate the component code when an array is used
    var componentCode = componentCodes.first;

    var columnNumberToAdd = getColumnNumberToAdd(commentPath);
    var arrayValue =
        arrayValues.last.last; // We assume the last array will start with 1
    var unlimitedColumnNumber =
        componentCode.columnNumber.value + (arrayValue - 1) * columnNumberToAdd;
    var columnNumber = ColumNumber((unlimitedColumnNumber - 1) % 8 + 1);
    var pageNumber =
        componentCode.pageNumber + ((unlimitedColumnNumber - 1) ~/ 8);
    var letters = getComponentCodeLetters(commentPath, componentCode);

    return [
      ComponentCode(
        site: componentCode.site,
        electricPanel: componentCode.electricPanel,
        pageNumber: pageNumber,
        letters: letters,
        columnNumber: columnNumber,
      ),
    ];
  }

  List<ComponentCode> getComponentCodes(String commentPath) =>
      componentCodeParser
          .allMatches(commentPath, overlapping: false)
          .whereType<ComponentCode>()
          .toList();

  int getColumnNumberToAdd(String commentPath) {
    final matches = NextComponentCodeCommentAttribute.parser.allMatches(
      commentPath,
      overlapping: true,
    );
    if (matches.isEmpty) {
      return 1; // Default value if no match is found
    } else {
      return matches.first.numberOfColumnsToAdd;
    }
  }

  /// override the letters of the component code based on the comment path.
  /// TODO do this with a CommentAttribute e.g. [S] or [Q]
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
}

/// commentAttributes is information in [Variable] or [DataType] comments that can be used to generate events.
/// TODO crate a CommentAttribute class and extend all CommentAttributes extend it. It needs to have a parser and description.  The description needs to be imported as documentation
/// \[.*?\] matches:
/// \[ — a literal opening bracket
/// .*? — any characters (non-greedy)
/// \] — a literal closing bracket
final RegExp commentAttributes = RegExp(r'\[.*?\]');

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

  /// finds [prio=l] [PRIO=mL] [PRIO=M] etc.
  static RegExp get regExp => RegExp(
    '\\[prio=(${values.map((v) => v.abbreviation).join('|')})\\]',
    caseSensitive: false,
  );

  static EventPriority valueOf(String comments) {
    final matches = regExp.allMatches(comments);
    if (matches.isEmpty) {
      return medium;
    }
    final abbreviation = matches.first.group(1)!.trim().toUpperCase();
    for (var value in values) {
      if (value.abbreviation == abbreviation) {
        return value;
      }
    }
    return medium;
  }
}

// TODO
// /// a CommentAttribute is a piece of text in a [Variable] or [DataType] comment
// /// that provides additional information about the event.
// /// It is surrounded by square brackets and is not visible in the event message.
// /// Example: [noAck] or [prio=M] or [cc=+2]
// abstract class CommentAttribute<T> {

//   Parser<CommentAttribute> get parser;

//   T get value;
// }

// class NoAckCommentAttribute extends CommentAttribute<bool> {
//   @override
//   Parser<CommentAttribute> get parser => stringIgnoreCase('[noack]').map((_) => this);
//   @override
//   bool get value => true;
// }

// class PrioCommentAttribute extends CommentAttribute<EventPriority> {
//   @override
//   final EventPriority value;

//   PrioCommentAttribute(this.value);

//   @override
//   Parser<CommentAttribute> get parser =>
//       EventPriority.regExp.map((match) => PrioCommentAttribute(
//           EventPriority.valueOf(match.group(0) ?? '')));

// }

class NextComponentCodeCommentAttribute {
  final int numberOfColumnsToAdd;

  NextComponentCodeCommentAttribute(this.numberOfColumnsToAdd);

  static Parser<NextComponentCodeCommentAttribute> parser =
      (stringIgnoreCase('[cc=') &
              (char('+').optional() & digit().plus()).flatten().map(int.parse) &
              char(']'))
          .map((values) => NextComponentCodeCommentAttribute(values[1]));
}
