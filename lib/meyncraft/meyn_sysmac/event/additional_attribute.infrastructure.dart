import 'dart:io';

import 'package:meyncraft/meyncraft/meyn_sysmac/event/comment_attribute.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';

/// Old style where we dit not have [IoAttribute]s
var oldAdditionalCommentAttributeMap = _createAdditionalCommentAttributeMap(
  r'lib\meyncraft\meyn_sysmac\event\additional_attribute_old.txt',
);

/// New style where we try to get the component codes and PLC addresses
/// using the parameters of function block calls
var newAdditionalCommentAttributeMap = _createAdditionalCommentAttributeMap(
  r'lib\meyncraft\meyn_sysmac\event\additional_attribute_new.txt',
);

/// Creates a Map with [CommentAttribute]s that still need to be added to
/// The PLC program and standard Meyn Libraries
/// * Key:  is the [DataType] path of an event, see [createDataTypePath]
/// * Value: are [CommentAttribute] that still need to be parsed
Map<String, String> _createAdditionalCommentAttributeMap(String filePath) {
  var file = File(filePath);
  var input = file.readAsStringSync();

  final Map<String, String> result = {};

  // Split by lines and iterate
  final lines = input.split('\n');
  for (var line in lines) {
    line = line.trim();

    if (_skipLine(line)) continue;

    // Match pattern: key=value
    if (line.contains('=')) {
      final eqIndex = line.indexOf('=');
      final key = line.substring(0, eqIndex).trim();
      final value = line.substring(eqIndex + 1).trim();
      result[key] = value;
    }
  }
  return result;
}

bool _skipLine(String line) => line.isEmpty || line.startsWith('#');

String createAdditionalCommentAttributes(
  EventNode eventNode,
  Map<String, String> commentAttributeMap,
) {
  var dataTypePath = createDataTypePath(eventNode);
  var attributes = commentAttributeMap[dataTypePath] ?? '';
  return attributes;
}

String? createDataTypePath(EventNode eventNode) {
  if (eventNode.baseType is! NxBool) {
    return null;
  }
  var parent = eventNode.parent;
  if (parent == null) {
    return null;
  }
  if (parent.baseType is! DataTypeReference) {
    return null;
  }
  return '${(parent.baseType as DataTypeReference).namePathWithBackSlashes}\\${eventNode.name}';
}
