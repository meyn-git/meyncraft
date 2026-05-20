import 'package:meyncraft/template/custom/exor_jmobile/jmobile_events_template.domain.dart';
import 'package:meyncraft/template/custom/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/template/custom/reports/event_report_template.domain.dart';
import 'package:meyncraft/template/custom/reports/isa88_report_template.domain.dart';
import 'package:meyncraft/template/custom/sysmac/sysmac_event_global_array_template.domain.dart';
import 'package:meyncraft/template/custom/sysmac/sysmac_packml_monitor_template.domain.dart';
import 'package:meyncraft/template/template.domain.dart';

final List<TemplateProject> allTemplates = [
  JMobileTagsTemplate(),
  JMobileEventsTemplate(),
  SysmacEventGlobalArrayTemplate(),
  SysmacPackMlMonitorTemplate(),
  EventReportTemplate(),
  Isa88ReportTemplate(),
];
