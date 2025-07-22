import 'package:meyncraft/meyncraft/generate/sysmac/event_array_code_file.service.dart';
import 'package:meyncraft/meyncraft/generate/xor_jmobile/events_file.service.dart';
import 'package:meyncraft/meyncraft/generate/xor_jmobile/tags_file.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.infrastructure.dart';

void generate(String sysmacProjectFilePath) {
  try {
    logger.info('Reading: $sysmacProjectFilePath');

    var sysmacProject = SysmacProjectFactory().create(sysmacProjectFilePath);

    writeJMobileTagsFile(sysmacProject);
    writeJMobileEventsFile(sysmacProject);
    writeSysmacEventArrayCodeFile(sysmacProject);
  } catch (e, s) {
    logger.info('Error while generating files for $sysmacProjectFilePath:');
    logger.info(e.toString());
    logger.info(s.toString());
  }
  logger.info('Finished.');
  logger.info('Restart the app to re-generate files.');
}
