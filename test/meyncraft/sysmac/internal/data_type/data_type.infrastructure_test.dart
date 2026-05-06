import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:shouldly/shouldly.dart';

import '../../../../test_resource.dart';

const String xml = """<?xml version="1.0" encoding="utf-8"?>
<data>
    <DataType Name="" BaseType="" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="">
<DataType Name="sEvent" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Event" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="148" OffsetType="CJ" Id="0ef73b17-8f7a-4af7-984b-414c9c1027c0">
<DataType Name="StopTimeOut" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Stop time out" OffsetChannel="0" OffsetBit="0" IsControllerDefinedType="false" Order="0" OffsetType="" Id="e6049547-4d4d-4a8d-a4b1-343e9baa116c"/>
<DataType Name="AlmName1" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Alarm text 1" OffsetChannel="0" OffsetBit="1" IsControllerDefinedType="false" Order="0" OffsetType="" Id="23c68f38-10d5-43a0-8b50-3a5c304a5195"/>
</DataType>
<DataType Name="sInterface" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Interface" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="127" OffsetType="NJ" Id="4a42ce20-5f99-4c0c-b9f5-6c1ad2fad8e0">
<DataType Name="PackML" BaseType="Generic\\Equipment\\sPackML" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="PackML" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="b6e1a262-dcfb-4ac5-9838-c75c170480fd"/>
<DataType Name="Unit" BaseType="Generic\\Equipment\\sInterface" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Unit &lt;> equipment" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="60ad66b6-e2ea-46a8-bcc7-b2494a5c0aba"/>
<DataType Name="Cmd" BaseType="Equipment\\Deskinner\\sInterfaceCmd" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Command" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="5e57a062-33aa-4182-b3f9-ad2df80c90b4"/>
<DataType Name="Sts" BaseType="Equipment\\Deskinner\\sInterfaceSts" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Status" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="30256571-e73e-429a-aec4-2b7bbe12efc3"/>
</DataType>
<DataType Name="sInterfaceCmd" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Command" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="66" OffsetType="NJ" Id="f7f359de-00de-42db-80ea-36ca9a215f7a">
<DataType Name="Command0" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="ee3826b5-b5bd-4d52-a605-2bf3b411b0cd"/>
</DataType>
<DataType Name="sInterfaceSts" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Status" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="65" OffsetType="NJ" Id="feb53ce1-9caf-40da-93b1-bc49cbb98471">
<DataType Name="Status0" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="d597da07-287b-4154-accc-c570dfdf3f3d"/>
</DataType>
<DataType Name="sConfig" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Configuration" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="138" OffsetType="NJ" Id="fbe1acec-4954-48f2-8162-cb68cf502de5">
<DataType Name="Present" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Present" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="9abd4bea-8f5d-4bdb-a9cf-ec3d12cba96d"/>
</DataType>
<DataType Name="sHmi" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="HMI" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="117" OffsetType="NJ" Id="ea78e85c-693d-4303-8bec-aa80e2ec0ab8">
<DataType Name="Cmd" BaseType="Equipment\\Deskinner\\sHmiCmd" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Command" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="a5ce49d3-7656-4626-825e-929143600c03"/>
<DataType Name="Sts" BaseType="Equipment\\Deskinner\\sHmiSts" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Status" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="0dd70b54-c84f-4e9b-afd4-587dd3822b0a"/>
<DataType Name="Config" BaseType="Equipment\\Deskinner\\sHmiConfig" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Configuration" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="eb9eaa4a-6d5a-4c88-88cc-9b67cc4264ac"/>
<DataType Name="Setting" BaseType="Equipment\\Deskinner\\sHmiSetting" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Setting" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="cb0bafb5-f30f-4471-abda-bb77fa98b21c"/>
</DataType>
<DataType Name="sHmiCmd" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Command" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="39" OffsetType="NJ" Id="5c9be38e-a7ff-4f17-8544-926405546f03">
<DataType Name="StartFwd" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Start forward" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="ba1ec773-af02-48bb-bdb3-bf5df7a5e45e"/>
<DataType Name="StartRev" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Start reverse" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="37c58d4a-012b-4550-a53b-2a9510ce6032"/>
<DataType Name="Stop" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Stop" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="5ec4f483-4678-406d-8f8a-6fc67c911405"/>
</DataType>
<DataType Name="sHmiSts" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Status" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="38" OffsetType="NJ" Id="da4ddd10-40a4-4a5a-bc1a-6c24c195dbe4">
<DataType Name="Event" BaseType="Generic\\Event\\sHandling" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Event handling" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="56c4f717-04f7-47c7-9a4c-f05e83fadf8c"/>
<DataType Name="StartFwd" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Start forward" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="c579d0e0-3ce0-4e19-8f2e-cdd9c28e5166"/>
<DataType Name="StartRev" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Start reverse" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="c781171e-05ec-40da-bfbe-6879053e52f9"/>
<DataType Name="Stop" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Stop" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="b22dfb3c-b9b5-43d9-bd36-e32d024cfba4"/>
</DataType>
<DataType Name="sHmiConfig" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Configuration" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="37" OffsetType="NJ" Id="00c58c3a-768a-4510-9667-d19847317dfe">
<DataType Name="Present" BaseType="BOOL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Present" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="2687f3c6-7490-4333-9a1c-1b062e2b80d1"/>
</DataType>
<DataType Name="sHmiSetting" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Setting" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="36" OffsetType="NJ" Id="979b31f4-eaf8-4f67-8d0c-c0503509d7a9">
<DataType Name="SpeedProduction" BaseType="Generic\\DataField\\sHmi" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Speed production mode" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="5ff8af98-4e83-40a5-a494-dfad7bef5025"/>
<DataType Name="SpeedManual" BaseType="Generic\\DataField\\sHmi" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Speed manual mode" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="9f27e37e-b5b9-4fbe-b445-0ab4e350418b"/>
<DataType Name="SpeedCleaning" BaseType="Generic\\DataField\\sHmi" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Speed cleaning mode" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="272956a4-cb06-447c-938e-d99b950ab694"/>
</DataType>
<DataType Name="sSetting" BaseType="STRUCT" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Setting" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="110" OffsetType="NJ" Id="61944cb9-beac-4f7b-9b5d-70315338be30">
<DataType Name="SpeedProduction" BaseType="REAL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Speed production mode" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="0aa0aaa3-f560-4f3e-a7eb-4542003ccbae"/>
<DataType Name="SpeedManual" BaseType="REAL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Speed manual mode" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="e5515474-6e40-4b4c-9af1-bf98b2d4cc04"/>
<DataType Name="SpeedCleaning" BaseType="REAL" ArrayType="" Length="" InitialValue="" EnumValue="" Comment="Speed cleaning mode" OffsetChannel="" OffsetBit="" IsControllerDefinedType="false" Order="0" OffsetType="" Id="7cafc757-f3fc-4af2-a58d-1dc669f2b363"/>
</DataType>
</DataType>
</data>""";

Future<void> main() async {
  GetIt.I.registerSingleton<Logger>(Logger());

  group('class: DataTypeXml', () {
    group('method: toDataTypes', () {
      var dataTypes = DataTypeArchiveXmlFile.fromXml(
        nameSpacePath: 'Test\\NameSpace',
        xml: xml,
      ).toDataTypeBases();

      test('5 main DataTypes in test xml', () {
        expect(dataTypes, hasLength(11));
      });
      group('1st DataTypes in test xml', () {
        test('name==sEvent', () {
          expect(dataTypes[0].name, 'sEvent');
        });
        test('comment==Event', () {
          expect(dataTypes[0].comment, 'Event');
        });
        test('baseType==UnknownBaseType', () {
          dataTypes[0].should.beOfType<Structure>();
        });
        test('children.length==2', () {
          expect(dataTypes[0].children, hasLength(2));
        });
      });
    });
  });

  group('function: createDataTypes', () {
    test('created dataType leaf paths should be correct', () async {
      File file = SysmacProjectTestResource().file;
      var sysmacProjectArchive = await SysmacProjectArchive.loadFromFile(file);
      var dataTypes = createDataTypes(sysmacProjectArchive);
      var dataTypeLeafPaths = dataTypes.findAllNodePaths(leafPathsFinder());
      dataTypeLeafPaths.length.should.be(56728);
    });

    test('should not contain HMI dataTypes', () async {
      File file = SysmacProjectTestResource().file;
      var sysmacProjectArchive = await SysmacProjectArchive.loadFromFile(file);
      var dataTypes = createDataTypes(sysmacProjectArchive);
      var dataTypePath = dataTypes.findFirstNodePath(
        namePathFinder(['Safety', 'sEvent', 'iCircleanEstpCord']),
      );
      dataTypePath.should.beEmpty();
    });
  });
}
