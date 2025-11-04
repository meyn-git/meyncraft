import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/code_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:shouldly/shouldly.dart';
import 'package:xml/xml.dart';

import '../../../../../../test_resource.dart';

void main() {
  group('SysmacProject', () {
    late SysmacProjectArchive sysmacProjectArchive;
    late XmlElement plcElement;

    setUp(() async {
      sysmacProjectArchive = await SysmacProjectArchive.create(
        SysmacProjectTestResource().file,
      );

      plcElement = sysmacProjectArchive
          .projectIndexXml
          .xmlDocument
          .descendantElements
          .firstWhere(
            (e) =>
                e.name.local == entity &&
                e.getAttribute(typeAttribute) == 'Device' &&
                (e.getAttribute(subTypeAttribute) ?? '').startsWith('NJ'),
          );
    });

    group('createPrograms()', () {
      late List<Program> programs;

      setUp(() {
        programs = createPrograms(sysmacProjectArchive, plcElement);
      });

      test('should return 28 programs', () {
        programs.length.should.be(28);
      });

      group('First program', () {
        late Program firstProgram;

        setUp(() {
          firstProgram = programs.first;
        });

        test(
          'first program should be LadderProgram with correct properties',
          () {
            firstProgram.should.beOfType<LadderProgram>();
            firstProgram.name.should.be('TaskControl');
            firstProgram.codeType.should.be(CodeType.ladder);
            (firstProgram as LadderProgram).length.should.be(1);
          },
        );

        group('first section of first program', () {
          late LadderSection firstSection;

          setUp(() {
            firstSection = (firstProgram as LadderProgram).first;
          });

          test('should have correct name and rung count', () {
            firstSection.name.should.be('TaskOnOff');
            firstSection.rungs.length.should.be(2);
          });

          group('first rung', () {
            late Rung firstRung;

            setUp(() {
              firstRung = firstSection.rungs.first;
            });

            test('should have correct comment and ladder object count', () {
              firstRung.comment.should.be('Run tasks startup');
              firstRung.ladderObjects.length.should.be(75);
            });

            test(
              'first ladder object should be a Contact with correct variable',
              () {
                final obj = firstRung.ladderObjects.first;
                obj.should.beOfType<Contact>();
                (obj as Contact).variable.should.be('P_First_Run');
              },
            );

            test(
              'should contain correct number of specific ladder object types',
              () {
                firstRung.ladderObjects.whereType<Coil>().length.should.be(25);
                firstRung.ladderObjects
                    .whereType<HorizontalLine>()
                    .length
                    .should
                    .be(17);
                firstRung.ladderObjects
                    .whereType<VerticalLine>()
                    .length
                    .should
                    .be(24);
              },
            );

            test('last ladder object should be a VerticalLine', () {
              firstRung.ladderObjects.last.should.beOfType<VerticalLine>();
            });
          });

          group('second rung', () {
            late Rung secondRung;

            setUp(() {
              secondRung = firstSection.rungs[1];
            });

            test('should have correct comment and ladder object count', () {
              secondRung.comment.should.be('Start/stop program');
              secondRung.ladderObjects.length.should.be(2);
            });

            test(
              'second ladder object should be InlineStructuredText with correct content',
              () {
                final obj = secondRung.ladderObjects[1];
                obj.should.beOfType<InlineStructuredText>();
                (obj as InlineStructuredText).structuredText.should.startWith(
                  "// Start/stop program for 'Hardware'",
                );
              },
            );
          });
        });
      });

      group('Last program', () {
        late Program lastProgram;

        setUp(() {
          lastProgram = programs.last;
        });

        test(
          'last program should be a StructuredTextProgram with correct properties',
          () {
            lastProgram.should.beOfType<StructuredTextProgram>();
            lastProgram.name.should.be('Test');
            lastProgram.codeType.should.be(CodeType.structuredText);
            (lastProgram as StructuredTextProgram).name.should.be('Test');
            (lastProgram as StructuredTextProgram).structuredText.should
                .endWith('numer:=1+1;');
          },
        );
      });
    });
  });
}
