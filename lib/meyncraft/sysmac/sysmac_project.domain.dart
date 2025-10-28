import 'dart:io';

import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/identity/identity.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/event/event.service.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/identity/identity.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/pou/pou.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/pou/pou.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.service.dart';
import 'internal/data_type/data_type.domain.dart';

/// Represents a physical Sysmac project file,
/// which is actually a zip [Archive] containing [ArchiveFile]s
class SysmacProject {
  late final SysmacProjectArchive _archive;

  late final SysmacProjectIdentity details = createIdentity(_archive.file);

  late final DataTypeTree dataTypeTree = DataTypeTreeFactory().create(_archive);

  late final GlobalVariableService globalVariableService =
      GlobalVariableService(_archive, dataTypeTree);

  late final EventService eventService = EventService(globalVariableService);

  late final List<ProgramOrganizationUnit> _programOrganizationUnits =
      createPous(_archive);

  late final List<ProgramBody> programs = _programOrganizationUnits
      .whereType<ProgramBody>()
      .toList();

  // TODO late final List<Function$> functions=programOrganizationUnits.whereType<Function$>().toList();
  // TODO late final List<FunctionBlock> functionBlocks=programOrganizationUnits.whereType<FunctionBlock>().toList();

  SysmacProject(this._archive);

  static Future<SysmacProject> create(File file) async {
    var sysmacProjectArchive = await SysmacProjectArchive.create(file);
    return SysmacProject(sysmacProjectArchive);
  }
}
