import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:shouldly/shouldly.dart';

import '../../../../test_resource.dart';

void main() {
  GetIt.I.registerSingleton<Logger>(Logger());

  group('createGlobalVariables(_archive, dataTypeTree) function', () {
    late final SysmacProjectArchive sysmacProjectArchive;
    late final DataTypeTree dataTypeTree;
    setUp(() async {
      sysmacProjectArchive = await SysmacProjectArchive.create(
        SysmacProjectTestResource().file,
      );
      dataTypeTree = DataTypeTreeFactory().create(sysmacProjectArchive);
    });

    test('createGlobalVariables(0 should return correct result)', () {
      var globalVariables = createGlobalVariables(
        sysmacProjectArchive,
        dataTypeTree,
      );
      globalVariables.length.should.be(1729);
    });
  });
}
