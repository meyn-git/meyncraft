import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:shouldly/shouldly.dart';

import '../../../../test_resource.dart';

void main() {
  group('class: $BaseTypeFactory', () {
    var baseTypeFactory = BaseTypeFactory();

    group('${BaseType}s', () {
      var structType = 'STRUCT';
      test(structType, () {
        expect(
          baseTypeFactory.createFromExpression(structType),
          isA<BaseType>(),
        );
        expect(baseTypeFactory.createFromExpression(structType), isA<Struct>());
        expect(
          baseTypeFactory.createFromExpression(structType.toLowerCase()),
          isA<UnknownBaseType>(),
        );
      });

      var enumType = 'ENUM';
      test(enumType, () {
        expect(baseTypeFactory.createFromExpression(enumType), isA<BaseType>());
        expect(
          baseTypeFactory.createFromExpression(enumType),
          isA<EnumParent>(),
        );
        expect(
          baseTypeFactory.createFromExpression(enumType.toLowerCase()),
          isA<UnknownBaseType>(),
        );
      });
    });
    group('${NxType}s', () {
      test('INT', () {
        expect(baseTypeFactory.createFromExpression('INT'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('INT'), isA<NxInt>());
        expect(
          baseTypeFactory.createFromExpression('int'),
          isA<UnknownBaseType>(),
        );
      });
      test('DINT', () {
        expect(baseTypeFactory.createFromExpression('DINT'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('DINT'), isA<NxDInt>());
        expect(
          baseTypeFactory.createFromExpression('dint'),
          isA<UnknownBaseType>(),
        );
      });
      test('LINT', () {
        expect(baseTypeFactory.createFromExpression('LINT'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('LINT'), isA<NxLInt>());
        expect(
          baseTypeFactory.createFromExpression('lint'),
          isA<UnknownBaseType>(),
        );
      });
      test('UINT', () {
        expect(baseTypeFactory.createFromExpression('UINT'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('UINT'), isA<NxUInt>());
        expect(
          baseTypeFactory.createFromExpression('uint'),
          isA<UnknownBaseType>(),
        );
      });
      test('WORD', () {
        expect(baseTypeFactory.createFromExpression('WORD'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('WORD'), isA<NxWord>());
        expect(
          baseTypeFactory.createFromExpression('word'),
          isA<UnknownBaseType>(),
        );
      });
      test('UDINT', () {
        expect(baseTypeFactory.createFromExpression('UDINT'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('UDINT'), isA<NxUDInt>());
        expect(
          baseTypeFactory.createFromExpression('udint'),
          isA<UnknownBaseType>(),
        );
      });
      test('DWORD', () {
        expect(baseTypeFactory.createFromExpression('DWORD'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('DWORD'), isA<NxDWord>());
        expect(
          baseTypeFactory.createFromExpression('dword'),
          isA<UnknownBaseType>(),
        );
      });
      test('ULINT', () {
        expect(baseTypeFactory.createFromExpression('ULINT'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('ULINT'), isA<NxULInt>());
        expect(
          baseTypeFactory.createFromExpression('ulint'),
          isA<UnknownBaseType>(),
        );
      });
      test('LWORD', () {
        expect(baseTypeFactory.createFromExpression('LWORD'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('LWORD'), isA<NxLWord>());
        expect(
          baseTypeFactory.createFromExpression('lword'),
          isA<UnknownBaseType>(),
        );
      });
      test('REAL', () {
        expect(baseTypeFactory.createFromExpression('REAL'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('REAL'), isA<NxReal>());
        expect(
          baseTypeFactory.createFromExpression('real'),
          isA<UnknownBaseType>(),
        );
      });
      test('LREAL', () {
        expect(baseTypeFactory.createFromExpression('LREAL'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('LREAL'), isA<NxLReal>());
        expect(
          baseTypeFactory.createFromExpression('lreal'),
          isA<UnknownBaseType>(),
        );
      });
      test('BOOL', () {
        expect(baseTypeFactory.createFromExpression('BOOL'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('BOOL'), isA<NxBool>());
        expect(
          baseTypeFactory.createFromExpression('bool'),
          isA<UnknownBaseType>(),
        );
      });
      test('STRING', () {
        expect(baseTypeFactory.createFromExpression('STRING'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('STRING'), isA<NxString>());
        expect(
          baseTypeFactory.createFromExpression('STRING[123]'),
          isA<NxType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('STRING[123]'),
          isA<NxString>(),
        );
        expect(
          baseTypeFactory.createFromExpression('string'),
          isA<UnknownBaseType>(),
        );
      });
      test('SINT', () {
        expect(baseTypeFactory.createFromExpression('SINT'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('SINT'), isA<NxSInt>());
        expect(
          baseTypeFactory.createFromExpression('sint'),
          isA<UnknownBaseType>(),
        );
      });
      test('USINT', () {
        expect(baseTypeFactory.createFromExpression('USINT'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('USINT'), isA<NxUSInt>());
        expect(
          baseTypeFactory.createFromExpression('usint'),
          isA<UnknownBaseType>(),
        );
      });
      test('BYTE', () {
        expect(baseTypeFactory.createFromExpression('BYTE'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('BYTE'), isA<NxByte>());
        expect(
          baseTypeFactory.createFromExpression('byte'),
          isA<UnknownBaseType>(),
        );
      });
      test('TIME', () {
        expect(baseTypeFactory.createFromExpression('TIME'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('TIME'), isA<NxTime>());
        expect(
          baseTypeFactory.createFromExpression('time'),
          isA<UnknownBaseType>(),
        );
      });
      test('DATE', () {
        expect(baseTypeFactory.createFromExpression('DATE'), isA<NxType>());
        expect(baseTypeFactory.createFromExpression('DATE'), isA<NxDate>());
        expect(
          baseTypeFactory.createFromExpression('date'),
          isA<UnknownBaseType>(),
        );
      });
      test('DATE_AND_TIME', () {
        expect(
          baseTypeFactory.createFromExpression('DATE_AND_TIME'),
          isA<NxType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('DATE_AND_TIME'),
          isA<NxDateAndTime>(),
        );
        expect(
          baseTypeFactory.createFromExpression('date_and_time'),
          isA<UnknownBaseType>(),
        );
      });
      test('TIME_OF_DAY', () {
        expect(
          baseTypeFactory.createFromExpression('TIME_OF_DAY'),
          isA<NxType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('TIME_OF_DAY'),
          isA<NxTimeOfDay>(),
        );
        expect(
          baseTypeFactory.createFromExpression('time_of_day'),
          isA<UnknownBaseType>(),
        );
      });
    });

    group('${VbType}s', () {
      test('Short', () {
        expect(baseTypeFactory.createFromExpression('Short'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('Short'), isA<VbShort>());
        expect(
          baseTypeFactory.createFromExpression('short'),
          isA<UnknownBaseType>(),
        );
      });
      test('Integer', () {
        expect(baseTypeFactory.createFromExpression('Integer'), isA<VbType>());
        expect(
          baseTypeFactory.createFromExpression('Integer'),
          isA<VbInteger>(),
        );
        expect(
          baseTypeFactory.createFromExpression('integer'),
          isA<UnknownBaseType>(),
        );
      });
      test('Long', () {
        expect(baseTypeFactory.createFromExpression('Long'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('Long'), isA<VbLong>());
        expect(
          baseTypeFactory.createFromExpression('long'),
          isA<UnknownBaseType>(),
        );
      });
      test('UShort', () {
        expect(baseTypeFactory.createFromExpression('UShort'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('UShort'), isA<VbUShort>());
        expect(
          baseTypeFactory.createFromExpression('ushort'),
          isA<UnknownBaseType>(),
        );
      });
      test('UInteger', () {
        expect(baseTypeFactory.createFromExpression('UInteger'), isA<VbType>());
        expect(
          baseTypeFactory.createFromExpression('UInteger'),
          isA<VbUInteger>(),
        );
        expect(
          baseTypeFactory.createFromExpression('uinteger'),
          isA<UnknownBaseType>(),
        );
      });
      test('ULong', () {
        expect(baseTypeFactory.createFromExpression('ULong'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('ULong'), isA<VbULong>());
        expect(
          baseTypeFactory.createFromExpression('ulong'),
          isA<UnknownBaseType>(),
        );
      });
      test('Single', () {
        expect(baseTypeFactory.createFromExpression('Single'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('Single'), isA<VbSingle>());
        expect(
          baseTypeFactory.createFromExpression('single'),
          isA<UnknownBaseType>(),
        );
      });
      test('Double', () {
        expect(baseTypeFactory.createFromExpression('Double'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('Double'), isA<VbDouble>());
        expect(
          baseTypeFactory.createFromExpression('double'),
          isA<UnknownBaseType>(),
        );
      });
      test('Decimal', () {
        expect(baseTypeFactory.createFromExpression('Decimal'), isA<VbType>());
        expect(
          baseTypeFactory.createFromExpression('Decimal'),
          isA<VbDecimal>(),
        );
        expect(
          baseTypeFactory.createFromExpression('decimal'),
          isA<UnknownBaseType>(),
        );
      });
      test('Boolean', () {
        expect(baseTypeFactory.createFromExpression('Boolean'), isA<VbType>());
        expect(
          baseTypeFactory.createFromExpression('Boolean'),
          isA<VbBoolean>(),
        );
        expect(
          baseTypeFactory.createFromExpression('boolean'),
          isA<UnknownBaseType>(),
        );
      });
      test('String', () {
        expect(baseTypeFactory.createFromExpression('String'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('String'), isA<VbString>());
        expect(
          baseTypeFactory.createFromExpression('String[123]'),
          isA<VbType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('String[123]'),
          isA<VbString>(),
        );
        expect(
          baseTypeFactory.createFromExpression('string'),
          isA<UnknownBaseType>(),
        );
      });
      test('Char', () {
        expect(baseTypeFactory.createFromExpression('Char'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('Char'), isA<VbChar>());
        expect(
          baseTypeFactory.createFromExpression('char'),
          isA<UnknownBaseType>(),
        );
      });
      test('SByte', () {
        expect(baseTypeFactory.createFromExpression('SByte'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('SByte'), isA<VbSByte>());
        expect(
          baseTypeFactory.createFromExpression('sbyte'),
          isA<UnknownBaseType>(),
        );
      });
      test('Byte', () {
        expect(baseTypeFactory.createFromExpression('Byte'), isA<VbType>());
        expect(baseTypeFactory.createFromExpression('Byte'), isA<VbByte>());
        expect(
          baseTypeFactory.createFromExpression('byte'),
          isA<UnknownBaseType>(),
        );
      });
      test('DateTime', () {
        expect(baseTypeFactory.createFromExpression('DateTime'), isA<VbType>());
        expect(
          baseTypeFactory.createFromExpression('DateTime'),
          isA<VbDateTime>(),
        );
        expect(
          baseTypeFactory.createFromExpression('datetime'),
          isA<UnknownBaseType>(),
        );
      });
      test('System.TimeSpan', () {
        expect(
          baseTypeFactory.createFromExpression('System.TimeSpan'),
          isA<VbType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('System.TimeSpan'),
          isA<VbTimeSpan>(),
        );
        expect(
          baseTypeFactory.createFromExpression('system.timespan'),
          isA<UnknownBaseType>(),
        );
      });
    });

    group('Arrays', () {
      test('INT', () {
        expect(
          baseTypeFactory.createFromExpression('INT').arrayRanges,
          isEmpty,
        );
      });
      test('invalid arrays', () {
        expect(
          baseTypeFactory.createFromExpression('array[1..2] OF INT'),
          isA<UnknownBaseType>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('array[1..2] OF INT')
              .arrayRanges
              .length,
          0,
        );

        expect(
          baseTypeFactory.createFromExpression('ARRAY[1..] OF INT'),
          isA<UnknownBaseType>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..] OF INT')
              .arrayRanges
              .length,
          0,
        );

        expect(
          baseTypeFactory.createFromExpression('ARRAY[..2] OF INT'),
          isA<UnknownBaseType>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[..2] OF INT')
              .arrayRanges
              .length,
          0,
        );

        expect(
          baseTypeFactory.createFromExpression('ARRAY[2] OF INT'),
          isA<UnknownBaseType>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2] OF INT')
              .arrayRanges
              .length,
          0,
        );

        expect(
          baseTypeFactory.createFromExpression('ARRAY[1..2]OF INT'),
          isA<UnknownBaseType>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2]OF INT')
              .arrayRanges
              .length,
          0,
        );

        expect(
          baseTypeFactory.createFromExpression('ARRAY[1..2] OFINT'),
          isA<UnknownBaseType>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OFINT')
              .arrayRanges
              .length,
          0,
        );

        expect(
          baseTypeFactory.createFromExpression('ARRAY[1..2] OF'),
          isA<UnknownBaseType>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OF')
              .arrayRanges
              .length,
          0,
        );
      });

      test('ARRAY[1..2] OF INT', () {
        expect(
          baseTypeFactory.createFromExpression('ARRAY[1..2] OF INT'),
          isA<NxType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('ARRAY[1..2] OF INT'),
          isA<NxInt>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OF INT')
              .arrayRanges
              .length,
          1,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OF INT')
              .arrayRanges[0]
              .min,
          1,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OF INT')
              .arrayRanges[0]
              .max,
          2,
        );
      });

      test('ARRAY[2..3,4..5] OF BOOL', () {
        expect(
          baseTypeFactory.createFromExpression('ARRAY[2..3,4..5] OF BOOL'),
          isA<NxType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('ARRAY[2..3,4..5] OF BOOL'),
          isA<NxBool>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5] OF BOOL')
              .arrayRanges
              .length,
          2,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5] OF BOOL')
              .arrayRanges[0]
              .min,
          2,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5] OF BOOL')
              .arrayRanges[0]
              .max,
          3,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5] OF BOOL')
              .arrayRanges[1]
              .min,
          4,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5] OF BOOL')
              .arrayRanges[1]
              .max,
          5,
        );
      });

      test('ARRAY[2..3,4..5,7..10] OF BOOL', () {
        expect(
          baseTypeFactory.createFromExpression('ARRAY[2..3,4..5] OF BOOL'),
          isA<NxType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('ARRAY[2..3,4..5] OF BOOL'),
          isA<NxBool>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5,7..10] OF BOOL')
              .arrayRanges
              .length,
          3,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5,7..10] OF BOOL')
              .arrayRanges[0]
              .min,
          2,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5,7..10] OF BOOL')
              .arrayRanges[0]
              .max,
          3,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5,7..10] OF BOOL')
              .arrayRanges[1]
              .min,
          4,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5,7..10] OF BOOL')
              .arrayRanges[1]
              .max,
          5,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5,7..10] OF BOOL')
              .arrayRanges[2]
              .min,
          7,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[2..3,4..5,7..10] OF BOOL')
              .arrayRanges[2]
              .max,
          10,
        );
      });
      test('ARRAY[1..2]', () {
        expect(
          baseTypeFactory.createFromExpression('ARRAY[1..2]'),
          isA<NxType>(),
        );
        expect(
          baseTypeFactory.createFromExpression('ARRAY[1..2]'),
          isA<NxBool>(),
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2]')
              .arrayRanges
              .length,
          1,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2]')
              .arrayRanges[0]
              .min,
          1,
        );
        expect(
          baseTypeFactory
              .createFromExpression('ARRAY[1..2]')
              .arrayRanges[0]
              .max,
          2,
        );
      });
      test('ARRAY[1..6] OF Equipment\\LineModuleWash_v11\\sInterface', () {
        var result = baseTypeFactory.createFromExpression(
          'ARRAY[1..6] OF Equipment\\LineModuleWash_v11\\sInterface',
        );
        result.should.beOfType<UnknownBaseType>();
        result.arrayRanges.length.should.be(1);
        result.arrayRanges[0].min.should.be(1);
        result.arrayRanges[0].max.should.be(6);
      });
    });
    group('Custom types', () {
      test('createFromExpressionIncludingCustomTypes', () async {
        var sysmacProjectArchive = await SysmacProjectArchive.create(
          SysmacProjectTestResource().file,
        );
        var dataTypes = createDataTypes(sysmacProjectArchive);
        var sEventType = baseTypeFactory
            .createFromExpressionIncludingCustomTypes('sEvent', dataTypes);
        sEventType.should.beOfType<DataTypeReference>();
      });

      test('createFromExpressionIncludingCustomTypes', () async {
        var sysmacProjectArchive = await SysmacProjectArchive.create(
          SysmacProjectTestResource().file,
        );
        var dataTypes = createDataTypes(sysmacProjectArchive);
        var found = <String>[];
        for (var dataType in dataTypes) {
          var paths = dataType.findAllNodePaths(leafPathsFinder());
          for (var path in paths) {
            var pathString = path.map((n) => n.name).join('.');
            if (pathString.contains('sEvent.Common')) {
              found.add(pathString);
            }
          }
        }
        found.length.should.be(2);
      });
    });
  });
  group('ArrayFactory class', () {
    test('ArrayFactory class', () {
      var factory = ArrayFactory();
      factory.regex
          .hasMatch('ARRAY[1..6] OF EquipmentLineModuleWashv11sInterface')
          .should
          .be(true);
    });
  });

  group('function createDataTypes', () {
    GetIt.I.registerSingleton<Logger>(Logger());
    File file = SysmacProjectTestResource().file;
    late SysmacProjectArchive sysmacProjectArchive;
    setUpAll(() async {
      sysmacProjectArchive = await SysmacProjectArchive.create(file);
    });

    test('"Common.Alarm0" should not be an array', () {
      var dataTypes = createDataTypes(sysmacProjectArchive);
      var common = dataTypes.firstWhere((v) => v.name == 'Common');
      var sEvent = common.children.firstWhere((v) => v.name == 'sEvent');
      var alarm0 = sEvent.children.firstWhere((v) => v.name == 'Alarm0');
      var baseType = (alarm0 as DataType).baseType;
      baseType.arrayRanges.should.beEmpty();
    });
  });
}
