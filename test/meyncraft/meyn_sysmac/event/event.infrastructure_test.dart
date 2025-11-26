import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:shouldly/shouldly.dart';

import '../../../test_resource.dart';

Future<void> main() async {
  GetIt.I.registerSingleton<Logger>(Logger());
  File file = SysmacProjectTestResource().file;
  var sysmacProject = await MeynSysmacProject.create(file);

  group('class: EventService', () {
    test('events isNot Empty', () {
      var events = sysmacProject.events;
      events.should.not.beEmpty();
    });

    test('there should be 1 "EventGlobal.Common.Alarm0" name path', () {
      var eventGlobal = sysmacProject.globalVariables.firstWhere(
        (v) => v.name == 'EventGlobal',
      );
      var eventGlobalCommon = eventGlobal.children.firstWhere(
        (v) => v.name == 'Common',
      );
      var eventGlobalCommonAlarm0 = eventGlobalCommon.children.firstWhere(
        (v) => v.name == 'Alarm0',
      );
      var baseType = (eventGlobalCommonAlarm0 as DataType).baseType;
      baseType.arrayRanges.should.beEmpty();
    });
  });
}
