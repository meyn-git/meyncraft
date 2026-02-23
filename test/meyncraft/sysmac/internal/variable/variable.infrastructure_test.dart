import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:petitparser/core.dart';
import 'package:shouldly/shouldly.dart';

import '../../../../test_resource.dart';

void main() {
  GetIt.I.registerSingleton<Logger>(Logger());

  group('createDataTypes function', () {
    late SysmacProjectArchive sysmacProjectArchive;
    late List<DataTypeBase> dataTypes;
    setUp(() async {
      sysmacProjectArchive = await SysmacProjectArchive.create(
        SysmacProjectTestResource().file,
      );
      dataTypes = createDataTypes(sysmacProjectArchive);
    });

    test('createGlobalVariables should return correct result)', () {
      var globalVariables = createGlobalVariables(
        sysmacProjectArchive,
        dataTypes,
      );
      globalVariables.length.should.be(1738);
    });

    test(
      'createGlobalVariables should contain a GlobalEvents variable of the correct type)',
      () {
        var globalVariables = createGlobalVariables(
          sysmacProjectArchive,
          dataTypes,
        );
        var globalEvent = globalVariables.firstWhereOrNull(
          (v) => v.name == 'EventGlobal',
        );
        globalEvent.should.not.beNull();
        var globalEventBaseType = globalEvent!.baseType;
        globalEventBaseType.should.beOfType<DataTypeReference>();
        var globalEventRef = globalEventBaseType as DataTypeReference;
        globalEventRef.dataTypePath.toNamePath().join('.').should.be('sEvent');
      },
    );

    test('createGlobalVariables should parse SLDW files correctly)', () {
      var globalVariables = createGlobalVariables(
        sysmacProjectArchive,
        dataTypes,
      );
      var etherCatNode1 = globalVariables.firstWhereOrNull(
        (v) => v.name == 'EtherCatNode1',
      );
      etherCatNode1.should.not.beNull();
      etherCatNode1!.comment.should.be(
        '30U1 Line drive 1 [address=ECAT://node#1]',
      );
    });
  });

  group('slwdLineParser function', () {
    test('', () {
      var result = slwdLineParser.parse(
        '++D=INT	N=EtherCatNode1	IV=1	Const=1	G=VAR_GLOBAL	Com=30U1 Line drive 1 [address=ECAT://node#1]',
      );
      result.should.beOfType<Success<Map<String, String>>>();
      var resultValues = result.value;
      resultValues.length.should.be(6);
      resultValues['D'].should.be('INT');
      resultValues['N'].should.be('EtherCatNode1');
      resultValues['IV'].should.be('1');
      resultValues['Const'].should.be('1');
      resultValues['G'].should.be('VAR_GLOBAL');
      resultValues['Com'].should.be(
        '30U1 Line drive 1 [address=ECAT://node#1]',
      );
    });
  });

  group('parseSLWD function', () {
    test('', () {
      var groups = parseSLWD(
        '[SLWD version=1.0]\n'
        '_EN=Variables\n'
        '+GN=VAR_GLOBAL	GVT=GlobalNamespaceGroup\n'
        '++D=String[256]	N=LineNumber	R=1	NTP=PublicationOnly	G=VAR_GLOBAL\n'
        '++D=INT	N=EtherCatNode1	IV=1	Const=1	G=VAR_GLOBAL	Com=30U1 Line drive 1 [address=ECAT://node#1]\n',
      );

      groups.length.should.be(1);
      var firstGroup = groups.first;
      firstGroup.name.should.be('VAR_GLOBAL');
      firstGroup.entities.length.should.be(2);
      var firstEntity = firstGroup.entities[0];
      firstEntity.length.should.be(5);
      firstEntity['D'].should.be('String[256]');
      firstEntity['N'].should.be('LineNumber');
      firstEntity['R'].should.be('1');
      firstEntity['NTP'].should.be('PublicationOnly');
      firstEntity['G'].should.be('VAR_GLOBAL');
      var secondEntity = firstGroup.entities[1];
      secondEntity.length.should.be(6);
      secondEntity['D'].should.be('INT');
      secondEntity['N'].should.be('EtherCatNode1');
      secondEntity['IV'].should.be('1');
      secondEntity['Const'].should.be('1');
      secondEntity['G'].should.be('VAR_GLOBAL');
      secondEntity['Com'].should.be(
        '30U1 Line drive 1 [address=ECAT://node#1]',
      );
    });
  });
}
