import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.infrastructure.dart';

import '../../../test_resource.dart';

void main() {
  GetIt.I.registerSingleton<Logger>(Logger());

  group('class: $SysmacProjectFactory', () {
    group('constructor', () {
      test('path without extension should throw error', () {
        expect(
          () => SysmacProjectFactory().create(File('sysmacProjectFile')),
          throwsA(
            predicate(
              (e) =>
                  e is ArgumentError &&
                  e.message == 'does not end with .smc2 extension',
            ),
          ),
        );
      });
      test('path that does not exist should throw error', () {
        expect(
          () => SysmacProjectFactory().create(
            File('sysmacProjectFile.${SysmacProjectArchive.extension}'),
          ),
          throwsA(
            predicate(
              (e) =>
                  e is ArgumentError &&
                  e.message ==
                      'does not point to a existing Sysmac project file',
            ),
          ),
        );
      });
      test('Successful creation using a correct path', () {
        File file = SysmacProjectTestResource().file;
        expect(
          SysmacProjectFactory().create(file).toString(),
          'Instance of \'$SysmacProject\'',
        );
      });
    });

    File file = SysmacProjectTestResource().file;
    var sysmacProjectFile = SysmacProjectFactory().create(file);

    group('property: dataTypeTree', () {
      test('finds populated dataTypeTree', () {
        var dataTypeTree = sysmacProjectFile.dataTypeTree;
        expect(dataTypeTree.children.length, 330);
      });
    });

    group('property: globalVariableService', () {
      test('finds globalVariableService with variable', () {
        var globalVariableService = sysmacProjectFile.globalVariableService;
        expect(globalVariableService.variables.length, 173);
      });
    });
  });
}
