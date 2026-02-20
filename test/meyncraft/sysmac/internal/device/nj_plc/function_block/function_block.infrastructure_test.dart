import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:shouldly/shouldly.dart';
import 'package:xml/xml.dart';

import '../../../../../../test_resource.dart';

void main() {
  group('SysmacProject', () {
    late SysmacProject sysmacProject;

    setUp(() async {
      sysmacProject = await SysmacProject.create(
        SysmacProjectTestResource().file,
      );
    });

    group('createFunctions() for a device element', () {
      late List<FunctionBlock> functionBlocks;

      setUp(() {
        XmlElement plcElement = sysmacProject
            .archive
            .projectIndexXml
            .xmlDocument
            .descendantElements
            .firstWhere(
              (e) =>
                  e.name.local == entity &&
                  e.getAttribute(typeAttribute) == 'Device' &&
                  (e.getAttribute(subTypeAttribute) ?? '').startsWith('NJ'),
            );

        functionBlocks = createFunctionBlocks(sysmacProject, plcElement);
      });

      test('should return 5 functionBlocks', () {
        functionBlocks.length.should.be(25);
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
            firstFunction.name.should.be('fbVenneGateway');
            firstFunction.codeType.should.be(CodeType.structuredText);
            firstFunction.internalVariables.length.should.be(27);
            firstFunction.externalVariables.length.should.be(0);
            firstFunction.inOutVariables.length.should.be(19);
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
            lastFunction.internalVariables.length.should.be(34);
            lastFunction.externalVariables.length.should.be(0);
            lastFunction.inOutVariables.length.should.be(18);
            (lastFunction as StructuredTextFunctionBlock).structuredText.should
                .endWith('ENO := ENI;');
          },
        );
      });
    });
    group('createFunctions() for a library element', () {
      late List<FunctionBlock> functionBlocks;

      setUp(() {
        XmlElement libraryElement = sysmacProject
            .archive
            .projectIndexXml
            .xmlDocument
            .descendantElements
            .where(isLibraryElement)
            .toList()[1];

        functionBlocks = createFunctionBlocks(sysmacProject, libraryElement);
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
            firstFunction.internalVariables.length.should.be(9);
            firstFunction.externalVariables.length.should.be(0);
            firstFunction.inOutVariables.length.should.be(8);
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
            lastFunction.internalVariables.length.should.be(1);
            lastFunction.externalVariables.length.should.be(0);
            lastFunction.inOutVariables.length.should.be(15);
            (lastFunction as LadderFunctionBlock).rungs.length.should.be(12);
          },
        );
      });
    });
  });
}
