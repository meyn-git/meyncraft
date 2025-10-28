import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/pou/pou.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:shouldly/shouldly.dart';

import '../../../../test_resource.dart';

void main() {
  group('On a sysmac project', () {
    late SysmacProjectArchive sysmacProjectArchive;
    setUp(() async {
      sysmacProjectArchive = await SysmacProjectArchive.create(
        SysmacProjectTestResource().file,
      );
    });
    test('calling createPous should return correct reply', () {
      var pous = createPous(sysmacProjectArchive);
      for (var pou in pous) {
        print(pou);
      }

      pous.length.should.be(27); //todo VERIFY
    });
  });
}
