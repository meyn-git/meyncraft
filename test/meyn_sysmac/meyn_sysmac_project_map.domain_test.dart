import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project_map.domain.dart';
import 'package:shouldly/shouldly.dart';
import 'package:get_it/get_it.dart';

import '../test_resource.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('MeynSysmacProjectMap class', () {
    late Map<String, dynamic> map;

    setUp(() async {
      await getIt.reset();
      var sysmacProject = await MeynSysmacProject.loadFromFile(
        SysmacProjectTestResource().file,
      );
      map = MeynSysmacProjectMap(sysmacProject);
    });

    test('Test MeynSysmacProjectMap.globalVariables', () async {
      var globalVariables =
          map[MeynSysmacProjectMap.globalVariablesKey] as List<dynamic>;
      Should.satisfyAllConditions([
        () => globalVariables.should.haveCount(1725),
        () => globalVariables.first.toString().should.be(
          "{name: LineNumber, comment: , networkPublish: publicationOnly, "
          "baseType: {type: IecType, name: STRING}, hardwareAddress: null, "
          "direction: null, isRetained: true, isConstant: false, "
          "initialValue: null}",
        ),
        () => globalVariables.last.toString().should.be(
          "{name: iVentCutCamPosPairedNodes, comment: , "
          "networkPublish: doNotPublish, baseType: {type: IecType, name: UINT}, "
          "hardwareAddress: ECAT://node#70/Transmit PDO Mapping_Paired "
          "nodes_203C_00, direction: null, isRetained: false, "
          "isConstant: false, initialValue: null}",
        ),
      ]);
    });

    test('Test MeynSysmacProjectMap.dataTypes', () async {
      var dataTypes =
          map[MeynSysmacProjectMap.dataTypesKey] as List<Map<String, dynamic>>;
      Should.satisfyAllConditions([
        () => dataTypes.should.haveCount(32),
        () => dataTypes.first.toString().should.be(
          "{type: Enumeration, name: eModuleCtrl, comment: , children: ["
          "{type: EnumerationMember, name: ONE_POS_NO_MOTOR, comment: , index: 0, baseType: {type: IecType, name: DINT}}, "
          "{type: EnumerationMember, name: TWO_POS_NO_MOTOR, comment: , index: 1, baseType: {type: IecType, name: DINT}}, "
          "{type: EnumerationMember, name: ONE_POS_WITH_MOTOR, comment: , index: 2, baseType: {type: IecType, name: DINT}}, "
          "{type: EnumerationMember, name: TWO_POS_WITH_MOTOR, comment: , index: 3, baseType: {type: IecType, name: DINT}}"
          "]}",
        ),
        () => dataTypes[18].toString().should.be(
          "{type: Enumeration, name: eIoLinkModule, comment: IO-Link module type"
          ", children: [{type: EnumerationMember, name: NOT_PRESENT, "
          "comment: Not present, index: 0, baseType: {type: IecType, name: DINT}}, "
          "{type: EnumerationMember, name: ETA_EM12D_TIO, comment: "
          "ETA Fuse group, index: 1, baseType: {type: IecType, name: DINT}}, "
          "{type: EnumerationMember, name: PHOENIX_CAPAROC_PM_IOL, "
          "comment: Phoenix Fuse group, index: 2, baseType: "
          "{type: IecType, name: DINT}}, "
          "{type: EnumerationMember, name: TURCK_IMX12_CCM, "
          "comment: Turck cabinet guard cabinet monitor, index: 3, "
          "baseType: {type: IecType, name: DINT}}, "
          "{type: EnumerationMember, name: STEGO_CSS_01411_2_00, "
          "comment: Stego cabinet monitor v2.00, index: 4, "
          "baseType: {type: IecType, name: DINT}}, "
          "{type: EnumerationMember, name: STEGO_CSS_01411_2_01, "
          "comment: Stego cabinet monitor v2.01, index: 5, "
          "baseType: {type: IecType, name: DINT}}]}",
        ),
      ]);
    });
  });
}
