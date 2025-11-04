import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:shouldly/shouldly.dart';
import 'package:xml/xml.dart';

import '../../../../../../test_resource.dart';

void main() {
  group('SysmacProject', () {
    late SysmacProjectArchive sysmacProjectArchive;

    setUp(() async {
      sysmacProjectArchive = await SysmacProjectArchive.create(
        SysmacProjectTestResource().file,
      );
    });

    group('createFunctions() for a device element', () {
      late List<FunctionBlock> functionBlocks;

      setUp(() {
        XmlElement plcElement = sysmacProjectArchive
            .projectIndexXml
            .xmlDocument
            .descendantElements
            .firstWhere(
              (e) =>
                  e.name.local == entity &&
                  e.getAttribute(typeAttribute) == 'Device' &&
                  (e.getAttribute(subTypeAttribute) ?? '').startsWith('NJ'),
            );

        functionBlocks = createFunctionBlocks(sysmacProjectArchive, plcElement);
      });

      test('should return 5 functionBlocks', () {
        functionBlocks.length.should.be(23);
      });

      test(
        'device functionBlocks should not contain library functionBlocks like Pack-ML',
        () {
          functionBlocks
              .where((f) => f.name.startsWith('PML'))
              .should
              .beEmpty();
        },
      );

      group('First functionBlock', () {
        late FunctionBlock firstFunction;

        setUp(() {
          firstFunction = functionBlocks.first;
        });

        test(
          'first functionBlock should be StructuredTextFunctionBlock with correct properties',
          () {
            firstFunction.should.beOfType<StructuredTextFunctionBlock>();
            firstFunction.name.should.be('fbFFAutoTune');
            firstFunction.codeType.should.be(CodeType.structuredText);
            (firstFunction as StructuredTextFunctionBlock).structuredText.should
                .startWith('(* Header');
          },
        );
      });

      group('Last functionBlock', () {
        late FunctionBlock lastFunction;

        setUp(() {
          lastFunction = functionBlocks.last;
        });

        test(
          'last functionBlock should be a StructuredTextFunctionBlock with correct properties',
          () {
            lastFunction.should.beOfType<StructuredTextFunctionBlock>();
            lastFunction.name.should.be('fbIoLinkMaster_v0104');
            lastFunction.codeType.should.be(CodeType.structuredText);
            (lastFunction as StructuredTextFunctionBlock).structuredText.should
                .endWith('ENO := ENI;');
          },
        );
      });
    });
    group('createFunctions() for a library element', () {
      late List<FunctionBlock> functionBlocks;

      setUp(() {
        XmlElement libraryElement = sysmacProjectArchive
            .projectIndexXml
            .xmlDocument
            .descendantElements
            .where(isLibraryElement)
            .toList()[1];

        functionBlocks = createFunctionBlocks(
          sysmacProjectArchive,
          libraryElement,
        );
      });

      test('should return 5 functionBlocks', () {
        functionBlocks.length.should.be(63);
      });

      test(
        'device functionBlocks should not contain device functionBlocks ',
        () {
          functionBlocks
              .where((f) => f.name == 'fEncRevTrigger')
              .should
              .beEmpty();
        },
      );

      test(
        'library functionBlocks should not contain nested library functionBlocks ',
        () {
          functionBlocks
              .where((f) => f.name.startsWith('PML'))
              .should
              .beEmpty();
        },
      );

      group('First functionBlock', () {
        late FunctionBlock firstFunction;

        setUp(() {
          firstFunction = functionBlocks.first;
        });

        test(
          'first functionBlock should be StructuredTextFunctionBlock with correct properties',
          () {
            firstFunction.should.beOfType<StructuredTextFunctionBlock>();
            firstFunction.name.should.be('fbAverageDint');
            firstFunction.codeType.should.be(CodeType.structuredText);
            (firstFunction as StructuredTextFunctionBlock).structuredText.should
                .startWith('(* Header');
          },
        );
      });

      group('Last functionBlock', () {
        late FunctionBlock lastFunction;

        setUp(() {
          lastFunction = functionBlocks.last;
        });

        test(
          'last functionBlock should be a LadderFunctionBlock with correct properties',
          () {
            lastFunction.should.beOfType<LadderFunctionBlock>();
            lastFunction.name.should.be('fbUnitInterface');
            lastFunction.codeType.should.be(CodeType.ladder);
            (lastFunction as LadderFunctionBlock).rungs.length.should.be(12);
          },
        );
      });
    });
  });
}
