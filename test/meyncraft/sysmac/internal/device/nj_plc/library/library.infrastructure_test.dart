import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
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

    group('createLibraries()', () {
      late List<Library> libraries;

      setUp(() {
        libraries = createLibraries(sysmacProjectArchive, plcElement);
      });

      test('should return 3 libraries', () {
        libraries.length.should.be(3);
      });

      test('first library should be Library with correct properties', () {
        var firstLibrary = libraries.first;
        firstLibrary.name.should.be('Meyn_MeynConnect1.2');
        firstLibrary.libraries.length.should.be(0);
        firstLibrary.programs.length.should.be(0);
        firstLibrary.functions.length.should.be(2);
        firstLibrary.functionBlocks.length.should.be(10);
      });

      test('second library should be Library with correct properties', () {
        var secondLibrary = libraries[1];
        secondLibrary.name.should.be('Meyn_Standard');
        secondLibrary.libraries.length.should.be(1);
        secondLibrary.programs.length.should.be(0);
        secondLibrary.functions.length.should.be(22);
        secondLibrary.functionBlocks.length.should.be(63);
      });

      test(
        'nested library in second library should be Library with correct properties',
        () {
          var secondLibrary = libraries[1];
          var nestedLibrary = secondLibrary.libraries.first;
          nestedLibrary.name.should.be('OmronLib_PackML30_V2_0');
          nestedLibrary.libraries.length.should.be(0);
          nestedLibrary.programs.length.should.be(0);
          nestedLibrary.functions.length.should.be(36);
          nestedLibrary.functionBlocks.length.should.be(4);
        },
      );

      test(
        'last library should be a StructuredTextLibrary with correct properties',
        () {
          var lastLibrary = libraries.last;
          lastLibrary.name.should.be('Meyn_Equipment');
          lastLibrary.libraries.length.should.be(0);
          lastLibrary.programs.length.should.be(0);
          lastLibrary.functions.length.should.be(1);
          lastLibrary.functionBlocks.length.should.be(22);
        },
      );
    });
  });
}
