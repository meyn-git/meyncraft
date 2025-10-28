import 'dart:io';

import 'package:meyncraft/meyncraft/generate/sysmac/event_array_code_file.service.dart';
import 'package:meyncraft/meyncraft/generate/sysmac/event_file.service.dart';
import 'package:meyncraft/meyncraft/generate/sysmac/fb_check_packml_sc_service.dart';
import 'package:meyncraft/meyncraft/generate/sysmac/unit_interface_service.dart';
import 'package:meyncraft/meyncraft/generate/xor_jmobile/events_file.service.dart';
import 'package:meyncraft/meyncraft/generate/xor_jmobile/tags_file.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';

Future<void> generate(String sysmacProjectFilePath) async {
  try {
    logger.info('Reading: $sysmacProjectFilePath');
    var file = File(sysmacProjectFilePath);
    var sysmacProject = await SysmacProject.create(file);

    await writeJMobileTagsFile(sysmacProject);
    await writeJMobileEventsFile(sysmacProject);

    await writeSysmacUnitInterfaceXmlImportFile(sysmacProject);
    await writeSysmacFbCheckPackMlScFile(sysmacProject);
    await writeSysmacEventArrayXmlImportFile(sysmacProject);
    await writeSysmacEventFile(sysmacProject);
  } catch (e, s) {
    logger.info('Error while generating files for $sysmacProjectFilePath:');
    logger.info(e.toString());
    logger.info(s.toString());
  }
  logger.completed = true;
}
