import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';

import '../../../../test_resource.dart';

Future<void> main() async {
  GetIt.I.registerSingleton<Logger>(Logger());
  File file = SysmacProjectTestResource().file;
  var sysmacProject = await SysmacProject.create(file);

  group('class: EventService', () {
    test('variables isNot Empty', () {
      var result = sysmacProject.eventService.events;
      expect(result.isNotEmpty, true);
    });
  });
}
