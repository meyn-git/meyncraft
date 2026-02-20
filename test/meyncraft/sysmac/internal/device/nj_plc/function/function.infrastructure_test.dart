import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.infrastructure.dart';
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
      late List<Function$> functions;

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

        functions = createFunctions(sysmacProject, plcElement);
      });

      test('should return 6 functions', () {
        functions.length.should.be(6);
      });

      test(
        'device functions should not contain library functions like Pack-ML',
        () {
          functions.where((f) => f.name.startsWith('PML')).should.beEmpty();
        },
      );

      group('First function', () {
        late Function$ firstFunction;

        setUp(() {
          firstFunction = functions.first;
        });

        test(
          'first function should be StructuredTextFunction with correct properties',
          () {
            firstFunction.should.beOfType<StructuredTextFunction>();
            firstFunction.name.should.be('fEncRevTrigger');
            firstFunction.codeType.should.be(CodeType.structuredText);
            firstFunction.internalVariables.length.should.be(0);
            firstFunction.externalVariables.length.should.be(0);
            firstFunction.inOutVariables.length.should.be(3);
            (firstFunction as StructuredTextFunction).structuredText.should
                .startWith('(* Header');
          },
        );
      });

      group('Last function', () {
        late Function$ lastFunction;

        setUp(() {
          lastFunction = functions.last;
        });

        test(
          'last function should be a StructuredTextFunction with correct properties',
          () {
            lastFunction.should.beOfType<StructuredTextFunction>();
            lastFunction.name.should.be('fAngleCalculation');
            lastFunction.codeType.should.be(CodeType.structuredText);
            lastFunction.internalVariables.length.should.be(5);
            lastFunction.externalVariables.length.should.be(0);
            lastFunction.inOutVariables.length.should.be(9);
            (lastFunction as StructuredTextFunction).structuredText.should
                .endWith('fAngleCalculation := TRUE;');
          },
        );
      });
    });
    group('createFunctions() for a library element', () {
      late List<Function$> functions;

      setUp(() {
        XmlElement libraryElement = sysmacProject
            .archive
            .projectIndexXml
            .xmlDocument
            .descendantElements
            .where(isLibraryElement)
            .toList()[1];

        functions = createFunctions(sysmacProject, libraryElement);
      });

      test('should return 5 functions', () {
        functions.length.should.be(22);
      });

      test('device functions should not contain device functions ', () {
        functions.where((f) => f.name == 'fEncRevTrigger').should.beEmpty();
      });

      test(
        'library functions should not contain nested library functions ',
        () {
          functions.where((f) => f.name.startsWith('PML')).should.beEmpty();
        },
      );

      group('First function', () {
        late Function$ firstFunction;

        setUp(() {
          firstFunction = functions.first;
        });

        test(
          'first function should be StructuredTextFunction with correct properties',
          () {
            firstFunction.should.beOfType<StructuredTextFunction>();
            firstFunction.name.should.be('fActualValueReal');
            firstFunction.codeType.should.be(CodeType.structuredText);
            firstFunction.internalVariables.length.should.be(1);
            firstFunction.externalVariables.length.should.be(0);
            firstFunction.inOutVariables.length.should.be(5);
            (firstFunction as StructuredTextFunction).structuredText.should
                .startWith('(* Header');
          },
        );
      });

      group('Last function', () {
        late Function$ lastFunction;

        setUp(() {
          lastFunction = functions.last;
        });

        test(
          'last function should be a StructuredTextFunction with correct properties',
          () {
            lastFunction.should.beOfType<StructuredTextFunction>();
            lastFunction.name.should.be('TIME_TO_REAL');
            lastFunction.codeType.should.be(CodeType.structuredText);
            lastFunction.internalVariables.length.should.be(0);
            lastFunction.externalVariables.length.should.be(0);
            lastFunction.inOutVariables.length.should.be(3);
            (lastFunction as StructuredTextFunction).structuredText.should
                .endWith('ENO := TRUE;');
          },
        );
      });
    });
  });
}
