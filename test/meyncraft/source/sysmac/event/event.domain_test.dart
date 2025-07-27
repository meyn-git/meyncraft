import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.infrastructure.dart';

import '../../../../test_resource.dart';

void main() {
  GetIt.I.registerSingleton<Logger>(Logger());
  File file = SysmacProjectTestResource().file;
  var sysmacProject = SysmacProjectFactory().create(file);

  group('class: EventService', () {
    test('variables isNot Empty', () {
      var result = sysmacProject.eventService.events;
      expect(result.isNotEmpty, true);
    });
  });
}
