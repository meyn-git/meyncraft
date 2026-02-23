import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/generate/exor_jmobile/tags_file.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:shouldly/shouldly.dart';

import '../../../test_resource.dart';

void main() {
  group('function: createTags', () {
    GetIt.I.registerSingleton<Logger>(Logger());
    late SysmacProject sysmacProject;

    setUp(() async {
      sysmacProject = await SysmacProject.create(
        SysmacProjectTestResource().file,
      );
    });
    test('Should return tags', () {
      var variables = sysmacProject.globalVariables;
      List<ExorTag> tags = createTags(variables);
      tags.length.should.be(12530);
    });

    test('Should contain HmiGlobal', () {
      var variables = sysmacProject.globalVariables;
      List<ExorTag> tags = createTags(variables);
      var tagNames = tags.map((tag) => tag.name);
      tagNames.should.any((name) => name.startsWith('HmiGlobal'));
    });
  });
}
