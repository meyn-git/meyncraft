import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.infrastructure.dart';

import '../../../test_resource.dart';

void main() {
  File file = SysmacProjectTestResource().file;
  var sysmacProjectArchive = SysmacProjectArchive(file);
  ProjectIndexXml projectIndexXml = sysmacProjectArchive.projectIndexXml;
  DataTypeTree dataTypeTree = DataTypeTreeFactory().create(
    sysmacProjectArchive,
  );

  group('class: ProjectIndexXml', () {
    group('method: findDataTypeArchiveFiles', () {
      test('not empty', () {
        var dataTypeArchiveFiles = projectIndexXml.dataTypeArchiveXmlFiles();
        expect(dataTypeArchiveFiles, isNotEmpty);
      });
    });
  });
}
