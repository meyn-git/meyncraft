import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/scroll_bar.presentation.dart';
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
          builder: (BuildContext context, Widget? child) =>
              ContentView(widget.content),
        )
      : ContentView(widget.content);
}

class ContentView extends StatelessWidget {
  final MarkdownTabContent content;
  const ContentView(this.content, {super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      MarkdownView(content: content),
      if (content.buttons.isNotEmpty) BottomButtonBar(content: content),
    ],
  );
}

class MarkdownView extends StatelessWidget {
  const MarkdownView({super.key, required this.content});

  final MarkdownTabContent content;

  @override
  Widget build(BuildContext context) => Expanded(
    child: ScrollbarAlwaysVisible(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(
            styleSheet: MeynMarkdownStyleSheet(context),
            data: content.markdown,
            onTapLink: onLinkTap,
            // ),
          ),
        ),
      ),
    ),
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
    var hashCode = meynCraftUri.host;
    var tabs = content.linkedTabs;
    var tab = tabs.firstWhereOrNull(
      (tab) => tab.hashCode.toString() == hashCode,
    );
    if (tab != null) {
      var tabService = GetIt.I.get<TabService>();
      tabService.addOrSelectTab(tab);
    }
  }

  void openFileExplorerAtFileLocation(Uri fileUri) {
    final file = File.fromUri(fileUri);
    Process.run('explorer', ['/select,', file.path]);
  }
}

class BottomButtonBar extends StatelessWidget {
  const BottomButtonBar({super.key, required this.content});

  final MarkdownTabContent content;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12, // horizontal spacing
        children: content.buttons,
      ),
    ),
  );
}

abstract class MarkdownTabContent {
  String get tabTitle;
  String get markdown;

  /// Tabs that the markdown kan refer to with a hyperlink uri. See [meynCraftUriToTab]
  List<ClosableTab> get linkedTabs;

  List<Widget> get buttons;
}

Uri meynCraftUriToTab(ClosableTab tab) =>
    Uri(scheme: 'meyncraft', host: tab.hashCode.toString());

class StaticMarkdownContent implements MarkdownTabContent {
  @override
  final String markdown;

  @override
  final String tabTitle;

  @override
  final List<ClosableTab> linkedTabs;

  @override
  final List<Widget> buttons;

  StaticMarkdownContent({
    required this.markdown,
    required this.tabTitle,
    this.linkedTabs = const [],
    this.buttons = const [],
  });
}

class DynamicMarkdownTabContent extends ChangeNotifier
    implements MarkdownTabContent {
  final StringBuffer _markdownBuffer = StringBuffer();

  @override
  String get markdown => _markdownBuffer.toString();

  @override
  final String tabTitle;

  @override
  final List<ClosableTab> linkedTabs = [];

  final List<Widget> _buttons = [];

  @override
  List<Widget> get buttons => _buttons;

  DynamicMarkdownTabContent(this.tabTitle);

  Uri addTabLink(ClosableTab tab) {
    linkedTabs.add(tab);
    return meynCraftUriToTab(tab);
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

  void addToButtons(Widget button) {
    _buttons.add(button);
    notifyListeners();
  }
}
