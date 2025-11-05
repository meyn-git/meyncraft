import 'dart:io';

import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/device.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'internal/data_type/data_type.domain.dart';

/// Represents a physical Sysmac project file,
/// which is actually a zip [Archive] containing [ArchiveFile]s
class SysmacProject {
  late final SysmacProjectArchive archive;

  //TODO change it to a function (see createDevices)
  late final DataTypeTree dataTypeTree = DataTypeTreeFactory().create(archive);

  late final List<Variable> globalVariables = createGlobalVariables(
    archive,
    dataTypeTree,
  );

  late final List<Device> devices = createDevices(this);

  SysmacProject(this.archive);

  static Future<SysmacProject> create(File file) async {
    var sysmacProjectArchive = await SysmacProjectArchive.create(file);
    return SysmacProject(sysmacProjectArchive);
  }
}
