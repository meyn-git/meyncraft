import 'dart:io';

import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/device.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/identity/identity.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/event/event.service.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/identity/identity.service.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'internal/data_type/data_type.domain.dart';

/// Represents a physical Sysmac project file,
/// which is actually a zip [Archive] containing [ArchiveFile]s
class SysmacProject {
  late final SysmacProjectArchive archive;

  late final SysmacProjectIdentity identity = createIdentity(archive.file);

  //TODO change it to a function (see createDevices)
  late final DataTypeTree dataTypeTree = DataTypeTreeFactory().create(archive);

  late final List<Variable> globalVariables = createGlobalVariables(
    archive,
    dataTypeTree,
  );

  //TODO move to NxPlc and change it to a function (see createDevices)
  late final EventService eventService = EventService(globalVariables);

  late final List<Device> devices = createDevices(this);

  SysmacProject(this.archive);

  static Future<SysmacProject> create(File file) async {
    var sysmacProjectArchive = await SysmacProjectArchive.create(file);
    return SysmacProject(sysmacProjectArchive);
  }
}
