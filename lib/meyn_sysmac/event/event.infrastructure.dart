import 'package:collection/collection.dart';
import 'package:meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyn_sysmac/event/comment_attribute.domain.dart';
import 'package:meyncraft/meyn_sysmac/event/additional_attribute.infrastructure.dart';
import 'package:meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/sysmac/node.domain.dart';
import 'package:meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyn_sysmac/event/component_code.domain.dart';
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
  var eventPaths = eventGlobal.findAllNodePaths<NodePathWithIndexes>(
    eventPathFinder(),
  );
  var counter = Counter();
  var additionalCommentAttributeMap = createAdditionalCommentAttributeMap();
  var events = eventPaths
      .map(
        (eventPath) => createEvent(
          sysmacProject,
          counter,
          eventPath,
          additionalCommentAttributeMap,
        ),
      )
      .toList();
  logger.info('Found ${events.length} events');
  return events;
}

bool isLeafNode(Node<Node<dynamic>> node) => node.children.isEmpty;

bool isDataTypeRefWithBaseTypeBoolOrArrayOfBool(Node<Node<dynamic>> node) {
  if (node is! DataTypeMember) {
    return false;
  }
  var baseType = node.baseType;
  return baseType is IecBool ||
      baseType is ArrayType && baseType.baseType is IecBool;
}

/// recursive function to find all [NodePathWithIndexes] within a node that represent an event
NodePathsFinder<NodePathWithIndexes> eventPathFinder({
  NodePathWithIndexes precedingPath = const NodePathWithIndexes.empty(),
}) => (Node node) {
  var eventsPaths = _createEventPaths(precedingPath, node);

  if (isLeafNode(node)) {
    if (isDataTypeRefWithBaseTypeBoolOrArrayOfBool(node)) {
      return eventsPaths;
    } else {
      return [];
    }
  }

  var eventPathsFromChildren = <NodePathWithIndexes>[];
  for (var eventPath in eventsPaths) {
    var finder = eventPathFinder(precedingPath: eventPath);
    for (var child in node.children) {
      var eventPathsFromChild = finder(child as Node);
      if (eventPathsFromChild.isNotEmpty) {
        eventPathsFromChildren.addAll(eventPathsFromChild);
      }
    }
  }
  return eventPathsFromChildren;
};

List<NodePathWithIndexes> _createEventPaths(
  NodePathWithIndexes precedingPath,
  Node<Node<dynamic>> node,
) {
  var indexValues = _createIndexValues(node);
  if (indexValues.isEmpty) {
    return [
      NodePathWithIndexes(
        [...precedingPath, node],
        [...precedingPath.arrayIndexes, null],
      ),
    ];
  } else {
    return indexValues
        .map(
          (arrayIndexValue) => NodePathWithIndexes(
            [...precedingPath, node],
            [...precedingPath.arrayIndexes, arrayIndexValue],
          ),
        )
        .toList();
  }
}

List<String> _createIndexValues(Node<Node<dynamic>> node) {
  if (node is! DataTypeMember) {
    return [];
  }
  var baseType = node.baseType;
  if (baseType is ArrayType) {
    return baseType.arrayRanges.toStringList();
  } else {
    return [];
  }
}

Event createEvent(
  SysmacProject sysmacProject,
  Counter counter,
  NodePathWithIndexes eventPath,
  Map<String, String> additionalCommentAttributeMap,
) {
  var namePathWithArrayIndexes = eventPath.toNamePathWithArrayIndexes().join(
    '.',
  );
  var eventValues = createEventValues(additionalCommentAttributeMap, eventPath);
  var acknowledgeNeeded = AcknowledgeAttribute.acknowledge(eventValues);
  var priority = PriorityAttribute.priority(eventValues);
  var ioAttributeVariablePaths = IoAttribute.findIoAttributeVariablePaths(
    sysmacProject,
    namePathWithArrayIndexes,
    eventValues,
  );
  var variablePathWithComponentCodes =
      IoAttribute.findIoVariableNameWithComponentCodes(
        ioAttributeVariablePaths,
      );
  var variableNameWithHardwareAddress =
      IoAttribute.findIoVariableNameWithAddresses(ioAttributeVariablePaths);

  //TODO change to ioVariables
  var componentCodes = findComponentCodes(
    namePathWithArrayIndexes,
    eventValues,
    [],
  );

  var messageParts = createMessage(eventValues).split('-');
  return Event(
    number: counter.next(),
    namePath: namePathWithArrayIndexes,
    group: createGroupName(namePathWithArrayIndexes),
    ioVariableNamePaths: _uniqueNamePaths(ioAttributeVariablePaths.values),
    componentCodes: componentCodes,
    variableNameWithComponentCodes: variablePathWithComponentCodes,
    variableNameWithHardwareAddress: variableNameWithHardwareAddress,
    messageParts: messageParts,
    priority: priority,
    acknowledgeRequired: acknowledgeNeeded,
  );
}

List<dynamic> createEventValues(
  Map<String, String> additionalCommentAttributeMap,
  NodePathWithIndexes eventPath,
) {
  var additionalAttributes = findAdditionalCommentAttributes(
    additionalCommentAttributeMap,
    eventPath,
  );
  // skipping the namePath of the InterfaceGlobal variable
  var namePath = eventPath.toNamePathWithArrayIndexes().skip(1).join('.');
  // skipping the comment of the InterfaceGlobal variable
  var commentPath = eventPath.toCommentPath().skip(1).join('-');
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

String findAdditionalCommentAttributes(
  Map<String, String> commentAttributeMap,
  NodePathWithIndexes eventPath,
) {
  var key = createDataTypePathWithoutIndexes(eventPath);
  var attributes = commentAttributeMap[key] ?? '';
  return attributes;
}

// returns null if there is none
String? createDataTypePathWithoutIndexes(NodePath eventPath) {
  if (eventPath.length <= 1) return null;
  var parentIndex = eventPath.length - 2;
  var parent = eventPath[parentIndex];
  if (parent is! DataTypeMember) return null;
  var baseType = parent.baseType;
  if (baseType is ArrayType) {
    baseType = baseType.baseType;
  }
  if (baseType is! DataTypeReference) return null;
  var dataTypePath = baseType.dataTypePath;
  return '${dataTypePath.toNamePath().join(r'\')}\\${eventPath.last.name}';
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

/// normalizes the commentPath to a message.
String createMessage(List eventValues) {
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
      .trim();
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

Iterable<String> _uniqueNamePaths(Iterable<NodePath> nodePaths) => nodePaths
    .map((nodePath) => nodePath.map((node) => node.name).join('.'))
    .toSet();
