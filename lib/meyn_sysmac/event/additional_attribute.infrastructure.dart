import 'package:flutter/services.dart';
import 'package:meyncraft/meyn_sysmac/event/comment_attribute.domain.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';

/// Creates a Map with [CommentAttribute]s that still need to be added to
/// The PLC program and standard Meyn Libraries
/// * Key:  is the [DataType] path of an event, see [createDataTypePath]
/// * Value: are [CommentAttribute] that still need to be parsed
/// TODO It would be better to put this information in the Meyn sysmac libraries once everyone agrees this is the way forward.
Future<Map<String, String>> createAdditionalCommentAttributeMap() async {
  var input = await rootBundle.loadString('assets/additional_attributes.txt');

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
