import 'dart:io';

import 'package:meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/meyn_sysmac/event/event.infrastructure.dart';
import 'package:meyncraft/meyn_sysmac/identity/identity.domain.dart';
import 'package:meyncraft/meyn_sysmac/identity/identity.service.dart';
import 'package:meyncraft/meyn_sysmac/isa88/isa88.domain.dart';
import 'package:meyncraft/meyn_sysmac/isa88/isa88.infrastructure.dart';
import 'package:meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/sysmac/sysmac_project.infrastructure.dart';

/// An extension on a [SysmacProject] with additional information
/// for [SysmacProject]s that follow Meyn conventions.
class MeynSysmacProject extends SysmacProject {
  MeynSysmacProject(super.archive);

  late final SysmacProjectIdentity identity = createIdentity(archive.file);

  late final List<Event> events = createEvents(this);

  late final List<Isa88Node> isa88Nodes = createMeynIsa88Nodes(this);

  static Future<MeynSysmacProject> loadFromFile(File file) async {
    var sysmacProjectArchive = await SysmacProjectArchive.loadFromFile(file);
    return MeynSysmacProject(sysmacProjectArchive);
  }
}
