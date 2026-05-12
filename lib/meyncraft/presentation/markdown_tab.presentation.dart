import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:meyncraft/meyncraft/presentation/style/markdown_style_sheet.presentation.dart';
import 'package:meyncraft/meyncraft/presentation/tab.presentation.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownTab extends ClosableTab {
  final MarkdownTabContent content;

  MarkdownTab(this.content, {super.key}) : super(tabTitle: content.tabTitle);

  @override
  State<MarkdownTab> createState() => _MarkdownTabState();
}

class _MarkdownTabState extends State<MarkdownTab> {
  @override
  Widget build(BuildContext context) =>
      widget.content is DynamicMarkdownTabContent
      ? ListenableBuilder(
          listenable: (widget.content as DynamicMarkdownTabContent),
          builder: (BuildContext context, Widget? child) => Markdown(
            styleSheet: MeynMarkdownStyleSheet(context),
            data: widget.content.markdown,
            onTapLink: onLinkTap,
          ),
        )
      : Markdown(
          styleSheet: MeynMarkdownStyleSheet(context),
          data: widget.content.markdown,
          onTapLink: onLinkTap,
        );

  void onLinkTap(String text, String? href, String? title) {
    if (href != null) {
      var uri = Uri.parse(href);
      switch (uri.scheme.toLowerCase()) {
        case 'meyncraft':
          openMeynCraftTab(uri);
          break;
        case 'file':
          openFileExplorerAtFileLocation(uri);
          break;
        default:
          launchUrl(uri);
      }
    }
  }

  void openMeynCraftTab(Uri meynCraftUri) {
    // TODO open (or select an existing) tab using an ID that can be found in widget.content.meynConnectLinks
    // var templateName = meynCraftUri.path;
    // var template = allTemplates().firstWhere(
    //   (t) => t.name == templateName,
    //   orElse: () => throw Exception('Template not found: $templateName'),
    // );
    // var tabService = GetIt.I.get<TabService>();
    // tabService.addOrSelectTab(TemplateDetailTab(template: template));
    print('meynCraftUri: $meynCraftUri');
  }

  void openFileExplorerAtFileLocation(Uri fileUri) {
    final file = File.fromUri(fileUri);
    Process.run('explorer', ['/select,', file.path]);
  }
}

abstract class MarkdownTabContent {
  String get tabTitle;
  String get markdown;
}

class StaticMarkdownContent implements MarkdownTabContent {
  @override
  final String markdown;

  @override
  final String tabTitle;

  StaticMarkdownContent({required this.markdown, required this.tabTitle});
}

class DynamicMarkdownTabContent extends ChangeNotifier
    implements MarkdownTabContent {
  final StringBuffer _markdownBuffer = StringBuffer();

  void append(String markdown) {
    _markdownBuffer.writeln(markdown);
    notifyListeners();
  }

  void set(String markdown) {
    _markdownBuffer.clear();
    _markdownBuffer.writeln(markdown);
    notifyListeners();
  }

  @override
  String get markdown => _markdownBuffer.toString();

  @override
  final String tabTitle;

  DynamicMarkdownTabContent(this.tabTitle);
}
