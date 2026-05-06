import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/generate/generator.service.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/tab.service.dart';
import 'package:meyncraft/meyncraft/style/markdown_style_sheet.presentation.dart';
import 'package:meyncraft/meyncraft/template/template.service.dart';
import 'package:meyncraft/meyncraft/template/template_detail_tab.presentation.dart';
import 'package:url_launcher/url_launcher.dart';

class GeneratorResultTab extends ClosableTab {
  final MarkdownReport outputReport;

  const GeneratorResultTab(this.outputReport, {required super.tabKey})
    : super(tabName: 'Generator Results');

  @override
  State<GeneratorResultTab> createState() => _GeneratorResultTabState();
}

class _GeneratorResultTabState extends State<GeneratorResultTab> {
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.outputReport,
    builder: (BuildContext context, Widget? child) => Markdown(
      styleSheet: MeynMarkdownStyleSheet(context),
      data: widget.outputReport.markdown,
      onTapLink: onLinkTap,
    ),
  );

  void onLinkTap(String text, String? href, String? title) {
    if (href != null) {
      var uri = Uri.parse(href);
      if (uri.scheme == 'detail') {
        var templateName = uri.path;
        var template = allTemplates().firstWhere(
          (t) => t.name == templateName,
          orElse: () => throw Exception('Template not found: $templateName'),
        );
        var tabService = GetIt.I.get<TabService>();
        tabService.addOrSelectTab(
          TemplateDetailTab(template: template, tabKey: UniqueKey()),
        );
      } else {
        launchUrl(uri);
      }
    }
  }
}

/// FIXME: remove
//  class GeneratorResultTab2 extends ClosableTab {
//   final StreamController<GeneratorResult> results;

//   GeneratorResultTab(this.results) : super(tabName: 'Generator Results');

//   var markdown = StringBuffer();

//   @override
//   Widget build(BuildContext context)  => StreamBuilder<GeneratorResult>(
//     stream: results.stream,
//     builder: (context, snapshot) {
//       if (snapshot.hasData) {
//         var result = snapshot.data!;
//         markdown.writeln(result.toMarkdown());
//       }
//       return Markdown(
//         styleSheet: MeynMarkdownStyleSheet(context),
//         data: markdown.toString(),
//         onTapLink: (text, href, title) {
//           if (href != null) {
//             var uri = Uri.parse(href);
//             if (uri.scheme == 'detail') {
//               var templateName = uri.path;
//               var template = allTemplates().firstWhere(
//                 (t) => t.name == templateName,
//                 orElse: () =>
//                     throw Exception('Template not found: $templateName'),
//               );
//               var tabService = GetIt.I.get<TabService>();
//               tabService.addOrSelectTab(TemplateDetailTab(template));
//             } else {
//               launchUrl(uri);
//             }
//           }
//         },
//       );
//     },
//   );

// }
