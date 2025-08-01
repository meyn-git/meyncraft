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
      var conditionalAppends =
          ConditionalAppendCommentAttribute.attributesFromCommentPath(
            commentPath,
          );
      var acknowledgeNeeded = !NoAcknowledgeCommentAttribute.valueOf(
        commentPath,
      );
      var priority = EventPriorityCommentAttribute.valueOf(commentPath);
      for (var namePath in namePaths) {
        var componentCodes = getComponentCodes(
          namePath: namePath,
          commentPath: commentPath,
          conditionalAppends: conditionalAppends,
        );
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
          ArrayNumberCommentAttribute.parser,
          ArrayNumberCommentAttribute.valueOf(arrayValues),
        )
        .replaceAll(commentAttributes, '')
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

  List<ComponentCode> getComponentCodes({
    required String namePath,
    required String commentPath,
    required Iterable<ConditionalAppendCommentAttribute> conditionalAppends,
  }) {
    var componentCodes = componentCodeParser
        .allMatches(
          commentPath.replaceAll(commentAttributes, ''),
          overlapping: false,
        )
        .whereType<ComponentCode>()
        .toList();

    var toAppend = ConditionalAppendCommentAttribute.componentsForNamePath(
      conditionalAppends,
      namePath,
    );
    if (conditionalAppends.isNotEmpty) {
      logger.info('!!!$conditionalAppends');
    }
    return [...componentCodes, ...toAppend];
  }

  int getColumnNumberToAdd(String commentPath) {
    final matches = ComponentCodeColumnCommentAttribute.parser.allMatches(
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
}
