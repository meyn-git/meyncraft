import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';

import '../../../../test_resource.dart';

void main() {
  File file = SysmacProjectTestResource().file;
  var sysmacProject = SysmacProjectFactory().create(file);
  var variableService = sysmacProject.globalVariableService;

  group('group name', () {});
  (
    'class: $GlobalVariableService',
    () {
      group('field: globalVariables', () {
        var results = variableService.variablesOld;
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
        var results = variableService.findVariablesWithEventGlobalName();
        test('contains one variable with $eventGlobalVariableName', () {
          expect(results, hasLength(1));
          expect(results[0].name, eventGlobalVariableName);
          expect(results[0].baseType, isA<DataTypeReference>());
          expect(results[0].children.isNotEmpty, true);
          expect(
            (results[0].baseType as DataTypeReference).dataType.baseType,
            isA<Struct>(),
          );
        });
      });
    },
  );
}
