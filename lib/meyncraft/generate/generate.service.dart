import 'dart:io';

import 'package:meyncraft/meyncraft/generate/exor_jmobile/events_file.service.dart';
import 'package:meyncraft/meyncraft/generate/exor_jmobile/tags_file.service.dart';
import 'package:meyncraft/meyncraft/generate/reports/isa88_report_service.dart';
import 'package:meyncraft/meyncraft/generate/sysmac/event_array_code_file.service.dart';
import 'package:meyncraft/meyncraft/generate/sysmac/fb_check_packml_monitor_service.dart';
import 'package:meyncraft/meyncraft/generate/reports/event_report.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';

Future<void> generate(String sysmacProjectFilePath) async {
  try {
    logger.info('Reading: $sysmacProjectFilePath');
    var file = File(sysmacProjectFilePath);
    var sysmacProject = await MeynSysmacProject.create(file);

    await writeJMobileTagsFile(sysmacProject);
    await writeJMobileEventsFile(sysmacProject);
    await writeSysmacEventArrayXmlImportFile(sysmacProject);
    await writeEventReportFile(sysmacProject);
    await writeIsa88ReportFile(sysmacProject);
    // await writeSysmacFbCheckPackMlScFile(sysmacProject);
    // await writeSysmacUnitInterfaceXmlImportFile(sysmacProject);
    await writeSysmacPackMlMonitorFile(sysmacProject);
  } catch (e, s) {
    logger.info('Error while generating files for $sysmacProjectFilePath:');
    logger.info(e.toString());
    logger.info(s.toString());
  }
  logger.completed = true;
}
