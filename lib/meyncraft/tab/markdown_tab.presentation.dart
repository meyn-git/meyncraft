import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/style/markdown_style_sheet.presentation.dart';
import 'package:meyncraft/meyncraft/tab/tab.presentation.dart';
import 'package:meyncraft/meyncraft/tab/tab.service.dart';
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
    if (widget.content is DynamicMarkdownTabContent) {
      var hashCode = meynCraftUri.host;
      var tabs = (widget.content as DynamicMarkdownTabContent).tabs;
      var tab = tabs.firstWhereOrNull(
        (tab) => tab.hashCode.toString() == hashCode,
      );
      if (tab != null) {
        var tabService = GetIt.I.get<TabService>();
        tabService.addOrSelectTab(tab);
      }
    }
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

  @override
  String get markdown => _markdownBuffer.toString();

  @override
  final String tabTitle;

  final List<ClosableTab> tabs = <ClosableTab>[];

  DynamicMarkdownTabContent(this.tabTitle);

  Uri addLink(ClosableTab tab) {
    tabs.add(tab);
    return Uri(scheme: 'meyncraft', host: tab.hashCode.toString());
  }

  void addToMarkdown(String markdown) {
    _markdownBuffer.writeln(markdown);
    notifyListeners();
  }

  void setMarkdown(String markdown) {
    _markdownBuffer.clear();
    _markdownBuffer.writeln(markdown);
    notifyListeners();
  }
}
