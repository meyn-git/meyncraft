import 'dart:io';

import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

/// FIXME: this is an temp app to investigate. remove later!!!

Future<void> main(List<String> args) async {
  var file = File(r'test\1176DE02-Evisceration-008.smc2');
  var sysmacProjectArchive = await SysmacProjectArchive.create(file);
  var elements =
      ((sysmacProjectArchive.projectIndexXml as ProjectIndexXml).xmlDocument)
          .siblingElements;
  var entities = elements.where((e) => e.name.local == 'Entity');
  for (var entity in entities) {
    print(
      'type=${entity.getAttribute('type')}, subtype=${entity.getAttribute('subtype')}, name=${entity.getAttribute('name')}',
    );
  }
  exit(0);
}
