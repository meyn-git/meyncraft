import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:shouldly/shouldly.dart';

import '../../../../test_resource.dart';

void main() {
  GetIt.I.registerSingleton<Logger>(Logger());

  group('createdataTypes function', () {
    late  SysmacProjectArchive sysmacProjectArchive;
    late DataTypes dataTypes;
    setUp(() async {
      sysmacProjectArchive = await SysmacProjectArchive.create(
        SysmacProjectTestResource().file,
      );
      dataTypes = createDataTypes(sysmacProjectArchive);
    });

    test('createGlobalVariables should return correct result)', () {
      var globalVariables = createGlobalVariables(
        sysmacProjectArchive,
        dataTypes,
      );
      globalVariables.length.should.be(1729);
    });

    test(
      'createGlobalVariables should contain a GlobalEvents variable of the correct type)',
      () {
        var globalVariables = createGlobalVariables(
          sysmacProjectArchive,
          dataTypes,
        );
        var globalEvent = globalVariables.firstWhereOrNull(
          (v) => v.name == 'EventGlobal',
        );
        globalEvent.should.not.beNull();
        globalEvent!.baseType.should.beOfType<DataTypeReference>();
        (globalEvent.baseType as DataTypeReference).dataType.name.should.be(
          'sEvent',
        );
      },
    );
  });
}
