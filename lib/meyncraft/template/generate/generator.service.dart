import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/presentation/markdown_tab.presentation.dart';
import 'package:meyncraft/meyncraft/template/custom/exor_jmobile/jmobile_events_template.domain.dart';
import 'package:meyncraft/meyncraft/template/custom/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/meyncraft/template/custom/reports/isa88_report_template.domain.dart';
import 'package:meyncraft/meyncraft/template/custom/sysmac/sysmac_event_global_array_template.domain.dart';
import 'package:meyncraft/meyncraft/template/custom/sysmac/sysmac_packml_monitor_template.domain.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';

@Deprecated('Use generate() instead')
Future<void> generateOld(String sysmacProjectFilePath) async {
  try {
    logger.info('Reading: $sysmacProjectFilePath');
    var file = File(sysmacProjectFilePath);
    var sysmacProject = await MeynSysmacProject.loadFromFile(file);

    await writeJMobileTagsFile(sysmacProject);
    await writeJMobileEventsFile(sysmacProject);
    await writeSysmacEventArrayXmlImportFile(sysmacProject);
    // await writeEventReportFile(sysmacProject);
    await writeIsa88ReportFile(sysmacProject);
    // await writeSysmacFbCheckPackMlScFile(sysmacProject);
    // await writeSysmacUnitInterfaceXmlImportFile(sysmacProject);
    await writeSysmacPackMlMonitorFiles(sysmacProject);
  } catch (e, s) {
    logger.info('Error while generating files for $sysmacProjectFilePath:');
    logger.info(e.toString());
    logger.info(s.toString());
  }
  logger.completed = true;
}

Future<DynamicMarkdownTabContent> generate(
  List<Template> selectedTemplates,
  Map<String, dynamic> parameterValues,
  DynamicMarkdownTabContent outputReport,
) async {
  for (var template in selectedTemplates) {
    //var templateResult = TemplateGenerationResult(template, results);
    outputReport.append('# [${template.name}](meyncraft:${template.name})\n');
    for (var generator in template.generators) {
      try {
        outputReport = await generator.generate(
          template,
          parameterValues,
          outputReport,
        );
      } on Exception catch (e, stackTrace) {
        var errorLink = GenerationErrorLink(
          template: template,
          generator: generator,
          message: 'Error generating ${generator.source}',
          stackTrace: stackTrace,
        );
        outputReport.append('* ${errorLink.toMarkdown()}');
      }
    }
  }

  outputReport.append('# Generation completed.');
  outputReport.append(
    '[Click here to run again with the same parameters](meyncraft://regenerate)',
  );
  return outputReport;
}
