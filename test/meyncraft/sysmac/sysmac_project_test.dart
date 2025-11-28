import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';

import '../../test_resource.dart';

void main() {
  GetIt.I.registerSingleton<Logger>(Logger());

  group('class: $SysmacProject', () {
    group('create() method', () {
      test('path without extension should throw error', () {
        expect(
          () async => await SysmacProject.create(File('sysmacProjectFile')),
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
          () async => await SysmacProject.create(
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
      test('Successful creation using a correct path', () async {
        File file = SysmacProjectTestResource().file;
        expect(
          (await SysmacProject.create(file)).toString(),
          'Instance of \'$SysmacProject\'',
        );
      });
    });
    late SysmacProject sysmacProjectFile;
    setUp(() async {
      late File file = SysmacProjectTestResource().file;
      sysmacProjectFile = await SysmacProject.create(file);
    });
    group('property: dataTypes', () {
      test('finds populated dataTypes', () {
        var dataTypePaths = sysmacProjectFile.dataTypes.findAllNodePaths(
          leafPathsFinder(),
        );
        expect(dataTypePaths.length, 53260);
      });
    });

    group('property: globalVariables', () {
      test('finds globalVariableService with variable', () {
        expect(sysmacProjectFile.globalVariables.length, 1729);
      });
    });
  });
}
