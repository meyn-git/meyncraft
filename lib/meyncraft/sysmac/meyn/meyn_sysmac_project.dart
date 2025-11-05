import 'dart:io';

import 'package:meyncraft/meyncraft/sysmac/meyn/event/event.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/event/event.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/identity/identity.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/identity/identity.service.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';

/// An extension on a [SysmacProject] with additional information
/// for [SysmacProject]s that follow Meyn conventions
class MeynSysmacProject extends SysmacProject {
  MeynSysmacProject(super.archive);

  late final List<Event> events = createEvents(this);

  late final SysmacProjectIdentity identity = createIdentity(archive.file);

  static Future<MeynSysmacProject> create(File file) async {
    var sysmacProjectArchive = await SysmacProjectArchive.create(file);
    return MeynSysmacProject(sysmacProjectArchive);
  }
}
