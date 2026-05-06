import 'dart:io';

import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/device.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.infrastructure.dart';
import 'internal/data_type/data_type.domain.dart';

/// Represents a physical Sysmac project file.
///
/// A Sysmac Project File is an exported
/// [Omron Sysmac project](https://automation.omron.com/en/us/products/family/sysstdio).
/// This is a file with the *.scm file extension.
///
/// This file is  actually a zip [Archive] containing [ArchiveFile]s
class SysmacProject {
  late final SysmacProjectArchive archive;

  late final List<DataTypeBase> dataTypes = createDataTypes(archive);

  late final List<Variable> globalVariables = createGlobalVariables(
    archive,
    dataTypes,
  );

  late final List<Device> devices = createDevices(this);

  SysmacProject(this.archive);

  static Future<SysmacProject> create(File file) async {
    var sysmacProjectArchive = await SysmacProjectArchive.loadFromFile(file);
    return SysmacProject(sysmacProjectArchive);
  }
}
