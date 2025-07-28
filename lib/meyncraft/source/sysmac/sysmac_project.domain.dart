import 'package:meyncraft/meyncraft/source/sysmac/identity/identity.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/event.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'data_type/data_type.domain.dart';

/// Represents a physical Sysmac project file,
/// which is actually a zip [Archive] containing [ArchiveFile]s
class SysmacProject {
  // final SysmacProjectArchive archive;
  // final Site? site;
  // final ElectricPanel? electricPanel;
  // final PlcName? plcName;
  // final SysmacProjectVersion? sysmacProjectVersion;
  final SysmacProjectIdentity details;
  final DataTypeTree dataTypeTree;
  final GlobalVariableService globalVariableService;
  final EventService eventService;

  SysmacProject({
    required this.details,
    required this.dataTypeTree,
    required this.globalVariableService,
    required this.eventService,
  });
}
