import 'dart:async';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/generate/exor_jmobile/events_file.service.dart';
import 'package:meyncraft/meyncraft/generate/exor_jmobile/tags_file.service.dart';
import 'package:meyncraft/meyncraft/generate/generate_result.domain.dart';
import 'package:meyncraft/meyncraft/generate/generator_parameter_tab.presentation.dart';
import 'package:meyncraft/meyncraft/generate/generator_result_tab.presentation.dart';
import 'package:meyncraft/meyncraft/generate/reports/isa88_report_service.dart';
import 'package:meyncraft/meyncraft/generate/sysmac/event_array_code_file.service.dart';
import 'package:meyncraft/meyncraft/generate/sysmac/fb_check_packml_monitor_service.dart';
import 'package:meyncraft/meyncraft/generate/reports/event_report.service.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';

Future<void> generateOld(String sysmacProjectFilePath) async {
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

Future<void> generateNew(
  List<Template> selectedTemplates,
  Map<String, dynamic> parameterValues,
  StreamController<GeneratorResult> results,
) async {
  var tabService = GetIt.I.get<TabService>();
  tabService.addTab(GeneratorResultTab(results));

  for (var template in selectedTemplates) {
    var templateResult = TemplateGenerationResult(template, results);
    results.add(templateResult);
    for (var generator in template.generators) {
      try {
        await generator.generate(
          //sysmacProject,
          parameterValues,
          templateResult.childResults,
        );
      } on Exception catch (e) {
        templateResult.childResults.add(
          Error(
            'Error generating ${generator.source.runtimeType}: ${e.toString()}',
          ),
        );
      }
    }
  }

  results.add(Info('Generation completed.'));
  results.close();
}
