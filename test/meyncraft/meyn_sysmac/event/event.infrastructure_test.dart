import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
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
      var globalVariables = sysmacProject.globalVariables;
      var eventPath = globalVariables.findFirstNodePath(
        namePathFinder(['EventGlobal', 'Common', 'Alarm0']),
      );
      eventPath.should.not.beEmpty();
      eventPath.last.name.should.be('Alarm0');
      eventPath.last.should.beOfType<DataType>();
      (eventPath.last as DataType).baseType.should.beOfType<IecBool>();
    });
  });

  group('function: eventPathFinder', () {
    test('eventPathFinder should return the correct NodePathWithIndexes', () {
      // FIXME
      // var eventGlobal = sysmacProject.globalVariables.firstWhereOrNull(
      //   (v) => v.name == eventGlobalVariableName,
      // );
      // var eventPaths = eventGlobal.findAllNodePaths<NodePathWithIndexes>(
      //   eventPathFinder(),
      // );
      // var eventExpressions = eventPaths.map(
      //   (eventPath) => eventPath.namePathWithArrayIndexes.join('.'),
      // );

      var events = sysmacProject.events;
      var eventExpressions = events.map((e) => e.namePath).toList();

      eventExpressions.should.contain(
        'EventGlobal.VentCutCamPosGateway.GatewayCommTimeout',
      );
      eventExpressions.should.not.contain(
        'EventGlobal.VentCutCamPosGateway.NodeCommTimeout[0]',
      );
      eventExpressions.should.contain(
        'EventGlobal.VentCutCamPosGateway.NodeCommTimeout[5]',
      );
      eventExpressions.should.contain(
        'EventGlobal.VentCutCamPosGateway.NodeCommTimeout[15]',
      );
      eventExpressions.should.not.contain(
        'EventGlobal.VentCutCamPosGateway.NodeBatteryLow[0]',
      );
      eventExpressions.should.contain(
        'EventGlobal.VentCutCamPosGateway.NodeBatteryLow[5]',
      );
      eventExpressions.should.contain(
        'EventGlobal.VentCutCamPosGateway.NodeBatteryLow[15]',
      );
    });
  });
}
