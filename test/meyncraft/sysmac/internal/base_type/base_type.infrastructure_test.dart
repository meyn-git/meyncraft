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
    group('${IecType}s', () {
      var baseTypeFactory = BaseTypeFactory.forIecTypes();
      test('INT', () {
        var createFromExpression = baseTypeFactory.createFromExpression('INT');
        createFromExpression.should.beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('INT').should.beOfType<IecInt>();

        baseTypeFactory.createFromExpression('int').should.beOfType<IecInt>();
      });
      test('DINT', () {
        baseTypeFactory
            .createFromExpression('DINT')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('DINT').should.beOfType<IecDInt>();
        baseTypeFactory.createFromExpression('dint').should.beOfType<IecDInt>();
      });
      test('LINT', () {
        baseTypeFactory
            .createFromExpression('LINT')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('LINT').should.beOfType<IecLInt>();

        baseTypeFactory.createFromExpression('lint').should.beOfType<IecLInt>();
      });
      test('UINT', () {
        baseTypeFactory
            .createFromExpression('UINT')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('UINT').should.beOfType<IecUInt>();

        baseTypeFactory.createFromExpression('uint').should.beOfType<IecUInt>();
      });
      test('WORD', () {
        baseTypeFactory
            .createFromExpression('WORD')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('WORD').should.beOfType<IecWord>();

        baseTypeFactory.createFromExpression('word').should.beOfType<IecWord>();
      });
      test('UDINT', () {
        baseTypeFactory
            .createFromExpression('UDINT')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory
            .createFromExpression('UDINT')
            .should
            .beOfType<IecUDInt>();

        baseTypeFactory
            .createFromExpression('udint')
            .should
            .beOfType<IecUDInt>();
      });
      test('DWORD', () {
        baseTypeFactory
            .createFromExpression('DWORD')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory
            .createFromExpression('DWORD')
            .should
            .beOfType<IecDWord>();

        baseTypeFactory
            .createFromExpression('dword')
            .should
            .beOfType<IecDWord>();
      });
      test('ULINT', () {
        baseTypeFactory
            .createFromExpression('ULINT')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory
            .createFromExpression('ULINT')
            .should
            .beOfType<IecULInt>();

        baseTypeFactory
            .createFromExpression('ulint')
            .should
            .beOfType<IecULInt>();
      });
      test('LWORD', () {
        baseTypeFactory
            .createFromExpression('LWORD')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory
            .createFromExpression('LWORD')
            .should
            .beOfType<IecLWord>();

        baseTypeFactory
            .createFromExpression('lword')
            .should
            .beOfType<IecLWord>();
      });
      test('REAL', () {
        baseTypeFactory
            .createFromExpression('REAL')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('REAL').should.beOfType<IecReal>();

        baseTypeFactory.createFromExpression('real').should.beOfType<IecReal>();
      });
      test('LREAL', () {
        baseTypeFactory
            .createFromExpression('LREAL')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory
            .createFromExpression('LREAL')
            .should
            .beOfType<IecLReal>();

        baseTypeFactory
            .createFromExpression('lreal')
            .should
            .beOfType<IecLReal>();
      });
      test('BOOL', () {
        baseTypeFactory
            .createFromExpression('BOOL')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('BOOL').should.beOfType<IecBool>();

        baseTypeFactory.createFromExpression('bool').should.beOfType<IecBool>();
      });
      test('STRING', () {
        baseTypeFactory
            .createFromExpression('STRING')
            .should
            .beAssignableTo<IecType>();

        baseTypeFactory
            .createFromExpression('STRING')
            .should
            .beOfType<IecString>();

        baseTypeFactory
            .createFromExpression('STRING[123]')
            .should
            .beOfType<IecString>()!
            .size
            .should
            .be(123);

        baseTypeFactory
            .createFromExpression('string[5]')
            .should
            .beOfType<IecString>()!
            .size
            .should
            .be(5);

        baseTypeFactory
            .createFromExpression('string')
            .should
            .beOfType<IecString>();
      });
      test('SINT', () {
        baseTypeFactory
            .createFromExpression('SINT')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('SINT').should.beOfType<IecSInt>();

        baseTypeFactory.createFromExpression('sint').should.beOfType<IecSInt>();
      });
      test('USINT', () {
        baseTypeFactory
            .createFromExpression('USINT')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory
            .createFromExpression('USINT')
            .should
            .beOfType<IecUSInt>();

        baseTypeFactory
            .createFromExpression('usint')
            .should
            .beOfType<IecUSInt>();
      });
      test('BYTE', () {
        baseTypeFactory
            .createFromExpression('BYTE')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('BYTE').should.beOfType<IecByte>();

        baseTypeFactory.createFromExpression('byte').should.beOfType<IecByte>();
      });
      test('TIME', () {
        baseTypeFactory
            .createFromExpression('TIME')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('TIME').should.beOfType<IecTime>();

        baseTypeFactory.createFromExpression('time').should.beOfType<IecTime>();
      });
      test('DATE', () {
        baseTypeFactory
            .createFromExpression('DATE')
            .should
            .beAssignableTo<IecType>();
        baseTypeFactory.createFromExpression('DATE').should.beOfType<IecDate>();

        baseTypeFactory.createFromExpression('date').should.beOfType<IecDate>();
      });
      test('DATE_AND_TIME', () {
        baseTypeFactory
            .createFromExpression('DATE_AND_TIME')
            .should
            .beAssignableTo<IecType>();

        baseTypeFactory
            .createFromExpression('DATE_AND_TIME')
            .should
            .beOfType<IecDateAndTime>();

        baseTypeFactory
            .createFromExpression('date_and_time')
            .should
            .beOfType<IecDateAndTime>();
      });
      test('TIME_OF_DAY', () {
        baseTypeFactory
            .createFromExpression('TIME_OF_DAY')
            .should
            .beAssignableTo<IecType>();

        baseTypeFactory
            .createFromExpression('TIME_OF_DAY')
            .should
            .beOfType<IecTimeOfDay>();

        baseTypeFactory
            .createFromExpression('time_of_day')
            .should
            .beOfType<IecTimeOfDay>();
      });
      group('Arrays', () {
        test('INT', () {
          baseTypeFactory.createFromExpression('INT').should.beOfType<IecInt>();
        });
        test('invalid arrays', () {
          baseTypeFactory
              .createFromExpression('array[1A..2] OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('array[1..2b] OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..] OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..] OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[..2] OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[..2] OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[2] OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[2] OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..2]OF INT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OFINT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OFINT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OF')
              .should
              .beOfType<UnknownBaseType>();
        });

        test('ARRAY[1..2] OF INT', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[1..2] OF INT',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<IecInt>();
          arrayType.arrayRanges.length.should.be(1);
          arrayType.arrayRanges[0].min.should.be(1);
          arrayType.arrayRanges[0].max.should.be(2);
        });

        test('ARRAY[2..3,4..5] OF BOOL', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[2..3,4..5] OF BOOL',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<IecBool>();
          arrayType.arrayRanges.length.should.be(2);
          arrayType.arrayRanges[0].min.should.be(2);
          arrayType.arrayRanges[0].max.should.be(3);
          arrayType.arrayRanges[1].min.should.be(4);
          arrayType.arrayRanges[1].max.should.be(5);
        });

        test('ARRAY[2..3,4..5,7..10] OF BOOL', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[2..3,4..5,7..10] OF BOOL',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<IecBool>();
          arrayType.arrayRanges.length.should.be(3);
          arrayType.arrayRanges[0].min.should.be(2);
          arrayType.arrayRanges[0].max.should.be(3);
          arrayType.arrayRanges[1].min.should.be(4);
          arrayType.arrayRanges[1].max.should.be(5);
          arrayType.arrayRanges[2].min.should.be(7);
          arrayType.arrayRanges[2].max.should.be(10);
        });

        test('ARRAY[1..2]', () {
          var baseType = baseTypeFactory.createFromExpression('ARRAY[1..2]');
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<IecBool>();
          arrayType.arrayRanges.length.should.be(1);
          arrayType.arrayRanges[0].min.should.be(1);
          arrayType.arrayRanges[0].max.should.be(2);
        });

        test('ARRAY[1..5] OF STRING[256]', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[1..5] OF STRING[256]',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<IecString>()!.size.should.be(256);
          arrayType.arrayRanges.length.should.be(1);
          arrayType.arrayRanges[0].min.should.be(1);
          arrayType.arrayRanges[0].max.should.be(5);
        });

        test('ARRAY[1..6] OF Equipment\\LineModuleWash_v11\\sInterface', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[1..6] OF Equipment\\LineModuleWash_v11\\sInterface',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<UnknownBaseType>();
          baseType.arrayRanges.length.should.be(1);
          baseType.arrayRanges[0].min.should.be(1);
          baseType.arrayRanges[0].max.should.be(6);
        });
      });
      group('Custom types', () {
        test(
          'createDataTypes should have a single "sEvent.Common" dataType path',
          () async {
            var sysmacProjectArchive = await SysmacProjectArchive.loadFromFile(
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
            found.length.should.be(1);
          },
        );
      });
    });

    group('${VbType}s', () {
      var baseTypeFactory = BaseTypeFactory.forVbTypes();
      test('Short', () {
        var createFromExpression = baseTypeFactory.createFromExpression(
          'Short',
        );
        createFromExpression.should.beAssignableTo<VbType>();
        baseTypeFactory
            .createFromExpression('Short')
            .should
            .beOfType<VbShort>();
        baseTypeFactory
            .createFromExpression('short')
            .should
            .beOfType<VbShort>();
      });
      test('Integer', () {
        baseTypeFactory
            .createFromExpression('Integer')
            .should
            .beAssignableTo<VbType>();

        baseTypeFactory
            .createFromExpression('Integer')
            .should
            .beOfType<VbInteger>();

        baseTypeFactory
            .createFromExpression('integer')
            .should
            .beOfType<VbInteger>();
      });
      test('Long', () {
        baseTypeFactory
            .createFromExpression('Long')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory.createFromExpression('Long').should.beOfType<VbLong>();

        baseTypeFactory.createFromExpression('long').should.beOfType<VbLong>();
      });
      test('UShort', () {
        baseTypeFactory
            .createFromExpression('UShort')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory
            .createFromExpression('UShort')
            .should
            .beOfType<VbUShort>();

        baseTypeFactory
            .createFromExpression('ushort')
            .should
            .beOfType<VbUShort>();
      });
      test('UInteger', () {
        baseTypeFactory
            .createFromExpression('UInteger')
            .should
            .beAssignableTo<VbType>();

        baseTypeFactory
            .createFromExpression('UInteger')
            .should
            .beOfType<VbUInteger>();

        baseTypeFactory
            .createFromExpression('uinteger')
            .should
            .beOfType<VbUInteger>();
      });
      test('ULong', () {
        baseTypeFactory
            .createFromExpression('ULong')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory
            .createFromExpression('ULong')
            .should
            .beOfType<VbULong>();

        baseTypeFactory
            .createFromExpression('ulong')
            .should
            .beOfType<VbULong>();
      });
      test('Single', () {
        baseTypeFactory
            .createFromExpression('Single')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory
            .createFromExpression('Single')
            .should
            .beOfType<VbSingle>();

        baseTypeFactory
            .createFromExpression('single')
            .should
            .beOfType<VbSingle>();
      });
      test('Double', () {
        baseTypeFactory
            .createFromExpression('Double')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory
            .createFromExpression('Double')
            .should
            .beOfType<VbDouble>();

        baseTypeFactory
            .createFromExpression('double')
            .should
            .beOfType<VbDouble>();
      });
      test('Decimal', () {
        baseTypeFactory
            .createFromExpression('Decimal')
            .should
            .beAssignableTo<VbType>();

        baseTypeFactory
            .createFromExpression('Decimal')
            .should
            .beOfType<VbDecimal>();

        baseTypeFactory
            .createFromExpression('decimal')
            .should
            .beOfType<VbDecimal>();
      });
      test('Boolean', () {
        baseTypeFactory
            .createFromExpression('Boolean')
            .should
            .beAssignableTo<VbType>();

        baseTypeFactory
            .createFromExpression('Boolean')
            .should
            .beOfType<VbBoolean>();

        baseTypeFactory
            .createFromExpression('boolean')
            .should
            .beOfType<VbBoolean>();
      });
      test('String', () {
        baseTypeFactory
            .createFromExpression('String')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory
            .createFromExpression('String')
            .should
            .beOfType<VbString>();

        baseTypeFactory
            .createFromExpression('String[123]')
            .should
            .beAssignableTo<VbType>();

        baseTypeFactory
            .createFromExpression('String[123]')
            .should
            .beOfType<VbString>()!
            .size
            .should
            .be(123);

        baseTypeFactory
            .createFromExpression('string')
            .should
            .beOfType<VbString>();
      });
      test('Char', () {
        baseTypeFactory
            .createFromExpression('Char')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory.createFromExpression('Char').should.beOfType<VbChar>();

        baseTypeFactory.createFromExpression('char').should.beOfType<VbChar>();
      });
      test('SByte', () {
        baseTypeFactory
            .createFromExpression('SByte')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory
            .createFromExpression('SByte')
            .should
            .beOfType<VbSByte>();

        baseTypeFactory
            .createFromExpression('sbyte')
            .should
            .beOfType<VbSByte>();
      });
      test('Byte', () {
        baseTypeFactory
            .createFromExpression('Byte')
            .should
            .beAssignableTo<VbType>();
        baseTypeFactory.createFromExpression('Byte').should.beOfType<VbByte>();
        baseTypeFactory.createFromExpression('byte').should.beOfType<VbByte>();
      });
      test('DateTime', () {
        baseTypeFactory
            .createFromExpression('DateTime')
            .should
            .beAssignableTo<VbType>();

        baseTypeFactory
            .createFromExpression('DateTime')
            .should
            .beOfType<VbDateTime>();

        baseTypeFactory
            .createFromExpression('datetime')
            .should
            .beOfType<VbDateTime>();
      });
      test('System.TimeSpan', () {
        baseTypeFactory
            .createFromExpression('System.TimeSpan')
            .should
            .beAssignableTo<VbType>();

        baseTypeFactory
            .createFromExpression('System.TimeSpan')
            .should
            .beOfType<VbTimeSpan>();

        baseTypeFactory
            .createFromExpression('system.timespan')
            .should
            .beOfType<VbTimeSpan>();
      });
      group('Arrays', () {
        test('Integer', () {
          baseTypeFactory
              .createFromExpression('Integer')
              .should
              .beOfType<VbInteger>();
        });
        test('invalid arrays', () {
          baseTypeFactory
              .createFromExpression('array[1A..2] OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('array[1..2b] OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..] OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..] OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[..2] OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[..2] OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[2] OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[2] OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..2]OF Integer')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OFINT')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OFInteger')
              .should
              .beOfType<UnknownBaseType>();

          baseTypeFactory
              .createFromExpression('ARRAY[1..2] OF')
              .should
              .beOfType<UnknownBaseType>();
        });

        test('ARRAY[1..2] OF Integer', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[1..2] OF Integer',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<VbInteger>();
          arrayType.arrayRanges.length.should.be(1);
          arrayType.arrayRanges[0].min.should.be(1);
          arrayType.arrayRanges[0].max.should.be(2);
        });

        test('ARRAY[2..3,4..5] OF Boolean', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[2..3,4..5] OF Boolean',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<VbBoolean>();
          arrayType.arrayRanges.length.should.be(2);
          arrayType.arrayRanges[0].min.should.be(2);
          arrayType.arrayRanges[0].max.should.be(3);
          arrayType.arrayRanges[1].min.should.be(4);
          arrayType.arrayRanges[1].max.should.be(5);
        });

        test('ARRAY[2..3,4..5,7..10] OF Boolean', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[2..3,4..5,7..10] OF Boolean',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<VbBoolean>();
          arrayType.arrayRanges.length.should.be(3);
          arrayType.arrayRanges[0].min.should.be(2);
          arrayType.arrayRanges[0].max.should.be(3);
          arrayType.arrayRanges[1].min.should.be(4);
          arrayType.arrayRanges[1].max.should.be(5);
          arrayType.arrayRanges[2].min.should.be(7);
          arrayType.arrayRanges[2].max.should.be(10);
        });

        test('ARRAY[1..6] OF Equipment\\LineModuleWash_v11\\sInterface', () {
          var baseType = baseTypeFactory.createFromExpression(
            'ARRAY[1..6] OF Equipment\\LineModuleWash_v11\\sInterface',
          );
          baseType.should.beOfType<ArrayType>();
          var arrayType = baseType as ArrayType;
          arrayType.baseType.should.beOfType<UnknownBaseType>();
          baseType.arrayRanges.length.should.be(1);
          baseType.arrayRanges[0].min.should.be(1);
          baseType.arrayRanges[0].max.should.be(6);
        });
      });
      group('Custom types', () {
        test(
          'createDataTypes should have a single "sEvent.Common" dataType path',
          () async {
            var sysmacProjectArchive = await SysmacProjectArchive.loadFromFile(
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
            found.length.should.be(1);
          },
        );
      });
    });
  });
  group('ArrayFactory class', () {
    test('ArrayFactory class', () {
      var factory = ArrayFactory(BaseTypeFactory.forIecTypes());
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
      sysmacProjectArchive = await SysmacProjectArchive.loadFromFile(file);
    });

    test('DataType "Common.sEvent.Alarm0" should exist and be correct', () {
      var dataTypes = createDataTypes(sysmacProjectArchive);
      var dataTypePath = dataTypes.findFirstNodePath(
        namePathFinder(['Common', 'sEvent', 'Alarm0']),
      );
      dataTypePath.should.not.beEmpty();
      dataTypePath.last.name.should.be('Alarm0');
      dataTypePath.last.should.beOfType<DataTypeMember>();
      (dataTypePath.last as DataTypeMember).baseType.should.beOfType<IecBool>();
    });

    test(
      'baseType of DataType "sEvent.BirdBrushMtr" should be an array[1..2]',
      () {
        var dataTypes = createDataTypes(sysmacProjectArchive);
        var dataTypePath = dataTypes.findFirstNodePath(
          namePathFinder(['sEvent', 'BirdBrushMtr']),
        );
        dataTypePath.should.not.beEmpty();
        var birdBrushMtr = dataTypePath.last;
        birdBrushMtr.should.beOfType<DataTypeMember>();
        var birdBrushMtrBaseType = (birdBrushMtr as DataTypeMember).baseType;
        birdBrushMtrBaseType.should.beOfType<ArrayType>();
        var birdBrushMtrArrayType = birdBrushMtrBaseType as ArrayType;
        birdBrushMtrArrayType.arrayRanges.toString().should.be('[1..2]');
      },
    );

    test('DataType "sEvent.BirdBrushMtr" should have 5 children', () {
      var dataTypes = createDataTypes(sysmacProjectArchive);
      var dataTypePath = dataTypes.findFirstNodePath(
        namePathFinder(['sEvent', 'BirdBrushMtr']),
      );
      dataTypePath.should.not.beEmpty();
      var birdBrushMtr = dataTypePath.last;
      birdBrushMtr.should.beOfType<DataTypeMember>();
      birdBrushMtr.children.length.should.be(5);
    });

    test('DataType "sEvent.BirdBrushMtr" first child should be correct', () {
      var dataTypes = createDataTypes(sysmacProjectArchive);
      var dataTypePath = dataTypes.findFirstNodePath(
        namePathFinder(['sEvent', 'BirdBrushMtr']),
      );
      dataTypePath.should.not.beEmpty();
      var birdBrushMtr = dataTypePath.last;
      birdBrushMtr.should.beOfType<DataTypeMember>();
      birdBrushMtr.children.should.not.beEmpty();
      birdBrushMtr.children[0].should.beOfType<DataTypeMember>();
      var firstChild = birdBrushMtr.children[0] as DataTypeMember;
      firstChild.name.should.be('MtrSw');
      firstChild.comment.should.be('Switched off');
      firstChild.baseType.should.beOfType<IecBool>();
      firstChild.children.should.beEmpty();
    });
  });
}
