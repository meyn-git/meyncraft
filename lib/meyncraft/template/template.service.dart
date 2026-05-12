import 'package:meyncraft/meyncraft/template/custom/exor_jmobile/jmobile_events_template.domain.dart';
import 'package:meyncraft/meyncraft/template/custom/exor_jmobile/jmobile_tags_tempate.domain.dart';
import 'package:meyncraft/meyncraft/template/custom/reports/event_report_template.domain.dart';
import 'package:meyncraft/meyncraft/template/custom/reports/isa88_report_template.domain.dart';
import 'package:meyncraft/meyncraft/template/custom/sysmac/sysmac_event_global_array_template.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';

List<Template> allTemplates() {
  return [
    JMobileTagsTemplate(),
    JMobileEventsTemplate(),
    SysmacEventGlobalArrayTemplate(),
    EventReportTemplate(),
    Isa88ReportTemplate(),
  ];
}
