import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/nj_plc.domain.dart';
import 'package:meyncraft/sysmac/internal/variable/variable.domain.dart';

/// Creates a first draft for a additional comment attributes file
/// by analyzing a [SysmacProject].
/// See: lib\meyncraft\meyn_sysmac\event\additional_attribute_new.txt
/// These files are a temporary solution until all dataType event structures
/// In the PLC program and standard libraries have gotten additional [CommentAttribute]s

/// FIXME remove this when no longer needed
Future<void> main(List<String> args) async {
  var file = File(r'test\9062DE02-Evisceration-021-002.smc2');
  var project = await MeynSysmacProject.loadFromFile(file);
  await writeSysmacEventArrayXmlImportFile(project);
  exit(0);
}

Future<void> writeSysmacEventArrayXmlImportFile(
  MeynSysmacProject sysmacProject,
) async {
  var plcs = sysmacProject.devices.whereType<NjPlc>().toList();
  var functions = filterMap<Function$>(
    mergeMap<Function$>(plcs.map((p) => p.allFunctions)),
  );
  var functionBlocks = filterMap<FunctionBlock>(
    mergeMap<FunctionBlock>((plcs.map((p) => p.allFunctionBlocks))),
  );

  var codeOwners = <CodeOwner>{...functions.keys, ...functionBlocks.keys};

  var lines = StringBuffer();
  for (var codeOwner in codeOwners) {
    for (var function in functions[codeOwner] ?? <Function$>[]) {
      lines.writeln(write(codeOwner, function.name, function.inOutVariables));
    }
    for (var functionBlock in functionBlocks[codeOwner] ?? <FunctionBlock>[]) {
      lines.writeln(
        write(codeOwner, functionBlock.name, functionBlock.inOutVariables),
      );
    }
  }

  // var file = createOutputFile(sysmacProject, '-Sysmac-Events-DefaultAttributes.txt');
  // file.createSync(recursive: true);
  // file.writeAsStringSync(lines.toString());
  print(lines.toString());
}

String write(CodeOwner codeOwner, String name, List<Variable> variables) {
  var lines = StringBuffer();
  lines.writeln('# Code owner: ${codeOwner.name}');
  lines.writeln('# function (block): $name');

  var eventOutputs = variables.where(isEventOutput);
  var remainingVariables = variables.where((e) => !isEventOutput(e)).toList();
  var inVarNames = remainingVariables
      .where((v) => v.direction == VariableDirection.in$)
      .map((v) => v.name);
  lines.writeln('# in: ${inVarNames.join(', ')}');

  var outVarNames = remainingVariables
      .where((v) => v.direction == VariableDirection.out)
      .map((v) => v.name);
  lines.writeln('# out: ${outVarNames.join(', ')}');

  var inOutVarNames = remainingVariables
      .where((v) => v.direction == VariableDirection.inOut)
      .map((v) => v.name);
  lines.writeln('# in/out: ${inOutVarNames.join(', ')}');

  for (var eventOutput in eventOutputs) {
    var dataTypeMember = (eventOutput.baseType as DataTypeMember);
    var dataTypeReference = (dataTypeMember.baseType as DataTypeReference);
    var parentPath = dataTypeReference.dataTypePath.toNamePath().join(r'\');
    for (var child in dataTypeMember.children) {
      var dataTypePath = '$parentPath\\${child.name}';
      var attributes = createAttributes(
        dataTypePath,
        remainingVariables,
      ).join();
      lines.writeln([dataTypePath, attributes].join('='));
    }
  }

  return lines.toString();
}

List<String> createAttributes(String dataTypePath, List<Variable> variables) {
  var attributes = <String>[];
  if (dataTypePath.startsWith(r'Equipment\') &&
      dataTypePath.endsWith(r'\sEvent\StopTimeOut')) {
    attributes.add('[noAck]');
  }
  if (dataTypePath == r'Safety\sEventInDualChannel\RstReq') {
    attributes.add('[noAck]');
    attributes.add('[prio=info]');
  }
  if (dataTypePath == r'Safety\sEventInDualChannel\Active') {
    attributes.add('[noAck]');
  }
  if (dataTypePath == r'Safety\sEventInDualChannel\ActiveWarning') {
    attributes.add('[noAck]');
    attributes.add('[prio=info]');
  }
  if (dataTypePath.startsWith(r'Cm\StartStopCtrl')) {
    attributes.add('[noAck]');
    attributes.add('[prio=info]');
  }
  if (dataTypePath.startsWith(r'Safety\sEvent') &&
      !attributes.contains('[prio=info]')) {
    attributes.add('[prio=critical]');
  }

  var ioAttributes = findComparableIoAttributes(dataTypePath, variables);
  attributes.addAll(ioAttributes);

  return attributes;
}

List<String> findComparableIoAttributes(
  String dataTypePath,
  List<Variable> variables,
) {
  var nameToFind = dataTypePath.split(r'\').last;
  var foundVariables = variables.where((v) => comparable(nameToFind, v.name));
  var attributes = foundVariables.map((v) => '[io=${v.name}]').toList();
  return attributes;
}

bool comparable(String name1, String name2) {
  var longestSequentialMatch2 = longestSequentialMatch(
    name1.toLowerCase(),
    name2.toLowerCase(),
  );
  return longestSequentialMatch2 >= (name1.length + name2.length) / 4;
}

Map<CodeOwner, List<T>> mergeMap<T>(Iterable<Map<CodeOwner, List<T>>> maps) {
  var mergedMap = <CodeOwner, List<T>>{};
  for (var map in maps) {
    for (var key in map.keys) {
      if (mergedMap[key] == null) {
        mergedMap[key] = map[key]!;
      } else {
        mergedMap[key] = [...mergedMap[key]!, ...map[key]!];
      }
    }
  }
  return mergedMap;
}

Map<CodeOwner, List<T>> filterMap<T>(Map<CodeOwner, List<T>> map) {
  var filteredMap = <CodeOwner, List<T>>{};
  for (var key in map.keys) {
    var objects = map[key]!.where((e) => include(e)).toList();
    filteredMap[key] = objects;
  }
  return filteredMap;
}

bool include(dynamic fun) {
  if (fun is Function$) {
    return hasEventsOutput(fun.inOutVariables);
  }
  if (fun is FunctionBlock) {
    return hasEventsOutput(fun.inOutVariables);
  }
  return false;
}

bool hasEventsOutput(List<Variable> variables) => variables.any(isEventOutput);

bool isEventOutput(Variable variable) =>
    (variable.direction == VariableDirection.inOut ||
        variable.direction == VariableDirection.out) &&
    variable.baseType is DataTypeMember &&
    (variable.baseType as DataTypeMember).baseType is DataTypeReference &&
    ((variable.baseType as DataTypeMember).baseType as DataTypeReference)
        .dataTypePath
        .toNamePath()
        .contains('sEvent');

File createOutputFile(MeynSysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.identity.projectFile;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}

int longestSequentialMatch(String word1, String word2) {
  int maxMatch = 0;

  for (int startIndex1 = 0; startIndex1 < word1.length; startIndex1++) {
    for (int startIndex2 = 0; startIndex2 < word2.length; startIndex2++) {
      int count = 0;
      int index1 = startIndex1;
      int index2 = startIndex2;

      // Count continuous matching characters
      while (index1 < word1.length &&
          index2 < word2.length &&
          word1[index1] == word2[index2]) {
        count++;
        index1++;
        index2++;
      }

      if (count > maxMatch) {
        maxMatch = count;
      }
    }
  }

  return maxMatch;
}
