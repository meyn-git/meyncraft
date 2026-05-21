import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:meyncraft/meyn_sysmac/event/comment_attribute.domain.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';

/// Copies an asset file into the app's writable data directory on first run.
/// Returns the full path to the copied file.
File additionalAttributesFile() {
  const additionalAttributesFileName = 'additional_attributes.txt';
  final exeDirectoryPath = File(Platform.resolvedExecutable).parent.path;
  if (kDebugMode) {
    return File(
      '${Directory.current.path}${Platform.pathSeparator}assets'
      '${Platform.pathSeparator}$additionalAttributesFileName',
    );
  }
  return File(
    '$exeDirectoryPath\\data\\flutter_assets\\'
    'assets%5Cadditional_attributes.txt',
  );
}

/// Creates a Map with [CommentAttribute]s that still need to be added to
/// The PLC program and standard Meyn Libraries
/// * Key:  is the [DataType] path of an event, see [createDataTypePath]
/// * Value: are [CommentAttribute] that still need to be parsed
Map<String, String> createAdditionalCommentAttributeMap() {
  var file = additionalAttributesFile();
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
