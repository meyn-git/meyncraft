import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/sysmac/internal/device/device.infrastructure.dart';
import 'package:meyncraft/sysmac/internal/device/nj_plc/nj_plc.domain.dart';
import 'package:meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:shouldly/shouldly.dart';

import '../../../../test_resource.dart';

void main() {
  group('On a sysmac project', () {
    late SysmacProject sysmacProject;
    setUp(() async {
      sysmacProject = await SysmacProject.create(
        SysmacProjectTestResource().file,
      );
    });
    test('calling createDevices should return correct reply', () {
      var devices = createDevices(sysmacProject);

      devices.length.should.be(7);
      devices[0].should.beOfType<NjPlc>();
      devices[0].name.should.be('EVI1_PLC');
      devices[1].should.beOfType<NesSafetyPlc>();
      devices[1].name.should.be('Safety');
      devices[2].should.beOfType<NaHmi>();
      devices[2].name.should.be('EVI1_HMI1_UNUSED');
      devices[3].should.beOfType<NaHmi>();
      devices[3].name.should.be('EVI1_VET1_NX');
      devices[4].should.beOfType<NaHmi>();
      devices[4].name.should.be('EVI1_VET2_NX');
      devices[5].should.beOfType<NaHmi>();
      devices[5].name.should.be('EVI1_VET1_CJ');
      devices[6].should.beOfType<NaHmi>();
      devices[6].name.should.be('EVI1_VET2_CJ');
    });
  });
}
