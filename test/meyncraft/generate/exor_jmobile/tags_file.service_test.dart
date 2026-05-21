import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/template/custom/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:shouldly/shouldly.dart';

import '../../../test_resource.dart';

void main() {
  group('function: createTags', () {
    late SysmacProject sysmacProject;

    setUp(() async {
      sysmacProject = await SysmacProject.create(
        SysmacProjectTestResource().file,
      );
    });
    test('Should return tags', () {
      var tags = createTags(sysmacProject);
      tags.length.should.be(12606);
    });

    test('Should contain HmiGlobal', () {
      Iterable<ExorTag> tags = createTags(sysmacProject);
      var tagNames = tags.map((tag) => tag.name);
      tagNames.should.any((name) => name.startsWith('HmiGlobal'));
    });
  });
}
