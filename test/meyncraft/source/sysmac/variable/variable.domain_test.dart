import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';

import '../../../../test_resource.dart';

Future<void> main() async {
  GetIt.I.registerSingleton<Logger>(Logger());
  File file = SysmacProjectTestResource().file;
  var sysmacProject = await SysmacProject.create(file);
  var variableService = sysmacProject.globalVariableService;

  group('class: $GlobalVariableService', () {
    group('field: globalVariables', () {
      var results = variableService.variables;
      test('variables isNot Empty', () {
        expect(results, isNotEmpty);
      });
    });
    group('method: findVariablesByName', () {
      var nameToFind = 'LineNumber';
      var results = variableService.findVariablesByName(nameToFind);
      test('contains one variable with $nameToFind', () {
        expect(results, hasLength(1));
      });
    });
    group('method: findVariablesWithEventsGlobalName', () {
      var results = variableService.findVariablesByName('EventGlobal');
      test('contains one variable with $eventGlobalVariableName', () {
        expect(results, hasLength(1));
        expect(results[0].name, eventGlobalVariableName);
        expect(results[0].baseType, isA<DataTypeReference>());
        expect(
          (results[0].baseType as DataTypeReference).dataType.baseType,
          isA<Struct>(),
        );
      });
    });
  });
}
