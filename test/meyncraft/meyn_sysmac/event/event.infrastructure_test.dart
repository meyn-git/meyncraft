import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.infrastructure.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:shouldly/shouldly.dart';

import '../../../test_resource.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  group('class: EventService', () {
    late MeynSysmacProject sysmacProject;

    setUp(() async {
      await getIt.reset();
      sysmacProject = await MeynSysmacProject.loadFromFile(
        SysmacProjectTestResource().file,
      );
      if (!getIt.isRegistered<Logger>()) {
        getIt.registerSingleton<Logger>(Logger());
      }
    });

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
      eventPath.last.should.beOfType<DataTypeMember>();
      (eventPath.last as DataTypeMember).baseType.should.beOfType<IecBool>();
    });

    test('EventGlobal.Safety.i210S1Estp.Active" should be correct', () {
      var event = sysmacProject.events.firstWhereOrNull(
        (event) => event.namePath == 'EventGlobal.Safety.i210S1Estp.Active',
      );
      event.should.not.beNull();
      event!.componentCodesAndMessage.should.be(
        '210S1 Satellite panel-Emergency stop-Activated',
      );
    });

    test('eventPathFinder should return the correct NodePathWithIndexes', () {
      var eventGlobal = sysmacProject.globalVariables.firstWhere(
        (v) => v.name == eventGlobalVariableName,
      );
      var eventPaths = eventGlobal.findAllNodePaths<NodePathWithIndexes>(
        eventPathFinder(),
      );
      var eventExpressions = eventPaths.map(
        (eventPath) => eventPath.toNamePathWithArrayIndexes().join('.'),
      );

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
      eventExpressions.should.contain('EventGlobal.BirdBrushMtr[1].MtrSw');
      eventExpressions.should.contain('EventGlobal.BirdBrushMtr[2].MtrSw');
    });
  });
}
