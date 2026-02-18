import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/comment_attribute.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/additional_attribute.infrastructure.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/component_code.domain.dart';
import 'package:petitparser/petitparser.dart';

const String eventGlobalVariableName = 'EventGlobal';

List<Event> createEvents(SysmacProject sysmacProject) {
  var eventGlobal = sysmacProject.globalVariables.firstWhereOrNull(
    (v) => v.name == eventGlobalVariableName,
  );
  if (eventGlobal == null) {
    logger.warning('Could not find a global variable with name: $eventGlobal');
    return [];
  }
  var eventRootNode = EventNode.fromVariable(eventGlobal);
  var counter = Counter();
  var additionalCommentAttributeMap = createAdditionalCommentAttributeMap();
  var events = eventRootNode.createEvents(
    sysmacProject,
    additionalCommentAttributeMap,
    counter,
  );
  logger.info('Found ${events.length} events');
  return events;
}

///TODO investigate if we can use DataTypeBase.findPaths instead of using EventNode.
/// Used to creates Events from [Variable] and [DataType]
class EventNode {
  final EventNode? parent;
  final String name;
  final String comment;
  final BaseType baseType;
  late final List<EventNode> children;

  EventNode.fromVariable(Variable variable)
    : parent = null,
      name = variable.name,
      // The comment of the GlobalEvent variable is not needed
      comment = '',
      baseType = variable.baseType {
    children = createChildren(this, variable.baseType);
  }

  EventNode.fromDataType(DataType dataType, [this.parent])
    : name = dataType.name,
      comment = dataType.comment,
      baseType = dataType.baseType {
    children = createChildren(this, dataType.baseType);
  }

  static List<EventNode> createChildren(EventNode parent, BaseType baseType) =>
      baseType is DataTypeReference
      ? baseType.children
            .map((c) => c as DataType)
            .map((c) => EventNode.fromDataType(c, parent))
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
    SysmacProject sysmacProject,
    Map<String, String> additionalCommentAttributeMap,
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
        var eventValues = createEventValues(
          additionalCommentAttributeMap,
          namePath,
          commentPath,
        );
        var acknowledgeNeeded = AcknowledgeAttribute.acknowledge(eventValues);
        var priority = PriorityAttribute.priority(eventValues);
        var ioAttributeVariablePaths = IoAttribute.findIoAttributeVariablePaths(
          sysmacProject,
          namePath,
          eventValues,
        );
        var variablePathWithComponentCodes =
            IoAttribute.findIoVariableNameWithComponentCodes(
              ioAttributeVariablePaths,
            );
        var variableNameWithHardwareAddress =
            IoAttribute.findIoVariableNameWithAddresses(
              ioAttributeVariablePaths,
            );
        var componentCodes = findComponentCodes(
          namePath,
          eventValues,
          //TODO change to ioVariables
          [],
        );
        var messageParts = createMessageParts(eventValues);
        var event = Event(
          number: counter.next(),
          namePath: namePath,
          group: createGroupName(namePath),
          ioVariableNamePaths: _uniqueNamePaths(
            ioAttributeVariablePaths.values,
          ).toSet().toList(),
          componentCodes: componentCodes,
          variableNameWithComponentCodes: variablePathWithComponentCodes,
          variableNameWithHardwareAddress: variableNameWithHardwareAddress,
          messageParts: messageParts,
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
              sysmacProject,
              additionalCommentAttributeMap,
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
  List<String> createMessageParts(List eventValues) {
    var rawMessage = eventValues
        .where((v) => v is String || v is num)
        .map((v) => v.toString())
        .join();
    return rawMessage
        // remove all leading dashes
        .replaceAll(RegExp(r'^(-\s*)+'), '')
        // remove all trailing dashes
        .replaceAll(RegExp(r'(-\s*)+$'), '')
        // remove all spaces before or after dashes
        .replaceAll(RegExp(r'(\s*-\s*)'), '-')
        // remove all unneeded characters
        .replaceAll(' : ', ':')
        .replaceAll(' :', ':')
        .replaceAll(': ', ':')
        .replaceAll('  ', ' ')
        .replaceAll('--', '-')
        .replaceAll(', message instead of alarm event', '')
        .trim()
        .split('-');
  }

  List<ComponentCode> findComponentCodes(
    String namePath,
    List eventValues,
    List<Variable> io,
  ) {
    var componentCodes = <ComponentCode>[];
    for (var variable in io) {
      componentCodes.addAll(componentCodeParser.allMatches(variable.comment));
    }

    componentCodes.addAll(eventValues.whereType<ComponentCode>());
    var columnAttribute = ComponentCodeAddColumnsAttribute.valueOf(
      namePath,
      eventValues,
    );
    var lettersAttribute = ComponentCodeOverrideLettersAttribute.valueOf(
      eventValues,
    );
    var pageAttribute = ComponentCodeAddPageAttribute.valueOf(eventValues);
    var result = <ComponentCode>[];
    for (var componentCode in componentCodes) {
      if (columnAttribute != null) {
        componentCode = columnAttribute.componentCode(componentCode, namePath);
      }
      if (lettersAttribute != null) {
        componentCode = lettersAttribute.componentCode(componentCode);
      }
      if (pageAttribute != null) {
        componentCode = pageAttribute.componentCode(componentCode);
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

  List<dynamic> createEventValues(
    Map<String, String> additionalCommentAttributeMap,
    String namePath,
    String commentPath,
  ) {
    var additionalAttributes = createAdditionalCommentAttributes(
      this,
      additionalCommentAttributeMap,
    );
    var result = commentPathParser.parse(additionalAttributes + commentPath);
    var values = result is Failure ? [] : result.value;
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

  Iterable<String> _uniqueNamePaths(Iterable<NodePath> nodePaths) => nodePaths
      .map((nodePath) => nodePath.map((node) => node.name).join('.'))
      .toSet();
}
